trigger createErrorLogs on CreateErrorLogEvent__e (after insert) {
    for(CreateErrorLogEvent__e e:Trigger.New){
        ProcessLogging.quickProcessLog(e.Process_Name__c, e.Stack_Trace__c, e.Message__c);
    }
    
}