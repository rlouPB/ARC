@isTest
private class ScriptSureBatchSchedulerTest {

    static Integer numberOfUsers = 5;

    @TestSetup
    static void createTestData(){
        List<User> userList = new List<User>();
        Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;

        for (Integer i = 0; i < numberOfUsers; i++) {
            //TODO: Create Users
            User objUser = new User(
                ProfileId = profileId,
                LastName = 'last-' + String.valueOf(i),
                Email = 'puser000' + String.valueOf(i) + '@amamama.com',
                Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias-' + String.valueOf(i),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                External_ScriptSure_User_Id__c = 'test' + i
            );

            userList.add(objUser);
        }

        insert userList;

        // Added to accomodate ITrigger/TriggerFactory, 20220708 - Sols
		disco__Form_Template__c[] formTemplates = new disco__Form_Template__c[]{
            new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer')
        };
        insert formTemplates;

        PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
        Account patient = [SELECT Id, External_Patient_Id__c, Current_Admission__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        update patient;

        Admission__c admission = [SELECT Id, Stage__c FROM Admission__c WHERE Id = :patient.Current_Admission__c];
        admission.Stage__c = 'Admitted';
        admission.Psychotherapist__c = Userinfo.getUserId();
        update admission;
    }

    @isTest
	static void scriptSureBatchIsScheduledTest()
	{
        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
		SchedulableContext sc = null;
        ScriptSureBatchScheduler ssbs = new ScriptSureBatchScheduler();
        ssbs.execute(sc);

		Test.stopTest();

		Integer executedBatchJobs = [SELECT count() FROM AsyncApexJob WHERE JobType = 'BatchApex'
		    AND ApexClass.Name = 'ScriptSureBatch'
		];
		
		System.assertEquals(1, executedBatchJobs, 'The batch job should be executed.');
	}
}