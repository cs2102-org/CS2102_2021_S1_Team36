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
// middle ware
var bodyParser = require('body-parser')
app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
})); 

app.get('/test', async(req, res) => {
    try {
        const msql = await pool.query('SELECT * FROM Users');
        console.log(msql);
        res.json(msql.rows);
    } catch (err) {
        console.error(err);
    }
});

// get all users
app.get('/user', async(req, res) => {
    try {
        const users = await pool.query("SELECT * FROM Users");
        res.json(users.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the pets of a specified user
app.get('/user/owns/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const pets = await pool.query(
            "SELECT * FROM Pets WHERE email = $1",
            [email]
        );
        res.json(pets.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the fullTimeLeave table
app.get('/caretaker/ft/leave/', async(req, res) => {
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
app.get('/caretaker/ft/leave/:email', async(req, res) => {
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
app.get('/caretaker/all', async(req, res) => {
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
app.get('/caretaker/ft/na/all', async(req, res) => {
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
app.get('/caretaker/ft/na/:email', async(req, res) => {
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
app.get('/caretaker/ft/na/range', async(req, res) => {
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

// get the availability of a specified part time worker
// i.e. their available dates - dates where they have confirmed bids
app.get('/caretaker/pt/avail/:email', async(req, res) => {
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


// -- select TO_TIMESTAMP('2020-10-26', 'YYYY-MM-DD') + interval '1' day from fulltimeleave;
// -- select leave_date + interval '1' day * 4 from fulltimeleave;
// select email from caretakers C1
// where not exists (
// select 1 from (select leave_date as date, 1 as num_days from fulltimeleave where email=C1.email UNION select bid_date as date, number_of_days as num_days from bidsfor where caretaker_email = C1.email and is_confirmed = true) as NA
// where ('2020-10-28' <= NA.date and TO_TIMESTAMP('2020-10-28', 'YYYY-MM-DD') + interval '1' day * 2 >= NA.date)
// or (NA.date < '2020-10-28' and NA.date + interval '1' day * NA.num_days >= '2020-10-28'));

// find all caretakers who can look after a specified pet type
app.get('/caretaker/type/:type', async(req, res) => {
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

// get all bids (the whole BidsFor table)
app.get('/bids/all', async(req, res) => {
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
app.get('/bids/by/:email', async(req, res) => {
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
app.get('/bids/for/:email', async(req, res) => {
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

// get the working dates of a specified caretaker in a specified interval
app.get('/pcs/getwork/range/:email', async(req, res) => {
    try {
        const { email } = req.params;
        var startdate = req.body.startdate;
        var enddate = req.body.enddate;
        const msql = await pool.query(
            "select bid_date as start_date, number_of_days from bidsfor \
            where caretaker_email = $1 and is_confirmed = true \
            and $2 <= bid_date \
            and date(bid_date) + interval '1' * (number_of_days - 1) <= date(enddate) \
            UNION \
            select $2 as start_date, \
            EXTRACT(EPOCH FROM ( \
            	(date(bid_date) + interval '1' day * (number_of_days))- date($2) \
            )) / 86400 as number_of_days \
            from  bidsfor \
            where caretaker_email = $1 and is_confirmed = true \
            and bid_date < $2 \
            and date($2) <= date(bid_date) + interval '1' day * (number_of_days - 1) \
            and date(bid_date) + interval '1' day * (number_of_days - 1) <= date($3) \
            UNION \
            select $2 as start_date, \
            EXTRACT(EPOCH FROM ( \
            	'2021-05-03' - bid_date \
            )) / 86400 + 1 as number_of_days \
            from  bidsfor \
            where caretaker_email = $1 and is_confirmed = true \
            and $2 <= bid_date \
            and bid_date <= $3 \
            and $3 < bid_date + interval '1' day * (number_of_days - 1) \
            UNION \
            (select $2 as start_date, \
            date($3) - date($2) + 1 as number_of_days \
            from bidsfor \
            where caretaker_email = $1 and is_confirmed = true \
            and bid_date < $2 \
            and $3 < bid_date + interval '1' day * (number_of_days - 1));",
            [email, startdate, numdays]
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});





// todo: change this to use id
// // get all Posts
// app.get('/forum/', async(req, res) => {
//     try {
//         const msql = await pool.query(
//             "select * from posts",
//         );
//         res.json(msql.rows); 
//     } catch (err) {
//         console.error(err);
//     }
// });

// // get all comments for a specified Post
// app.get('/forum/:title', async(req, res) => {
//     try {
//         const { title } = req.params;
//         const msql = await pool.query(
//             "select * from comments where title = $1;",
//             [title]
//         );
//         res.json(msql.rows);
//     } catch (err) {
//         console.error(err);
//     }
// });










// examples ------------------------------------------
app.get('/todos', async(req, res) => {
    try {
        const allTodos = await pool.query("SELECT * FROM todo");
        res.json(allTodos.rows); 
    } catch (err) {
        console.error(err);
    }
});

app.post('/todos', async(req, res) => {
    try {
        const { description } = req.body;
        const newTodo = await pool.query(
            "INSERT INTO todo (description) VALUES($1) RETURNING *",
            [description]
        );
        res.json(newTodo.rows[0]);
    } catch (err) {
        console.error(err);
    }
});

app.put("/todos/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { description } = req.body;
        const updateTodo = await pool.query(
            "UPDATE todo SET description = $1 where todo_id = $2",
            [description, id]
        )
        res.json("todo was updated!");
    } catch (err) {
        console.error(err);
    }
});



app.use(express.json())
    .use(cors())
    .use(express.urlencoded({extended: false}))
    .use(router)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));