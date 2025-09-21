// backend/src/models/Vehicle.js

module.exports = (sequelize, DataTypes) => {
  const Vehicle = sequelize.define(
    'Vehicle',
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      vin: {
        type: DataTypes.STRING,
        unique: true,
        allowNull: false,
      },
      plate: DataTypes.STRING,
      model: DataTypes.STRING,
      year: DataTypes.INTEGER,
      color: DataTypes.STRING,
      battery_kwh: DataTypes.FLOAT,
      odo_km: DataTypes.FLOAT,
      status: {
        type: DataTypes.ENUM('available', 'sold', 'in-service'),
        defaultValue: 'available',
      },
      price: DataTypes.DECIMAL(15, 2),
      images: DataTypes.JSON,
      docs: DataTypes.JSON,
      seller_id: {
        type: DataTypes.UUID,
        allowNull: false, // 👈 BẮT BUỘC CÓ NGƯỜI BÁN
      },
    },
    {
      tableName: 'vehicles',
      timestamps: true,
    }
  );

  Vehicle.associate = function (models) {
    Vehicle.belongsTo(models.User, {
      foreignKey: {
        name: 'seller_id',
        allowNull: false,
      },
      onDelete: 'CASCADE', // 👈 QUAN TRỌNG: DÙNG CASCADE THAY VÌ SET NULL
      onUpdate: 'CASCADE',
    });
    Vehicle.hasOne(models.Listing, { foreignKey: 'vehicle_id' });
  };

  return Vehicle;
};