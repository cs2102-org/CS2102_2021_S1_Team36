const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const pcsRouter = express.Router(); // use address  http://localhost:5000/api/pcs-admins/...

pcsRouter.post('/pet-types', async (req, res) => {
    const species = req.body.species;
    const result = await pool.query(
        'INSERT INTO PetTypes(species) VALUES($1) returning *',
        [species],
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
        "select COUNT(*) as num_days, SUM(demand) total_demand, (SUM(demand) / COUNT(*))::DECIMAL(10, 2) as avg_demand from ( \
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

module.exports = {
    pcsRouter
}