require('dotenv').config();
console.log('👉 ENV DB_USER:', process.env.DB_USER);
console.log('👉 ENV DB_PASS:', process.env.DB_PASS);
const express = require('express');
const cors = require('cors');
const sequelize = require('./src/config/database');
const authRoutes = require('./src/routes/auth');
const listingRoutes = require('./src/routes/listing');

const app = express();
app.use(cors({
  origin: 'http://localhost:3000',
  credentials: true
}));
app.use(express.json());

// Test DB connection
sequelize.authenticate()
  .then(() => console.log('🔌 MySQL connected successfully.'))
  .catch(err => console.error('❌ Unable to connect to MySQL:', err));

// Sync models
sequelize.sync({ alter: true })
  .then(() => console.log('✅ Models synced with MySQL'));

app.use('/api/auth', authRoutes);
app.use('/api/listings', listingRoutes);

app.listen(5000, () => console.log('🚀 Server running on port 5000'));