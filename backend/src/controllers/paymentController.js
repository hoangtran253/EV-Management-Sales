const { Order, Listing, User } = require('../models');
const VNPayService = require('../services/vnpay'); // giả lập

exports.createDeposit = async (req, res) => {
  const { listing_id, deposit_amount } = req.body;
  const buyer_id = req.user.id;

  try {
    const listing = await Listing.findByPk(listing_id, {
      include: [{ model: User, as: 'Seller' }]
    });
    if (!listing) return res.status(404).json({ error: 'Listing not found' });

    // Tạo đơn hàng
    const order = await Order.create({
      listing_id,
      buyer_id,
      seller_id: listing.seller_id,
      deposit_amount,
      amount: listing.price,
      status: 'pending_deposit'
    });

    // Tạo URL thanh toán VNPay
    const paymentUrl = VNPayService.createPaymentUrl({
      amount: deposit_amount,
      orderId: order.id,
      returnUrl: `${process.env.FRONTEND_URL}/payment/return`
    });

    res.json({ paymentUrl, orderId: order.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.handleReturn = async (req, res) => {
  const { vnp_ResponseCode, vnp_TxnRef } = req.query; // vnp_TxnRef = orderId

  if (vnp_ResponseCode === '00') {
    await Order.update(
      { status: 'paid', payment_tx: req.query.vnp_TransactionNo },
      { where: { id: vnp_TxnRef } }
    );
    // Gửi mail/SMS thông báo
  }

  res.redirect(`/order/${vnp_TxnRef}/success`);
};