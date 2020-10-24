const express = require('express');
const pool = require('../db');
const jwt = require('../auth/index');
const bcrypt = require('bcrypt');

const saltRounds = 10;

const router = express.Router();

router.get("/", async (req, res) => {
  const { rows } = await pool.query(
    "SELECT * FROM Users;"
  );

  return res.status(200).json(rows);
});

// User login
router.post("/login", async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query(
    "SELECT password, is_fulltime, U.email AS uemail, P.email AS pemail, C.email AS cemail, A.email AS aemail \
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
        const returnJson = { token };
        if (user.pemail != null) {
          returnJson['is_petowner'] = true;
        } else if (user.cemail != null) {
          returnJson['is_caretaker'] = true;
          if (user.is_fulltime) {
            returnJson['is_fulltime'] = true;
          }
        } if (user.aemail != null) {
          returnJson['is_admin'] = true;
        } 
        return res.status(200).json(returnJson);
      });
    // }
  } 

  return res.status(404).json({ error: "User not found" });
});

// User signup
router.post("/signup", async (req, res) => {
  const { name, email, password, desc, caretaker, pet_owner, type } = req.body;
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

module.exports = router;