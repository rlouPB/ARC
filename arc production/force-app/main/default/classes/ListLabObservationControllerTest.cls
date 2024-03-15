@isTest private with sharing class ListLabObservationControllerTest {
    @testSetup static void setup() {
        List<sObject> compendium = Test.loadData(Compendium_Entry__c.sObjectType, 'TestData_Compendium');
        List<sObject> bundle = Test.loadData(Compendium_Bundle__c.sObjectType, 'TestData_CompendiumBundle');
        List<sObject> assignment = Test.loadData(Compendium_Bundle_Assignment__c.sObjectType, 'TestData_CompendiumBundleAssignment');
        System.assertEquals(29, compendium.size());
        System.assertEquals(3, bundle.size());
        System.assertEquals(30, assignment.size());
    }
    @isTest private static void unitTest() {
        ListLabObservationController.retrieveBundles();
        
        List<Compendium_Entry__c> compendiumEntries = [SELECT Id FROM Compendium_Entry__c];
        Integer index=0;
        List<String> idList = new List<String> ();
        for(Compendium_Entry__c entry : compendiumEntries) {
            if(Math.mod(index, 3) == 0) {
                idList.add(entry.Id);
            }
            index++;
        }
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType 
                        WHERE IsActive = TRUE and SobjectType='Procedure_Order__c' and DeveloperName='Lab_Order' limit 1];

        Procedure_Order__c po = new Procedure_Order__c(recordtypeId=rt.Id);
        insert po;
        ListLabObservationController.getLabObservationInstance(po.Id, compendiumEntries[0].Id);
        ListLabObservationController.saveLabObservationFromBundle(po.Id, JSON.serialize(idList));
        ListLabObservationController.LabObservationResponse res = ListLabObservationController.loadLabObservationData(po.Id);
        //labObservations
        index=0;
        List<ListLabObservationController.JSONLOParser> los = new List<ListLabObservationController.JSONLOParser>();
        for(Lab_Observation__c lab : res.labObservations) {
            ListLabObservationController.JSONLOParser lo = new ListLabObservationController.JSONLOParser();
            lo.Id = lab.Id;
            lo.compendiumEntryId = lab.Compendium_Entry__r.Id;
            lo.isDeleted = 'false';
            if(Math.mod(index, 2) == 0) {
                lo.isDeleted='true';
            }
            los.add(lo);
            index++;
        }
        ListLabObservationController.saveLabObservations(JSON.serialize(los), po.Id);Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
        List<Contact> patientContactList = new List<Contact> {
            new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
        };
        insert patientContactList;   
            
        List<Contact> accWithContacts = [SELECT Id, LastName, AccountId  
                                        FROM Contact 
                                        WHERE Id IN :patientContactList 
                                        ORDER BY LastName];
            
        List<Admission__c> admissionList = new List<Admission__c> 
        {
                new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, 
                            Stage__c='Discharged', Service_Type__c = 'Residential', Discharge_Date__c=Date.Today().addMonths(-12), 
                            Admit_Date__c=Date.Today().addMonths(-15), Psychotherapist__c = Userinfo.getUserId()), //good
                
                new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id,
                             Stage__c = 'Discharged', Service_Type__c = 'Residential', Discharge_Date__c=Date.Today().addDays(-12), 
                             Admit_Date__c=Date.Today().addMonths(-1), Psychotherapist__c = Userinfo.getUserId())
               
                //,new Admission__c(Patient_Account__c = accWithContacts[3].AccountId, Patient_Contact__c = accWithContacts[3].Id, Stage__c='Waitlist') //not a Patient
        };
        insert admissionList;
        ListLabObservationController.getAdmissionID(accWithContacts[0].AccountId);

        List<Lab_Observation__c> labs = [SELECT Id from Lab_Observation__c];
        for(Lab_Observation__c lab : labs) {
            lab.Stat_Flag__c = true;
        }
        update labs;
        delete labs;
    }
}