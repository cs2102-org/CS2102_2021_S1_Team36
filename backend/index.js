const express = require('express');
const pool = require('./sql');

const app = express();
const PORT = process.env.PORT || 5000;

// middle ware
var bodyParser = require('body-parser')
app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
})); 

app.get('/', async(req, res) => {
    try {
        const test = await pool.query('SELECT * FROM test');
        console.log(test);
        res.json(test.rows);
    } catch (err) {
        console.error(err);
    }
});

app.get('/user', async(req, res) => {
    try {
        const users = await pool.query("SELECT * FROM Users");
        res.json(users.rows); 
    } catch (err) {
        console.error(err);
    }
});

app.get('/user/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const users = await pool.query(
            "SELECT * FROM Users WHERE email = $1",
            [email]
        );
        res.json(users.rows[0]); 
    } catch (err) {
        console.error(err);
    }
});

// get full time leave whole table
app.get('/fulltime/leave/', async(req, res) => {
    try {
        const allLeave = await pool.query(
            "SELECT * FROM FullTimeLeave",
        );
        res.json(allLeave.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get full time leave of someone 
app.get('/fulltime/leave/:email', async(req, res) => {
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
});

// queries to view caretaker availability

// view all caretakers
app.get('/caretaker/avail', async(req, res) => {
    try {
        const cts = await pool.query(
            "SELECT * FROM Caretakers;",
        );
        res.json(cts.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view all caretakers availability
app.get('/caretaker/avail/all', async(req, res) => {
    try {
        const sql = await pool.query(
            "select email, leave_date as na_start_date, 1 as na_num_days from fulltimeleave \
            UNION \
            select caretaker_email as email, bid_date as na_start_date, number_of_days as na_num_days from bidsfor where is_confirmed = true;"
        );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// view a certain caretakers availability
app.get('/caretaker/avail/:email', async(req, res) => {
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

// view all caretakers available for a date range
// accounts for their leave and their confirmed bids
app.get('/caretaker/avail/range', async(req, res) => {
    try {
        var startdate = req.body.startdate;
        var numdays = req.body.numdays;
        const sql = await pool.query(
            "select email from caretakers C1 \
            where not exists ( \
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


// -- select TO_TIMESTAMP('2020-10-26', 'YYYY-MM-DD') + interval '1' day from fulltimeleave;
// -- select leave_date + interval '1' day * 4 from fulltimeleave;
// select email from caretakers C1
// where not exists (
// select 1 from (select leave_date as date, 1 as num_days from fulltimeleave where email=C1.email UNION select bid_date as date, number_of_days as num_days from bidsfor where caretaker_email = C1.email and is_confirmed = true) as NA
// where ('2020-10-28' <= NA.date and TO_TIMESTAMP('2020-10-28', 'YYYY-MM-DD') + interval '1' day * 2 >= NA.date)
// or (NA.date < '2020-10-28' and NA.date + interval '1' day * NA.num_days >= '2020-10-28'));

// find all caretakers who can look after a specified pet type
app.get('/caretaker/avail/type/:type', async(req, res) => {
    try {
        const { type } = req.params;
        const sql = await pool.query(
            "select email from caretakers C1 \
            where exists (select 1 from takecareprice where email = C1.email and species = $1);",
            [type]
            );
        res.json(sql.rows); 
    } catch (err) {
        console.error(err);
    }
});











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
    .use(express.urlencoded({extended: false}))
    .listen(PORT, () => console.log(`Running server on ${PORT}`));