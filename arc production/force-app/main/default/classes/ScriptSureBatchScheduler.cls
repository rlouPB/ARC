global with sharing class ScriptSureBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        ScriptSureBatch ssBatch = new ScriptSureBatch() ;
        Id ssBatchProcessId = Database.executeBatch(ssBatch, 1); // this has to be a batch size of one as we have callouts with DMLs after.
    }
 }