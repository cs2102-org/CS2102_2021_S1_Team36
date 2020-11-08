const express = require('express');
const pool = require('../db');
const { jwt, verifyJwt } = require('../auth/index');
const bcrypt = require('bcrypt');

const saltRounds = 10;

const authRouter = express.Router();

authRouter.get("/", async (req, res) => {
  // const { rows } = await pool.query(
  //   "SELECT * FROM Users;"
  // );

  // return res.status(200).json(rows);
  res.send('herllo!');
});

// User login
authRouter.post("/login", async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query(
    "SELECT U.email, password, is_fulltime, U.email AS uemail, P.email AS pemail, C.email AS cemail, A.email AS aemail \
      FROM ((Users U LEFT JOIN PetOwners P ON U.email=P.email) \
        LEFT JOIN Caretakers C ON U.email=C.email) \
          LEFT JOIN PCSAdmins A on U.email=A.email \
    WHERE U.email=$1 AND U.password=$2"
  , [email, password]);

  if (rows.length > 0) {
    const user = rows[0];
    // const passwordStored = user.password;
    // const validPass = await bcrypt.compare(password, passwordStored);
    // if (validPass) {
      return jwt.sign(rows[0], 'secretkey', (err, token) => {
        const { pemail, cemail, aemail, is_fulltime } = rows[0];
        const returnJson = Object.assign({}, { token }, { pemail, cemail, aemail, is_fulltime });
        return res.status(200).json(returnJson);
      });
    // }
  } 

  return res.status(404).json({ error: "User not found" });
});

// User signup
authRouter.post("/signup", async (req, res) => {
  const { name, email, password, description, caretaker, pet_owner } = req.body;
  // const hash = await bcrypt.hash(password, saltRounds);
  try {
    if (pet_owner && caretaker) {
      await pool.query(
        "select createPtAndPo($1, $2, $3, $4);",
      [email, name, description, password]);
    } else if (pet_owner) {
      await pool.query(
        "select createPetOwner($1, $2, $3, $4);",
      [email, name, description, password]);
    } else if (caretaker){
      await pool.query(
        "select createPtCaretaker($1, $2, $3, $4);",
      [email, name, description, password]);
    } else {
      return res.status(404).json({ error: "No options chosen." });
    }
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
          "SELECT email, description, rating, name, password, \
          CASE WHEN is_fulltime THEN 'Full Time' ELSE 'Part Time' END\
          FROM Users NATURAL JOIN Caretakers WHERE email = $1\;",
          [email]
      );
      const msql_po = await pool.query(
          "select * from users U natural join petowners\
          where U.email = $1;",
          [email]
      );
      const msql_pcs = await pool.query(
        "select * from pcsadmins P natural join users U\
        where P.email = $1;",
        [email]
    );
      userProfileList.push(msql_ct.rows);
      userProfileList.push(msql_po.rows);
      userProfileList.push(msql_pcs.rows);
      console.log(userProfileList);
      res.json(userProfileList);

  } catch (err) {
      console.error(err);
  }
});

// Update User's Name, Password and Description
authRouter.put("/update", verifyJwt, async (req, res) => {
  const user = res.locals.user;
  const email = user.email;
  const {name, password, description} = req.body;
  try {
    const { rows } = await pool.query(
      "UPDATE users SET \
        name = $1,\
        password = $2, \
        description = $3 \
      WHERE email=$4;"
    , [name, password, description, email]);
    res.json(true);
    console.log(req.body);
    } catch (err) {
      console.log(err);
      res.json(false);
    }
});