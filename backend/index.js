const express = require('express');
const pool = require('./db');

const app = express();
const PORT = process.env.PORT || 5000;

// app.get('/', async(req, res) => {
//     try {
//         const test = await pool.query('SELECT * FROM test');
//         console.log(test);
//         res.json(test.rows);
//     } catch (err) {
//         console.error(err);
//     }
// });

const usersRouter = require('./routes/users');

app.use(express.json())
    .use(express.urlencoded({extended: false}))
    .use('/api', usersRouter)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));