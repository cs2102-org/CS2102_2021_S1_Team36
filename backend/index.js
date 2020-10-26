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