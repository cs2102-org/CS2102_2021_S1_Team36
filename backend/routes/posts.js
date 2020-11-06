const express = require('express');
const pool = require('../db');
const { json, response } = require('express');
const { verifyJwt } = require('../auth/index')

const postsRouter = express.Router();

// get all posts
postsRouter.get('/', async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM Posts P \
            NATURAL JOIN (SELECT name, email FROM users U) as foo \
            NATURAL JOIN (SELECT post_id, count(*) FROM comments GROUP BY (post_id)) as counts;'
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// get a specific post
postsRouter.post('/specific', async (req, res) => {
    try {
        const {post_id} = req.body;
        const result = await pool.query(
            'SELECT * FROM Posts P \
            NATURAL JOIN (SELECT name, email FROM users U) as foo \
            WHERE P.post_id = $1;',
            [post_id]
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// create a post
postsRouter.post('/create', verifyJwt, async (req, res) => {
    try {
        const email = res.locals.user.email;
        const { title, cont } = req.body;
        const result = await pool.query(
            `
            INSERT INTO Posts(post_id, email, title, cont)
            VALUES(DEFAULT, $1, $2, $3) 
            returning *
            `,
            [email, title, cont],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// update a post
postsRouter.put('/:id', verifyJwt, async (req, res) => {
    try {
        const post_id = req.params.id;
        const email = res.locals.user.email;
        const { title, cont } = req.body;
        const result = await pool.query(
            `
            UPDATE Posts
            SET title = $3, cont = $4, last_modified = NOW()
            WHERE post_id = $1
                AND email = $2
            returning *
            `,
            [post_id, email, title, cont],
        );
        return res.status(200).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

// delete a post 
postsRouter.post('/delete/:id', verifyJwt, async (req, res) => {
    try {
        const post_id = req.params.id;
        const email = res.locals.user.email;
        const result = await pool.query(
            `
            DELETE FROM Posts
            WHERE post_id = $1
                AND email = $2
            `,
            [post_id, email],
        );
        return res.status(204).json(result.rows);
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    postsRouter
}