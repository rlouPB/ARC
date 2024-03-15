@isTest
private class SIP_PrescriptionsEndDateStatusTest {

    private static final String DRUG_NAME = 'Test Update Medication';
    
    @TestSetup
    static void makeData()
    {
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
        
        List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [
			SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c,
					ScheduledItemProcessor_Parameters__c, MasterLabel
			FROM Scheduled_Item_Definition__mdt
			WHERE ScheduledItemProcessor_to_Use__c = 'PrescriptionsEndDateStatus'
		];
    }

    @isTest
    private static void prescriptionsEndDateStatusTest() {
        Prescription__c pres = [SELECT Id, End_Date__c from Prescription__c LIMIT 1];
        Date endDate = System.today().addDays(-1);
        pres.End_Date__c = endDate;
        update pres;

        List<Scheduled_Item_Definition__mdt> scheduledItemDefs = [
			SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c,
					ScheduledItemProcessor_Parameters__c, MasterLabel
			FROM Scheduled_Item_Definition__mdt
			WHERE ScheduledItemProcessor_to_Use__c = 'PrescriptionsEndDateStatus'
		];

		Test.startTest();
        SIP_PrescriptionsEndDateStatus.process(scheduledItemDefs);
        Test.stopTest();
    }

    @isTest
    private static void prescriptionsEndDateStatusErrorTest(){
        Test.startTest();
        SIP_PrescriptionsEndDateStatus.process(null);
        Test.stopTest();
    }
}