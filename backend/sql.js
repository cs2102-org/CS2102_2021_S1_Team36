const { Pool } = require('pg');

const pool = new Pool({
    user: process.env.PSQL_USER,          //edit here
    database: "pcs"
});

module.exports = pool;