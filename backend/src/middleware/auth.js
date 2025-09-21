const jwt = require('jsonwebtoken');
const { User } = require('../models');

module.exports = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findByPk(decoded.id);
      next();
    } catch (err) {
      return res.status(401).json({ error: 'Token không hợp lệ' });
    }
  }

  if (!token) {
    return res.status(401).json({ error: 'Không có token, truy cập bị từ chối' });
  }
};