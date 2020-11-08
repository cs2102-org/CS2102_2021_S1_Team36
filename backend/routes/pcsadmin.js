const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const pcsRouter = express.Router(); // use address  http://localhost:5000/api/pcs-admins/...

pcsRouter.post('/pet-types', async (req, res) => {
    try {
        const { species, base_price } = req.body;
        const result = await pool.query(
            'INSERT INTO PetTypes VALUES($1, $2) returning *',
            [species, base_price],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.put('/pet-types', async (req, res) => {
    try {
        const { species, base_price } = req.body;
        console.log(species, base_price);
        const result = await pool.query(
            'UPDATE PetTypes  \
            SET base_price = $2 \
            WHERE species = $1',
            [species, base_price],
        );
        return res.status(200).json(true);
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.delete('/user/:email', async (req, res) => {
    try {
        const { email } = req.params;
        await pool.query(
            `
            DELETE FROM Users 
            WHERE email = $1 
            `,
            [email],
        );
        return res.status(204).send('Account successfully deleted');
    } catch (err) {
        console.error(err);
    }
});

pcsRouter.delete('/pet-type/:species', async (req, res) => {
    try {
        const { species } = req.params;
        await pool.query(
            `
            DELETE FROM PetTypes 
            WHERE species = $1 
            `,
            [species],
        );
        return res.status(204).send('Pet Type successfully deleted');
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

pcsRouter.get('/admins', async (req, res) => {
    const result = await pool.query(
        'select email, name, description from Users natural join pcsadmins order by name asc;',
    );
    return res.status(200).json(result.rows);
});

// compute the demand statistics for a specified species
// input: start_date, end_date, species
// output: table(num_days, total_demand, avg_demand)
// output is a single row
pcsRouter.post('/demand', async (req, res) => {
    const { start_date, end_date, species } = req.body;
    const msql = await pool.query(
        "select COUNT(*) as num_days, SUM(demand) as total_demand, (SUM(demand) / COUNT(*))::DECIMAL(10, 2) as avg_demand from ( \
            select datez, ( \
                select COUNT(*) from bidsFor natural join (select email as owner_email, pet_name, species from pets) SP \
                where \
                    clash(start_date, end_date, datez) and \
                    species = $3 \
                ) as demand \
            from (select generate_series($1::date, $2::date, '1 day'::interval)::date as datez) D \
        ) Dem", 
        [start_date, end_date, species],
    );
    return res.status(200).json(msql.rows);
});

// compute the supply statistics for a specified species
// input: species
// output: table(supply)
// output is a single row
pcsRouter.post('/supply', async (req, res) => {
    const { species } = req.body;
    const msql = await pool.query(
        "select SUM(pet_limit) as supply from ( \
            select getPetLimit(email) as pet_limit from takecareprice \
            where \
                species = $1 \
        ) as PL", 
        [species],
    );
    return res.status(200).json(msql.rows);
});

pcsRouter.get('/pet-types', async (req, res) => {
    try {
        const msql = await pool.query(
            "select species, base_price, (select COUNT(*) from Pets P2 where P2.species = P1.species) as count  \
            from Pettypes P1 order by species asc;"
            );
        res.json(msql.rows); 
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

// get the pets of a specified user by admin
pcsRouter.get('/pets/:email', async(req, res) => {
    try {
        const email = req.params.email;
        const pets = await pool.query(
            "SELECT * FROM Pets WHERE email = $1",
            [email]
        );
        res.json(pets.rows); 
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

// This only counts jobs that were COMPLETED (end_date) during [start_date, end_date] inclusive
// e.g.: if job starts Jan 30, ends Feb 5, this job only counts towards his Feb salary
// bc there is min 3k salary for FT, only makes sense when querying entire months
// e.g. start: 2020-01-01, end: 2020-01-31
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
                rating, \
                getSalary(email, $1, $2),    \
                getWorkDays(email, $1, $2),  \
                getTotalRevenue(email, $1, $2) as revenue \
            from \
                users natural join caretakers order by type asc, name asc;",
            [start_date, end_date]);
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    pcsRouter
}

