const jwt = require('jsonwebtoken');

function verifyJwt(req, res, next) {
  const bearerHeader = req.headers.authorization;

  if (!bearerHeader) {
    res.status(403).json({"error": "Please Login"});
  }

  if (!bearerHeader.startsWith("Bearer ")) {
    res.status(403).json({"error": "Invalid format"});
  }

  const token = bearerHeader.replace("Bearer ", "");
  let user;
  jwt.verify(token, "secretkey", function(err, decoded) {
    if (err) res.status(403).json({"error": "Please Login"});
    user = decoded;
  });

  res.locals.user = user;
  next();
}

module.exports = { verifyJwt, jwt };