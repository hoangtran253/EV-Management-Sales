// backend/seed.js
require('dotenv').config();
const sequelize = require('./src/config/database');
const {
  User,
  Vehicle,
  Listing,
  Order,
  MaintenanceTicket,
  Telemetry,
  Contract,
  ChatMessage
} = require('./src/models');

async function seed() {
  try {
    console.log('🔧 Đang reset database...');
    await sequelize.sync({ force: true });
    console.log('✅ Database reset hoàn tất');

    // =============== TẠO NGƯỜI DÙNG ===============
    console.log('\n👤 Đang tạo người dùng mẫu...');

    const admin = await User.create({
      name: 'Admin EV Marketplace',
      email: 'admin@ev.com',
      phone: '0900000001',
      role: 'admin',
      kyc_status: true,
      password: '$2b$10$QkWvJvFzYz5R5u3v3Yw8Ee7K9O9Z0Y4K4X4X4X4X4X4X4' // bcrypt hash of "123456"
    });

    const seller = await User.create({
      name: 'Nguyễn Văn Seller',
      email: 'seller@ev.com',
      phone: '0900000002',
      role: 'seller',
      kyc_status: true,
      password: '$2b$10$QkWvJvFzYz5R5u3v3Yw8Ee7K9O9Z0Y4K4X4X4X4X4X4X4'
    });

    const buyer = await User.create({
      name: 'Trần Thị Buyer',
      email: 'buyer@ev.com',
      phone: '0900000003',
      role: 'buyer',
      password: '$2b$10$QkWvJvFzYz5R5u3v3Yw8Ee7K9O9Z0Y4K4X4X4X4X4X4X4'
    });

    console.log('✅ Đã tạo 3 người dùng:');
    console.log(`   - Admin: ${admin.email}`);
    console.log(`   - Seller: ${seller.email}`);
    console.log(`   - Buyer: ${buyer.email}`);

    // =============== TẠO XE ===============
    console.log('\n🚗 Đang tạo xe điện mẫu...');

    const vehicle1 = await Vehicle.create({
      vin: 'VF123456789000001',
      plate: '51A-999.99',
      model: 'VinFast VF e34',
      year: 2023,
      color: 'Đỏ',
      battery_kwh: 42.0,
      odo_km: 12000,
      price: 690000000,
      images: [
        'https://via.placeholder.com/600x400/ff6b6b/ffffff?text=VF+e34+Red+Front',
        'https://via.placeholder.com/600x400/4ecdc4/ffffff?text=VF+e34+Red+Side'
      ],
      docs: ['registration.pdf', 'warranty.pdf'],
      seller_id: seller.id
    });

    const vehicle2 = await Vehicle.create({
      vin: 'VF123456789000002',
      plate: '51B-888.88',
      model: 'VinFast VF 8 Plus',
      year: 2024,
      color: 'Trắng',
      battery_kwh: 87.0,
      odo_km: 5000,
      price: 1350000000,
      images: [
        'https://via.placeholder.com/600x400/f7f9fc/333333?text=VF8+White+Front',
        'https://via.placeholder.com/600x400/e3e3e3/333333?text=VF8+White+Rear'
      ],
      docs: ['registration.pdf', 'inspection.pdf'],
      seller_id: seller.id
    });

    console.log('✅ Đã tạo 2 xe:');
    console.log(`   - ${vehicle1.model} (VIN: ${vehicle1.vin})`);
    console.log(`   - ${vehicle2.model} (VIN: ${vehicle2.vin})`);

    // =============== TẠO TIN ĐĂNG ===============
    console.log('\n📢 Đang tạo tin đăng...');

    const listing1 = await Listing.create({
      vehicle_id: vehicle1.id,
      seller_id: seller.id,
      price: 690000000,
      status: 'active',
      description: 'Xe đẹp, pin khỏe, bảo dưỡng định kỳ, tặng bảo hiểm 1 năm.'
    });

    const listing2 = await Listing.create({
      vehicle_id: vehicle2.id,
      seller_id: seller.id,
      price: 1350000000,
      status: 'active',
      description: 'Xe mới 99%, full option, camera 360, hỗ trợ trả góp 0%.'
    });

    console.log('✅ Đã tạo 2 tin đăng hoạt động');

    // =============== TẠO LỊCH SỬ BẢO DƯỠNG ===============
    console.log('\n🔧 Đang tạo lịch sử bảo dưỡng...');

    await MaintenanceTicket.bulkCreate([
      {
        vehicle_id: vehicle1.id,
        type: 'routine',
        status: 'completed',
        cost: 500000,
        notes: 'Thay dầu, kiểm tra phanh, cân chỉnh thước lái.',
        service_date: new Date('2024-10-01')
      },
      {
        vehicle_id: vehicle2.id,
        type: 'recall',
        status: 'completed',
        cost: 0,
        notes: 'Cập nhật phần mềm hệ thống phanh khẩn cấp.',
        service_date: new Date('2024-11-15')
      }
    ]);

    console.log('✅ Đã tạo 2 bản ghi bảo dưỡng');

    // =============== TẠO DỮ LIỆU TELEMETRY ===============
    console.log('\n📡 Đang tạo dữ liệu telemetry (pin, km, cảnh báo)...');

    const now = new Date();
    await Telemetry.bulkCreate([
      { vehicle_id: vehicle1.id, soc: 85, odo_km: 12000, charging_cycles: 45, alerts: [] },
      { vehicle_id: vehicle1.id, soc: 60, odo_km: 12100, charging_cycles: 46, alerts: ['low_tire_pressure'] },
      { vehicle_id: vehicle1.id, soc: 95, odo_km: 12150, charging_cycles: 47, alerts: [] },
      { vehicle_id: vehicle2.id, soc: 78, odo_km: 5000, charging_cycles: 12, alerts: [] },
      { vehicle_id: vehicle2.id, soc: 45, odo_km: 5200, charging_cycles: 13, alerts: ['battery_temp_high'] }
    ]);

    console.log('✅ Đã tạo 5 bản ghi telemetry');

    // =============== TẠO ĐƠN HÀNG & HỢP ĐỒNG ===============
    console.log('\n🧾 Đang tạo đơn hàng và hợp đồng mẫu...');

    const order = await Order.create({
      listing_id: listing1.id,
      buyer_id: buyer.id,
      seller_id: seller.id,
      amount: 690000000,
      deposit_amount: 50000000,
      status: 'paid',
      payment_tx: 'VNPay_TX_123456789'
    });

    await Contract.create({
      order_id: order.id,
      contract_pdf: 'https://example.com/contracts/contract_123.pdf',
      signed_by_buyer: true,
      signed_by_seller: true,
      signed_at: new Date()
    });

    console.log('✅ Đã tạo 1 đơn hàng và 1 hợp đồng điện tử');

    // =============== TẠO TIN NHẮN CHAT ===============
    console.log('\n💬 Đang tạo tin nhắn chat...');

    await ChatMessage.bulkCreate([
      {
        conv_id: listing1.id,
        sender_id: buyer.id,
        content: 'Chào anh, em muốn hỏi về xe VF e34 này ạ. Xe còn bảo hành không ạ?'
      },
      {
        conv_id: listing1.id,
        sender_id: seller.id,
        content: 'Chào bạn, xe còn bảo hành chính hãng đến tháng 12/2025 nhé. Mời bạn đến xem xe!'
      },
      {
        conv_id: listing1.id,
        sender_id: buyer.id,
        content: 'Cảm ơn anh, em sẽ qua xem vào cuối tuần này ạ.'
      }
    ]);

    console.log('✅ Đã tạo 3 tin nhắn chat');

    console.log('\n🎉 🚀 SEED DATA HOÀN THÀNH! HỆ THỐNG SẴN SÀNG CHO PHÁT TRIỂN.');
    console.log('👉 Bạn có thể bắt đầu test API hoặc phát triển frontend.');

    process.exit(0);
  } catch (err) {
    console.error('\n❌ SEED DATA THẤT BẠI:');
    console.error(err);
    process.exit(1);
  }
}

seed();