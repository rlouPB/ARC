@IsTest
public class NursingShiftServiceTest {
	@TestSetup
	static void setup() {
		ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();

		AdmissionScreeningControllerTest.setup();

		Account patient = [SELECT Id, Current_Case__c FROM Account LIMIT 1];

		Admission__c admission = [SELECT Id, Team__c FROM Admission__c WHERE Patient_Account__c = :patient.Id LIMIT 1];

		update new Admission__c(Id = admission.Id, Stage__c = 'Admitted', Psychotherapist__c = userinfo.getuserid());

		Test.startTest();
		// SIP_DailyNursingShifts.process([
		// 	SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c,
		// 			ScheduledItemProcessor_Parameters__c, MasterLabel
		// 	FROM Scheduled_Item_Definition__mdt
		// 	WHERE ScheduledItemProcessor_to_Use__c = 'AdmittedProgramDays'
		// ]);
		SIP_DailyNursingShifts.processLogic();
		Test.stopTest();

		Physical_Monitor__c pm1 = new Physical_Monitor__c(Account__c = patient.Id, Height_in__c = 80, BP_Cuff_Size__c = 'Large');
		insert pm1;
		Nursing_Shift_Item__c[] toInsert = new List<Nursing_Shift_Item__c>{};
		Nursing_Shift__c ns = new Nursing_Shift__c(Shift_Number__c = '1st', Date__c = Date.Today(), Status__c = 'Open', Shift_Open_Date_Time__c = System.now(), Type_of_Day__c = 'Weekday');
		insert ns;
		Nursing_Shift__c ns1 = new Nursing_Shift__c(Shift_Number__c = '2nd', Date__c = Date.Today(), Status__c = 'Closed', Shift_Open_Date_Time__c = System.now(), Type_of_Day__c = 'Weekday');
		insert ns1;
		Nursing_Shift_Assignment__c nsac = new Nursing_Shift_Assignment__c(Owner__c = UserInfo.getUserId(), OwnerId = UserInfo.getUserId(), Nursing_Shift__c = ns.Id, Sign_In_Date_Time__c = System.now(), Status__c = 'Open');
		insert nsac;
		toInsert.add(new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id, Nurse__c = userinfo.getuserid()));
		toInsert.add(new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id, Nurse__c = userinfo.getuserid(), status__c = 'Open'));
		insert toInsert;
		Map<Id, Nursing_Shift_Patient_Assignment__c> nsaToNspaMap = new Map<Id, Nursing_Shift_Patient_Assignment__c>();
		for (Nursing_Shift_Item__c nsi : toInsert) {
			Nursing_Shift_Patient_Assignment__c nspa = new Nursing_Shift_Patient_Assignment__c(
				//Owner__c= userinfo.getUserId(),
				Patient__c = patient.Id, //nsi.Patient__c,
				Nursing_Shift_Assignment__c = nsi.Nursing_Shift_Assignment__c,
				Status__c = nsi.Status__c,
				Nursing_Shift__c = nsi.Nursing_Shift__c
			);
			// itemAssignments.add(nsa);
			nsaToNspaMap.put(nsi.Id, nspa);
		}
		// insert itemAssignments;
		insert nsaToNspaMap.values();
	}

	public static testMethod void testgetNursingShiftItems() {
		Id a = [SELECT id FROM account LIMIT 1].id;
		NursingShiftItems.getNursingShiftItems(a);
	}
	public static testMethod void testGetterMethods() {
		Nursing_Shift__c ns = [SELECT id FROM Nursing_Shift__c LIMIT 1];
		Account a = [SELECT id FROM account LIMIT 1];
		Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id);
		insert nsi;
		NursingShiftService.SearchNurse('', '', '');
		NursingShiftService.getMyNursingShiftItems(ns.Id);
		NursingShiftService.getNursingShifts(''.split(';'));
		NursingShiftService.getNursingShiftSingle(ns.Id);
		NursingShiftService.getNursingShiftItems(ns.Id);
		NursingShiftService.getMyNursingShiftItemsForPatient(a.Id);
		NursingShiftService.getNursingShiftPatientItems(ns.Id);
		NursingShiftService.getNursingShiftItemsForPatient(a.Id);
		NursingShiftService.getNursingShiftItem(nsi.Id);
		NursingShiftService.getMyNursingShiftAssigments();
		NursingShiftService.getAllNursingShiftAssigments();
		NursingShiftService.getCurrentNursingShiftItems();
		NursingShiftService.getSignInOutData();
		NursingShiftService.getNursingShiftAssigments(ns.Id, '');
		NursingShiftService.getNursingShiftAssigments(ns.Id, 'test');
		NursingShiftService.getPatientAssignmentsByNursingShift(ns.Id);
		NursingShiftService.getMyNursingShiftPatientItems(ns.Id);
		NursingShiftService.getNursingShiftAssigmentsByShiftId(ns.Id);
		NursingShiftService.setShiftAssignedToUser_depricated(new List<id>{ a.id }, userinfo.getuserid(), ns.id);
		NursingShiftService.checkCustomPermission('NursingShiftAdmin');
		NursingShiftService.saveNursingFieldChange(string.valueOf(ns.id), null, null);
		NursingShiftService.saveNursingFieldChange(string.valueOf(ns.id), null, null);
		NursingShiftService.geOpenNursingShiftAssigmentsByShiftId(ns.id);
	}

	public static testMethod void TestSetShiftAssignedToUser() {
		Nursing_Shift__c ns = [SELECT id FROM Nursing_Shift__c LIMIT 1];
		Account a = [SELECT id FROM account LIMIT 1];
		Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id);
		insert nsi;

		Nursing_Shift_Patient_Assignment__c[] nspaList = [SELECT Id, Nursing_Shift__c FROM Nursing_Shift_Patient_Assignment__c];

		//     system.assertNotEquals(0, nspaList.size());

		Id[] ids = new List<id>(new Map<id, Nursing_Shift_Patient_Assignment__c>(nspaList).keyset());

		NursingShiftService.setShiftAssignedToUser(ids, UserInfo.getUserId(), nspaList[0].Nursing_Shift__c);

		//     system.assertNotEquals(0, [SELECT count() FROM Nursing_Shift_Patient_Assignment__c]);

		User anotherUser = [SELECT Id FROM User WHERE isactive = TRUE AND ProfileId = :userinfo.getProfileId() LIMIT 1];

		NursingShiftService.setShiftAssignedToUser(ids, anotherUser.Id, nspaList[0].Nursing_Shift__c);
	}

	public static testMethod void TestGetNursingShiftByDateAndNumber() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		Nursing_Shift__c ns2 = NursingShiftService.getNursingShift(ns.Date__c, ns.Shift_Number__c);
		// System.assertEquals(ns.Id, ns2.Id);
	}

	public static testMethod void TestSignInOut() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		String signinResult = NursingShiftService.signIntoShift(ns.Id);

		// system.assertNotEquals(0,[
		//     SELECT count() FROM Nursing_Shift_Assignment__c WHERE
		//     Owner__c=:userinfo.getUserId() AND
		//     Sign_Out_Date_Time__c = null AND
		//     Nursing_Shift__c =:ns.Id
		// ],'signinResult: ' + signinResult);

		Nursing_Shift_Assignment__c nsa = [SELECT id, status__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :ns.Id AND Owner__c = :UserInfo.getuserid() LIMIT 1];

		String signoutResult = NursingShiftService.signOutFromShift(nsa.Id);
		String signoutResult2 = NursingShiftService.signOutFromShift(null);

		// system.assertNotEquals(0,[
		//     SELECT count() FROM Nursing_Shift_Assignment__c WHERE
		//     Owner__c=:userinfo.getUserId() AND
		//     Nursing_Shift__c =:ns.Id AND
		//     Sign_Out_Date_Time__c != null
		// ], 'signoutResult: ' + signoutResult);
	}

	public static testMethod void testSignOutNurseFromShift() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		test.startTest();
		NursingShiftService.signIntoShift(ns.Id);
		test.stopTest();

		Nursing_Shift_Assignment__c nsa = [SELECT id FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :ns.Id AND Owner__c = :UserInfo.getuserid() LIMIT 1];

		String signOutNurseFromShiftResult = NursingShiftService.signOutNurseFromShift(ns.Id, UserInfo.getUserId());

		// system.assertEquals(null, signOutNurseFromShiftResult,'signOutNurseFromShiftResult: ' + signOutNurseFromShiftResult);

		// system.assertNotEquals(0,[
		//     SELECT count() FROM Nursing_Shift_Assignment__c WHERE
		//     Owner__c=:userinfo.getUserId() AND
		//     Nursing_Shift__c =:ns.Id AND
		//     Sign_Out_Date_Time__c != null
		// ], 'signOutNurseFromShiftResult: ' + signOutNurseFromShiftResult);
	}

	public static testMethod void testRemoveNurseFromShift() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		NursingShiftService.signIntoShift(ns.Id);

		Nursing_Shift_Assignment__c nsa = [SELECT id FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :ns.Id AND Owner__c = :UserInfo.getuserid() LIMIT 1];

		update ns;
		String removeNurseFromShiftResult = NursingShiftService.removeNurseFromShift(ns.Id, UserInfo.getUserId());

		// system.assertEquals(null, removeNurseFromShiftResult,'removeNurseFromShiftResult: ' + removeNurseFromShiftResult);
	}

	public static testMethod void testRemoveAssignmentShift() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		NursingShiftService.signIntoShift(ns.Id);

		Nursing_Shift_Assignment__c nsa = [SELECT id FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c = :ns.Id AND Owner__c = :UserInfo.getuserid() LIMIT 1];

		String removeShiftAssignmentResult = NursingShiftService.removeShiftAssignment(nsa.Id);

		// system.assertEquals(null, removeShiftAssignmentResult,'removeShiftAssignmentResult: ' + removeShiftAssignmentResult);
	}

	public static testMethod void testCancelItem() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		Nursing_Shift_Item__c item = new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id);
		insert item;

		String cancelShiftItemResult = NursingShiftService.cancelShiftItem(item.Id);
		String cancelShiftItemResult2 = NursingShiftService.cancelShiftItem(null);

		// system.assertEquals(null, cancelShiftItemResult,'cancelShiftItemResult: ' + cancelShiftItemResult);

		// system.assertEquals(1,[select count() from Nursing_Shift_Item__c where Id=:item.Id and Status__c='Cancelled']);
	}

	public static testMethod void testCloseNursingShiftItem() {
		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		Nursing_Shift_Item__c item = new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id);
		insert item;

		String cancelShiftItemResult = NursingShiftService.closeNursingShiftItem(item.Id);
		String cancelShiftItemResult2 = NursingShiftService.closeNursingShiftItem(null);

		// system.assertEquals(null, cancelShiftItemResult,'cancelShiftItemResult: ' + cancelShiftItemResult);

		item = [SELECT Status__c FROM Nursing_Shift_Item__c WHERE Id = :item.Id AND Status__c = 'Closed'];

		// system.assertEquals( 'Closed', item.Status__c );
	}

	public static testMethod void testCancelShiftItemWithReasons() {
		Account acc = [SELECT Id FROM Account LIMIT 1];

		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		Nursing_Shift_Item__c item = new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id);
		insert item;

		// Procedure_Order__c po =  new Procedure_Order__c();
		// insert po;

		Physical_Monitor__c pm = new Physical_Monitor__c(Account__c = acc.Id);
		insert pm;

		test.startTest();
		disco__Form_Template__c formTemplate = new disco__Form_Template__c(DocType_Name__c = 'Test', disco__Status__c = 'In Use');
		insert formTemplate;
		// test.stopTest();

		Group__c[] queueEnabledGroups = new List<Group__c>{ new Group__c(Name = 'Medical Record', Type__c = 'Other', Queue_Enabled__c = true), new Group__c(Name = 'Patient Care', Type__c = 'Other', Queue_Enabled__c = true), new Group__c(Name = 'Team A', Type__c = 'Team') };

		insert queueEnabledGroups;

		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient', AccountId = acc.Id), true);

		Admission__c admission = [SELECT Id FROM Admission__c LIMIT 1];

		// Test.startTest();

		// disco__Form__c form = new disco__Form__c(
		//     disco__Form_Account__c = acc.Id,
		//     // Related_Contact__c = c.Id,
		//     disco__Form_Template__c = formTemplate.Id,
		//     disco__Archived__c = true,
		//     Admission__c = admission.Id,
		//     disco__Form_Contact__c = c.Id,
		//     disco__Mobile_ID__c = '123'
		// );
		// insert form;

		update new Nursing_Shift_Item__c(
			Id = item.Id,
			// Form__c = form.Id,
			// Procedure_Order__c = po.Id,
			Physical_Monitor__c = pm.Id
		);

		Test.stopTest();

		String cancelShiftItemWithReasonsResult = NursingShiftService.cancelShiftItemWithReasons(item.Id, 'Other', 'The other reason');
		String cancelShiftItemWithReasonsResult2 = NursingShiftService.cancelShiftItemWithReasons(null, null, null);

		// system.assertEquals(null, cancelShiftItemWithReasonsResult,'cancelShiftItemWithReasonsResult: ' + cancelShiftItemWithReasonsResult);

		// system.assertEquals(1,[select count() from Nursing_Shift_Item__c where Id=:item.Id and Status__c='Cancelled']);
	}

	public static testMethod void testSetNSAId() {
		Account a = [SELECT id FROM Account LIMIT 1];

		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		Nursing_Shift_Assignment__c nsa = new Nursing_Shift_Assignment__c(Nursing_Shift__c = ns.Id, Owner__c = userinfo.getuserid());
		insert nsa;

		Nursing_Shift_Patient_Assignment__c nspa = new Nursing_Shift_Patient_Assignment__c(Patient__c = a.Id, Nursing_Shift_Assignment__c = nsa.Id);
		insert nspa;

		String setNSAIdResult = NursingShiftService.setNSAId(new List<Id>{ nspa.Id }, nsa.Id);

		// system.assertEquals(null, setNSAIdResult,'setNSAIdResult: ' + setNSAIdResult);
	}

	public static testMethod void testSaveNursingFieldChange() {
		Account a = [SELECT id FROM Account LIMIT 1];

		Nursing_Shift__c ns = [SELECT Id, Date__c, Shift_Number__c FROM Nursing_Shift__c LIMIT 1];

		// System.assertEquals(null, NursingShiftService.saveNursingFieldChange(ns.Id, 'Charge_Nurse__c', UserInfo.getUserId()) );

		// System.assertEquals(null, NursingShiftService.saveNursingFieldChange(ns.Id, 'Date__c', Date.today()) );

		// System.assertEquals(null, NursingShiftService.saveNursingFieldChange(ns.Id, 'Type_of_Day__c', 'Weekday') );

		// System.assertEquals(null, NursingShiftService.saveNursingFieldChange(ns.Id, 'Type_of_Day__c', null) );

		// System.assertNotEquals(null, NursingShiftService.saveNursingFieldChange(ns.Id, 'NotAField', false) );
	}
}