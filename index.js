const express = require("express");
const app = express();

app.get("/", (_, res) => {
  res.sendFile("public/install.sh", { root: __dirname });
});

module.exports = app;
