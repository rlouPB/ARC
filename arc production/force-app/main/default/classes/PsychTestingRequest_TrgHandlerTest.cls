@isTest
public class PsychTestingRequest_TrgHandlerTest {
    static testmethod void test1(){
        account acc = new account (name = 'rtes');
        insert acc;
         disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        AdmissionScreeningControllerTest.setup();
        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account LIMIT 1];
        Map<String, Schema.RecordTypeInfo> patientNoteRecordTypeMap = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName();
        Patient_Note__c consultantNote = new Patient_Note__c(Account__c = patient.Id,
                                                            Admission__c = patient.Current_Admission__c,
                                                            Consultation_Assigned_Date__c = System.today(),
                                                            Consultation_Requested_By__c = 'Patient',
                                                             Type__c = 'Psychotherapy Consultation Note',
                                                            RecordTypeId = patientNoteRecordTypeMap.get('Custom_Note').getRecordTypeId());
        insert consultantNote;
        
        Psych_Testing_Request__c psy = new Psych_Testing_Request__c();
        psy.Patient_Account__c = acc.id;
        psy.Patient_Note__c = consultantNote.id;   
        Psych_Testing_Request__c[] psys = new Psych_Testing_Request__c[]{};
        psys.add(psy);
        insert psys;
        update psys;
        delete psys;
        Psych_Testing_RequestTriggerHandler ss = new Psych_Testing_RequestTriggerHandler();
        ss.beforeupdate(psy,psy);
        ss.afterupdate(psy,psy);
        ss.beforeDelete(psy);
        ss.afterDelete(psy);

        
            
    }
}