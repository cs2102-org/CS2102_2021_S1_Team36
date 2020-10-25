const { Pool } = require('pg');

const pool = new Pool({
<<<<<<< HEAD:backend/db.js
    user: process.env.PSQL_USER,
    database: "pcs"
=======
    user: "postgres",
    password: "aaa",
    database: "pcs",
    port: "5432",
    host: "localhost"
>>>>>>> jh:backend/sql.js
});

module.exports = pool;
