const express = require('express');
const pool = require('../db');
const { json, response } = require('express');
const { verifyJwt } = require('../auth/index')

const commentsRouter = express.Router();

// get all comments by qn id
commentsRouter.get('/', async (req, res) => {
    try {
        const post_id = parseInt(req.body.post_id);
        const result = await pool.query(
            `
            SELECT * FROM Comments
            WHERE post_id = $1
            `,
            [post_id]
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// create a comment
commentsRouter.post('/', verifyJwt, async (req, res) => {
    try {
        const email = res.locals.user.email;
        const { post_id, cont } = req.body;
        const result = await pool.query(
            `
            INSERT INTO Comments(post_id, email, date_time, cont)
            VALUES($1, $2, DEFAULT, $3) 
            returning *
            `,
            [post_id, email, cont],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// update a comment
commentsRouter.put('/', verifyJwt, async (req, res) => {
    try {
        const email = res.locals.user.email;
        const { post_id, date_time, cont } = req.body;
        const result = await pool.query(
            `
            UPDATE Comments
            SET cont = $4
            WHERE post_id = $1
                AND email = $2
                AND DATE(date_time) = DATE($3)
            returning *
            `,
            [post_id, email, date_time, cont],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// delete a comment 
commentsRouter.delete('/', verifyJwt, async (req, res) => {
    try {
        const email = res.locals.user.email;
        const { post_id, date_time } = req.body;
        const result = await pool.query(
            `
            DELETE FROM Comments
            WHERE post_id = $1
                AND email = $2
                AND DATE(date_time) = DATE($3)
            `,
            [post_id, email, date_time],
        );
        return res.status(204).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    commentsRouter
}