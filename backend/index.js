require('express-async-errors');
require('dotenv');
const express = require('express');
const pool = require('./db');
const cors = require('cors');
const {pcsRouter} = require('./routes/pcsadmin.js');
const {authRouter} = require('./routes/auth');

const router = express.Router();
const app = express();
const PORT = process.env.PORT || 5000;

// DEFINE ROUTES
router.use("/api/auth", authRouter)
      .use("/api/pcs-admins", pcsRouter);

app.use(express.json())
    .use(cors())
    .use(express.urlencoded({extended: false}))
    .use(router)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));