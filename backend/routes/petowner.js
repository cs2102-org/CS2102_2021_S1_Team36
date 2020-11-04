const express = require('express');
const pool = require('../db');
const { json, response } = require('express');
const { verifyJwt } = require('../auth/index')

const petownerRouter = express.Router();

/*
to test the endpoints here, use http://localhost:5000/api/petowner/ in front of the urls
*/

// get all pet owners
petownerRouter.get('/petowners', async(req, res) => {
    try {
        const pets = await pool.query(
            "SELECT email, name, description FROM Users natural join Petowners order by name asc;",
        );
        res.json(pets.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the pets of a specified user
petownerRouter.get('/pets', verifyJwt, async(req, res) => {
    try {
        const user = res.locals.user;
        const email = user.email;
        const pets = await pool.query(
            "SELECT * FROM Pets WHERE email = $1",
            [email]
        );
        res.json(pets.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get the pets of a specified user that can be taken care of by a caretaker
petownerRouter.get('/pets/:caretaker', verifyJwt, async(req, res) => {
    try {
        const user = res.locals.user;
        const userEmail = user.email;
        const caretakerEmail = req.params.caretaker;
        const pets = await pool.query(
            "SELECT P.pet_name, P.species, P.description, P.species \
            FROM Pets P INNER JOIN TakeCarePrice T ON P.species = T.species \
            WHERE P.email = $1 and T.email=$2",
            [userEmail, caretakerEmail]
        );
        res.json(pets.rows); 
    } catch (err) {
        console.error(err);
    }
});

// Add new pet to the database of a specific user
// email must exist in the table of Users (FK dependency)
// pet_name must not already exist in Pets table (must be unique)
petownerRouter.post('/:email/pets', async (req, res) => {
    try {
        const { email } = req.params
        const { pet_name, special_requirements, description, species } = req.body;
        // console.log(req.body);
        const sql = await pool.query(
            "INSERT INTO Pets (email, pet_name, special_requirements, description, species) \
             VALUES ($1, $2, $3, $4, $5);",
             [email, pet_name, special_requirements, description, species]
        );
        res.status(200).send(`Inserted: ${email}, ${pet_name}, ${special_requirements}, ${description}, ${species}`);
    } catch (err) {
        console.error(err);
    }
});

// Add new pet to database of user (with verifyJwt)
petownerRouter.post('/addpet', verifyJwt, async (req, res) => {
    const user = res.locals.user;
    const email = user.email;
    const {pet_name, special_requirements, description, species} = req.body;
    try {
    const { rows } = await pool.query(
        "INSERT INTO pets (email, pet_name, special_requirements, description, species) \
        VALUES ($1, $2, $3, $4, $5);",
    [email, pet_name, special_requirements, description, species]);
    res.json(true);
    console.log(req.body);
    } catch (err) {
        console.log(err);
        res.json(false);
    }
});

// Update existing pet to database of user (with verifyJwt)
petownerRouter.put('/updatepet', verifyJwt, async (req, res) => {
    const user = res.locals.user;
    const email = user.email;
    const {pet_name, special_requirements, description, species} = req.body;
    console.log(req.body);
    try {
    const { rows } = await pool.query(
        "UPDATE pets SET \
        special_requirements = $3, \
        description = $4, \
        species = $5 \
        WHERE email = $1 and pet_name = $2",
    [email, pet_name, special_requirements, description, species]);
    res.json(true);
    } catch (err) {
        console.log(err);
        res.json(false);
    }
});

// Remove existing pet from database of user (with verifyJwt)
petownerRouter.post('/deletepet', verifyJwt, async (req, res) => {
    const user = res.locals.user;
    const email = user.email;
    const { pet_name } = req.body;
    try {
    const { rows } = await pool.query(
        "DELETE FROM pets \
        WHERE email = $1 and pet_name = $2",
    [email, pet_name]);
    res.json(true);
    console.log(email+pet_name);
    } catch (err) {
        console.log(err);
        res.json(false);
    }
});

// returns a list of all pet types
petownerRouter.get('/alltypes', async(req, res) => {
    try {
        const msql = await pool.query(
            "select * from Pettypes;"
            );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// get specified pet details
petownerRouter.post('/pet/detailed', async(req, res) => {
    try {
        const pet_name = req.body.pet_name;
        const owner = req.body.owner_email;
        const msql = await pool.query(
            "select species, special_requirements, description from pets where pet_name=$1 and email=$2;",
            [pet_name, owner]
            );
        res.json(msql.rows[0]); 
    } catch (err) {
        console.error(err);
    }
});


module.exports = {
    petownerRouter
}