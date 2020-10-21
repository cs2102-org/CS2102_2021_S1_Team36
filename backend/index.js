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