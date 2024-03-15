global with sharing class LabOrderBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        LabOrderRequestBatch ssBatch = new LabOrderRequestBatch() ;
        Id ssBatchProcessId = Database.executeBatch(ssBatch, 1); // this has to be a batch size of one as we have callouts with DMLs after.
    }
 }