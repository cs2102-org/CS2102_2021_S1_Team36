const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const pcsRouter = express.Router();

pcsRouter.post('/pet-types', async (req, res) => {
    try {
        const species = req.body.species;
        const result = await pool.query(
            'INSERT INTO PetTypes(species) VALUES($1) returning *',
            [species],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.delete('/user', async (req, res) => {
    try {
        const { name, email } = req.body;
        await pool.query(
            `
            DELETE FROM Users 
            WHERE name = $1 AND email = $2 
            `,
            [name, email],
        );
        return res.status(204).send('Account successfully deleted');
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.delete('/forum/:id', async (req, res) => {
    try {
        const id = req.params.id;
        await pool.query(
            `
            DELETE FROM Posts
            WHERE post_id = $1
            `,
            [id],
        );
        return res.status(204).send('Post successfully deleted');
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.delete('/comments', async (req, res) => {
    try {
        const { post_id, email, date_time } = req.body;
        await pool.query(
            `
            DELETE FROM Comments
            WHERE post_id = $1
                AND email = $2
                AND DATE(date_time) = DATE($3)
            `,
            [post_id, email, date_time],
        );
        return res.status(204).send('Comment successfully deleted');
    } catch (err) {
        console.error(err);
    }
});

//create a new pcsadmin, or return an error message if unable to
pcsRouter.post('/', async (req, res) => {
    try {
        const { name, email } = req.body;
        const user_query = await pool.query(
            "select * from users where email=$1",
            [email]
        );
        if (user_query.rows.length > 0) {
            //user with this email already exists
            return res.json("This email is already taken. User creation failed. ");
        }
        // else, create the new user and insert in pcsadmin table in a single transaction
        const create_user = await pool.query(
            "select createPcsAdmin($1, $2);",
            [email, name]);
        return res.json("User successfully created.");
    } catch (err) {
        console.error(err);
    }
});

//create a new FT caretaker or return an error message if unable to
pcsRouter.post('/ft', async (req, res) => {
    try {
        const { name, email } = req.body;
        const user_query = await pool.query(
            "select * from users where email=$1",
            [email]
        );
        if (user_query.rows.length > 0) {
            //user with this email already exists
            return res.json("This email is already taken. User creation failed. ");
        }
        // else, create the new user and insert in caretakers table in a single transaction
        const create_user = await pool.query(
            "select createFtCaretaker($1, $2);",
            [email, name]);
        return res.json("User successfully created.");
    } catch (err) {
        console.error(err);
    }
});

// This only counts jobs that were COMPLETED (end_date) during [start, end] inclusive
// e.g.: if job starts Jan 30, ends Feb 5, this job only counts towards
// his Feb salary
// returns table of (email, name, type, description, salary)
pcsRouter.get('/salaries/:start_date/:end_date', async(req, res) => {
    try {
        const { start_date, end_date } = req.params;
        console.log(start_date, end_date);
        const msql = await pool.query(
            "select \
                email,  \
                name,   \
                CASE WHEN is_fulltime THEN 'Full Time' ELSE 'Part Time' END as type,    \
                description,    \
                getSalary(email, $1, $2)    \
            from \
                users natural join caretakers;",
            [start_date, end_date]);
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    pcsRouter
}