const express = require('express');
const pool = require('../db');
const { json, response } = require('express');
const { verifyJwt } = require('../auth/index')

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

// Give a specified fulltime caretaker leave on the interval [start_date, end_date]
// todo: check for overlaps with existing leave dates
caretakerRouter.post('/ft/leave/new/range', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
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

// Give a specified parttime caretaker avail dates on the interval [start_date, end_date]
// todo: check for overlaps with existing avail dates
caretakerRouter.post('/pt/avail/new/range', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        var {start_date, end_date} = req.body;
        start_date = new Date(start_date);
        end_date = new Date(end_date);

        console.log(email, start_date, end_date);
        var arr = getDaysArray(start_date, end_date);
        var work_date;
        for (var i = 0; i < arr.length; i++) {
            work_date = `${arr[i].getFullYear()}-${arr[i].getMonth()+1}-${arr[i].getDate()}`;
            const msql = await pool.query(
                "INSERT INTO PartTimeAvail(email, work_date) VALUES ($1, $2)",
                [email, work_date]
            );
        }
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

//delete full time leave
caretakerRouter.delete('/ft/leave/:date', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const leave_date = req.params.date;
        const msql = await pool.query(
            "DELETE FROM FullTimeLeave \
            WHERE email = $1 and leave_date = $2",
            [email, leave_date]
        );
        
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

//delete part time avail
caretakerRouter.delete('/pt/avail/:date', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const work_date = req.params.date;
        const msql = await pool.query(
            "DELETE FROM PartTimeAvail \
            WHERE email = $1 and work_date = $2",
            [email, work_date]
        );
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

// insert new caretaker
caretakerRouter.post('/new', verifyJwt, async(req, res) => {
    try {
        const { email, full_time } = req.body;
        res.json(true); 
    } catch (err) {
        console.error(err);
    }
});

// view all caretakers
caretakerRouter.get('/all', async(req, res) => {
    try {
        const cts = await pool.query(
            "SELECT name, email, is_fulltime, rating, description FROM Caretakers NATURAL JOIN Users order by name asc;",
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

// view a specified fulltime caretakers non-availability
caretakerRouter.get('/ft/na/:email', async(req, res) => {
    const date = new Date(), y = date.getFullYear(), m = date.getMonth();
    const firstDay = new Date(y, m, 2).toISOString().slice(0,10);
    const lastDay = new Date(y + 2, m, 2).toISOString().slice(0,10);
    try {
        const { email } = req.params;
        const sql = await pool.query(
            "SELECT to_char(date_trunc('day', dd)::date, 'YYYY-MM-dd') as date\
                FROM generate_series ( $1::timestamp, $2::timestamp, '1 day'::interval) dd \
            WHERE canWork($3, date_trunc('day', dd)::date, date_trunc('day', dd)::date) = false;",
            [firstDay, lastDay, email]
        );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the fullTimeLeave of a specified full time caretaker
// assumes specified caretaker is actually full time
// if start_date end_date not specified, assumes we want the interval [now, now + 2 years]
caretakerRouter.get('/ft/leave', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const { start_date, end_date } = req.body;
        console.log(start_date, end_date);
        if ( !start_date || !end_date ) {
            const msql = await pool.query(
                "SELECT to_char(leave_date, 'YYYY-MM-dd') as date FROM FullTimeLeave WHERE email = $1",
                [email]
            );
            res.json(msql.rows);
        } else {
            const msql = await pool.query(
                "SELECT to_char(leave_date, 'YYYY-MM-dd') as date FROM FullTimeLeave WHERE email = $1 AND clash($2, $3, leave_date)",
                [email, start_date, end_date]
            );
            res.json(msql.rows);
        }
    } catch (err) {
        console.error(err);
    }
});

// get the availability of a specified part time worker
// i.e. their available dates - dates where they have confirmed bids
caretakerRouter.get('/pt/avail', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const sql = await pool.query(
            "select email, to_char(work_date, 'YYYY-mm-dd') as date from parttimeavail \
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

// get the availability of a specified part time worker
// i.e. their available dates - dates where they have confirmed bids
caretakerRouter.get('/pt/avail/:email', async(req, res) => {
    try {
        const email = req.params.email;
        const sql = await pool.query(
            "select email, to_char(work_date, 'YYYY-mm-dd') as date from parttimeavail \
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

// get the avail dates of a specified part time worker
// i.e. their available dates
caretakerRouter.get('/pt/av', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;
        const sql = await pool.query(
            "select email, to_char(work_date, 'YYYY-mm-dd') as date from parttimeavail \
            where email = $1;",
            [email]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// // get the availability of a specified part time caretaker
// // assumes specified caretaker is actually part time
// // if start_date and end_date not specified, assumes we want the interval [now, now + 2 years]
// caretakerRouter.get('/pt/avail/:email', async(req, res) => {
//     try {
//         const { email } = req.params;
//         const { start_date, end_date } = req.body;
//         console.log(start_date, end_date);
//         if ( !start_date || !end_date ) {
//             const msql = await pool.query(
//                 "SELECT * FROM PartTimeAvail WHERE email = $1 AND clash(NOW()::date, (NOW() + interval '2 year')::date, work_date)",
//                 [email]
//             );
//             res.json(msql.rows);
//         } else {
//             const msql = await pool.query(
//                 "SELECT * FROM PartTimeAvail WHERE email = $1 AND clash($2, $3, work_date)",
//                 [email, start_date, end_date]
//             );
//             res.json(msql.rows);
//         }
//     } catch (err) {
//         console.error(err);
//     }
// });


// given email
// return all pets and price that email can take care of 
caretakerRouter.get('/caresfor/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select species, daily_price from takecareprice where email = $1 order by species asc;",
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

// returns a list of all pet types in database
caretakerRouter.get('/alltypes', async(req, res) => {
    try {
        const msql = await pool.query(
            "select * from Pettypes;"
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
            "select * from \
            (select email, U1.name, rating, \
                'Full Time' as type\
            from caretakers NATURAL JOIN users as U1 \
            where is_fulltime = true \
            UNION  \
            select email, U2.name, rating, \
                'Part Time' as type\
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

// Get detailed information of specified caretaker
caretakerRouter.get('/detailed/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "SELECT email, description, rating, name, \
            CASE WHEN is_fulltime THEN 'Full Time' ELSE 'Part Time' END as type \
            FROM Users NATURAL JOIN Caretakers WHERE email = $1;",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// filter endpoint
// filter by:
// substring: caretakers name contains substr
// availability: caretakers available for (start_date, end_date).
// ^ This means that caretakers current capacity < max capacity for this entire interval
// pet type: caretakers can take care of pet_type
// price: caretaker price for pet_type in range [min, max]
// rating: caretaker rating >= rating
// is_fulltime: true or false to filter for fulltime or parttime caretakers
caretakerRouter.post('/filter', async(req, res) => {
    try {
        var { substr, start_date, end_date, pet_type, min, max, rating, is_fulltime } = req.body;
        console.log(substr, start_date, end_date, pet_type, min, max, rating);
        var nameRating = "select email, rating, is_fulltime from caretakers NATURAL JOIN Users\
            where \
                (rating >= $7 or $7 is null) and \
                (name LIKE '%' || $1 || '%' or $1 is null)";
        var speciesPrice = "select email, rating, is_fulltime from takecareprice NATURAL JOIN Caretakers \
            where \
                (species = $4 or $4 is null) and \
                (daily_price >= $5 or $5 is null) and \
                (daily_price <= $6 or $6 is null)";
        var canWork = "select email, rating, is_fulltime from caretakers \
            where \
                canWork(email, $2, $3) or \
                $2 is null or \
                $3 is null";
        var fullTime = "select email, rating, is_fulltime from caretakers \
            where \
                is_fulltime = $8 or \
                $8 is null";
        var combine = "select * from (select F.email, US.name, rating, \
            CASE \
                WHEN is_fulltime THEN 'Full Time' \
                ELSE 'Part Time' \
            END \
            as type \
            FROM (" + nameRating + " INTERSECT " + speciesPrice + " INTERSECT " + canWork + " INTERSECT " + fullTime + ") \
            AS F NATURAL JOIN Users US) as temp order by rating desc;";
        const msql = await pool.query(
            combine,
            [substr, start_date, end_date, pet_type, min, max, rating, is_fulltime]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

caretakerRouter.post('/filter/recommended', verifyJwt, async(req, res) => {
    try {
        var { substr, start_date, end_date, pet_type, min, max, rating, is_fulltime } = req.body;
        console.log(substr, start_date, end_date, pet_type, min, max, rating);
        const email = res.locals.user.email;

        const mkView = await pool.query(
            "CREATE OR REPLACE VIEW potentialCaretakers AS \
                (select DISTINCT caretaker_email as email from bidsfor where is_confirmed = True and owner_email in \
                    (select DISTINCT owner_email from bidsfor where is_confirmed = True and caretaker_email in \
                        (select caretaker_email from bidsfor where owner_email = '" + email + "' and is_confirmed = True))) \
                EXCEPT \
                (select caretaker_email as email from bidsfor where owner_email = '" + email + "' and is_confirmed = True);"
        );

        var selectCaretakers = "select email, name, rating, \
            case when is_fulltime then 'Full Time' else 'Part Time' End \
            as type from (potentialCaretakers NATURAL JOIN Caretakers NATURAL JOIN Users) as PC \
            where exists ( \
	            (select species from takecareprice T1 where T1.email = PC.email) \
	            INTERSECT \
	            (select species from pets P1 where P1.email = $9) \
            )"

        var nameRating = "select email, rating, is_fulltime from caretakers NATURAL JOIN Users\
            where \
                (rating >= $7 or $7 is null) and \
                (name LIKE '%' || $1 || '%' or $1 is null)";
        var speciesPrice = "select email, rating, is_fulltime from takecareprice NATURAL JOIN Caretakers \
            where \
                (species = $4 or $4 is null) and \
                (daily_price >= $5 or $5 is null) and \
                (daily_price <= $6 or $6 is null)";
        var canWork = "select email, rating, is_fulltime from caretakers \
            where \
                canWork(email, $2, $3) or \
                $2 is null or \
                $3 is null";
        var fullTime = "select email, rating, is_fulltime from caretakers \
            where \
                is_fulltime = $8 or \
                $8 is null";
        var combine = "select * from ((select F.email, US.name, rating, \
            CASE \
                WHEN is_fulltime THEN 'Full Time' \
                ELSE 'Part Time' \
            END \
            as type \
            FROM (" + nameRating + " INTERSECT " + speciesPrice + " INTERSECT " + canWork + " INTERSECT " + fullTime + ") \
            AS F NATURAL JOIN Users US) \
            INTERSECT (" +
            selectCaretakers + ")) as temp order by rating desc";
        const msql = await pool.query(
            combine,
            [substr, start_date, end_date, pet_type, min, max, rating, is_fulltime, email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

caretakerRouter.post('/filter/transacted', verifyJwt, async(req, res) => {
    try {
        var { substr, start_date, end_date, pet_type, min, max, rating, is_fulltime } = req.body;
        console.log(substr, start_date, end_date, pet_type, min, max, rating);
        const email = res.locals.user.email;

        var tranx = "SELECT email, name, rating, \
                CASE \
                    WHEN is_fulltime THEN 'Full Time' \
                    ELSE 'Part Time' \
                END \
                as type FROM \
                (select DISTINCT caretaker_email as email from bidsFor \
                where \
                    owner_email = $9 and \
                    is_confirmed = True \
                ) AS TB \
                NATURAL JOIN Users NATURAL JOIN Caretakers";
        var nameRating = "select email, rating, is_fulltime from caretakers NATURAL JOIN Users\
            where \
                (rating >= $7 or $7 is null) and \
                (name LIKE '%' || $1 || '%' or $1 is null)";
        var speciesPrice = "select email, rating, is_fulltime from takecareprice NATURAL JOIN Caretakers \
            where \
                (species = $4 or $4 is null) and \
                (daily_price >= $5 or $5 is null) and \
                (daily_price <= $6 or $6 is null)";
        var canWork = "select email, rating, is_fulltime from caretakers \
            where \
                canWork(email, $2, $3) or \
                $2 is null or \
                $3 is null";
        var fullTime = "select email, rating, is_fulltime from caretakers \
            where \
                is_fulltime = $8 or \
                $8 is null";
        var combine = "select * from \
            ((select F.email, US.name, rating, \
                CASE \
                    WHEN is_fulltime THEN 'Full Time' \
                    ELSE 'Part Time' \
                END \
                as type \
                FROM (" + nameRating + " INTERSECT " + speciesPrice + " INTERSECT " + canWork + " INTERSECT " + fullTime + ") \
                AS F NATURAL JOIN Users US) " + 
                "INTERSECT (" + tranx + ")) as temp order by rating desc";
        const msql = await pool.query(
            combine,
            [substr, start_date, end_date, pet_type, min, max, rating, is_fulltime, email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});



// find recommended caretakers
// return email, name rating, is_fulltime
caretakerRouter.get('/rec', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email;

        const mkView = await pool.query(
            "CREATE OR REPLACE VIEW potentialCaretakers AS \
                (select DISTINCT caretaker_email as email from bidsfor where is_confirmed = True and owner_email in \
                    (select DISTINCT owner_email from bidsfor where is_confirmed = True and caretaker_email in \
                        (select caretaker_email from bidsfor where owner_email = '" + email + "' and is_confirmed = True))) \
                EXCEPT \
                (select caretaker_email as email from bidsfor where owner_email = '" + email + "' and is_confirmed = True);"
        );

        var selectCaretakers = "select email, name, rating, \
            case when is_fulltime then 'Full Time' else 'Part Time' End \
            as type from (potentialCaretakers NATURAL JOIN Caretakers NATURAL JOIN Users) as PC \
            where exists ( \
	            (select species from takecareprice T1 where T1.email = PC.email) \
	            INTERSECT \
	            (select species from pets P1 where P1.email = $1) \
            ) order by rating desc;"
        const msql = await pool.query(
            selectCaretakers,
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// returns a list of caretakers that :email has previously transacted with
caretakerRouter.get('/txnbefore', verifyJwt, async(req, res) => {
    try {
        const email = res.locals.user.email
        const msql = await pool.query(
            "SELECT email, name, rating, \
                CASE \
                    WHEN is_fulltime THEN 'Full Time' \
                    ELSE 'Part Time' \
                END \
                as type FROM \
                (select DISTINCT caretaker_email as email from bidsFor \
                where \
                    owner_email = $1 and \
                    is_confirmed = True \
                ) AS TB \
                NATURAL JOIN Users NATURAL JOIN Caretakers \
                order by rating desc",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

caretakerRouter.get('/reviews/:email', async(req, res) => {
    try {
        const email = req.params.email;
        const msql = await pool.query(
            "SELECT U.name, review, rating FROM bidsFor B inner join Users U on B.owner_email = U.email WHERE \
            caretaker_email = $1 ",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.log(err);
    }
});

module.exports = {
    caretakerRouter
}

// ================================================== garbage ===========================================================
// view all caretakers non-availability (na)
// i.e. for each caretaker, all the confirmed bids and all their leave dates
// caretakerRouter.get('/ft/na/all', async(req, res) => {
//     try {
//         const msql = await pool.query(
//             "select email, leave_date as start_date, leave_date as end_date from fulltimeleave \
//             UNION \
//             select \
//                 caretaker_email as email, \
//                 start_date, \
//                 end_date \
//             from bidsfor where is_confirmed = true;"
//         );
//         res.json(msql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });


// view a specified fulltime caretakers non-availability
// caretakerRouter.get('/ft/na/:email', async(req, res) => {
//     try {
//         const { email } = req.params;
//         const sql = await pool.query(
//             "select email, leave_date as start, leave_date as end from fulltimeleave where email = $1 \
//             UNION \
//             select \
//                 caretaker_email as email, \
//                 start_date as start, \
//                 end_date as end \
//             from bidsfor where \
//                 caretaker_email = $1 and \
//                 is_confirmed = true;",
//             [email]
//             );
//         res.json(sql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// view all full time caretakers available for a specified date range
// accounts for their leave and their confirmed bids
// range is specified as start_date, end_date inclusive
// caretakerRouter.get('/ft/unavail/range', async(req, res) => {
//     try {
//         var { start_date, end_date } = req.body;
//         end_date = incDate(end_date);
//         // var startdate = '2020-10-11';
//         // var numdays = 5;
//         const msql = await pool.query(
//             "select C1.email from caretakers C1 \
//             where C1.is_fulltime = True  \
//             and not exists ( \
//             (select leave_date as na_date \
//             from fulltimeleave \
//             where email=C1.email and \
//             (leave_date, leave_date + interval '1 day') overlaps ($1::date, $2::date)) \
//             UNION \
//             (select start_date as na_date \
//             from bidsfor \
//             where caretaker_email = C1.email and is_confirmed = true \
//             and \
//             (start_date, end_date + interval '1 day') overlaps ($1::date, $2::date) \
//             ));",
//             [start_date, end_date]
//         );
//         res.json(msql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });



// // get the availability of a specified part time worker
// // i.e. their available dates - dates where they have confirmed bids
// caretakerRouter.get('/pt/availafterbid/:email', async(req, res) => {
//     try {
//         const { email } = req.params;
//         const sql = await pool.query(
//             "select email, to_char(work_date, 'YYYY-mm-dd') as date from parttimeavail \
//             where email = $1 and \
//             not exists ( \
//             select 1 from bidsfor where \
//                 is_confirmed = true and \
//                 caretaker_email = $1 and \
//                 (start_date, end_date + interval '1 day') overlaps (work_date, work_date + interval '1 day')\
//             );",
//             [email]
//             );
//         res.json(sql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// COVERED BY FILTER
// get all pt caretakers who are avail on the whole of given range
// caretakerRouter.get('/pt/availrange', async(req, res) => {
//     try {
//         var { start_date, end_date } = req.body;
//         console.log(start_date, end_date);
//         const sql = await pool.query(
//             "select C1.email from caretakers C1 \
//             where \
//                 is_fulltime = false and \
//                 not exists ( \
//                     SELECT generate_series($1::date, $2::date, '1 day'::interval)::date as datez \
//                     EXCEPT \
//                     (select work_date as datez from parttimeavail \
//                      where email = C1.email and \
//                      not exists ( \
//                      select 1 from bidsfor where \
//                          is_confirmed = true and \
//                          caretaker_email = C1.email and \
//                          (start_date, end_date + interval '1 day') overlaps (work_date, work_date + interval '1 day')) \
//                     )\
//                 )\
//             ;",
//             [start_date, end_date]);
//         res.json(sql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// COVERED BY FILTER
// get all caretakers (ft and pt) that are avail for the entire given range
// caretakerRouter.get('/availrange', async(req, res) => {
//     try {
//         var { start_date, end_date } = req.body;
//         const sql = await pool.query(
//             "select C1.email from caretakers C1 \
//             where C1.is_fulltime = True  \
//             and not exists ( \
//                 (select leave_date as na_date \
//                 from fulltimeleave \
//                 where email=C1.email and \
//                 (leave_date, leave_date + interval '1 day') overlaps ($1::date, $2::date + interval '1 day')) \
//                 UNION \
//                 (select start_date as na_date \
//                 from bidsfor \
//                 where caretaker_email = C1.email and is_confirmed = true \
//                 and \
//                 (start_date, end_date + interval '1 day') overlaps ($1::date, $2::date) \
//                 )) \
//             UNION \
//             select C1.email from caretakers C1 \
//             where \
//                 is_fulltime = false and \
//                 not exists ( \
//                     SELECT generate_series($1::date, $2::date, '1 day'::interval)::date as datez \
//                     EXCEPT \
//                     (select work_date as datez from parttimeavail \
//                      where email = C1.email and \
//                      not exists ( \
//                      select 1 from bidsfor where \
//                          is_confirmed = true and \
//                          caretaker_email = C1.email and \
//                          (start_date, end_date + interval '1 day') overlaps (work_date, work_date + interval '1 day')) \
//                     )\
//                 )\
//             ;",
//             [start_date, end_date]);
//         res.json(sql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// COVERED BY FILTER
// find all caretakers who can look after a specified pet type
// caretakerRouter.get('/type/:type', async(req, res) => {
//     try {
//         const { type } = req.params;
//         const msql = await pool.query(
//             "select email from caretakers C1 \
//             where exists (select 1 from takecareprice where email = C1.email and species = $1);",
//             [type]
//             );
//         res.json(msql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// COVERED BY FILTER
// find all caretakers who can look after a specified pet type
// caretakerRouter.get('/type/:type', async(req, res) => {
//     try {
//         const { type } = req.params;
//         const msql = await pool.query(
//             "select email from caretakers C1 \
//             where exists (select 1 from takecareprice where email = C1.email and species = $1);",
//             [type]
//             );
//         res.json(msql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });
