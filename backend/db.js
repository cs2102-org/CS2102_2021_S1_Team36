const { Pool } = require('pg');

// const pool = new Pool({
//     user: process.env.PSQL_USER,
//     database: "pcs"
// });

// const pool = new Pool({
//     user: "postgres",
//     database: "pcs",
//     host: "localhost",
//     password: "aaa",
//     port: "5432"
// });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

module.exports = pool;
