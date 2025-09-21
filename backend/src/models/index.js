// backend/src/models/index.js

const { Sequelize } = require('sequelize');
const sequelize = require('../config/database');

// 👇 GỌI HÀM VỚI sequelize & DataTypes
const User = require('./User')(sequelize, Sequelize.DataTypes);
const Vehicle = require('./Vehicle')(sequelize, Sequelize.DataTypes);
const Listing = require('./Listing')(sequelize, Sequelize.DataTypes);

// Thiết lập quan hệ
User.associate && User.associate({ User, Vehicle, Listing });
Vehicle.associate && Vehicle.associate({ User, Listing });
Listing.associate && Listing.associate({ Vehicle, User });

module.exports = {
  User,
  Vehicle,
  Listing,
  sequelize,
};