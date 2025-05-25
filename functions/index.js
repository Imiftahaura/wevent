/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const fetch = require("node-fetch");

const challongeApiKey = "API_KEY_ANDA"; // ⚠️ GANTI DENGAN API KEY CHALLONGE ANDA ⚠️

exports.getTournaments = functions.https.onRequest(async (req, res) => {
  try {
    const response = await fetch("https://api.challonge.com/v1/tournaments.json", {
      method: "GET",
      headers: {
        "Authorization": `Basic ${Buffer.from(challongeApiKey + ":").toString("base64")}`,
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      console.error(`Challonge API error: ${response.status} ${response.statusText}`);
      res.status(response.status).send(`Error fetching tournaments from Challonge: ${response.statusText}`);
      return;
    }

    const tournaments = await response.json();
    res.status(200).send(tournaments);
  } catch (error) {
    console.error("Error fetching tournaments:", error);
    res.status(500).send(`Internal Server Error: ${error}`);
  }
});