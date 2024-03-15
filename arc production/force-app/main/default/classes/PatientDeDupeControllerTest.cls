@isTest
public class PatientDeDupeControllerTest {
	@testSetup
	static void setup() {
		// disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
		//     Name = 'Psychiatrist Transfer from Test',
		//     disco__Status__c = 'In Use',
		//     DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
		// );
		// insert discoFormTemplate;

		PatientFileTestDataUtil.createPatient();
	}

	@isTest
	static void isDuplicateRecordsExistTest() {
		Test.startTest();
		Contact con = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestContactMerge1' LIMIT 1];
		Boolean isDupAcc = PatientDeDupeController.isDuplicateRecordsExist(con.AccountId);
		Boolean isDupAcc1 = PatientDeDupeController.isDuplicateRecordsExist(con.Id);
		System.assertEquals(true, isDupAcc);
		System.assertEquals(false, isDupAcc1);
		Test.stopTest();
	}

	@isTest
	static void setAsDifferentPeopleTest() {
		Set<Id> conIdSet = new Set<Id>();
		Contact con = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestContactMerge1' LIMIT 1];
		conIdSet.add(con.Id);

		Test.startTest();
		PatientDeDupeController.setAsDifferentPeople(JSON.serialize(conIdSet), true);
		Test.stopTest();

		DuplicateRecordItem recItem = [SELECT Id, Different_Person__c FROM DuplicateRecordItem WHERE RecordId = :con.Id LIMIT 1];
		System.assertEquals(true, recItem.Different_Person__c);
	}

	@isTest
	static void getDuplicateRecordSet() {
		Test.startTest();
		Contact con = [SELECT Id, AccountId FROM Contact WHERE LastName = 'TestContactMerge1' LIMIT 1];
		String deDupeWrapperStr = PatientDeDupeController.getDuplicateRecordSet(con.AccountId);
		System.assertEquals(true, deDupeWrapperStr.containsAny('allFieldSet'));
		System.assertEquals(true, deDupeWrapperStr.containsAny('records'));
		Test.stopTest();
	}

	@isTest
	static void mergePatientsTest() {
		Contact masterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName = 'TestContactMerge1' LIMIT 1];
		Contact nonMasterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName = 'TestContactMerge2' LIMIT 1];
		Account masterAcc = [SELECT Id FROM Account WHERE Id = :masterCon.AccountId LIMIT 1];
		Account nonMasterAcc = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId LIMIT 1];
		Admission__c masterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :masterAcc.Id LIMIT 1];
		Admission__c nonMasterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :nonMasterAcc.Id LIMIT 1];
		List<Related_Contact__c> beforeMergeMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c = :masterAcc.Id];
		List<Related_Contact__c> beforeMergeNonMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c = :nonMasterAcc.Id];
		List<task> beforeMergeMasterTasks = [SELECT Id FROM task WHERE Admission__c = :masterAdmission.Id];
		List<task> beforeMergeNonMasterTasks = [SELECT Id FROM task WHERE Admission__c = :nonMasterAdmission.Id];
		List<Patient_Note__c> beforeMergeMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c = :masterAdmission.Id];
		List<Patient_Note__c> beforeMergeNonMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c = :nonMasterAdmission.Id];
		List<Admission_Medication__c> beforeMergeMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c = :masterAdmission.Id];
		List<Admission_Medication__c> beforeMergeNonMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c = :nonMasterAdmission.Id];
		List<disco__Form__c> beforeMergeMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c = :masterAdmission.Id];
		List<disco__Form__c> beforeMergeNonMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c = :nonMasterAdmission.Id];

		masterCon.MailingCity = nonMasterCon.MailingCity;

		Test.startTest();
		PatientDeDupeController.RecordsWrapper recWrapper = new PatientDeDupeController.RecordsWrapper();
		recWrapper.accountRec = masterAcc;
		recWrapper.contactRec = masterCon;
		//recWrapper.admissionRec = masterAdmission;

		PatientDeDupeController.mergePatients(JSON.serialize(recWrapper), nonMasterCon.Id);

		Test.stopTest();

		Contact masterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName = 'TestContactMerge1' LIMIT 1];
		List<Contact> nonMasterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName = 'TestContactMerge2' LIMIT 1];
		List<Account> nonMasterAccCheck = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId];
		List<Admission__c> nonMasterAdmissionCheck = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :nonMasterAcc.Id];
		List<Related_Contact__c> afterMergeMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c = :masterAcc.Id];
		List<task> afterMergeMasterTasks = [SELECT Id FROM task WHERE WhatId = :masterAcc.Id];
		List<Patient_Note__c> afterMergeMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c = :masterAdmission.Id];
		List<Admission_Medication__c> afterMergeMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c = :masterAdmission.Id];
		List<disco__Form__c> afterMergeMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c = :masterAdmission.Id];

		System.assertEquals(masterConCheck.MailingCity, nonMasterCon.MailingCity);
		System.assert(nonMasterAccCheck.isEmpty());
		System.assert(nonMasterConCheck.isEmpty());
		System.assert(nonMasterAdmissionCheck.isEmpty());
		//System.assertEquals(afterMergeMasterForms.size(), beforeMergeMasterForms.size() + beforeMergeNonMasterForms.size());
		//System.assertEquals(afterMergeMasterMedications.size(), beforeMergeMasterMedications.size() + beforeMergeNonMasterMedications.size());
		//System.assertEquals(afterMergeMasterRelatedCon.size(), beforeMergeMasterRelatedCon.size() + beforeMergeNonMasterRelatedCon.size() - 1);
		//System.assertEquals(afterMergeMasterTasks.size(), beforeMergeMasterTasks.size() + beforeMergeNonMasterTasks.size());
		//System.assertEquals(afterMergeMasterNotes.size(), beforeMergeMasterNotes.size() + beforeMergeNonMasterNotes.size());
	}

	//  public static testMethod void mergeInquiriesTest(){
	//      Test.startTest();
	//      Contact masterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge1' LIMIT 1];
	//      Contact nonMasterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge2' LIMIT 1];
	//      Account masterAcc = [SELECT Id FROM Account WHERE Id = :masterCon.AccountId];
	//      Account nonMasterAcc = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId];
	//      Admission__c masterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :masterAcc.Id];
	//      Admission__c nonMasterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :nonMasterAcc.Id];
	//      List<Related_Contact__c> beforeMergeMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c= :masterAcc.Id];
	//      List<Related_Contact__c> beforeMergeNonMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c= :nonMasterAcc.Id];
	//List<task> beforeMergeMasterTasks = [SELECT Id FROM task WHERE Admission__c= :masterAdmission.Id];
	//      List<task> beforeMergeNonMasterTasks = [SELECT Id FROM task WHERE Admission__c= :nonMasterAdmission.Id];
	//      List<Patient_Note__c> beforeMergeMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c= :masterAdmission.Id];
	//      List<Patient_Note__c> beforeMergeNonMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c= :nonMasterAdmission.Id];
	//      List<Admission_Medication__c> beforeMergeMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c= :masterAdmission.Id];
	//      List<Admission_Medication__c> beforeMergeNonMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c= :nonMasterAdmission.Id];
	//      List<disco__Form__c> beforeMergeMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c= :masterAdmission.Id];
	//      List<disco__Form__c> beforeMergeNonMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c= :nonMasterAdmission.Id];

	//      masterCon.MailingCity = nonMasterCon.MailingCity;
	//      PatientDeDupeController.RecordsWrapper recWrapper = new PatientDeDupeController.RecordsWrapper();
	//      recWrapper.accountRec = masterAcc;
	//      recWrapper.contactRec = masterCon;
	//      recWrapper.admissionRec = masterAdmission;

	//      PatientDeDupeController.mergeInquiries(JSON.serialize(recWrapper), nonMasterCon.Id, nonMasterAdmission.Id);

	//      Contact masterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge1' LIMIT 1];
	//      List<Contact> nonMasterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge2' LIMIT 1];
	//List<Account> nonMasterAccCheck = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId];
	//      List<Admission__c> nonMasterAdmissionCheck = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :nonMasterAcc.Id];
	//      List<Related_Contact__c> afterMergeMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c= :masterAcc.Id];
	//List<task> afterMergeMasterTasks = [SELECT Id FROM task WHERE Admission__c= :masterAdmission.Id];
	//      List<Patient_Note__c> afterMergeMasterNotes = [SELECT Id FROM Patient_Note__c WHERE Admission__c= :masterAdmission.Id];
	//      List<Admission_Medication__c> afterMergeMasterMedications = [SELECT Id FROM Admission_Medication__c WHERE Admission__c= :masterAdmission.Id];
	//      List<disco__Form__c> afterMergeMasterForms = [SELECT Id FROM disco__Form__c WHERE Admission__c= :masterAdmission.Id];

	//      System.assertEquals(masterConCheck.MailingCity, nonMasterCon.MailingCity);
	//      System.assert(nonMasterAccCheck.isEmpty());
	//      System.assert(nonMasterConCheck.isEmpty());
	//      System.assert(nonMasterAdmissionCheck.isEmpty());
	//      System.assertEquals(afterMergeMasterRelatedCon.size(), beforeMergeMasterRelatedCon.size() + beforeMergeNonMasterRelatedCon.size());
	//      System.assertEquals(afterMergeMasterTasks.size(), beforeMergeMasterTasks.size() + beforeMergeNonMasterTasks.size());
	//      System.assertEquals(afterMergeMasterNotes.size(), beforeMergeMasterNotes.size() + beforeMergeNonMasterNotes.size());
	//      System.assertEquals(afterMergeMasterMedications.size(), beforeMergeMasterMedications.size() + beforeMergeNonMasterMedications.size());
	//      System.assertEquals(afterMergeMasterForms.size(), beforeMergeMasterForms.size() + beforeMergeNonMasterForms.size());

	//      Test.stopTest();
	//  }

	//  public static testMethod void separateInquiriesTest(){
	//      Test.startTest();
	//      Contact masterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge1' LIMIT 1];
	//      Contact nonMasterCon = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge2' LIMIT 1];
	//      Account masterAcc = [SELECT Id FROM Account WHERE Id = :masterCon.AccountId];
	//      Account nonMasterAcc = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId];
	//      Admission__c masterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :masterAcc.Id];
	//      Admission__c nonMasterAdmission = [SELECT Id FROM Admission__c WHERE Patient_Account__c = :nonMasterAcc.Id];
	//      List<Related_Contact__c> beforeMergeMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c= :masterAcc.Id];
	//      List<Related_Contact__c> beforeMergeNonMasterRelatedCon = [SELECT Id FROM Related_Contact__c WHERE Account__c= :nonMasterAcc.Id];

	//      masterCon.MailingCity = nonMasterCon.MailingCity;
	//      PatientDeDupeController.RecordsWrapper recWrapper = new PatientDeDupeController.RecordsWrapper();
	//      recWrapper.accountRec = masterAcc;
	//      recWrapper.contactRec = masterCon;
	//      recWrapper.admissionRec = masterAdmission;

	//      PatientDeDupeController.separateInquiries(JSON.serialize(recWrapper), nonMasterCon.Id, nonMasterAdmission.Id);

	//      Contact masterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge1' LIMIT 1];
	//      List<Contact> nonMasterConCheck = [SELECT Id, MailingCity, AccountId FROM Contact WHERE LastName='TestContactMerge2' LIMIT 1];
	//List<Account> nonMasterAccCheck = [SELECT Id FROM Account WHERE Id = :nonMasterCon.AccountId];
	//      Admission__c nonMasterAdmissionCheck = [SELECT Id,Stage__c FROM Admission__c WHERE Patient_Account__c = :masterAcc.Id AND Id = :nonMasterAdmission.Id];

	//      System.assertEquals(masterConCheck.MailingCity, nonMasterCon.MailingCity);
	//      System.assert(nonMasterAccCheck.isEmpty());
	//      System.assert(nonMasterConCheck.isEmpty());
	//      System.assertEquals('Inactive', nonMasterAdmissionCheck.Stage__c);

	//      Test.stopTest();
	//  }
}