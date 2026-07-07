require("dotenv").config();
const express = require("express");
const cors = require("cors");
const OpenAI = require("openai");

const app = express();
const PORT = process.env.PORT || 3000;

let openai = null;
function getOpenAI() {
  if (!process.env.OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY is not configured on Railway.");
  }
  if (!openai) {
    openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }
  return openai;
}
const API_SECRET = process.env.API_SECRET || "";
const MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const TOKEN_RATE_USD = Number(process.env.TOKEN_RATE_USD || 0.002);

const FEATURE_TOKEN_COSTS = {
  "script-generation": { min: 180, label: "Script Generation" },
  "complaint-response": { min: 120, label: "Complaint Response" },
  "billing-agent": { min: 250, label: "Billing Agent Review" },
  "manager-brief": { min: 300, label: "Manager Brief" },
  chat: { min: 80, label: "Chat Coach" },
  roleplay: { min: 200, label: "Roleplay" },
  "crm-assist": { min: 100, label: "CRM Assist" },
};

function buildTokenCharge(feature, tokensUsed, tier = "Free") {
  const min = FEATURE_TOKEN_COSTS[feature]?.min ?? 100;
  const billableTokens = Math.max(tokensUsed || 0, min);
  const chargeUSD = Number(((billableTokens / 1000) * TOKEN_RATE_USD).toFixed(4));
  return {
    feature,
    featureLabel: FEATURE_TOKEN_COSTS[feature]?.label || feature,
    tokensUsed: tokensUsed || 0,
    billableTokens,
    chargeUSD,
    ratePer1k: TOKEN_RATE_USD,
    tier,
  };
}

const COACH_PROMPT =
  "You are Sales Coach, an expert AI sales trainer and CRM assistant. Help users write scripts, improve pitches, handle objections, and close deals. Be concise, actionable, and encouraging.";

app.use(cors());
app.use(express.json({ limit: "1mb" }));

function authMiddleware(req, res, next) {
  if (!API_SECRET) return next();
  const key = req.headers["x-api-key"];
  if (key !== API_SECRET) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
}

app.use("/api", authMiddleware);

app.get("/health", (_req, res) => {
  const key = process.env.OPENAI_API_KEY || "";
  const openaiConfigured = Boolean(key) && !key.includes("your-") && !key.startsWith("sk-your");
  res.json({
    status: "ok",
    service: "salescoach-api",
    openai: openaiConfigured,
    openaiKeyValid: openaiConfigured,
    tokenBilling: {
      ratePer1k: TOKEN_RATE_USD,
      features: FEATURE_TOKEN_COSTS,
    },
  });
});

app.get("/api/billing/token-rates", (_req, res) => {
  res.json({
    ratePer1k: TOKEN_RATE_USD,
    features: FEATURE_TOKEN_COSTS,
  });
});

app.post("/api/billing/charge-preview", (req, res) => {
  const { feature, tokensUsed, tier } = req.body;
  if (!feature) {
    return res.status(400).json({ error: "feature required" });
  }
  res.json(buildTokenCharge(feature, Number(tokensUsed) || 0, tier || "Free"));
});

app.post("/api/billing/usage-report", async (req, res) => {
  try {
    const { tier, tokensUsed, roleplaysUsed, discoveryUsed, featureBreakdown } = req.body;
    const limitByTier = { Free: 10000, Pro: 100000, Team: 500000, Enterprise: null };
    const limit = limitByTier[tier] ?? null;
    const overageTokens = limit == null ? 0 : Math.max(0, Number(tokensUsed) - limit);
    const overageUSD = Number(((overageTokens / 1000) * TOKEN_RATE_USD).toFixed(2));
    const breakdown = (featureBreakdown || []).map((row) =>
      buildTokenCharge(row.feature, Number(row.tokensUsed) || 0, tier)
    );
    const totalUSD = breakdown.reduce((sum, row) => sum + row.chargeUSD, 0);

    res.json({
      tier,
      tokensUsed: Number(tokensUsed) || 0,
      tokenLimit: limit,
      overageTokens,
      overageUSD,
      totalFeatureChargesUSD: Number(totalUSD.toFixed(4)),
      breakdown,
      roleplaysUsed: Number(roleplaysUsed) || 0,
      discoveryUsed: Number(discoveryUsed) || 0,
    });
  } catch (err) {
    return handleOpenAIError(err, res, "Usage report failed");
  }
});

async function chatCompletion(messages, temperature = 0.7) {
  const response = await getOpenAI().chat.completions.create({
    model: MODEL,
    messages,
    temperature,
  });
  return {
    content: response.choices[0]?.message?.content?.trim() || "",
    tokensUsed: response.usage?.total_tokens ?? 0,
  };
}

function handleOpenAIError(err, res, fallbackMessage) {
  const msg = err?.message || fallbackMessage || "AI request failed";
  console.error(fallbackMessage || "openai error:", err);
  if (msg.includes("Incorrect API key")) {
    return res.status(503).json({
      error:
        "OpenAI API key invalid on Railway. Set OPENAI_API_KEY in Railway Variables to a real key from platform.openai.com/api-keys.",
      code: "OPENAI_KEY_INVALID",
    });
  }
  return res.status(500).json({ error: msg });
}

app.post("/api/chat/team-sales", async (req, res) => {
  try {
    const { messages, repName, teamMembers, leads } = req.body;
    if (!Array.isArray(messages)) {
      return res.status(400).json({ error: "messages array required" });
    }
    const teamSummary = (teamMembers || [])
      .slice(0, 8)
      .map((m) => `- ${m.name || m.fullName || "Rep"}`)
      .join("\n");
    const leadSummary = (leads || [])
      .slice(0, 8)
      .map((l) => `- ${l.name} @ ${l.company || "no company"}`)
      .join("\n");
    const system = `${COACH_PROMPT}

This is an internal team sales log. Reps announce closed deals to their sales team. Clients do NOT use this app.

When the user reports a closed sale, respond with JSON ONLY:
{"reply":"friendly confirmation","actions":[{"type":"logSale","leadMatch":"Client or Company","dealValue":5000,"summary":"optional notes"}]}

Only use action type logSale. Do NOT create leads, log calls, or schedule follow-ups.

Rep logging: ${repName || "Sales Rep"}
Team:
${teamSummary || "(solo rep)"}

Known accounts (optional CRM match):
${leadSummary || "(none)"}`;

    const result = await chatCompletion(
      [{ role: "system", content: system }, ...messages],
      0.4
    );
    let parsed;
    try {
      parsed = JSON.parse(result.content.replace(/```json|```/g, "").trim());
    } catch {
      parsed = { reply: result.content, actions: [] };
    }
    const actions = (parsed.actions || []).filter((a) => a.type === "logSale");
    res.json({
      reply: parsed.reply || result.content,
      actions,
      tokensUsed: result.tokensUsed,
    });
  } catch (err) {
    return handleOpenAIError(err, res, "Team sales chat failed");
  }
});

app.post("/api/chat", async (req, res) => {
  try {
    const { messages } = req.body;
    if (!Array.isArray(messages)) {
      return res.status(400).json({ error: "messages array required" });
    }
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      ...messages,
    ]);
    res.json({ content: result.content, tokensUsed: result.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Chat failed");
  }
});

app.post("/api/roleplay/turn", async (req, res) => {
  try {
    const { scenario, personality, personalityDescription, transcript, closingProgress } = req.body;
    const system = `You are roleplaying as a ${personality} in a ${scenario} sales scenario. Stay in character. ${personalityDescription || ""} Current closing progress: ${closingProgress || 0}/100. Return valid JSON only with keys: customerReply (string, 1-3 sentences), closingProgressDelta (int, -10 to 15), suggestion (string, one coaching tip for the sales rep).`;

    const apiMessages = [{ role: "system", content: system }];
    for (const entry of transcript || []) {
      apiMessages.push({
        role: entry.speaker === "You" ? "user" : "assistant",
        content: entry.text,
      });
    }

    const raw = await chatCompletion(apiMessages);
    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    let parsed;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      parsed = {
        customerReply: raw.content,
        closingProgressDelta: 3,
        suggestion: "Ask a follow-up question to keep the conversation moving.",
      };
    }

    res.json({
      customerReply: parsed.customerReply || raw.content,
      closingProgressDelta: Math.min(15, Math.max(-10, parsed.closingProgressDelta ?? 3)),
      suggestion: parsed.suggestion || "Listen actively and respond to their last point.",
      tokensUsed: raw.tokensUsed,
    });
  } catch (err) {
    return handleOpenAIError(err, res, "Roleplay failed");
  }
});

app.post("/api/roleplay/score", async (req, res) => {
  try {
    const { scenario, personality, transcript } = req.body;
    const transcriptText = (transcript || [])
      .map((e) => `${e.speaker}: ${e.text}`)
      .join("\n");

    const prompt = `Score this sales roleplay from 1-100. Scenario: ${scenario}. Customer type: ${personality}.\n\nTranscript:\n${transcriptText}\n\nReturn JSON with keys: overallScore (int), categories (array of {name, score}), strengths (array), improvements (array), betterResponses (array), scriptSuggestions (array). Categories: Confidence, Clarity, Listening, Rapport Building, Discovery Questions, Objection Handling, Closing Ability, Professionalism, Product Knowledge.`;

    const raw = await chatCompletion([
      { role: "system", content: "You are a sales coach scoring roleplay sessions. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.4);

    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Scoring failed");
  }
});

app.post("/api/crm/follow-up", async (req, res) => {
  try {
    const { type, lead } = req.body;
    const prompt = `Generate a ${type} for this lead: Name: ${lead.name}, Company: ${lead.company}, Stage: ${lead.dealStage}, Value: $${lead.dealValue}, Notes: ${lead.notes}. Make it professional and ready to send.`;
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ content: result.content, tokensUsed: result.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Follow-up generation failed");
  }
});

app.post("/api/crm/next-action", async (req, res) => {
  try {
    const { lead } = req.body;
    const prompt = `Given lead Name: ${lead.name}, Company: ${lead.company}, Stage: ${lead.dealStage}, Probability: ${lead.probabilityOfClosing}%, Notes: ${lead.notes}—recommend ONE specific next action in one sentence.`;
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ content: result.content, tokensUsed: result.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Recommendation failed");
  }
});

app.post("/api/crm/pre-call-briefing", async (req, res) => {
  try {
    const { lead, category } = req.body;
    const intel = lead.contactIntel || {};
    const prompt = `Generate a pre-call briefing for a sales rep calling ${lead.name} at ${lead.company}.
Vertical: ${category || lead.leadSource || "General sales"}
Stage: ${lead.dealStage}, Probability: ${lead.probabilityOfClosing}%, Value: $${lead.dealValue}
Notes: ${lead.notes || "None"}
Personal intel: likes=${intel.likes || ""}, interests=${intel.interests || ""}, kids=${intel.kidsNames || ""}
Return JSON only with keys: openingLine (string), keyPoints (array of strings), questionsToAsk (array), closeLine (string), personalHooks (array of strings referencing personal details when available).`;

    const raw = await chatCompletion([
      { role: "system", content: "You are a sales coach. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.5);

    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Pre-call briefing failed");
  }
});

app.post("/api/crm/post-visit-debrief", async (req, res) => {
  try {
    const { lead, visitNotes } = req.body;
    const prompt = `Debrief a field visit with ${lead.name} at ${lead.company}.
Stage: ${lead.dealStage}, Notes from visit: ${visitNotes || "No notes provided"}
Return JSON only with keys: whatWentWell (array), improvements (array), nextStep (string), practicePrompt (string for roleplay practice).`;

    const raw = await chatCompletion([
      { role: "system", content: "You are a sales coach. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.5);

    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Post-visit debrief failed");
  }
});

app.post("/api/training/analyze-call", async (req, res) => {
  try {
    const { transcript } = req.body;
    if (!transcript || !String(transcript).trim()) {
      return res.status(400).json({ error: "transcript required" });
    }

    const prompt = `Analyze this sales call transcript and return JSON only with keys:
talkRatioPercent (int, rep talk % estimate), questionsAsked (int), fillerWordCount (int),
overallScore (int 1-100), strengths (array), improvements (array).

Transcript:
${transcript}`;

    const raw = await chatCompletion([
      { role: "system", content: "You are a sales call analyst. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.4);

    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Call analysis failed");
  }
});

app.post("/api/tts", async (req, res) => {
  try {
    const { text, voice = "shimmer", speed = 0.94, model = "tts-1-hd" } = req.body;
    if (!text || !String(text).trim()) {
      return res.status(400).json({ error: "text required" });
    }

    const speech = await getOpenAI().audio.speech.create({
      model: model === "tts-1" ? "tts-1" : "tts-1-hd",
      voice,
      input: String(text).trim(),
      speed: Math.min(1.15, Math.max(0.82, Number(speed) || 0.94)),
    });

    const buffer = Buffer.from(await speech.arrayBuffer());
    const tokensUsed = Math.max(1, Math.ceil(String(text).length / 4));

    res.json({
      audioBase64: buffer.toString("base64"),
      tokensUsed,
    });
  } catch (err) {
    return handleOpenAIError(err, res, "TTS failed");
  }
});

app.post("/api/crm/win-loss-autopsy", async (req, res) => {
  try {
    const { lead, won, finalValue, reason } = req.body;
    const prompt = `Analyze this ${won ? "WON" : "LOST"} deal for coaching.
Client: ${lead.name} at ${lead.company}
Stage: ${lead.dealStage}, Value: $${finalValue}, Objections: ${(lead.objectionTags || []).join(", ")}
${won ? "" : `Loss reason: ${reason || "unknown"}`}
Return JSON only with keys: headline, whatWorked (array), whatToImprove (array), playbookSnippet (string), recommendedDrill (string), nextActions (array).`;

    const raw = await chatCompletion([
      { role: "system", content: "You are a sales coach. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.5);

    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed });
  } catch (err) {
    return handleOpenAIError(err, res, "Win/loss autopsy failed");
  }
});

app.post("/api/office/generate-script", async (req, res) => {
  try {
    const { scriptType, lead, category, customPrompt } = req.body;
    const prompt = `Write a ${scriptType || "sales"} script for a rep selling to ${lead?.name || "a prospect"} at ${lead?.company || "their company"}.
Category: ${category || "general"}. Extra instructions: ${customPrompt || "none"}.
Return only the script text the rep should say, ready to use.`;
    const raw = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ script: raw.content, tokensUsed: raw.tokensUsed, billing: buildTokenCharge("script-generation", raw.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Script generation failed");
  }
});

app.post("/api/office/complaint-response", async (req, res) => {
  try {
    const { summary, details, clientName, priority } = req.body;
    const prompt = `Draft a professional, empathetic client complaint response.
Client: ${clientName}. Priority: ${priority}. Issue: ${summary}. Details: ${details || ""}.
Return only the response message text.`;
    const raw = await chatCompletion([
      { role: "system", content: "You de-escalate client issues and protect the relationship." },
      { role: "user", content: prompt },
    ]);
    res.json({ response: raw.content, tokensUsed: raw.tokensUsed, billing: buildTokenCharge("complaint-response", raw.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Complaint response failed");
  }
});

app.post("/api/office/billing-agent", async (req, res) => {
  try {
    const { tier, tokensUsed, roleplaysUsed, discoveryUsed } = req.body;
    const prompt = `You are an autonomous billing agent for a sales coaching SaaS app.
Current plan: ${tier}. Tokens used: ${tokensUsed}. Roleplays: ${roleplaysUsed}. Discovery searches: ${discoveryUsed}.
Return JSON only with keys: summary (string), recommendedTier (Free|Pro|Team|Enterprise), actions (array of {title, detail}).`;
    const raw = await chatCompletion([
      { role: "system", content: "Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.4);
    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed, billing: buildTokenCharge("billing-agent", raw.tokensUsed, tier) });
  } catch (err) {
    return handleOpenAIError(err, res, "Billing agent failed");
  }
});

app.post("/api/office/manager-brief", async (req, res) => {
  try {
    const { pipeline, winRate, staleCount, overdueCount, avgScore } = req.body;
    const prompt = `Create a manager morning coaching brief.
Pipeline: $${pipeline}. Win rate: ${winRate}%. Stale deals: ${staleCount}. Overdue follow-ups: ${overdueCount}. Avg roleplay score: ${avgScore}.
Return JSON with keys: headline, repHighlights (array), coachingAssignments (array), pipelineAlerts (array), teamWins (array).`;
    const raw = await chatCompletion([
      { role: "system", content: "You are a sales manager coach. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.5);
    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed, billing: buildTokenCharge("manager-brief", raw.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Manager brief failed");
  }
});

app.post("/api/platform/bi-query", async (req, res) => {
  try {
    const { question } = req.body;
    if (!question) return res.status(400).json({ error: "question required" });
    const result = await chatCompletion([
      { role: "system", content: "You are a revenue intelligence analyst for sales teams. Answer concisely with actionable insights." },
      { role: "user", content: String(question) },
    ]);
    res.json({ answer: result.content, tokensUsed: result.tokensUsed, billing: buildTokenCharge("crm-assist", result.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "BI query failed");
  }
});

app.post("/api/platform/proposal", async (req, res) => {
  try {
    const { clientName, company, amount, scope, notes } = req.body;
    const prompt = `Write a professional sales proposal for ${clientName} at ${company}. Investment: $${amount}. Scope: ${scope || "standard package"}. Context: ${notes || ""}. Include executive summary, scope, pricing, and next steps.`;
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ proposal: result.content, tokensUsed: result.tokensUsed, billing: buildTokenCharge("script-generation", result.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Proposal generation failed");
  }
});

app.post("/api/platform/email", async (req, res) => {
  try {
    const { type, clientName, company, stage } = req.body;
    const prompt = `Write a ${type} email for ${clientName} at ${company}. Deal stage: ${stage}. Include subject line. Ready to send.`;
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ email: result.content, tokensUsed: result.tokensUsed, billing: buildTokenCharge("crm-assist", result.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Email generation failed");
  }
});

app.post("/api/platform/live-copilot", async (req, res) => {
  try {
    const { clientName, company, stage, transcript, category } = req.body;
    if (!transcript) return res.status(400).json({ error: "transcript required" });
    const prompt = `Live sales call coaching. Vertical: ${category || "General"}. Client: ${clientName} at ${company}. Stage: ${stage}.
Rep just said: "${transcript}"
Give ONE short coaching tip (1-2 sentences) for what to say or ask next. Be specific and actionable.`;
    const result = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ], 0.6);
    res.json({ tip: result.content, tokensUsed: result.tokensUsed, billing: buildTokenCharge("chat", result.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Live co-pilot failed");
  }
});

app.post("/api/platform/campaign", async (req, res) => {
  try {
    const { name, channel, audience, goal } = req.body;
    const prompt = `Create a ${channel || "email"} marketing campaign draft.
Name: ${name}. Audience: ${audience || "prospects"}. Goal: ${goal || "pipeline growth"}.
Return JSON only with keys: subject, preview, body, cadence (array of day labels).`;
    const raw = await chatCompletion([
      { role: "system", content: "You are a B2B marketing strategist. Return valid JSON only." },
      { role: "user", content: prompt },
    ], 0.5);
    const cleaned = raw.content.replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(cleaned);
    res.json({ ...parsed, tokensUsed: raw.tokensUsed, billing: buildTokenCharge("crm-assist", raw.tokensUsed) });
  } catch (err) {
    return handleOpenAIError(err, res, "Campaign generation failed");
  }
});

app.listen(PORT, () => {
  console.log(`Sales Coach AI API running on port ${PORT}`);
});
