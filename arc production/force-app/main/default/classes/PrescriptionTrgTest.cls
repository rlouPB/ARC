@isTest
    public with sharing class PrescriptionTrgTest {
    private static final String DRUG_NAME = 'Test Update Medication';

	Public Static testMethod void myUnitTest (){
        
        Account objAcc = new Account();
		objAcc.Name = 'Test Account';
		insert objAcc;

        Prescription__c[] preslist = new Prescription__c[]{};
        
        Prescription__c pres = new Prescription__c(); 
        pres.Name = 'a350978hgcf';
        pres.Medication_Filled_with__c = DRUG_NAME;
        pres.External_Prescription_Id__c = 01010;
        pres.Drug_Name__c = DRUG_NAME;
        pres.Medication_Filled_with__c = DRUG_NAME;
        pres.Account__c = objAcc.Id;
        pres.Drug_Format__c = 'testing';
        pres.Medication_Format__c = 'testing';
        pres.Times_Of_Day__c = '6 AM Early Morning';
        presList.add(pres);
        
          Prescription__c pres1 = new Prescription__c(); 
        pres1.Name = 'a35097sdsdsd8hgcf';
        pres1.External_Prescription_Id__c = 0101012;
        pres1.Drug_Name__c = DRUG_NAME;

        pres1.Account__c = objAcc.Id;
        pres1.Drug_Format__c = 'testing';
        pres1.Medication_Format__c = 'testing';
        pres1.Times_Of_Day__c = '12 Noon';
        presList.add(pres1);
        
        Prescription__c pres2 = new Prescription__c(); 
        pres2.Name = 'a350978hgcsdf';
        pres2.External_Prescription_Id__c = 02231010;
        pres2.Drug_Name__c = DRUG_NAME;
        pres2.Medication_Filled_with__c = DRUG_NAME;
        pres2.Account__c = objAcc.Id;
        pres2.Parent__c=pres.id;
        pres2.Drug_Format__c = 'testing';
        pres2.Times_Of_Day__c = '9 AM Morning';
        presList.add(pres2);
        
            Prescription__c pres3 = new Prescription__c(); 
        pres3.Name = 'a350978hgcs3df';
        pres3.External_Prescription_Id__c = 3022310;
        pres3.Drug_Name__c = DRUG_NAME;
        pres3.Medication_Filled_with__c = DRUG_NAME;
        pres3.Account__c = objAcc.Id;
        pres3.Parent__c=pres.id;
        pres3.Drug_Format__c = 'testing';
        pres3.Times_Of_Day__c = '5:30 PM Evening';
        presList.add(pres3);
        
        insert presList;
        Test.startTest();
        
        
        TriggerFactory.Recursions.clear();
        pres.Medication_Filled_with__c = DRUG_NAME;
        
        pres3.Times_Of_Day__c ='9:30 PM Late Evening';
        
        pres2.Times_Of_Day__c ='11:30 PM Night';
        update presList;
        Prescription__c pres21 = [Select Id, name, Medication_Filled_with__c from Prescription__c where Id = :pres.Id];
        System.assertEquals(pres21.Name, pres21.Medication_Filled_with__c);
        Test.stopTest();
        
        delete pres;


    }

    Public Static testMethod void endDateTest (){
        
        Account objAcc = new Account();
		objAcc.Name = 'Test Account';
		insert objAcc;
 
        Prescription__c[] preslist = new Prescription__c[]{};
        Prescription__c pres = new Prescription__c(); 
        pres.Name = 'a350978hgcf';
        pres.Medication_Filled_with__c = DRUG_NAME;
        pres.External_Prescription_Id__c = 01010;
        pres.Drug_Name__c = DRUG_NAME;
        pres.Medication_Filled_with__c = DRUG_NAME;
        pres.Account__c = objAcc.Id;
        pres.Drug_Format__c = 'testing';
        pres.Medication_Format__c = 'testing';
        pres.Times_Of_Day__c = '6 AM Early Morning';
        presList.add(pres);
        
        Prescription__c pres1 = new Prescription__c(); 
        pres1.Name = 'a35097sdsdsd8hgcf';
        pres1.External_Prescription_Id__c = 0101012;
        pres1.Drug_Name__c = DRUG_NAME;
        pres1.Account__c = objAcc.Id;
        pres1.Drug_Format__c = 'testing';
        pres1.Medication_Format__c = 'testing';
        pres1.Times_Of_Day__c = '12 Noon';
        presList.add(pres1);
        
        Prescription__c pres2 = new Prescription__c(); 
        pres2.Name = 'a350978hgcsdf';
        pres2.External_Prescription_Id__c = 02231010;
        pres2.Drug_Name__c = DRUG_NAME;
        pres2.Medication_Filled_with__c = DRUG_NAME;
        pres2.Account__c = objAcc.Id;
        pres2.Parent__c=pres.id;
        pres2.Drug_Format__c = 'testing';
        pres2.Times_Of_Day__c = '9 AM Morning';
        presList.add(pres2);
        
        Prescription__c pres3 = new Prescription__c(); 
        pres3.Name = 'a350978hgcs3df';
        pres3.External_Prescription_Id__c = 3022310;
        pres3.Drug_Name__c = DRUG_NAME;
        pres3.Medication_Filled_with__c = DRUG_NAME;
        pres3.Account__c = objAcc.Id;
        pres3.Parent__c=pres.id;
        pres3.Drug_Format__c = 'testing';
        pres3.Times_Of_Day__c = '5:30 PM Evening';
        presList.add(pres3);
        insert presList;

        Test.startTest();
        TriggerFactory.Recursions.clear();
        pres2.Inactive_Datetime__c = System.now();
        update pres2;
        pres2 = [Select Id, End_Date__c, Inactive_Datetime__c FROM Prescription__c WHERE ID = :pres2.Id];
        System.assertEquals(pres2.Inactive_Datetime__c.date(), pres2.End_Date__c);
        Test.stopTest();
    }
}