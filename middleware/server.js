const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Database configuration - Use environment variables in production
const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'sync_user',
    password: process.env.DB_PASSWORD || 'sync_password',
    database: process.env.DB_NAME || 'user_sync',
    port: process.env.DB_PORT || 3306
};

// Create MySQL connection pool
const pool = mysql.createPool(dbConfig);

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'SF User Sync Middleware API is running',
        timestamp: new Date().toISOString()
    });
});

// GET /users/changes-since/:timestamp - Get users modified since timestamp
app.get('/users/changes-since/:timestamp', async (req, res) => {
    try {
        const { timestamp } = req.params;
        console.log(`Fetching users changed since: ${timestamp}`);
        
        // Convert timestamp to MySQL format
        const mysqlTimestamp = new Date(timestamp).toISOString().slice(0, 19).replace('T', ' ');
        
        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE updated_at > ? ORDER BY updated_at ASC',
            [mysqlTimestamp]
        );
        
        // Transform MySQL data to Salesforce format
        const users = rows.map(row => ({
            externalId: row.external_user_id,
            email: row.email,
            firstName: row.first_name,
            lastName: row.last_name,
            phone: row.phone,
            deleted: Boolean(row.deleted),
            lastModified: row.updated_at.toISOString()
        }));
        
        console.log(`Found ${users.length} users changed since ${timestamp}`);
        res.json({ success: true, users, count: users.length });
        
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error',
            message: error.message 
        });
    }
});

// POST /users/from-salesforce - Receive users from Salesforce
app.post('/users/from-salesforce', async (req, res) => {
    try {
        const { users } = req.body;
        console.log(`Received ${users.length} users from Salesforce`);
        
        if (!Array.isArray(users) || users.length === 0) {
            return res.status(400).json({ 
                success: false, 
                error: 'Invalid input: users array is required' 
            });
        }
        
        let processed = 0;
        let errors = [];
        
        // Process each user
        for (const user of users) {
            try {
                // Validate required fields
                if (!user.externalId) {
                    errors.push(`User missing external ID: ${JSON.stringify(user)}`);
                    continue;
                }
                
                // Insert or update user (UPSERT using ON DUPLICATE KEY UPDATE)
                await pool.execute(`
                    INSERT INTO users (external_user_id, email, first_name, last_name, phone, deleted)
                    VALUES (?, ?, ?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE
                        email = VALUES(email),
                        first_name = VALUES(first_name),
                        last_name = VALUES(last_name),
                        phone = VALUES(phone),
                        deleted = VALUES(deleted),
                        updated_at = CURRENT_TIMESTAMP
                `, [
                    user.externalId,
                    user.email || null,
                    user.firstName || null,
                    user.lastName || null,
                    user.phone || null,
                    user.deleted || false
                ]);
                
                processed++;
                console.log(`Processed user: ${user.externalId}`);
                
            } catch (userError) {
                console.error(`Error processing user ${user.externalId}:`, userError);
                errors.push(`User ${user.externalId}: ${userError.message}`);
            }
        }
        
        const response = {
            success: true,
            processed,
            total: users.length,
            errors: errors.length > 0 ? errors : undefined
        };
        
        console.log(`Processing complete: ${processed}/${users.length} successful`);
        res.json(response);
        
    } catch (error) {
        console.error('Error processing users from Salesforce:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error',
            message: error.message 
        });
    }
});

// GET /users - Get all users (for debugging)
app.get('/users', async (req, res) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM users ORDER BY updated_at DESC');
        
        const users = rows.map(row => ({
            id: row.id,
            externalId: row.external_user_id,
            email: row.email,
            firstName: row.first_name,
            lastName: row.last_name,
            phone: row.phone,
            deleted: Boolean(row.deleted),
            createdAt: row.created_at,
            updatedAt: row.updated_at
        }));
        
        res.json({ success: true, users, count: users.length });
        
    } catch (error) {
        console.error('Error fetching all users:', error);
        res.status(500).json({ 
            success: false, 
            error: 'Internal server error',
            message: error.message 
        });
    }
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 SF User Sync Middleware API running on http://localhost:${PORT}`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
    console.log(`👥 All users: http://localhost:${PORT}/users`);
    console.log(`🔄 Changes endpoint: http://localhost:${PORT}/users/changes-since/{timestamp}`);
    console.log(`📨 Salesforce endpoint: POST http://localhost:${PORT}/users/from-salesforce`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});