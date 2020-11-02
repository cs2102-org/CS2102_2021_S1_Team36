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

// Find petowners with similar tastes as the specified petowner
// input: email of petowner A
// output: table (email) of emails of petowners with similar taste as A
// two petowners have similar taste if their sets of liked caretakers have at least 3 caretakers in common
// this endpoint is more for testing than actually becoming a feature
// test: input perry, should get pearl (and vice versa)
petownerRouter.post('/similar/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * from petowners \
            where \
                isSimilar($1, email) and \
                email != $1",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

// find all caretakers that this petowner likes
// a petowner likes a caretaker if the petowner's average rating for that caretaker is >= 4
// input: petowner email
// output: table(email, rating, is_fulltime)
// this endpoint is more for testing than actually becoming a feature
// test with perry, pearl
petownerRouter.post('/likes/:email', async (req, res) => {
    try {
        const { email } = req.params;
        const msql = await pool.query(
            "select * from caretakers \
            where \
                likes($1, email)",
            [email]
        );
        res.json(msql.rows); 
    } catch (err) {
        console.error(err);
    }
});

module.exports = {
    petownerRouter
}