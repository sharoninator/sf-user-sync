public class ExternalUserInboundSync implements Schedulable, Database.AllowsCallouts {
    
    public static final String CRON_HOURLY = '0 0 * * * ?'; // Run every hour at the top of the hour
    private static final String CURSOR_SETTING_NAME = 'External_User_Sync_Cursor';
    
    public void execute(SchedulableContext context) {
        try {
            // Get the last sync cursor (timestamp) from custom settings
            String cursor = getLastSyncCursor();
            
            // Fetch changed users from external system
            List<ExternalUserService.ExternalUserData> changedUsers = 
                HttpCalloutService.fetchUsersFromExternalSystem(cursor);
            
            if (!changedUsers.isEmpty()) {
                // Upsert users into Salesforce
                List<Id> upsertedIds = ExternalUserService.upsertUsers(changedUsers);
                
                // Update sync cursor for next run
                updateSyncCursor();
                
                // Log successful inbound sync
                SyncLogService.logInboundSuccess(changedUsers.size(), upsertedIds.size(),
                    'Successfully processed ' + upsertedIds.size() + ' of ' + changedUsers.size() + ' users from external system');
                
            } else {
                // Log that no changes were found
                SyncLogService.logInboundSuccess(0, 0, 'No changes found in external system');
            }
            
        } catch (Exception ex) {
            // Log inbound sync failure
            SyncLogService.logInboundFailure(ex.getMessage(),
                'Inbound sync failed with cursor: ' + getLastSyncCursor() + '. Error: ' + ex.getStackTraceString());
        }
    }
    
    private String getLastSyncCursor() {
        // Try to get cursor from custom metadata or custom settings
        // For simplicity, using a basic approach here
        try {
            List<External_User_Sync_Config__c> configs = [
                SELECT Last_Sync_Timestamp__c 
                FROM External_User_Sync_Config__c 
                WHERE Name = :CURSOR_SETTING_NAME 
                LIMIT 1
            ];
            
            if (!configs.isEmpty() && configs[0].Last_Sync_Timestamp__c != null) {
                return String.valueOf(configs[0].Last_Sync_Timestamp__c.getTime());
            }
        } catch (Exception ex) {
            System.debug('Could not retrieve sync cursor: ' + ex.getMessage());
        }
        
        // Default to 1 hour ago if no cursor found
        DateTime oneHourAgo = DateTime.now().addHours(-1);
        return String.valueOf(oneHourAgo.getTime());
    }
    
    private void updateSyncCursor() {
        try {
            // Upsert the sync timestamp
            External_User_Sync_Config__c config = new External_User_Sync_Config__c();
            config.Name = CURSOR_SETTING_NAME;
            config.Last_Sync_Timestamp__c = DateTime.now();
            
            upsert config Name;
            
        } catch (Exception ex) {
            System.debug('Could not update sync cursor: ' + ex.getMessage());
        }
    }
    
    // Utility method to schedule the job
    public static String scheduleHourlySync() {
        ExternalUserInboundSync syncJob = new ExternalUserInboundSync();
        return System.schedule('External User Inbound Sync - Hourly', CRON_HOURLY, syncJob);
    }
    
    // Utility method to abort all scheduled instances
    public static void abortScheduledSync() {
        List<CronTrigger> scheduledJobs = [
            SELECT Id 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE '%External User Inbound Sync%'
        ];
        
        for (CronTrigger job : scheduledJobs) {
            System.abortJob(job.Id);
        }
    }
}