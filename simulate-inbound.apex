
// Simulate what the inbound sync would do
// This represents data that would come from the middleware API

List<ExternalUserService.ExternalUserData> usersFromMiddleware = new List<ExternalUserService.ExternalUserData>();

// Create mock data that represents what we'd get from MySQL via middleware
ExternalUserService.ExternalUserData user1 = new ExternalUserService.ExternalUserData();
user1.externalId = 'MYSQL_001';
user1.email = 'mysql.user@database.com';
user1.firstName = 'MySQL';
user1.lastName = 'User';
user1.phone = '+1777888999';
user1.deleted = false;
usersFromMiddleware.add(user1);

// This simulates the inbound sync process
List<Id> syncedIds = ExternalUserService.upsertUsers(usersFromMiddleware);

System.debug('Simulated inbound sync completed');
System.debug('Synced ' + syncedIds.size() + ' users from MySQL');
System.debug('User IDs: ' + syncedIds);

