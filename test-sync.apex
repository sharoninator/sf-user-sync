
External_User__c testUser = new External_User__c();
testUser.External_User_Id__c = 'SYNC_TEST_001';
testUser.Email__c = 'sync.test@integration.com';
testUser.FirstName__c = 'Integration';
testUser.LastName__c = 'Test';
testUser.Phone__c = '+1111222333';
testUser.Deleted__c = false;

insert testUser;

System.debug('Created External User with ID: ' + testUser.Id);
System.debug('External ID: ' + testUser.External_User_Id__c);

