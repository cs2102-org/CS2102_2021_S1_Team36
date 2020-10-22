require('express-async-errors');
require('dotenv');
const express = require('express');
const pool = require('./sql');
const {pcsRouter} = require('./routes/pcsadmin.js');

const router = express.Router();
const app = express();
const PORT = process.env.PORT || 5000;

// DEFINE ROUTES
router.use("/", pcsRouter);

app.get('/', async(req, res) => {
    try {
        const test = await pool.query('SELECT * FROM test');
        console.log(test);
        res.json(test.rows);
    } catch (err) {
        console.error(err);
    }
});

app.use(express.json())
    .use(express.urlencoded({extended: false}))
    .use(router)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));