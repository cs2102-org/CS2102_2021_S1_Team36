const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.PSQL_USER,
    database: "pcs"
});

module.exports = pool;