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
            // Convert External_User__c records to ExternalUserData format
            List<ExternalUserService.ExternalUserData> userData = convertToUserData(changedRecords);
            
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
            data.email = externalUser.Email__c;
            data.firstName = externalUser.FirstName__c;
            data.lastName = externalUser.LastName__c;
            data.phone = externalUser.Phone__c;
            data.deleted = externalUser.Deleted__c;
            
            userData.add(data);
        }
        
        return userData;
    }
}