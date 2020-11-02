const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const pcsRouter = express.Router();

pcsRouter.post('/pet-types', async (req, res) => {
    const species = req.body.species;
    const result = await pool.query(
        'INSERT INTO PetTypes(species) VALUES($1) returning *',
        [species],
    );
    return res.status(200).json(result.rows);
});

pcsRouter.get('/admins', async (req, res) => {
    const result = await pool.query(
        'select email, name from Users natural join pcsadmins;',
    );
    return res.status(200).json(result.rows);
});

pcsRouter.get('/pet-types', async (req, res) => {
    try {
        const msql = await pool.query(
            "select species, (select COUNT(*) from Pets P2 where P2.species = P1.species) as count  \
            from Pettypes P1;"
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    pcsRouter
}