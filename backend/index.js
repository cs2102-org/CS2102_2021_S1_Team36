const express = require('express');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json())
    .use(express.urlencoded({extended: false}))
    .listen(PORT, () => console.log(`Running server on ${PORT}`));