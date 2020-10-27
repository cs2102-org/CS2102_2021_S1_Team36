require('express-async-errors');
require('dotenv');
const express = require('express');
const pool = require('./db');
const cors = require('cors');
const {pcsRouter} = require('./routes/pcsadmin.js');
const {authRouter} = require('./routes/auth');
const {caretakerRouter} = require('./routes/caretaker.js');
const { bidsRouter } = require('./routes/bids.js');

const router = express.Router();
const app = express();
const PORT = process.env.PORT || 5000;

// DEFINE ROUTES
router.use("/api/auth", authRouter)
      .use("/api/pcs-admins", pcsRouter)
      .use("/api/caretaker", caretakerRouter)
      .use("/api/bids", bidsRouter);

app.use(express.json())
    .use(cors())
    .use(express.urlencoded({extended: false}))
    .use(router)
    .listen(PORT, () => console.log(`Running server on ${PORT}`));

// get all users
app.get('/user', async(req, res) => {
      try {
          const users = await pool.query("SELECT * FROM Users");
          res.json(users.rows); 
      } catch (err) {
          console.error(err);
      }
  });
  
// get the pets of a specified user
app.get('/user/owns/:email', async(req, res) => {
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
app.post('/user/owns/:email', async (req, res) => {
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

