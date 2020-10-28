const jwt = require('jsonwebtoken');

function verifyJwt(req, res, next) {
  const bearerHeader = req.headers.authorization;

  if (!bearerHeader) {
    res.status(403).json({"error": "Please Login"});
  }

  if (!bearerHeader.startsWith("Bearer ")) {
    res.status(403).json({"error": "Token has expired"});
  }

  const token = bearerHeader.replace("Bearer ", "");
  const user = jwt.verify(token, "secretkey");

  res.locals.user = user;
  next();
}

module.exports = { verifyJwt, jwt };