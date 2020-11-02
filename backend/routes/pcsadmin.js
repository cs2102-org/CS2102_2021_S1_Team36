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