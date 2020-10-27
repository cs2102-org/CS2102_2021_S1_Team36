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

module.exports = {
    pcsRouter
}