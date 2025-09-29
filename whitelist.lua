const express = require("express");
const axios = require("axios");
const app = express();

app.use(express.json());

const DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1411352211975569449/WlV3eyoDuDLwQIINO2IgU1_QZfG51oOQy0lBz29p1BHu6KbZq-iSDh2SFyBR4nNifRYu"; // thay webhook của bạn

app.post("/webhook", async (req, res) => {
    try {
        const { content } = req.body;
        if (!content) return res.status(400).json({ error: "No content" });

        await axios.post(DISCORD_WEBHOOK, { content });
        res.json({ success: true });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to send webhook" });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log("🚀 Proxy server chạy cổng " + PORT));
