#!/bin/bash

# SF User Sync - Deployment Script
# Deploys the complete bidirectional sync system

echo "Deploying SF User Sync System..."

# Deploy Salesforce components
echo "Deploying Salesforce components..."
sf project deploy start --source-dir force-app/

if [ $? -eq 0 ]; then
    echo "Salesforce deployment successful"
else
    echo "Salesforce deployment failed"
    exit 1
fi

# Check if middleware is running locally
echo "Checking middleware status..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "Local middleware is running"
    echo "You can now test with: ./test.sh"
else
    echo "Local middleware not detected"
    echo "Start middleware with: cd middleware && npm start"
    echo "Or use Railway production: middleware-production-229f.up.railway.app"
fi

echo "Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Update HttpCalloutService.cls with your Railway URL"
echo "2. Update Production_Middleware.remoteSite-meta.xml with your Railway URL"
echo "3. Run ./test.sh to verify bidirectional sync"