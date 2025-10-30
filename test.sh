#!/bin/bash

# SF User Sync - Comprehensive Test Script
# Tests bidirectional synchronization between Salesforce and Railway MySQL

echo "Testing SF User Sync - Bidirectional Synchronization"
echo "=================================================="

# Configuration
MIDDLEWARE_URL="https://middleware-production-229f.up.railway.app"
TEST_PREFIX="BIDIRECTIONAL_TEST"
TIMESTAMP=$(date +%s)

echo "Test run: $(date)"
echo "Middleware: $MIDDLEWARE_URL"
echo ""

# Test 1: Health Check
echo "1. Testing middleware health..."
HEALTH_RESPONSE=$(curl -s "$MIDDLEWARE_URL/health")
if [[ $? -eq 0 && "$HEALTH_RESPONSE" == *"OK"* ]]; then
    echo "Middleware health check passed"
else
    echo "Middleware health check failed"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test 2: Check initial user count
echo ""
echo "2. Checking initial user counts..."
INITIAL_SF_COUNT=$(sf data query --query "SELECT COUNT() FROM External_User__c" --json | jq -r '.result.totalSize')
INITIAL_MYSQL_COUNT=$(curl -s "$MIDDLEWARE_URL/users" | jq '.users | length')
echo "Salesforce users: $INITIAL_SF_COUNT"
echo "MySQL users: $INITIAL_MYSQL_COUNT"

# Test 3: Create test user in Salesforce (tests outbound sync)
echo ""
echo "3. Testing Salesforce to MySQL sync (CREATE)..."
cat << EOF > create_test_user.apex
External_User__c testUser = new External_User__c();
testUser.External_User_Id__c = '${TEST_PREFIX}_CREATE_${TIMESTAMP}';
testUser.User_Email__c = 'test.create.${TIMESTAMP}@sync-test.com';
testUser.User_FirstName__c = 'Test';
testUser.User_LastName__c = 'Creator';
testUser.User_Phone__c = '+1555000${TIMESTAMP:(-4)}';
testUser.User_Deleted__c = false;
insert testUser;
System.debug('SUCCESS: Created test user: ' + testUser.Id);
System.debug('External ID: ' + testUser.External_User_Id__c);
EOF

sf apex run --file create_test_user.apex
echo "WAIT: Waiting 10 seconds for sync to complete..."
sleep 10

# Verify the user was synced to MySQL
MYSQL_USER=$(curl -s "$MIDDLEWARE_URL/users" | jq -r ".users[] | select(.externalId == \"${TEST_PREFIX}_CREATE_${TIMESTAMP}\") | .externalId")
if [ "$MYSQL_USER" == "${TEST_PREFIX}_CREATE_${TIMESTAMP}" ]; then
    echo "SUCCESS: User successfully synced to MySQL"
else
    echo "ERROR: User not found in MySQL"
fi

# Test 4: Update user in Salesforce (tests outbound sync)
echo ""
echo "4. Testing Salesforce to MySQL sync (UPDATE)..."
cat << EOF > update_test_user.apex
List<External_User__c> users = [SELECT Id FROM External_User__c WHERE External_User_Id__c = '${TEST_PREFIX}_CREATE_${TIMESTAMP}'];
if (!users.isEmpty()) {
    External_User__c user = users[0];
    user.User_FirstName__c = 'Updated';
    user.User_Phone__c = '+1555999${TIMESTAMP:(-4)}';
    update user;
    System.debug('SUCCESS: Updated test user: ' + user.Id);
}
EOF

sf apex run --file update_test_user.apex
echo "WAIT: Waiting 10 seconds for sync to complete..."
sleep 10

# Verify the update was synced to MySQL
UPDATED_USER=$(curl -s "$MIDDLEWARE_URL/users" | jq -r ".users[] | select(.externalId == \"${TEST_PREFIX}_CREATE_${TIMESTAMP}\") | .firstName")
if [ "$UPDATED_USER" == "Updated" ]; then
    echo "SUCCESS: User update successfully synced to MySQL"
else
    echo "ERROR: User update not reflected in MySQL"
fi

# Test 5: Create user in MySQL (tests inbound sync)
echo ""
echo "5. Testing MySQL to Salesforce sync (CREATE via middleware)..."
CREATE_PAYLOAD="{
    \"users\": [
        {
            \"externalId\": \"${TEST_PREFIX}_INBOUND_${TIMESTAMP}\",
            \"email\": \"test.inbound.${TIMESTAMP}@sync-test.com\",
            \"firstName\": \"Inbound\",
            \"lastName\": \"Tester\",
            \"phone\": \"+1666000${TIMESTAMP:(-4)}\",
            \"deleted\": false
        }
    ]
}"

curl -s -X POST "$MIDDLEWARE_URL/users/from-salesforce" \
    -H "Content-Type: application/json" \
    -d "$CREATE_PAYLOAD" > /dev/null

echo "WAIT: Running inbound sync job..."
cat << EOF > run_inbound_sync.apex
ExternalUserInboundSync.executeAsQueueable();
System.debug('SUCCESS: Inbound sync job queued');
EOF

sf apex run --file run_inbound_sync.apex
echo "WAIT: Waiting 15 seconds for inbound sync to complete..."
sleep 15

# Verify the user was synced to Salesforce
SF_INBOUND_USER=$(sf data query --query "SELECT Id FROM External_User__c WHERE External_User_Id__c = '${TEST_PREFIX}_INBOUND_${TIMESTAMP}'" --json | jq -r '.result.records[0].Id // empty')
if [ -n "$SF_INBOUND_USER" ]; then
    echo "SUCCESS: Inbound user successfully synced to Salesforce"
else
    echo "ERROR: Inbound user not found in Salesforce"
fi

# Test 6: Soft delete test
echo ""
echo "6. Testing soft delete functionality..."
cat << EOF > delete_test_user.apex
List<External_User__c> users = [SELECT Id FROM External_User__c WHERE External_User_Id__c = '${TEST_PREFIX}_CREATE_${TIMESTAMP}'];
if (!users.isEmpty()) {
    External_User__c user = users[0];
    user.User_Deleted__c = true;
    update user;
    System.debug('SUCCESS: Soft deleted test user: ' + user.Id);
}
EOF

sf apex run --file delete_test_user.apex
echo "WAIT: Waiting 10 seconds for delete sync to complete..."
sleep 10

# Verify the deletion was synced to MySQL
DELETED_USER=$(curl -s "$MIDDLEWARE_URL/users" | jq -r ".users[] | select(.externalId == \"${TEST_PREFIX}_CREATE_${TIMESTAMP}\") | .deleted")
if [ "$DELETED_USER" == "1" ] || [ "$DELETED_USER" == "true" ]; then
    echo "SUCCESS: User deletion successfully synced to MySQL"
else
    echo "ERROR: User deletion not reflected in MySQL"
fi

# Test 7: Final count verification
echo ""
echo "7. Final count verification..."
FINAL_SF_COUNT=$(sf data query --query "SELECT COUNT() FROM External_User__c" --json | jq -r '.result.totalSize')
FINAL_MYSQL_COUNT=$(curl -s "$MIDDLEWARE_URL/users" | jq '.users | length')
ACTIVE_SF_COUNT=$(sf data query --query "SELECT COUNT() FROM External_User__c WHERE User_Deleted__c = false" --json | jq -r '.result.totalSize')
ACTIVE_MYSQL_COUNT=$(curl -s "$MIDDLEWARE_URL/users" | jq '[.users[] | select(.deleted == false or .deleted == 0)] | length')

echo "Stats: Final Salesforce users: $FINAL_SF_COUNT (Active: $ACTIVE_SF_COUNT)"
echo "Stats: Final MySQL users: $FINAL_MYSQL_COUNT (Active: $ACTIVE_MYSQL_COUNT)"

# Cleanup test files
rm -f create_test_user.apex update_test_user.apex run_inbound_sync.apex delete_test_user.apex

echo ""
echo "SUMMARY: Test Summary"
echo "==============="
if [ "$FINAL_SF_COUNT" -eq "$FINAL_MYSQL_COUNT" ] && [ "$ACTIVE_SF_COUNT" -eq "$ACTIVE_MYSQL_COUNT" ]; then
    echo "SUCCESS: SUCCESS: Bidirectional sync is working correctly!"
    echo "SUCCESS: Total user counts match: $FINAL_SF_COUNT"
    echo "SUCCESS: Active user counts match: $ACTIVE_SF_COUNT"
else
    echo "WARNING:  WARNING: User counts don't match"
    echo "   Salesforce: $FINAL_SF_COUNT total, $ACTIVE_SF_COUNT active"
    echo "   MySQL: $FINAL_MYSQL_COUNT total, $ACTIVE_MYSQL_COUNT active"
fi

echo ""
echo "INFO: Detailed sync logs available in Salesforce:"
echo "   Setup → Environments → Logs → Debug Logs"
echo "Railway logs: https://railway.app"