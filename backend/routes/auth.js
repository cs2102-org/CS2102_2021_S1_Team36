const express = require('express');
const pool = require('../db');
const jwt = require('../auth/index');
const bcrypt = require('bcrypt');
const { json } = require('express');

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
    "SELECT * FROM Users WHERE email=$1;"
  , [email]);
  const passwordStored = rows[0].password;
  const validPass = await bcrypt.compare(passwordStored, password);
  if (rows.length < 1 || !validPass) {
    return res.status(404).json({ error: "User not found" });
  } 

  jwt.sign(rows[0], 'secretkey', (err, token) => {
    return res.status(200).json({token});
  });
});

// User signup
router.post("/signup", async (req, res) => {
  const { name, email, password, desc } = req.body;
  const hash = await bcrypt.hash(password, saltRounds);
  try {
    await pool.query(
      "INSERT INTO Users VALUES ($1, $2, $3, $4);"
    , [name, email, hash, desc]);
  } catch (e) {
    return res.status(404).json({ error: e.toString() });
  }
  return res.status(200).json({ message: "Success" });
});

module.exports = router;