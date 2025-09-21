// backend/src/models/Order.js

module.exports = (sequelize, DataTypes) => {
  const Order = sequelize.define(
    'Order',
    {
      id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
      },
      amount: {
        type: DataTypes.DECIMAL(15, 2),
        allowNull: false,
      },
      deposit_amount: DataTypes.DECIMAL(15, 2),
      status: {
        type: DataTypes.ENUM('pending_deposit', 'paid', 'delivered', 'completed', 'cancelled'),
        defaultValue: 'pending_deposit',
      },
      payment_tx: DataTypes.STRING,
    },
    {
      tableName: 'orders',
      timestamps: true,
    }
  );

  Order.associate = function (models) {
    Order.belongsTo(models.Listing, { foreignKey: 'listing_id', as: 'Listing' });
    Order.belongsTo(models.User, { as: 'Buyer', foreignKey: 'buyer_id' });
    Order.belongsTo(models.User, { as: 'Seller', foreignKey: 'seller_id' });
  };

  return Order;
};