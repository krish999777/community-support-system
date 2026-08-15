const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const mongoose = require("mongoose");

mongoose.connect(process.env.MONGO_URI)
    .then(() => console.log("MongoDB Connected"))
    .catch(err => console.log(err));

const app = express();
app.use(cors());
app.use(express.json());

// 👉 paste your routes here
// example:
// app.use("/api/users", require("./routes/users"));

exports.api = functions.https.onRequest(app);