public with sharing class ExternalUserTriggerHandler {
    
    public static void handleAfterInsertUpdate(List<External_User__c> newRecords, Map<Id, External_User__c> oldMap) {
        // Collect changed records for outbound sync
        List<External_User__c> changedRecords = new List<External_User__c>();
        
        for (External_User__c externalUser : newRecords) {
            // For inserts, always include the record
            if (oldMap == null) {
                changedRecords.add(externalUser);
            } 
            // For updates, check if relevant fields changed
            else {
                External_User__c oldRecord = oldMap.get(externalUser.Id);
                if (hasRelevantFieldChanged(externalUser, oldRecord)) {
                    changedRecords.add(externalUser);
                }
            }
        }
        
        // Enqueue outbound sync job if we have changes
        if (!changedRecords.isEmpty()) {
            enqueueOutboundSync(changedRecords);
        }
    }
    
    private static Boolean hasRelevantFieldChanged(External_User__c newRecord, External_User__c oldRecord) {
        return newRecord.External_User_Id__c != oldRecord.External_User_Id__c ||
               newRecord.Email__c != oldRecord.Email__c ||
               newRecord.FirstName__c != oldRecord.FirstName__c ||
               newRecord.LastName__c != oldRecord.LastName__c ||
               newRecord.Phone__c != oldRecord.Phone__c ||
               newRecord.Deleted__c != oldRecord.Deleted__c;
    }
    
    private static void enqueueOutboundSync(List<External_User__c> changedRecords) {
        // Prevent recursive triggers and governor limit issues
        if (System.isFuture() || System.isBatch()) {
            return;
        }
        
        try {
            // Enqueue the queueable job for outbound sync
            ExternalUserOutboundSync syncJob = new ExternalUserOutboundSync(changedRecords);
            System.enqueueJob(syncJob);
        } catch (Exception ex) {
            // Log error when trigger fails to enqueue sync
            SyncLogService.logOutboundFailure('Failed to enqueue outbound sync job: ' + ex.getMessage(),
                'Trigger handler failed for ' + changedRecords.size() + ' records. Error: ' + ex.getStackTraceString());
        }
    }
}