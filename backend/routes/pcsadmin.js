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

pcsRouter.delete('/user', async (req, res) => {
    const { name, email } = req.body;
    await pool.query(
        `
        DELETE FROM Users 
        WHERE name = ($1) AND email = ($2)
        `,
        [name, email],
    );
    return res.status(204).send('Account successfully deleted');
});

pcsRouter.delete('/forum/:id', async (req, res) => {
    const id = req.params.id;
    await pool.query(
        `
        DELETE FROM Posts
        WHERE id = ($1)
        `,
        [id],
    );
    return res.status(204).send('Post successfully deleted');
});

pcsRouter.delete('/comments', async (req, res) => {
    const { title, email, date_time } = req.body;
    await pool.query(
        `
        DELETE FROM Comments
        WHERE title = ($1)
            AND email = ($2)
            AND date_time = ($3)
        `,
        [title, email, date_time],
    );
    return res.status(204).send('Comment successfully deleted');
});

module.exports = {
    pcsRouter
}