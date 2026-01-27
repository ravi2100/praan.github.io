const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

admin.initializeApp();

// v2: Get user by email instead of creating a new one.
exports.createPanchayatAdmins = functions.https.onRequest(async (req, res) => {

  const results = [];
  fs.createReadStream("./panchayatlist-userid.csv")
    .pipe(csv())
    .on("data", (data) => results.push(data))
    .on("end", async () => {
      for (const user of results) {
        const email = user["EMAIL ID"];
        const password = user["PASSWORD"];

        try {
          const userRecord = await admin.auth().getUserByEmail(email);

          await admin.auth().setCustomUserClaims(userRecord.uid, { role: "Panchayat Admin" });

          // Create a document in the "users" collection
          await admin.firestore().collection("users").doc(userRecord.uid).set({
            email: email,
            role: "Panchayat Admin",
          })
          .then(() => {
            console.log(`Successfully created Firestore document for user: ${email}`);
          })
          .catch((error) => {
            console.error(`Error creating Firestore document for user: ${email}`, error);
          });

          console.log(`Successfully created user: ${email}`);
        } catch (error) {
          console.error(`Error creating user: ${email}`, error);
        }
      }
    });

  res.send("User creation process started.");
});
