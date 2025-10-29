
External_User__c testUser = new External_User__c();
testUser.External_User_Id__c = 'SYNC_TEST_001';
insert testUser;
System.debug('Created External User with ID: ' + testUser.Id);

