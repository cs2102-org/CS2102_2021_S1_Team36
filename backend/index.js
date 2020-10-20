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

const authRouter = require('./routes/auth');

app.use(express.json())
    .use(express.urlencoded({extended: false}))
    .use('/api/auth', authRouter)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));