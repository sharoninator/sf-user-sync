# Salesforce MySQL User Synchronization System

A complete bidirectional synchronization system between Salesforce and MySQL for user data management.

## Architecture

```
Salesforce ↔ Node.js Middleware ↔ MySQL Database
```

### Components

- **Salesforce**: Custom objects, triggers, and Apex classes for real-time sync
- **Node.js Middleware**: Express.js API server for data transformation and routing  
- **MySQL Database**: User data storage with timestamp-based change tracking

## Deployment

### Prerequisites

1. Salesforce Developer Edition org
2. Railway account (free tier)
3. GitHub account

### Railway Deployment Steps

1. **Deploy to Railway**:
   - Connect this GitHub repository to Railway
   - Add MySQL database service
   - Configure environment variables (auto-populated by Railway)

2. **Update Salesforce Configuration**:
   - Replace `YOUR-RAILWAY-APP` in `HttpCalloutService.cls` with your Railway URL
   - Update `Production_Middleware.remoteSite-meta.xml` with your Railway URL
   - Deploy to Salesforce

3. **Initialize Database**:
   - Run the SQL schema from `database-schema.sql` in Railway MySQL

## Features

- **Real-time Outbound Sync**: Salesforce → MySQL via triggers
- **Scheduled Inbound Sync**: MySQL → Salesforce via schedulable jobs
- **External ID Upserts**: Prevents duplicates and handles updates
- **Comprehensive Logging**: Track sync operations and errors
- **Production Ready**: Environment variables and error handling

## API Endpoints

- `GET /health` - Health check
- `GET /users` - List all users
- `GET /users/changes-since/:timestamp` - Get users modified since timestamp
- `POST /users/from-salesforce` - Receive user updates from Salesforce

## Local Development

1. **Install Dependencies**:
   ```bash
   cd middleware && npm install
   ```

2. **Setup MySQL**:
   ```bash
   # Configure database connection in middleware/server.js
   # Run schema from database-schema.sql
   ```

3. **Start Middleware**:
   ```bash
   cd middleware && npm start
   ```

4. **Deploy Salesforce Components**:
   ```bash
   sf project deploy start --source-dir force-app/
   ```

## Database Schema

The `users` table includes:
- `external_user_id` (External ID for upserts)
- Contact fields: `email`, `first_name`, `last_name`, `phone`
- Status: `deleted` (soft delete flag)
- Timestamps: `created_at`, `updated_at` (for change tracking)

## Configuration

Update these files after Railway deployment:
- `force-app/main/default/classes/HttpCalloutService.cls` 
- `force-app/main/default/remoteSiteSettings/Production_Middleware.remoteSite-meta.xml`

Replace `YOUR-RAILWAY-APP` with your actual Railway application URL.
