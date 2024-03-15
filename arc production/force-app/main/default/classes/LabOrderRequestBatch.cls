global with sharing class LabOrderRequestBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('-->LabOrderRequestBatch start ');
        String query = 'SELECT Id, Procedure_Order__c FROM Procedure_Result__c ' + 
                        'WHERE Sent_Date_Time__c = null AND Date__c != null AND ' +
                        'Date__c <= Today AND ' +
                        'Status__c=\'Pending\' AND ' + 
                        'Procedure_Order__r.Recordtype.Name = \'Lab Order\' AND ' +
                        'Procedure_Order__r.Admission__r.Stage__c = \'Admitted\' AND ' +
                        'Exhaust_Max_Retries__c != TRUE';
        return Database.getQueryLocator(query);          
    }

    global void execute(Database.BatchableContext bc, List<Procedure_Result__c> scope){
        System.debug('-->LabOrderRequestBatch execute ' + scope);
        if(scope.size() > 1) {
            throw new CustomException('We can only process Lab Test Order one at a time. Update the batch size to 1.');
        }

        if(scope.size() == 1) { 
            Procedure_Result__c pr = scope.get(0);
            String procedureOrderId = pr.Procedure_Order__c;
            try {
                ProcedureOrderHL7Processor.sendOrder(procedureOrderId, pr.Id);
                // pr.Sent_Date_Time__c = DateTime.now();
                // update pr;
            } catch (Exception e) {
                ProcessLogging.addProcessLog('LabOrderRequestBatch', e.getStackTraceString(), e.GetMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        ProcessLogging.commitProcessLogs();
    }
}