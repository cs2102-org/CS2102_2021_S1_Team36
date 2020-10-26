const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const bodyParser = require('body-parser')

const caretakerRouter = express.Router();

/*
to test the endpoints here, use /api/caretaker/ in front of the urls
*/

// get the fullTimeLeave table
caretakerRouter.get('/ft/leave/all', async(req, res) => {
    try {
        const allLeave = await pool.query(
            "SELECT * FROM FullTimeLeave",
        );
        res.json(allLeave.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the fullTimeLeave of a specified full time caretaker
caretakerRouter.get('/ft/leave/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const leaves = await pool.query(
            "SELECT * FROM FullTimeLeave WHERE email = $1",
            [email]
        );
        res.json(leaves.rows);
    } catch (err) {
        console.error(err);
    }
}); // todo: check that specified caretaker is actually full time

// view all caretakers
caretakerRouter.get('/all', async(req, res) => {
    try {
        const cts = await pool.query(
            "SELECT * FROM Caretakers;",
        );
        res.json(cts.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view all caretakers non-availability (na)
// i.e. for each caretaker, all the confirmed bids and all their leave dates
caretakerRouter.get('/ft/na/all', async(req, res) => {
    try {
        const msql = await pool.query(
            "select email, leave_date as na_start_date, 1 as na_num_days from fulltimeleave \
            UNION \
            select caretaker_email as email, bid_date as na_start_date, number_of_days as na_num_days from bidsfor where is_confirmed = true;"
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view a specified fulltime caretakers non-availability
caretakerRouter.get('/ft/na/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const sql = await pool.query(
            "select leave_date as date, 1 as num_days from \
            fulltimeleave where email=$1 \
            UNION \
            select bid_date as date, number_of_days as num_days from bidsfor where caretaker_email = $1 and is_confirmed = true;",
            [email]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view all full time caretakers available for a specified date range
// accounts for their leave and their confirmed bids
caretakerRouter.get('/ft/na/range', async(req, res) => {
    try {
        var startdate = req.body.startdate;
        var numdays = req.body.numdays;
        const sql = await pool.query(
            "select C1.email from caretakers C1 \
            where C1.is_fulltime = True \
            and not exists ( \
            select 1 from (select leave_date as date, 1 as num_days from fulltimeleave where email=C1.email UNION select bid_date as date, number_of_days as num_days from bidsfor where caretaker_email = C1.email and is_confirmed = true) as NA \
            where ($1 <= NA.date and TO_TIMESTAMP($1, 'YYYY-MM-DD') + interval '1' day * $2 >= NA.date) \
            or (NA.date < $1 and NA.date + interval '1' day * NA.num_days >= $1));",
            [startdate, numdays]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the availability of all part time caretaker
// i.e. their available dates - dates where they have confirmed bids
caretakerRouter.get('/pt/avail/all', async(req, res) => {
    try {
        const sql = await pool.query(
            "select email, work_date as date, 1 as num_days from parttimeavail P1 \
            where \
            NOT EXISTS \
            (SELECT bid_date AS date, number_of_days AS num_days FROM bidsfor \
            WHERE caretaker_email = email \
            AND bid_date <= P1.work_date AND date(P1.work_date) - date(bid_date) <= (number_of_days - 1) \
            );"
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the availability of a specified part time worker
// i.e. their available dates - dates where they have confirmed bids
caretakerRouter.get('/pt/avail/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const sql = await pool.query(
            "select work_date as date, 1 as num_days from parttimeavail P1 \
            where P1.email = $1 \
            and \
            NOT EXISTS \
            (SELECT bid_date AS date, number_of_days AS num_days FROM bidsfor \
            WHERE caretaker_email = $1 \
            AND bid_date <= P1.work_date AND date(P1.work_date) - date(bid_date) <= (number_of_days - 1) \
            );",
            [email]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// find all caretakers who can look after a specified pet type
caretakerRouter.get('/type/:type', async(req, res) => {
    try {
        const { type } = req.params;
        const msql = await pool.query(
            "select email from caretakers C1 \
            where exists (select 1 from takecareprice where email = C1.email and species = $1);",
            [type]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// find all active caretakers, i.e. all fulltime + all parttime who have a avail date in the last two years
caretakerRouter.get('/active', async(req, res) => {
    try {
        const msql = await pool.query(
            "select email, is_fulltime, U1.name, description, rating \
            from caretakers NATURAL JOIN users as U1 \
            where is_fulltime = true \
            UNION  \
            select email, is_fulltime, U2.name, description, rating \
            FROM \
            (select DISTINCT email, false as is_fulltime \
            from parttimeavail  \
            where date(NOW()::timestamp) <= work_date and work_date <= date(NOW()::timestamp) + interval '2' year) as active \
            NATURAL JOIN caretakers NATURAL JOIN users as U2;"
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});




module.exports = {
    caretakerRouter
}
