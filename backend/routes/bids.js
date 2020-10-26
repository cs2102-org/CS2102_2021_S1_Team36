const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const bidsRouter = express.Router();

/*
to test the endpoints here, use /api/bids/ in front of the urls
*/

// get all bids (the whole BidsFor table)
bidsRouter.get('/all', async(req, res) => {
    try {
        const msql = await pool.query(
            "select * from bidsfor;",
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get all bids by a specified petowner
bidsRouter.get('/by/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * from bidsfor where owner_email = $1;",
            [email]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get all bids for a specified caretaker
bidsRouter.get('/for/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * from bidsfor where caretaker_email = $1;",
            [email]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    bidsRouter
}