const express = require('express');
const router = express.Router();
const { Listing, Vehicle, User } = require('../models');
const auth = require('../middleware/auth');

// GET /api/listings — tìm kiếm xe
router.get('/', async (req, res) => {
  try {
    const listings = await Listing.findAll({
      include: [
        {
          model: Vehicle,
          as: 'Vehicle', // 👈 PHẢI KHỚP VỚI `as` TRONG MODEL
          attributes: ['id', 'vin', 'model', 'year', 'color', 'battery_kwh', 'odo_km', 'images']
        },
        {
          model: User,
          as: 'Seller', // 👈 PHẢI KHỚP VỚI `as` TRONG MODEL
          attributes: ['name', 'phone', 'email']
        }
      ],
      limit: 20
    });

    res.json(listings);
  } catch (err) {
    console.error('❌ Lỗi lấy danh sách listing:', err);
    res.status(500).json({ error: 'Lỗi server' });
  }
});

// POST /api/listings — đăng tin (seller)
router.post('/', auth, async (req, res) => {
  const { vehicle_id, price, description } = req.body;
  try {
    const listing = await Listing.create({
      vehicle_id,
      seller_id: req.user.id,
      price,
      description
    });
    res.status(201).json(listing);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET /api/listings/:id
router.get('/:id', async (req, res) => {
  try {
    const listing = await Listing.findByPk(req.params.id, {
      include: [
        { model: Vehicle, attributes: { exclude: ['createdAt', 'updatedAt'] } },
        { model: User, as: 'Seller', attributes: ['name', 'phone'] }
      ]
    });
    if (!listing) return res.status(404).json({ error: 'Not found' });
    res.json(listing);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/listings/create — người bán đăng tin mới
router.post('/create', auth, async (req, res) => {
  const { 
    vin, plate, model, year, color, battery_kwh, odo_km, price, 
    description, images 
  } = req.body;

  try {
    // Tạo xe mới
    const vehicle = await Vehicle.create({
      vin,
      plate,
      model,
      year,
      color,
      battery_kwh,
      odo_km,
      price,
      images,
      seller_id: req.user.id // lấy từ JWT
    });

    // Tạo tin đăng
    const listing = await Listing.create({
      vehicle_id: vehicle.id,
      seller_id: req.user.id,
      price,
      status: 'active',
      description
    });

    res.status(201).json({ 
      message: 'Đăng tin thành công',
      listing_id: listing.id,
      vehicle_id: vehicle.id
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi khi đăng tin' });
  }
});

module.exports = router;