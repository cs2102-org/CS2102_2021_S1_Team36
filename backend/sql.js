const { Pool } = require('pg');

const pool = new Pool({
    user: "jay",          //edit here
    database: "pcs"
});

module.exports = pool;