public with sharing class ExternalUserTriggerHandler {
    
    public static void handleAfterInsertUpdate(List<External_User__c> newRecords, Map<Id, External_User__c> oldMap) {
        // Collect IDs of records that need sync
        Set<Id> recordIdsToSync = new Set<Id>();
        
        for (External_User__c externalUser : newRecords) {
            // For inserts, always include the record
            if (oldMap == null) {
                recordIdsToSync.add(externalUser.Id);
            } 
            // For updates, always sync for now (can optimize change detection later)
            else {
                recordIdsToSync.add(externalUser.Id);
            }
        }
        
        // Pass records directly to sync - the queueable job will handle querying for full records
        if (!recordIdsToSync.isEmpty()) {
            List<External_User__c> recordsToSync = new List<External_User__c>();
            for (External_User__c externalUser : newRecords) {
                if (recordIdsToSync.contains(externalUser.Id)) {
                    recordsToSync.add(externalUser);
                }
            }
            
            enqueueOutboundSync(recordsToSync);
        }
    }
    
    private static Boolean hasRelevantFieldChanged(External_User__c newRecord, External_User__c oldRecord) {
        Boolean changed = newRecord.External_User_Id__c != oldRecord.External_User_Id__c ||
               newRecord.User_Email__c != oldRecord.User_Email__c ||
               newRecord.User_FirstName__c != oldRecord.User_FirstName__c ||
               newRecord.User_LastName__c != oldRecord.User_LastName__c ||
               newRecord.User_Phone__c != oldRecord.User_Phone__c ||
               newRecord.User_Deleted__c != oldRecord.User_Deleted__c;
        
        
        return changed;
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