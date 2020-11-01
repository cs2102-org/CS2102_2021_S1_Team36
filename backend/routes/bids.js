const express = require('express');
const pool = require('../db');
const { json, response } = require('express');
const { verifyJwt } = require('../auth/index')

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
bidsRouter.get('/by', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const msql = await pool.query(
            "SELECT amount_bidded, caretaker_email, name, to_char(end_date, 'YYYY-mm-dd') as end, is_confirmed, is_paid, payment_type, pet_name, rating, to_char(start_date, 'YYYY-mm-dd') as start, 	to_char(submission_time, 'HH24:MI:SS') as submission_time, transfer_type \
                FROM Bidsfor B INNER JOIN Users U on B.caretaker_email=U.email \
            WHERE owner_email = $1 \
            ORDER BY \
            submission_time desc;",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// gets pending and upcoming bids for a specific petowner
// upcoming means now() <= start date of job
// order by earliest starting job first
bidsRouter.get('/by/:email/pending', async (req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * \
            from bidsfor    \
            where owner_email = $1 \
              and is_confirmed is null \
              and start_date >= now()::date \
            order by start_date ASC, end_date ASC;",
            [email]
        );
        res.json(msql.rows);
    } catch (err) {
        console.error(err);
    }
});

// gets rejected bids for a specific petowner
// is_confirmed = false regardless of time, like a record of all rejected bids
// reverse chronological order (recent start date first)
bidsRouter.get('/by/:email/rejected', async (req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * \
            from bidsfor    \
            where owner_email = $1  \
              and is_confirmed is false \
            order by start_date DESC, end_date DESC;",
            [email]
        );
        res.json(msql.rows);
    } catch (err) {
        console.error(err);
    }
});

// gets done bids for a specific petowner
bidsRouter.get('/by/:email/done', async (req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * \
            from bidsfor    \
            where owner_email = $1  \
              and is_confirmed is true \
            order by start_date DESC, end_date DESC;",
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

// add a bid
bidsRouter.post('/add', verifyJwt, async(req, res) => {
    try {
        const owner_email = res.locals.user.email;

        const { caretaker_email, pet_name, submission_time, start_date, end_date,
                amount_bidded, payment_type, transfer_type } = req.body;


        const petSpeciesSql = await pool.query(
            "select species from pets where email = $1 and pet_name = $2;",
            [owner_email, pet_name]
        );
        var species = petSpeciesSql.rows[0]["species"];

        const priceSql = await pool.query(
            "select daily_price from Takecareprice where email = $1 and species = $2",
            [caretaker_email, species]
        );
        var price = priceSql.rows[0]["daily_price"];

        const msql = await pool.query(
            "INSERT INTO BidsFor(owner_email, caretaker_email, pet_name, submission_time, start_date, end_date, price, \
            amount_bidded, payment_type, transfer_type) \
            VALUES \
            ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);",
            [owner_email, caretaker_email, pet_name, submission_time, start_date, end_date, price,
             amount_bidded, payment_type, transfer_type]
        );
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});
/* test example:
    "owner_email" : "peter@gmail.com",
    "caretaker_email" : "cassie@gmail.com",
    "pet_name" : "boomer",
    "submission_time" : "2020-10-25",
    "start_date" : "2020-10-26",
    "end_date" : "2020-10-30",
    "price" : 100,
    "amount_bidded" : 200,
    "is_confirmed" : true,
    "is_paid" : false,
    "payment_type" : "1",
    "transfer_type" : "2",
    "rating" : null,
*/

// get all working days and amount paid for that day, for a specified caretaker
// return table (caretaker_email, date, amount) which means caretaker worked on that date for that amount of money
bidsRouter.get('/hist/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select caretaker_email, \
            generate_series(start_date, end_date, '1 day'::interval)::date as date, \
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
        var { start_date, end_date } = req.body;
        // startdate = '2020-01-01';
        // enddate = '2021-03-01';
        const msql = await pool.query(
            "select * from \
            (select caretaker_email, \
            generate_series(start_date, end_date, '1 day'::interval)::date as date, \
            amount_bidded as amount \
            from bidsfor where caretaker_email = $1 and is_confirmed = true) as Q1 \
            where $2::date <= Q1.date and Q1.date <= $3::date",
            [email, start_date, end_date]
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
        var { start_date, end_date } = req.body;
        const msql = await pool.query(
            "select caretaker_email, COUNT(*) as days_worked, SUM(amount) as total_earnings from \
                (select caretaker_email, \
                generate_series(start_date, end_date, '1 day'::interval)::date as date, \
                amount_bidded as amount \
                from bidsfor where is_confirmed = true) as Q1 \
            where $1::date <= Q1.date and Q1.date <= $2::date \
            group by caretaker_email",
            [start_date, end_date]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// Add rating to a Bidsfor entry
// rating must be 0 <= rating <= 5
bidsRouter.put('/rate', verifyJwt, async (req, res) => {
    try {
        const owner_email = res.locals.user.email;
        const { rating, caretaker_email, pet_name, submission_time } = req.body;
        const sql = await pool.query(
            "UPDATE bidsfor SET rating = $1 \
            WHERE owner_email=$2 AND caretaker_email=$3 AND pet_name=$4 AND to_char(submission_time, 'HH24:MI:SS')=$5;",
            [rating, owner_email, caretaker_email, pet_name, submission_time]
        );
        console.log(sql);
        res.status(200).send({message: `Updated bidsfor with: ${owner_email}, ${caretaker_email}, ${pet_name}, ${submission_time} with rating ${rating}`});
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    bidsRouter
}
