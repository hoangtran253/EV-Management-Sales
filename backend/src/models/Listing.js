// backend/src/models/Listing.js

module.exports = (sequelize, DataTypes) => {
  const Listing = sequelize.define(
    'Listing',
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      vehicle_id: {
        type: DataTypes.UUID,
        allowNull: false, // 👈 BẮT BUỘC CÓ XE
      },
      seller_id: {
        type: DataTypes.UUID,
        allowNull: false, // 👈 BẮT BUỘC CÓ NGƯỜI BÁN
      },
      price: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: false,
      },
      status: {
        type: DataTypes.ENUM('pending', 'active', 'sold', 'rejected'),
        defaultValue: 'pending',
      },
      description: DataTypes.TEXT,
    },
    {
      tableName: 'listings',
      timestamps: true,
    }
  );

  Listing.associate = function (models) {
    // 👇 SỬA Ở ĐÂY — DÙNG ON DELETE CASCADE
    Listing.belongsTo(models.Vehicle, {
      foreignKey: {
        name: 'vehicle_id',
        allowNull: false,
      },
      onDelete: 'CASCADE', // 👈 XÓA LISTING KHI XÓA VEHICLE
      onUpdate: 'CASCADE',
    });

    Listing.belongsTo(models.User, {
      foreignKey: {
        name: 'seller_id',
        allowNull: false,
      },
      as: 'Seller',
      onDelete: 'CASCADE', // 👈 XÓA LISTING KHI XÓA SELLER
      onUpdate: 'CASCADE',
    });
  };

  return Listing;
};