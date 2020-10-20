const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
  const bearerHeader = rseq.headers['authorization'];
  if (typeof bearerHeader !== 'undefined') {
    const bearer = bearerHeader.split(' ');
    const bearerToken = bearer[1];
    req.token = bearerToken;
    next();
  } else {
    res.sendStatus(403);
  }
}

module.exports = jwt;