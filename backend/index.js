require('express-async-errors');
require('dotenv');
const express = require('express');
const pool = require('./db');
const cors = require('cors');
const { pcsRouter } = require('./routes/pcsadmin.js');
const { authRouter } = require('./routes/auth');
const { caretakerRouter } = require('./routes/caretaker.js');
const { bidsRouter } = require('./routes/bids.js');
const { petownerRouter } = require('./routes/petowner.js');
const { postsRouter } = require('./routes/posts.js');
const { commentsRouter } = require('./routes/comments.js');

const router = express.Router();
const app = express();
const PORT = process.env.PORT || 5000;

// DEFINE ROUTES
router.use("/api/auth", authRouter)
      .use("/api/pcs-admins", pcsRouter)
      .use("/api/caretaker", caretakerRouter)
      .use("/api/bids", bidsRouter)
      .use("/api/petowner", petownerRouter)
      .use("/api/posts", postsRouter)
      .use("/api/comments", commentsRouter);


// TODO: move all petowner related routes into it's own router file
// test the shit

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
  

