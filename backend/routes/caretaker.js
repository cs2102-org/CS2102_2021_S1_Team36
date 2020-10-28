const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const bodyParser = require('body-parser')

const caretakerRouter = express.Router();

/*
to test the endpoints here, use http://localhost:5000/api/caretaker/ in front of the urls
*/

// takes in two date objects
// i.e. start = new Date('2020-01-01')
// return arr of all the days in between
var getDaysArray = function(start, end) {
    for(var arr=[],dt=new Date(start); dt<=end; dt.setDate(dt.getDate()+1)){
        arr.push(new Date(dt));
    }
    return arr;
};

// dateString is YYYY-mm-dd
var incDate = function(dateString, numDays) {
    dt = new Date(dateString)
    dt.setDate(dt.getDate() + 1)
    dts = `${dt.getFullYear()}-${dt.getMonth()+1}-${dt.getDate()}`;
    return dts
};

// Give a specified caretaker leave on the interval [start_date, end_date]
// todo: check for overlaps with existing leave dates
caretakerRouter.post('/ft/leave/new/range/:email', async(req, res) => {
    try {
        const {email} = req.params;
        var {start_date, end_date} = req.body;
        start_date = new Date(start_date);
        end_date = new Date(end_date);

        console.log(email, start_date, end_date);
        var arr = getDaysArray(start_date, end_date);
        var leave_date;
        for (var i = 0; i < arr.length; i++) {
            leave_date = `${arr[i].getFullYear()}-${arr[i].getMonth()+1}-${arr[i].getDate()}`;
            const msql = await pool.query(
                "INSERT INTO FullTimeLeave(email, leave_date) VALUES ($1, $2)",
                [email, leave_date]
            );
        }
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

// insert new caretaker
caretakerRouter.post('/new', async(req, res) => {
    try {
        const {email, full_time, rating} = req.body;
        console.log(email);
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

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
 // todo: check that specified caretaker is actually full time
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


// view all caretakers non-availability (na)
// i.e. for each caretaker, all the confirmed bids and all their leave dates
caretakerRouter.get('/ft/na/all', async(req, res) => {
    try {
        const msql = await pool.query(
            "select email, leave_date as start_date, leave_date as end_date from fulltimeleave \
            UNION \
            select \
                caretaker_email as email, \
                start_date, \
                end_date \
            from bidsfor where is_confirmed = true;"
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});
// test


// view a specified fulltime caretakers non-availability
caretakerRouter.get('/ft/na/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const sql = await pool.query(
            "select email, leave_date as start, leave_date as end from fulltimeleave where email = $1 \
            UNION \
            select \
                caretaker_email as email, \
                start_date as start, \
                end_date as end \
            from bidsfor where \
                caretaker_email = $1 and \
                is_confirmed = true;",
            [email]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view all full time caretakers available for a specified date range
// accounts for their leave and their confirmed bids
// range is specified as start_date, end_date inclusive
caretakerRouter.get('/ft/unavail/range', async(req, res) => {
    try {
        var { start_date, end_date } = req.body;
        end_date = incDate(end_date);
        // var startdate = '2020-10-11';
        // var numdays = 5;
        const msql = await pool.query(
            "select C1.email from caretakers C1 \
            where C1.is_fulltime = True  \
            and not exists ( \
            (select leave_date as na_date \
            from fulltimeleave \
            where email=C1.email and \
            (leave_date, leave_date + interval '1 day') overlaps ($1::date, $2::date)) \
            UNION \
            (select start_date as na_date \
            from bidsfor \
            where caretaker_email = C1.email and is_confirmed = true \
            and \
            (start_date, end_date + interval '1 day') overlaps ($1::date, $2::date) \
            ));",
            [start_date, end_date]
        );
        res.json(msql.rows); 
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
            "select email, to_char(work_date, 'YYYY-mm-dd') from parttimeavail \
            where email = $1 and \
            not exists ( \
            select 1 from bidsfor where \
                is_confirmed = true and \
                caretaker_email = $1 and \
                (start_date, end_date + interval '1 day') overlaps (work_date, work_date + interval '1 day')\
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

// given email
// return all pets and price that email can take care of 
caretakerRouter.get('/caresfor/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select species, base_price, daily_price from takecareprice where email = $1;",
            [email]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// add a species that a caretaker can take care of
caretakerRouter.post('/type/add/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const { species, base_price, daily_price } = req.body;
        const msql = await pool.query(
            "INSERT INTO TakecarePrice(email, species, base_price, daily_price) \
            VALUES ($1, $2, $3, $4);",
            [email, species, base_price, daily_price]
            );
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});


// find all active caretakers, i.e. all fulltime + all parttime who have a avail date in the last two years
caretakerRouter.get('/active', async(req, res) => {
    try {
        const msql = await pool.query(
            "select * from \
            (select email, U1.name, rating, \
                case when is_fulltime then 'Full Time' else 'Part Time' End as type\
            from caretakers NATURAL JOIN users as U1 \
            where is_fulltime = true \
            UNION  \
            select email, U2.name, rating, \
                case when is_fulltime then 'Full Time' else 'Part Time' End as type\
            FROM \
            (select DISTINCT email, false as is_fulltime \
            from parttimeavail  \
            where date(NOW()::timestamp) <= work_date and work_date <= date(NOW()::timestamp) + interval '2' year) as active \
            NATURAL JOIN caretakers NATURAL JOIN users as U2) as Temp\
            order by rating desc;"
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// filter endpoint
// filter by:
// Caretaker name: find all caretakers whose name has a specified substring
// Date of availability (Range): find all caretakers available for a superset of the specified interval
// pet type: find all caretakers who can take care of a specified pet type
// filter by price range (min, max)
// filter by min rating




module.exports = {
    caretakerRouter
}
