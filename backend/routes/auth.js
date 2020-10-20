const express = require('express');
const pool = require('../db')

const router = express.Router();

router.get("/", async (req, res) => {
  const { rows } = await pool.query(
    "SELECT * FROM Users;"
  );

  return res.status(200).json(rows);
});

// User login
router.get("/login", async (req, res) => {
  const { email, password } = req.body;
  const { rows } = await pool.query(
    "SELECT * FROM Users WHERE email=$1 AND password=$2;"
  , [email, password]);
  if (rows.length < 1) {
    return res.status(404).json({ error: "User not found" });
  }
  return res.status(200).json(rows);
});

// User signup
router.post("/signup", async (req, res) => {
  const { name, email, password, desc } = req.body;
  try {
    await pool.query(
      "INSERT INTO Users VALUES ($1, $2, $3, $4);"
    , [name, email, password, desc]);
  } catch (e) {
    return res.status(404).json({ error: e.toString() });
  }
  return res.status(200).json({ message: "Success" });
});

module.exports = router;