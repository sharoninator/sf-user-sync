public with sharing class ExternalUserService {
    public class ExternalUserData {
        @AuraEnabled public String externalId;
        @AuraEnabled public String email;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String phone;
        @AuraEnabled public Boolean deleted;
    }

    // Upsert by External_User_Id__c (External ID)
    public static List<Id> upsertUsers(List<ExternalUserData> rows) {
        if (rows == null || rows.isEmpty()) return new List<Id>();

        List<External_User__c> toUpsert = new List<External_User__c>();
        for (ExternalUserData userData : rows) {
            if (String.isBlank(userData.externalId)) continue; // require key
            
            
            External_User__c externalUser = new External_User__c();
            externalUser.External_User_Id__c = userData.externalId;
            externalUser.User_Email__c      = userData.email;
            externalUser.User_FirstName__c  = userData.firstName;
            externalUser.User_LastName__c   = userData.lastName;
            externalUser.User_Phone__c      = userData.phone;
            externalUser.User_Deleted__c    = userData.deleted == null ? false : userData.deleted;
            toUpsert.add(externalUser);
        }
        upsert toUpsert External_User_Id__c;
        return new List<Id>(new Map<Id, External_User__c>(toUpsert).keySet());
    }
}
