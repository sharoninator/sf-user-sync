trigger ExternalUserTrigger on External_User__c (after insert, after update) {
    ExternalUserTriggerHandler.handleAfterInsertUpdate(Trigger.new, Trigger.oldMap);
}