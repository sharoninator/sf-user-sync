public class ExternalUserOutboundSync implements Queueable, Database.AllowsCallouts {
    
    private List<External_User__c> changedRecords;
    
    public ExternalUserOutboundSync(List<External_User__c> records) {
        this.changedRecords = records;
    }
    
    public void execute(QueueableContext context) {
        if (changedRecords == null || changedRecords.isEmpty()) {
            return;
        }
        
        try {
            // Query for full records to ensure we have all field values
            Set<Id> recordIds = new Set<Id>();
            for (External_User__c record : changedRecords) {
                recordIds.add(record.Id);
            }
            
            List<External_User__c> fullRecords = [
                SELECT Id, External_User_Id__c, User_Email__c, User_FirstName__c, 
                       User_LastName__c, User_Phone__c, User_Deleted__c
                FROM External_User__c 
                WHERE Id IN :recordIds
            ];
            
            // Convert External_User__c records to ExternalUserData format
            List<ExternalUserService.ExternalUserData> userData = convertToUserData(fullRecords);
            
            // Make callout to middleware
            HttpCalloutService.sendUsersToExternalSystem(userData);
            
            // Log successful outbound sync
            SyncLogService.logOutboundSuccess(userData.size(), 
                'Successfully synced ' + userData.size() + ' users to external system');
            
        } catch (Exception ex) {
            // Log outbound sync failure
            SyncLogService.logOutboundFailure(ex.getMessage(), 
                'Failed to sync ' + changedRecords.size() + ' users: ' + ex.getStackTraceString());
            
            // Optionally retry with exponential backoff
            // For now, just log the failure
        }
    }
    
    private List<ExternalUserService.ExternalUserData> convertToUserData(List<External_User__c> records) {
        List<ExternalUserService.ExternalUserData> userData = new List<ExternalUserService.ExternalUserData>();
        
        for (External_User__c externalUser : records) {
            ExternalUserService.ExternalUserData data = new ExternalUserService.ExternalUserData();
            data.externalId = externalUser.External_User_Id__c;
            data.email = externalUser.User_Email__c;
            data.firstName = externalUser.User_FirstName__c;
            data.lastName = externalUser.User_LastName__c;
            data.phone = externalUser.User_Phone__c;
            data.deleted = externalUser.User_Deleted__c;
            
            
            userData.add(data);
        }
        
        return userData;
    }
}