const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.PSQL_USER,
    database: "pcs",
    host: "localhost",
    password: "aaa",
    port: "5432"
});

module.exports = pool;
