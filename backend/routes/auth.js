const express = require('express');
const pool = require('../db');
const { jwt, verifyJwt } = require('../auth/index');
const bcrypt = require('bcrypt');
const { json } = require('express');

const saltRounds = 10;

const authRouter = express.Router();

authRouter.get("/", async (req, res) => {
  const { rows } = await pool.query(
    "SELECT * FROM Users;"
  );

  return res.status(200).json(rows);
});

// User login
authRouter.post("/login", async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query(
    "SELECT * FROM Users WHERE email=$1 and password=$2;"
  , [email, password]);

  if (rows.length > 0) {
    // const passwordStored = rows[0].password;
    // const validPass = await bcrypt.compare(password, passwordStored);
    // if (validPass) {
      return jwt.sign(rows[0], 'secretkey', (err, token) => {
        return res.status(200).json({token});
      });
    // }
  } 

  return res.status(404).json({ error: "User not found" });
});

// User signup
authRouter.post("/signup", async (req, res) => {
  const { name, email, password, desc } = req.body;
  // const hash = await bcrypt.hash(password, saltRounds);
  try {
    await pool.query(
      "INSERT INTO Users VALUES ($1, $2, $3, $4);"
    , [name, email, desc, password]);
  } catch (e) {
    return res.status(404).json({ error: e.toString() });
  }
  return res.status(200).json({ message: "Success" });
});

module.exports = {
  authRouter
};

// User profile retrieval. Gets detailed information of specified user [for user profile page]
authRouter.get('/profile', verifyJwt, async(req, res) => {
  try {
      const user = res.locals.user;
      const email = user.email;
      const userProfileList = [];
      const msql_ct = await pool.query(
          "SELECT email, description, rating, name, \
          CASE WHEN is_fulltime THEN 'Full Time' ELSE 'Part Time' END\
          FROM Users NATURAL JOIN Caretakers WHERE email = $1\;",
          [email]
      );
      const msql_po = await pool.query(
          "select * from users U left join petowners PO on U.email = PO.email\
          where U.email = $1;",
          [email]
      );
      userProfileList.push(msql_ct.rows);
      userProfileList.push(msql_po.rows);
      console.log(userProfileList);
      res.json(userProfileList);

  } catch (err) {
      console.error(err);
  }
});