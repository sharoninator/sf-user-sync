public with sharing class SyncLogService {
    
    public enum SyncType {
        INBOUND, OUTBOUND
    }
    
    public enum SyncStatus {
        SUCCESS, FAILURE, PARTIAL_SUCCESS
    }
    
    public class SyncLogData {
        @AuraEnabled public SyncType syncType;
        @AuraEnabled public SyncStatus status;
        @AuraEnabled public Integer totalRecords;
        @AuraEnabled public Integer successCount;
        @AuraEnabled public Integer errorCount;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String details;
    }
    
    public static Id logSyncOperation(SyncLogData logData) {
        if (logData == null) return null;
        
        try {
            Sync_Log__c syncLog = new Sync_Log__c();
            syncLog.Sync_Type__c = String.valueOf(logData.syncType);
            syncLog.Status__c = String.valueOf(logData.status);
            syncLog.Total_Records__c = logData.totalRecords != null ? logData.totalRecords : 0;
            syncLog.Success_Count__c = logData.successCount != null ? logData.successCount : 0;
            syncLog.Error_Count__c = logData.errorCount != null ? logData.errorCount : 0;
            syncLog.Error_Message__c = truncateString(logData.errorMessage, 255);
            syncLog.Details__c = truncateString(logData.details, 32768);
            syncLog.Sync_Timestamp__c = DateTime.now();
            
            insert syncLog;
            return syncLog.Id;
            
        } catch (Exception ex) {
            // Avoid infinite recursion - don't log logging failures
            System.debug('Failed to create sync log: ' + ex.getMessage());
            return null;
        }
    }
    
    public static Id logInboundSuccess(Integer totalRecords, Integer successCount, String details) {
        SyncLogData logData = new SyncLogData();
        logData.syncType = SyncType.INBOUND;
        logData.status = SyncStatus.SUCCESS;
        logData.totalRecords = totalRecords;
        logData.successCount = successCount;
        logData.errorCount = 0;
        logData.details = details;
        
        return logSyncOperation(logData);
    }
    
    public static Id logOutboundSuccess(Integer totalRecords, String details) {
        SyncLogData logData = new SyncLogData();
        logData.syncType = SyncType.OUTBOUND;
        logData.status = SyncStatus.SUCCESS;
        logData.totalRecords = totalRecords;
        logData.successCount = totalRecords;
        logData.errorCount = 0;
        logData.details = details;
        
        return logSyncOperation(logData);
    }
    
    public static Id logInboundFailure(String errorMessage, String details) {
        SyncLogData logData = new SyncLogData();
        logData.syncType = SyncType.INBOUND;
        logData.status = SyncStatus.FAILURE;
        logData.totalRecords = 0;
        logData.successCount = 0;
        logData.errorCount = 1;
        logData.errorMessage = errorMessage;
        logData.details = details;
        
        return logSyncOperation(logData);
    }
    
    public static Id logOutboundFailure(String errorMessage, String details) {
        SyncLogData logData = new SyncLogData();
        logData.syncType = SyncType.OUTBOUND;
        logData.status = SyncStatus.FAILURE;
        logData.totalRecords = 0;
        logData.successCount = 0;
        logData.errorCount = 1;
        logData.errorMessage = errorMessage;
        logData.details = details;
        
        return logSyncOperation(logData);
    }
    
    public static List<Sync_Log__c> getRecentLogs(Integer limitCount) {
        if (limitCount == null || limitCount <= 0) limitCount = 50;
        
        return [
            SELECT Id, Sync_Type__c, Status__c, Total_Records__c, Success_Count__c, 
                   Error_Count__c, Error_Message__c, Details__c, Sync_Timestamp__c, CreatedDate
            FROM Sync_Log__c 
            ORDER BY CreatedDate DESC 
            LIMIT :limitCount
        ];
    }
    
    public static List<Sync_Log__c> getLogsByDateRange(Date startDate, Date endDate, SyncType syncType) {
        String syncTypeFilter = syncType != null ? String.valueOf(syncType) : null;
        DateTime startDateTime = startDate != null ? DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)) : null;
        DateTime endDateTime = endDate != null ? DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 0)) : null;
        
        String query = 'SELECT Id, Sync_Type__c, Status__c, Total_Records__c, Success_Count__c, ' +
                      'Error_Count__c, Error_Message__c, Details__c, Sync_Timestamp__c, CreatedDate ' +
                      'FROM Sync_Log__c WHERE ';
        
        List<String> conditions = new List<String>();
        
        if (startDateTime != null) {
            conditions.add('CreatedDate >= :startDateTime');
        }
        if (endDateTime != null) {
            conditions.add('CreatedDate <= :endDateTime');
        }
        if (syncTypeFilter != null) {
            conditions.add('Sync_Type__c = :syncTypeFilter');
        }
        
        if (conditions.isEmpty()) {
            conditions.add('CreatedDate = TODAY');
        }
        
        query += String.join(conditions, ' AND ') + ' ORDER BY CreatedDate DESC LIMIT 1000';
        
        return Database.query(query);
    }
    
    private static String truncateString(String input, Integer maxLength) {
        if (String.isBlank(input) || input.length() <= maxLength) {
            return input;
        }
        return input.substring(0, maxLength - 3) + '...';
    }
}