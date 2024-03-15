@isTest
class ProcedureResultsTest {
	/*
        Covers Procedure Result trigger handler and ProcedureResults class
    */

	@testSetup
	static void makeData() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		ProcedureOrdersTest.createAdmittedPatient();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' LIMIT 1];

		//Insert Procedure Orderss
		Procedure_Order__c procOrder1 = new Procedure_Order__c(Procedure__c = '01', Admission__c = patientAccount.Current_Admission__c, Patient_Account__c = patientAccount.Id, RecordtypeId = recordTypeMap.get('Nursing_Procedure-Procedure_Order__c'), Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = null, Active__c = false);

		List<Procedure_Order__c> procOrders = new List<Procedure_Order__c>{ procOrder1 };
		insert procOrders;

		procOrder1.Active__c = true;
		procOrder1.Executed__c = false;
		update procOrders;

		procOrders = [SELECT Id, Active__c, Executed__c FROM Procedure_Order__c WHERE Id IN :procOrders];
		//execute Procedure Orders to create Procedure Results
		ProcedureOrders.executeProcedureOrders(procOrders);
	}

	@isTest
	static void testPopulateBeforeReceived() {
		List<Procedure_Order__c> checkProcOrders = [SELECT Id, Executed__c, (SELECT Id, Status__c FROM Procedure_Results__r) FROM Procedure_Order__c];
		System.assertEquals(1, checkProcOrders.size());
		//System.assertEquals(true, checkProcOrders[0].Executed__c);
		System.assertEquals(1, checkProcOrders[0].Procedure_Results__r.size());

		User thisUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
		List<Procedure_Result__c> procResults = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c FROM Procedure_Result__c ORDER BY Procedure_Order__r.Procedure__c];

		Procedure_Result__c procResult1 = procResults[0];
		System.assertEquals(null, procResult1.Received_Date__c);
		System.assertEquals('Pending', procResult1.Status__c);

		Test.startTest();
		//update PR Status to 'Received'
		procResult1.Status__c = 'Received';
		update procResult1;
		Test.stopTest();

		Procedure_Result__c checkProcResult1 = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c, Reviewed_Date_Time__c FROM Procedure_Result__c WHERE Id = :procResult1.Id];
		System.assertEquals('Received', checkProcResult1.Status__c);
		System.assertEquals(System.today(), checkProcResult1.Received_Date__c);
	}

	@isTest
	static void testPopulateBeforeReviewed() {
		List<Procedure_Order__c> checkProcOrders = [SELECT Id, Executed__c, (SELECT Id, Status__c FROM Procedure_Results__r) FROM Procedure_Order__c];
		System.assertEquals(1, checkProcOrders.size());
		//System.assertEquals(true, checkProcOrders[0].Executed__c);
		System.assertEquals(1, checkProcOrders[0].Procedure_Results__r.size());

		User thisUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
		List<Procedure_Result__c> procResults = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c FROM Procedure_Result__c ORDER BY Procedure_Order__r.Procedure__c];

		Procedure_Result__c procResult1 = procResults[0];
		System.assertEquals(null, procResult1.Reviewed_By__c);
		System.assertEquals(null, procResult1.Reviewed_By_Name__c);
		System.assertEquals('Pending', procResult1.Status__c);

		Procedure_Result__c checkProcResult1 = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c, Reviewed_Date_Time__c FROM Procedure_Result__c WHERE Id = :procResult1.Id];
		System.assertEquals(null, checkProcResult1.Reviewed_By__c);
		System.assertEquals(null, checkProcResult1.Reviewed_By_Name__c);

		Test.startTest();
		//update PR Status to 'Reviewed'
		procResult1.Status__c = 'Reviewed';
		procResult1.Reviewed_By__c = thisUser.Id;
		procResult1.Reviewed_Date_Time__c = System.now();
		update procResult1;
		Test.stopTest();

		checkProcResult1 = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c, Reviewed_Date_Time__c FROM Procedure_Result__c WHERE Id = :procResult1.Id];
		System.assertEquals('Reviewed', checkProcResult1.Status__c);
		System.assertEquals(thisUser.Id, checkProcResult1.Reviewed_By__c);
		System.assertEquals(thisUser.Professional_Name__c, checkProcResult1.Reviewed_By_Name__c);
	}

	@isTest
	static void testbulkAfter() {
		List<Procedure_Order__c> checkProcOrders = [SELECT Id, Executed__c, (SELECT Id, Status__c FROM Procedure_Results__r) FROM Procedure_Order__c];
		System.assertEquals(1, checkProcOrders.size());
		System.assertEquals(true, checkProcOrders[0].Executed__c);
		System.assertEquals(1, checkProcOrders[0].Procedure_Results__r.size());

		User thisUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
		List<Procedure_Result__c> procResults = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c FROM Procedure_Result__c ORDER BY Procedure_Order__r.Procedure__c];

		Procedure_Result__c procResult1 = procResults[0];
		System.assertEquals(null, procResult1.Received_Date__c);
		System.assertEquals('Pending', procResult1.Status__c);

		Test.startTest();
		//update PR Status to 'Received'
		procResult1.Status__c = 'Cancelled';
		update procResult1;
		Test.stopTest();

		Procedure_Result__c checkProcResult1 = [SELECT Id, Procedure_Order__r.Procedure__c, Status__c, Received_Date__c, Reviewed_By__c, Reviewed_By_Name__c, Reviewed_Date_Time__c FROM Procedure_Result__c WHERE Id = :procResult1.Id];
		System.assertEquals('Cancelled', checkProcResult1.Status__c);
	}
}