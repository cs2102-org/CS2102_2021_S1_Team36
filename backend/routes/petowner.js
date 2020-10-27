const express = require('express');
const pool = require('../db');
const { json, response } = require('express');

const petownerRouter = express.Router();

/*
to test the endpoints here, use http://localhost:5000/api/petowner/ in front of the urls
*/

// get the pets of a specified user
petownerRouter.get('/:email/pets', async(req, res) => {
    try {
        const { email } = req.params;
        const pets = await pool.query(
            "SELECT * FROM Pets WHERE email = $1",
            [email]
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

module.exports = {
    petownerRouter
}