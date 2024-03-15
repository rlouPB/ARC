@isTest
private class Test_Ctl_PrintScreeningMatrix {
	@testSetup
	static void doSetup() {
		AdmissionScreeningControllerTest.setup();
	}

	@isTest
    static void getQuestionsTest() {
        Contact c = [SELECT Id,AccountId, Account.Current_Admission__c FROM Contact  WHERE LastName = 'Test_Patient'];
        Admission__c thisAdm = [
    			SELECT Id, Name, Patient_Account__r.Name, Patient_Contact__r.Gender__c, Patient_Contact__r.Age__c,
    					Stage__c, Admission__c.Patient_Contact__r.Gender_Identifies_As__c, Admission__c.Patient_Contact__r.Preferred_Pronouns__c
    			FROM Admission__c
    			WHERE Id = :c.Account.Current_Admission__c];
        Account thisAcc = [
        		SELECT Id, Name, Patient_Contact__r.Gender__c, Patient_Contact__r.Age__c, Current_Admission_Stage__c, Patient_Contact__r.Gender_Identifies_As__c,
        				Patient_Contact__r.Preferred_Pronouns__c
        		FROM Account
        		WHERE Id = :c.AccountId];

        test.startTest();
        	ApexPages.standardController admCon = new ApexPages.standardController(thisAdm);
        	Ctl_PrintScreeningMatrix admCtl = new Ctl_PrintScreeningMatrix(admCon);


        	ApexPages.standardController accCon = new ApexPages.standardController(thisAcc);
        	Ctl_PrintScreeningMatrix accCtl = new Ctl_PrintScreeningMatrix(accCon);
        test.stopTest();

        System.assertEquals(admCtl.relatedContacts.size(),2);
        System.assertEquals(admCtl.allQuestions.size(),1);
        System.assertEquals(accCtl.relatedContacts.size(),2);
        System.assertEquals(accCtl.allQuestions.size(),1);
    }
}