// backend/src/models/User.js

module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define(
    'User', // tên model
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      name: {
        type: DataTypes.STRING,
        allowNull: false,
      },
      email: {
        type: DataTypes.STRING,
        unique: true,
        allowNull: false,
      },
      phone: DataTypes.STRING,
      role: {
        type: DataTypes.ENUM('buyer', 'seller', 'dealer', 'admin'),
        defaultValue: 'buyer',
      },
      kyc_status: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
      },
      password: DataTypes.STRING,
    },
    {
      tableName: 'users', // tên bảng trong MySQL
      timestamps: true,   // tự động thêm createdAt, updatedAt
    }
  );

  // Thiết lập quan hệ (nếu cần)
  User.associate = function (models) {
    User.hasMany(models.Vehicle, { foreignKey: 'seller_id' });
    User.hasMany(models.Listing, { foreignKey: 'seller_id' });
  };

  return User; // 👈 PHẢI RETURN MODEL
};