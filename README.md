# Salesforce User Sync

Bidirectional user synchronization between Salesforce and MySQL. Keeps user data in sync across systems automatically.

## What it does

Syncs user data between Salesforce (External_User__c object) and a MySQL database. Changes in either system show up in the other one.

Features:
- Real-time sync from Salesforce using triggers
- Scheduled sync from MySQL to Salesforce  
- Handles creates, updates, and soft deletes
- Logs all sync operations
- Uses external IDs to prevent duplicates

## How it works

**Salesforce to MySQL:**
When you change a user record in Salesforce, the trigger fires and queues a job that sends the data to the middleware API, which updates MySQL.

**MySQL to Salesforce:** 
A scheduled job periodically checks the middleware for changes and pulls new/updated users into Salesforce.

The middleware is a Node.js Express server deployed on Railway that handles the API calls and database operations.

## Setup

You need:
- Salesforce Developer Edition org
- Salesforce CLI installed
- Node.js and npm
- Railway account

To deploy:
```bash
git clone [repo-url]
cd sf-user-sync
./run.sh
```

Test everything:
```bash
./test.sh
```

## Project structure

```
force-app/main/default/
├── classes/               # Apex classes for sync logic
├── objects/               # Custom objects and fields  
├── triggers/              # Database triggers
└── remoteSiteSettings/    # HTTP permissions

middleware/                # Node.js API server
├── server.js
└── package.json

test.sh                   # Test script
run.sh                   # Deployment script
```

## API Endpoints

The middleware provides these endpoints:

- `GET /users` - List all users
- `GET /users/changes-since/{timestamp}` - Get users changed since a timestamp  
- `POST /users/from-salesforce` - Endpoint for Salesforce to push user changes
- `GET /health` - Health check

## Key Components

**Salesforce side:**
- `External_User__c` object stores the user data
- Trigger on the object fires when records change
- Queueable job handles the HTTP callout to middleware
- Schedulable job polls for external changes

**Middleware:**  
- Express.js server running on Railway
- Connects to Railway's MySQL database
- Handles data transformation between systems
- Provides REST API for both directions

**Database:**
- MySQL table with user fields and timestamps
- Uses external_user_id as the unique key for syncing
- Tracks created_at and updated_at for change detection
