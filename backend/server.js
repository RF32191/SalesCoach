require("dotenv").config();
const express = require("express");
const cors = require("cors");
const OpenAI = require("openai");

const app = express();
const PORT = process.env.PORT || 3000;

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const API_SECRET = process.env.API_SECRET || "";
const MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

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
  res.json({
    status: "ok",
    service: "salescoach-api",
    openai: Boolean(process.env.OPENAI_API_KEY),
  });
});

async function chatCompletion(messages, temperature = 0.7) {
  const response = await openai.chat.completions.create({
    model: MODEL,
    messages,
    temperature,
  });
  return response.choices[0]?.message?.content?.trim() || "";
}

app.post("/api/chat", async (req, res) => {
  try {
    const { messages } = req.body;
    if (!Array.isArray(messages)) {
      return res.status(400).json({ error: "messages array required" });
    }
    const content = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      ...messages,
    ]);
    res.json({ content });
  } catch (err) {
    console.error("chat error:", err);
    res.status(500).json({ error: err.message || "Chat failed" });
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
    const cleaned = raw.replace(/```json/g, "").replace(/```/g, "").trim();
    let parsed;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      parsed = {
        customerReply: raw,
        closingProgressDelta: 3,
        suggestion: "Ask a follow-up question to keep the conversation moving.",
      };
    }

    res.json({
      customerReply: parsed.customerReply || raw,
      closingProgressDelta: Math.min(15, Math.max(-10, parsed.closingProgressDelta ?? 3)),
      suggestion: parsed.suggestion || "Listen actively and respond to their last point.",
    });
  } catch (err) {
    console.error("roleplay turn error:", err);
    res.status(500).json({ error: err.message || "Roleplay failed" });
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

    const cleaned = raw.replace(/```json/g, "").replace(/```/g, "").trim();
    res.json(JSON.parse(cleaned));
  } catch (err) {
    console.error("score error:", err);
    res.status(500).json({ error: err.message || "Scoring failed" });
  }
});

app.post("/api/crm/follow-up", async (req, res) => {
  try {
    const { type, lead } = req.body;
    const prompt = `Generate a ${type} for this lead: Name: ${lead.name}, Company: ${lead.company}, Stage: ${lead.dealStage}, Value: $${lead.dealValue}, Notes: ${lead.notes}. Make it professional and ready to send.`;
    const content = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ content });
  } catch (err) {
    res.status(500).json({ error: err.message || "Follow-up generation failed" });
  }
});

app.post("/api/crm/next-action", async (req, res) => {
  try {
    const { lead } = req.body;
    const prompt = `Given lead Name: ${lead.name}, Company: ${lead.company}, Stage: ${lead.dealStage}, Probability: ${lead.probabilityOfClosing}%, Notes: ${lead.notes}—recommend ONE specific next action in one sentence.`;
    const content = await chatCompletion([
      { role: "system", content: COACH_PROMPT },
      { role: "user", content: prompt },
    ]);
    res.json({ content });
  } catch (err) {
    res.status(500).json({ error: err.message || "Recommendation failed" });
  }
});

app.listen(PORT, () => {
  console.log(`Sales Coach API running on port ${PORT}`);
});
