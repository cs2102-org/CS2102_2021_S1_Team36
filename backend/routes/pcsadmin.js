const express = require('express');
const pool = require('../sql');
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

module.exports = {
    pcsRouter
}