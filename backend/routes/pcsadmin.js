const express = require('express');
const pool = require('../sql');
const { json, response } = require('express');
const { restart } = require('nodemon');

const pcsRouter = express.Router();

pcsRouter.post('/pet-types', async (req, res) => {
    const species = req.body.species;
    const result = await pool.query(
        'INSERT INTO PetTypes(species) VALUES($1) returning *',
        [species],
    );
    return res.status(200).json(result.rows);
});

pcsRouter.delete('/user', async (req, res) => {
    const { name, email } = request.body;
    await pool.query(
        `
        DELETE FROM Users 
        WHERE name = ($1) AND email = ($2)
        `,
        [name, email],
    );
    return res.status(204).send('Account successfully deleted');
});

module.exports = {
    pcsRouter
}