const express = require("express");
const { resolve } = require("path");

const app = express();
const install = resolve("public/install.sh");

app.get("/", (_, res) => res.sendFile(install));

module.exports = app;
