const { Pool } = require('pg');

const pool = new Pool({
    user: "postgres",
    password: "aaa",
    database: "pcs",
    port: "5432",
    host: "localhost"
});

module.exports = pool;