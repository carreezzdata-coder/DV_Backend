const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const { testConnection, closePool } = require('./config/db');
const cleanupScheduler = require('./services/cleanupScheduler');
const promotionCronService = require('./services/promotionCronService');

const PORT = process.env.PORT || 5000;
const isProduction = process.env.NODE_ENV === 'production';

const server = http.createServer(app);

const allowedOrigins = isProduction
  ? [
      'https://www.dailyvaibe.com',
      'https://dailyvaibe.com',
      'https://dailyvaibe-frontend.onrender.com',
      process.env.FRONTEND_URL,
      process.env.CORS_ORIGIN
    ].filter(Boolean)
  : [
      'http://localhost:3000',
      'http://localhost:5173',
      'http://localhost:5001',
      'http://127.0.0.1:3000'
    ];

const io = new Server(server, {
  cors: {
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST']
  },
  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000,
  maxHttpBufferSize: 1e8,
  allowEIO3: true
});

io.engine.on('connection_error', (err) => {
  console.error('Socket.IO Connection Error:', {
    code: err.code,
    message: err.message
  });
});

io.use((socket, next) => {
  const origin = socket.handshake.headers.origin;

  if (!origin || allowedOrigins.includes(origin) || !isProduction) {
    return next();
  }

  console.error('WebSocket CORS blocked:', origin);
  next(new Error('Origin not allowed'));
});

io.on('connection', (socket) => {
  const clientIP = socket.handshake.headers['cf-connecting-ip'] ||
                   socket.handshake.headers['x-forwarded-for'] ||
                   socket.handshake.address;

  console.log(`Client connected: ${socket.id} | IP: ${clientIP}`);

  socket.on('disconnect', (reason) => {
    console.log(`Client disconnected: ${socket.id} | Reason: ${reason}`);
  });

  socket.on('join-room', (room) => {
    if (typeof room === 'string' && room.length < 100) {
      socket.join(room);
      socket.emit('room-joined', { room, success: true });
    } else {
      socket.emit('error', { message: 'Invalid room name' });
    }
  });

  socket.on('leave-room', (room) => {
    socket.leave(room);
    socket.emit('room-left', { room, success: true });
  });

  socket.on('error', (error) => {
    console.error(`Socket Error [${socket.id}]:`, error);
  });
});

app.set('io', io);

async function initializeWorkers() {
  console.log('\n========================================');
  console.log('   Initializing Background Workers');
  console.log('========================================\n');

  try {
    await cleanupScheduler.start();
    console.log('Cleanup Scheduler: Active (Every 24 hours)');
  } catch (error) {
    console.error('Cleanup Scheduler failed:', error.message);
  }

  try {
    promotionCronService.startAll();
    console.log('Promotion Cron Service: Active');
  } catch (error) {
    console.error('Promotion Cron Service failed:', error.message);
  }

  console.log('\n========================================');
  console.log('   Worker Initialization Complete');
  console.log('========================================\n');
}

const gracefulShutdown = async (signal) => {
  console.log(`\n${signal} received`);
  console.log('Starting graceful shutdown...');

  const shutdownTimeout = setTimeout(() => {
    console.error('Graceful shutdown timeout, forcing exit');
    process.exit(1);
  }, 30000);

  try {
    console.log('Stopping background workers...');
    cleanupScheduler.stop();
    promotionCronService.stopAll();
    console.log('Workers stopped');

    console.log('Closing Socket.IO connections...');
    io.close(() => {
      console.log('Socket.IO connections closed');
    });

    console.log('Closing HTTP server...');
    server.close(() => {
      console.log('HTTP server closed');
    });

    console.log('Closing database pool...');
    await closePool();
    console.log('Database pool closed');

    clearTimeout(shutdownTimeout);
    console.log('Graceful shutdown completed');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    clearTimeout(shutdownTimeout);
    process.exit(1);
  }
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

(async function startServer() {
  try {
    console.log('Testing database connection...');
    const connected = await testConnection();

    if (!connected) {
      console.error('Failed to connect to database');
      process.exit(1);
    }

    console.log('Database connected');

    if (process.env.CLOUDFLARE_ACCOUNT_ID && process.env.R2_ACCESS_KEY_ID) {
      console.log('Cloudflare R2 configured');
      console.log(`   - Bucket: ${process.env.R2_BUCKET_NAME || 'Not set'}`);
    } else {
      console.log('Cloudflare R2 not configured');
    }

    server.listen(PORT, '0.0.0.0', async () => {
      console.log('\n========================================');
      console.log('Daily Vaibe Backend Server Running');
      console.log('========================================');
      console.log(`Environment: ${isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}`);
      console.log(`Port: ${PORT}`);
      console.log(`HTTP: http://0.0.0.0:${PORT}`);
      console.log(`WebSocket: Enabled`);
      console.log(`Trust Proxy: ${isProduction ? 'Enabled' : 'Disabled'}`);
      console.log(`Cloudflare: ${process.env.CLOUDFLARE_ACCOUNT_ID ? 'Active' : 'Inactive'}`);
      console.log('========================================\n');

      await initializeWorkers();
    });

    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use`);
      } else {
        console.error('Server error:', error);
      }
      process.exit(1);
    });

  } catch (err) {
    console.error('Startup error:', err.message);
    process.exit(1);
  }
})();

module.exports = { server, io };