@isTest
public class ProcedureOrdersTest {
	@testSetup
	static void makeData() {
		createAdmittedPatient();
	}

	@isTest
	public static void createAdmittedPatient() {
		//Admitted Patient
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		List<Account> patientAccounts = new List<Account>{ new Account(RecordtypeId = recordTypeMap.get('Patient-Account'), Name = 'TestPatient_1', Service_Type_Text__c = 'Residential') };
		insert patientAccounts;

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', AccountId = patientAccounts[0].Id, RecordTypeId = recordTypeMap.get('Patient-Contact')) };
		insert contactList;

		Contact contactWithAccount = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = contactWithAccount.AccountId, Patient_Contact__c = contactWithAccount.Id, Stage__c = 'Waitlist') };
		insert admissionList;

		contactWithAccount = [SELECT Id, AccountId, Account.Current_Admission_Stage__c, Account.Current_Admission__c FROM Contact WHERE Id = :contactWithAccount.Id];
		// System.assertEquals('Waitlist', contactWithAccount.Account.Current_Admission_Stage__c);
		// System.assertEquals(admissionList[0].Id, contactWithAccount.Account.Current_Admission__c);

		//Assigned Clinicians
		List<Assigned_Clinician__c> assignedCliniciansList = new List<Assigned_Clinician__c>{ new Assigned_Clinician__c(Patient_Account__c = contactWithAccount.AccountId, Admission__c = contactWithAccount.Account.Current_Admission__c, User__c = UserInfo.getUserId(), Role__c = 'Psychotherapist', Start_Date__c = Date.Today().addDays(-5)) };
		insert assignedCliniciansList;

		admissionList[0].Consultation_Date__c = System.today();
		admissionList[0].Psychotherapist__c = assignedCliniciansList[0].User__c;
		update admissionList;

		Admission__c currentAdmission = [SELECT Id, Stage__c, Psychotherapist__c, Patient_Account__c, (SELECT Id, Start_Date__c, Role__c FROM Assigned_Clinicians__r WHERE Role__c = 'Psychotherapist') FROM Admission__c WHERE Id = :admissionList[0].Id];
		// System.assertEquals(1, currentAdmission.Assigned_Clinicians__r.size());
		// System.assertEquals(assignedCliniciansList[0].User__c, currentAdmission.Psychotherapist__c);

		admissionList[0].Admit_Date__c = System.today();
		admissionList[0].Stage__c = 'Admitted';
		update admissionList;
		Account checkPatientAccount = [SELECT Id, Current_Admission__c, Current_Admission__r.Stage__c, Current_Admission_Stage__c, Recordtype.Name FROM Account WHERE Id = :contactWithAccount.AccountId LIMIT 1];
		// System.assertEquals(currentAdmission.Id, checkPatientAccount.Current_Admission__c);
		// System.assertEquals('Admitted', checkPatientAccount.Current_Admission__r.Stage__c);
		// System.assertEquals('Admitted', checkPatientAccount.Current_Admission_Stage__c);
		// System.assertEquals('Patient', checkPatientAccount.Recordtype.Name);
	}

	@isTest
	static void testExecuteNursingProcedureOrderSingle() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' AND Current_Admission_Stage__c = 'Admitted' LIMIT 1];
		List<Procedure_Order__c> testProcOrders = new List<Procedure_Order__c>();
		Procedure_Order__c nursingPO = new Procedure_Order__c(Patient_Account__c = patientAccount.Id, Admission__c = patientAccount.Current_Admission__c, RecordtypeId = recordTypeMap.get('Nursing_Procedure' + '-' + 'Procedure_Order__c'), Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = 'Physical Monitor', Status__c = 'Draft', Active__c = false, Executed__c = false);
		testProcOrders.add(nursingPO);
		insert testProcOrders;

		Test.startTest();

		nursingPO.Active__c = true;
		nursingPO.Status__c = 'Finalized';
		nursingPO.Finalized_Date_Time__c = System.now();
		nursingPO.Finalized_By_User__c = Userinfo.getUserId();
		update nursingPO;
		ProcedureOrders.executeProcedureOrders(testProcOrders);
		Test.stopTest();
		//Confirm records created properly
		//Procedure Result
		//NursingShiftItem
		//Physical Monitor
	}

	static void dynamicTestRepeating(Date testActivationDate, String testRepeatingFrequency, Date testEndDate, Integer testExpectedResultCount) {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' AND Current_Admission_Stage__c = 'Admitted' LIMIT 1];
		List<Procedure_Order__c> testProcOrders = new List<Procedure_Order__c>();
		Procedure_Order__c nursingPO = new Procedure_Order__c(Patient_Account__c = patientAccount.Id, Admission__c = patientAccount.Current_Admission__c, RecordtypeId = recordTypeMap.get('Nursing_Procedure' + '-' + 'Procedure_Order__c'), Date_of_Order__c = System.today(), Repeating__c = true, Repeating_Frequency__c = testRepeatingFrequency, Activation_Date__c = testActivationDate, End_Date__c = testEndDate, Related_Records__c = 'Physical Monitor', Physical_Monitor_Sections__c = 'Height/Weight;Temperature', Active__c = false, Executed__c = false);
		testProcOrders.add(nursingPO);
		insert testProcOrders;

		Test.startTest();
		// System.assertEquals(false, ProcedureOrders.isExecutingProcedureOrders);

		nursingPO.Active__c = true;
		update testProcOrders;
		ProcedureOrders.executeProcedureOrders(testProcOrders);

		// System.assertEquals(false, ProcedureOrders.isExecutingProcedureOrders);

		Test.stopTest();

		//Confirm records created properly 'Height/Weight' => 'View_Height_Weight__c'
		nursingPO = [SELECT Id, Status__c, Active__c, Executed__c, (SELECT Id, Due_Date__c, Date__c, Nursing_Shift_Item__c FROM Procedure_Results__r), (SELECT Id, Nursing_Shift_Item__c, Status__c, View_Height_Weight__c, View_Blood_Pressure_Info__c, View_Temperature_Info__c, Recordtype.Name FROM Physical_Monitors__r), (SELECT Id, Status__c, Shift_Date__c, Shift_Number__c, Nursing_Shift__c, Procedure_Result__c FROM Nursing_Shift_Items__r) FROM Procedure_Order__c WHERE Id = :nursingPO.Id];
		// System.assertEquals(true, nursingPO.Active__c);
		// System.assertEquals(true, nursingPO.Executed__c);
		// System.assertEquals(testExpectedResultCount, nursingPO.Procedure_Results__r.size(), 'results ' + nursingPO.Procedure_Results__r.size() + ' mons ' + nursingPO.Physical_Monitors__r.size() + ' items ' + nursingPO.Nursing_Shift_Items__r.size());
		Procedure_Result__c procResult0 = nursingPO.Procedure_Results__r[0];
		// System.assertEquals(testExpectedResultCount, nursingPO.Physical_Monitors__r.size());
		Physical_Monitor__c physMon0 = nursingPO.Physical_Monitors__r[0];
		// System.assertEquals(testExpectedResultCount, nursingPO.Nursing_Shift_Items__r.size());
		Nursing_Shift_Item__c shiftItem0 = nursingPO.Nursing_Shift_Items__r[0];

		//Procedure Result
		// System.assertEquals(shiftItem0.Id, procResult0.Nursing_Shift_Item__c);
		//Physical Monitor
		// System.assertEquals(shiftItem0.Id, physMon0.Nursing_Shift_Item__c);
		// System.assertEquals(true, physMon0.View_Height_Weight__c);
		// System.assertEquals(false, physMon0.View_Blood_Pressure_Info__c);
		// System.assertEquals(true, physMon0.View_Temperature_Info__c);
		//NursingShiftItem
		// System.assertEquals(procResult0.Id, shiftItem0.Procedure_Result__c);
	}

	//'Daily'
	@isTest
	static void testExecuteNursingProcedureOrderRepeatingDaily() {
		Date testActivationDate = System.today().addDays(1);
		String testRepeatingFrequency = 'Daily';
		Date testEndDate = testActivationDate.addDays(6);
		Integer testExpectedResultCount = 7;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'1 Time Per Week'
	@isTest
	static void testExecuteNursingProcedureOrderRepeating1PerWeek() {
		Date testActivationDate = System.today().toStartOfWeek().addDays(1);
		String testRepeatingFrequency = '1 Time Per Week';
		Date testEndDate = testActivationDate.addDays(8);
		Integer testExpectedResultCount = 1;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'2 Times Per Week'
	@isTest
	static void testExecuteNursingProcedureOrderRepeating2PerWeek() {
		Date testActivationDate = System.today().toStartOfWeek().addDays(1);
		String testRepeatingFrequency = '2 Times Per Week';
		Date testEndDate = testActivationDate.addDays(8);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'3 Times Per Week'
	@isTest
	static void testExecuteNursingProcedureOrderRepeating3PerWeek() {
		Date testActivationDate = System.today().toStartOfWeek().addDays(1);
		String testRepeatingFrequency = '3 Times Per Week';
		Date testEndDate = testActivationDate.addDays(14);
		Integer testExpectedResultCount = 6;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'1 Time Per Two Weeks'
	@isTest
	static void testExecuteNursingProcedureOrderRepeating1Per2Weeks() {
		Date testActivationDate = System.today().toStartOfWeek().addDays(1);
		String testRepeatingFrequency = '1 Time Per Two Weeks';
		Date testEndDate = testActivationDate.addDays(28);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'1 Time Per Month'
	@isTest
	static void testExecuteNursingProcedureOrderRepeating1PerMonth() {
		Date testActivationDate = System.today().toStartOfMonth().addDays(1);
		String testRepeatingFrequency = '1 Time Per Month';
		Date testEndDate = testActivationDate.addMonths(2);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'Every 3 Months'
	@isTest
	static void testExecuteNursingProcedureOrderRepeatingEvery3Months() {
		Date testActivationDate = System.today().toStartOfMonth().addDays(1);
		String testRepeatingFrequency = 'Every 3 Months';
		Date testEndDate = testActivationDate.addMonths(6);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'Every 4 Months'
	@isTest
	static void testExecuteNursingProcedureOrderRepeatingEvery4Months() {
		Date testActivationDate = System.today().toStartOfMonth().addDays(1);
		String testRepeatingFrequency = 'Every 4 Months';
		Date testEndDate = testActivationDate.addMonths(8);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	//'Every 6 Months'
	@isTest
	static void testExecuteNursingProcedureOrderRepeatingEvery6Months() {
		Date testActivationDate = System.today().toStartOfMonth().addDays(1);
		String testRepeatingFrequency = 'Every 6 Months';
		Date testEndDate = testActivationDate.addMonths(12);
		Integer testExpectedResultCount = 2;
		dynamicTestRepeating(testActivationDate, testRepeatingFrequency, testEndDate, testExpectedResultCount);
	}

	@isTest
	static void testPopulateUserNames() {
		Map<Id, sObject> newMap = new Map<Id, sObject>();
		Map<Id, sObject> oldMap = new Map<Id, sObject>();
		List<User> someUsers = [SELECT Id, Professional_Name__c FROM User WHERE IsActive = TRUE LIMIT 10];

		User completeUser = someUsers[0];
		User finalizeUser = someUsers[1];
		User nobodyUser = someUsers[2];

		Procedure_Order__c completedPo = new Procedure_Order__c(Procedure__c = 'A');
		Procedure_Order__c finalizedPo = new Procedure_Order__c(Procedure__c = 'B');
		Procedure_Order__c nothingPo = new Procedure_Order__c(Procedure__c = 'C', Finalized_By_User__c = nobodyUser.Id);
		Procedure_Order__c noChangePo = new Procedure_Order__c(Procedure__c = 'D');

		List<Procedure_Order__c> testPos = new List<Procedure_Order__c>{ completedPo, finalizedPo, nothingPo, noChangePo };

		Test.startTest();
		insert testPos;

		oldMap = new Map<Id, sObject>(testPos);

		// List<sObject> queriedPos = [SELECT Id, Completed_By__c, Completed_By_Name__c, Completed_Date_Time__c,
		//                                 Finalized_By__c, Finalized_By_User__c, Finalized_Date_Time__c
		//                                 FROM Procedure_Order__c
		List<sObject> queriedPos = Database.query(QueryUtils.getQueryAll('Procedure_Order__c', new List<String>()) + ' WHERE Id = :testPos');
		newMap = new Map<Id, sObject>(queriedPos);

		//Change Completed
		sObject completeNewSo = newMap.get(completedPo.Id);
		// System.assertEquals(null, completeNewSo.get('Completed_By_Name__c'));

		completeNewSo.put('Completed_By__c', completeUser.Id);
		ProcedureOrders.populateProcedureOrderBeforeData(newMap, oldMap);
		// System.assertEquals(completeUser.Professional_Name__c, completeNewSo.get('Completed_By_Name__c'));

		//Change Finalized
		sObject finalizedNewSo = newMap.get(finalizedPo.Id);
		// System.assertEquals(null, finalizedNewSo.get('Finalized_By__c'));

		finalizedNewSo.put('Finalized_By_User__c', finalizeUser.Id);
		ProcedureOrders.populateProcedureOrderBeforeData(newMap, oldMap);
		// System.assertEquals(finalizeUser.Professional_Name__c, finalizedNewSo.get('Finalized_By__c'));

		//Change to nothing
		// // System.assertNotEquals(null, nothingPo.Finalized_By_User__c);
		// System.assertEquals(null, nothingPo.Finalized_By__c);
		nothingPo.Finalized_By__c = 'some text that should not be affected';

		sObject nothingNewSo = newMap.get(nothingPo.Id);
		nothingNewSo.put('Finalized_By_User__c', null);
		// System.assertEquals(null, nothingNewSo.get('Finalized_By__c'));
		nothingNewSo.put('Finalized_By__c', 'text in the new so that should go away');

		ProcedureOrders.populateProcedureOrderBeforeData(newMap, oldMap);
		// System.assertEquals(finalizeUser.Professional_Name__c, finalizedNewSo.get('Finalized_By__c'));
		Test.stopTest();
	}

	@isTest
	static void testLabOrderBatch() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' AND Current_Admission_Stage__c = 'Admitted' LIMIT 1];
		List<Procedure_Order__c> testProcOrders = new List<Procedure_Order__c>();
		Id rtId = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByName().get('Lab Order').getRecordTypeId();
		Procedure_Order__c labOrder = new Procedure_Order__c(Patient_Account__c = patientAccount.Id, Admission__c = patientAccount.Current_Admission__c, RecordtypeId = rtId, Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = 'Physical Monitor', Status__c = 'Draft', Active__c = false, Executed__c = false);

		insert labOrder;

		Procedure_Result__c procResult = new Procedure_Result__c(Status__c = 'Pending', Procedure_Order__c = labOrder.Id, Date__c = Date.Today());
		insert procResult;

		BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockLogin', null);
		BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockOrder', null);
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance('Default');

		endpoint2TestResp.put(lp.Login_Endpoint__c, loginResp);
		endpoint2TestResp.put(lp.Order_Endpoint__c, orderResp);

		HttpCalloutMock multiCalloutMock = new BHS_MultiRequestMock(endpoint2TestResp);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);

		Test.startTest();
		LabOrderRequestBatch ssBatch = new LabOrderRequestBatch();
		Id ssBatchProcessId = Database.executeBatch(ssBatch, 1);
		Test.stopTest();
		//Confirm records created properly
		//Procedure Result
		//NursingShiftItem
		//Physical Monitor
	}

	@isTest
	static void testLabOrderBatchScheduler() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' AND Current_Admission_Stage__c = 'Admitted' LIMIT 1];
		List<Procedure_Order__c> testProcOrders = new List<Procedure_Order__c>();
		Id rtId = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByName().get('Lab Order').getRecordTypeId();
		Procedure_Order__c labOrder = new Procedure_Order__c(Patient_Account__c = patientAccount.Id, Admission__c = patientAccount.Current_Admission__c, RecordtypeId = rtId, Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = 'Physical Monitor', Status__c = 'Draft', Active__c = false, Executed__c = false);

		insert labOrder;

		Procedure_Result__c procResult = new Procedure_Result__c(Status__c = 'Pending', Procedure_Order__c = labOrder.Id, Date__c = Date.Today());
		insert procResult;
		BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockLogin', null);
		BHS_SingleRequestMock orderResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockOrder', null);
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance('Default');

		endpoint2TestResp.put(lp.Login_Endpoint__c, loginResp);
		endpoint2TestResp.put(lp.Order_Endpoint__c, orderResp);

		HttpCalloutMock multiCalloutMock = new BHS_MultiRequestMock(endpoint2TestResp);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		Test.StartTest();
		String sch = '0 20 * * * ?';
		LabOrderBatchScheduler m = new LabOrderBatchScheduler();
		system.schedule('Lab Order Job test', sch, m);

		Test.stopTest();
	}

	@isTest
	static void testLabOrderRetrievalQueueable() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Account patientAccount = [SELECT Id, Current_Admission__c FROM Account WHERE Recordtype.Name = 'Patient' AND Current_Admission_Stage__c = 'Admitted' LIMIT 1];
		List<Procedure_Order__c> testProcOrders = new List<Procedure_Order__c>();
		Id rtId = Schema.SObjectType.Procedure_Order__c.getRecordTypeInfosByName().get('Lab Order').getRecordTypeId();
		Procedure_Order__c labOrder = new Procedure_Order__c(Patient_Account__c = patientAccount.Id, Admission__c = patientAccount.Current_Admission__c, RecordtypeId = rtId, Date_of_Order__c = System.today(), Activation_Date__c = System.today().addDays(1), Repeating__c = false, Related_Records__c = 'Physical Monitor', Status__c = 'Draft', Active__c = false, Executed__c = false);

		insert labOrder;

		Procedure_Result__c procResult = new Procedure_Result__c(Status__c = 'Pending', Procedure_Order__c = labOrder.Id, Date__c = Date.Today());
		insert procResult;
		BHS_SingleRequestMock loginResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockLogin', null);
		BHS_SingleRequestMock resultResp = new BHS_SingleRequestMock(200, 'Complete', 'BHS_MockOrder', null);
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance('Default');

		endpoint2TestResp.put(lp.Login_Endpoint__c, loginResp);
		endpoint2TestResp.put(lp.Result_Endpoint__c, resultResp);
		HttpCalloutMock multiCalloutMock = new BHS_MultiRequestMock(endpoint2TestResp);

		Test.setMock(HttpCalloutMock.class, multiCalloutMock);
		Test.StartTest();
		System.enqueueJob(new OrderResultRetrievalQueueable());

		Test.stopTest();
	}

	@isTest
	static void testHandler() {
		Procedure_Order__c nursingPO = new Procedure_Order__c(
			//  Admission__c = patientAccount.Current_Admission__c,
			// RecordtypeId = recordTypeMap.get('Nursing_Procedure'+'-'+'Procedure_Order__c'),
			Date_of_Order__c = System.today(),
			Activation_Date__c = System.today().addDays(1),
			Repeating__c = false,
			Related_Records__c = 'Physical Monitor',
			Status__c = 'Draft',
			Active__c = false,
			Executed__c = false
		);

		insert nursingPO;
		update nursingPO;
		delete nursingPO;
		Procedure_OrderTriggerHandler handler = new Procedure_OrderTriggerHandler();
		handler.beforeUpdate(nursingPO, nursingPO);
		handler.afterUpdate(nursingPO, nursingPO);
		handler.beforeDelete(nursingPO);
		handler.afterDelete(nursingPO);
	}
}