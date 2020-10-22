const express = require('express');
const pool = require('../db');
const { json } = require('express');

const router = express.Router();

router.get('/caretaker-availabilities', async (req, res) => {
    const { rows } = await pool.query(
        "SELECT * FROM Caretakers;"
    );

    return res.status(200).json(rows);
})

router.get('/caretaker-bids', async (req, res) => {
    const { rows } = await pool.query(
        "SELECT * FROM BidsFor;"
    )

    return res.status(200).json(rows);
})