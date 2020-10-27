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

// get all working days and amount paid for that day, for a specified caretaker
// return table (caretaker_email, date, amount) which means caretaker worked on that date for that amount of money
bidsRouter.get('/hist/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select caretaker_email, \
            generate_series(bid_date::date, bid_date::date + interval '1 day' * (number_of_days - 1), '1 day'::interval)::date as date, \
            amount_bidded as amount \
            from bidsfor where caretaker_email = $1 and is_confirmed = true",
            [email]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// for a given range,
// get all working days and amount paid for that day, for a specified caretaker
// return table (caretaker_email, date, amount) which means caretaker worked on that date for that amount of money
bidsRouter.get('/hist/range/:email', async(req, res) => {
    try {
        const { email } = req.params;
        startdate = req.body.startdate;
        enddate = req.body.enddate;
        // startdate = '2020-01-01';
        // enddate = '2021-03-01';
        const msql = await pool.query(
            "select * from \
            (select caretaker_email, \
            generate_series(bid_date::date, bid_date::date + interval '1 day' * (number_of_days - 1), '1 day'::interval)::date as date, \
            amount_bidded as amount \
            from bidsfor where caretaker_email = $1 and is_confirmed = true) as Q1 \
            where $2::date <= Q1.date and Q1.date <= $3::date",
            [email, startdate, enddate]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// find the number of days worked and total earnings for each caretaker over a specified range
// returns table (caretaker_email, days_worked, total_earnings)
// only caretakers with nonzero work days appear in the result
bidsRouter.get('/earnings/range', async(req, res) => {
    try {
        startdate = req.body.startdate;
        enddate = req.body.enddate;
        // startdate = '2020-01-01';
        // enddate = '2021-03-01';
        const msql = await pool.query(
            "select caretaker_email, COUNT(*) as days_worked, SUM(amount) as total_earnings from \
            (select caretaker_email, \
            generate_series(bid_date::date, bid_date::date + interval '1 day' * (number_of_days - 1), '1 day'::interval)::date as date, \
            amount_bidded as amount \
            from bidsfor where is_confirmed = true) as Q1 \
            where $1::date <= Q1.date and Q1.date <= $2::date \
            group by caretaker_email",
            [startdate, enddate]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// Add rating to a Bidsfor entry
// rating must be 0 <= rating <= 5
bidsRouter.post('/rate', async (req, res) => {
    try {
        const { rating, owner_email, caretaker_email, pet_name, submission_time } = req.body;
        // console.log(req.body);
        const sql = await pool.query(
            "UPDATE bidsfor SET rating = $1 \
            WHERE owner_email=$2 AND caretaker_email=$3 AND pet_name=$4 AND submission_time=$5;",
            [rating, owner_email, caretaker_email, pet_name, submission_time]
        );
        res.status(200).send(`Updated bidsfor with: ${owner_email}, ${caretaker_email}, ${pet_name}, ${submission_time} with rating ${rating}`);
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    bidsRouter
}
