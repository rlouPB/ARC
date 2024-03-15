@isTest
public class MessagingTestDataUtil {
	public static Map<String, Id> getRecordTypeInfo() {
		Map<String, Id> recordTypeMap = new Map<String, Id>();
		for (RecordType rt : [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = TRUE]) {
			recordTypeMap.put(rt.DeveloperName + '-' + rt.SobjectType, rt.Id);
		}
		return recordTypeMap;
	}

	public static void createFormTemplate() {
		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;
	}

	public static Map<String, Id> getProfileMap() {
		Map<String, Id> profileMap = new Map<String, Id>();
		for (Profile pro : [SELECT Id, Name FROM Profile ORDER BY Name]) {
			profileMap.put(pro.Name, pro.Id);
		}
		return profileMap;
	}

	public static void createInquiryPatientWithRelated() {
		List<Account> patientAccountList = new List<Account>{ new Account(Name = 'patient1', RecordtypeId = recordTypeHelper.getIdByName('Account', 'Patient')), new Account(Name = 'patient4', RecordtypeId = recordTypeHelper.getIdByName('Account', 'Patient')), new Account(Name = 'patientmerge2', RecordtypeId = recordTypeHelper.getIdByName('Account', 'Patient')), new Account(Name = 'patientmerge3', RecordtypeId = recordTypeHelper.getIdByName('Account', 'Patient')) };
		insert patientAccountList;

		List<Contact> contactList = new List<Contact>{
			//accWithContact
			new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient'), AccountId = patientAccountList[0].Id),
			new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Personal')),
			new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Professional')),
			new Contact(LastName = 'TestPatient_4', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient'), AccountId = patientAccountList[1].Id),
			new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Personal')),
			new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingStateCode = 'AB', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Professional')),
			//mergeContact1
			new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient'), AccountId = patientAccountList[3].Id),
			//mergeContact2
			new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingStateCode = 'AB', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient'), AccountId = patientAccountList[2].Id)
		};
		insert contactList;

		Map<String, Contact> nameToContactMap = new Map<String, Contact>();
		for (Contact con : contactList) {
			nameToContactMap.put(con.LastName, con);
		}

		Contact accWithContact = nameToContactMap.get('TestPatient_1');
		Contact mergeContact1 = nameToContactMap.get('TestContactMerge1');
		Contact mergeContact2 = nameToContactMap.get('TestContactMerge2');

		DuplicateRule dupRule = [SELECT Id FROM DuplicateRule LIMIT 1];
		DuplicateRecordSet dupRecSet = (DuplicateRecordSet) TestFactory_Patient.createSObject(new DuplicateRecordSet(DuplicateRuleId = dupRule.Id), true);

		List<DuplicateRecordItem> dupRecItems = new List<DuplicateRecordItem>();
		DuplicateRecordItem dupRecItem1 = (DuplicateRecordItem) TestFactory_Patient.createSObject(new DuplicateRecordItem(DuplicateRecordSetId = dupRecSet.Id, RecordId = mergeContact1.Id), false);
		DuplicateRecordItem dupRecItem2 = (DuplicateRecordItem) TestFactory_Patient.createSObject(new DuplicateRecordItem(DuplicateRecordSetId = dupRecSet.Id, RecordId = mergeContact2.Id), false);
		DuplicateRecordItem dupRecItem3 = (DuplicateRecordItem) TestFactory_Patient.createSObject(new DuplicateRecordItem(DuplicateRecordSetId = dupRecSet.Id, RecordId = accWithContact.Id), false);
		dupRecItems.add(dupRecItem1);
		dupRecItems.add(dupRecItem2);
		dupRecItems.add(dupRecItem3);
		insert dupRecItems;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = true, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Mother', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Personal')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Father', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Personal')),
			new Related_Contact__c(Contact__c = mergeContact1.Id, Account__c = mergeContact1.AccountId, Former__c = false, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Patient', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = mergeContact2.Id, Account__c = mergeContact2.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Patient', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient'))
		};
		insert relatedContacts;

		List<Admission__c> allAdmissions = [SELECT Id, Patient_Account__c, Patient_Account__r.Name, Patient_Contact__c, Stage__c FROM Admission__c];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = mergeContact1.AccountId, Patient_Contact__c = mergeContact1.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = mergeContact2.AccountId, Patient_Contact__c = mergeContact2.Id, Stage__c = 'Open Inquiry') };
		insert admissionList;

		Account mergeAccount1 = [SELECT Id, Name, Current_Admission__c, Patient_Contact__c FROM Account WHERE Id = :mergeContact1.AccountId];
		system.assert(mergeAccount1.Current_Admission__c != null, mergeAccount1);
		Account mergeAccount2 = [SELECT Id, Name, Current_Admission__c, Patient_Contact__c FROM Account WHERE Id = :mergeContact2.AccountId];

		Admission__c mergeAdmission1 = [SELECT Id, Patient_Account__c, Patient_Contact__c FROM Admission__c WHERE Patient_Account__c = :mergeAccount1.Id LIMIT 1];
		Admission__c mergeAdmission2 = [SELECT Id, Patient_Account__c, Patient_Contact__c FROM Admission__c WHERE Patient_Account__c = :mergeAccount2.Id LIMIT 1];

		mergeAccount1.Current_Admission__c = mergeAdmission1.Id;
		mergeAccount1.Patient_Contact__c = mergeContact1.Id;
		mergeAccount2.Current_Admission__c = mergeAdmission2.Id;
		mergeAccount2.Patient_Contact__c = mergeContact2.Id;

		Task task = (Task) TestFactory_Patient.createSObject(new Task(Admission__c = mergeAdmission2.Id), true);

		Patient_Note__c note = (Patient_Note__c) TestFactory_Patient.createSObject(new Patient_Note__c(Admission__c = mergeAdmission2.Id), true);

		Admission_Medication__c medication = (Admission_Medication__c) TestFactory_Patient.createSObject(new Admission_Medication__c(Admission__c = mergeAdmission2.Id), true);

		disco__Form_Template__c formTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(new disco__Form_Template__c(disco__Status__c = 'In Use'), true);

		disco__Form__c form = (disco__Form__c) TestFactory_Patient.createSObject(new disco__Form__c(disco__Form_Template__c = formTemplate.Id, Admission__c = mergeAdmission2.Id, disco__Form_Account__c = mergeAdmission2.Patient_Account__c), true);

		List<Account> accounts = [SELECT Id, Name, Current_Admission__c FROM Account WHERE Id = :accWithContact.AccountId];
		if (accounts[0].Current_Admission__c == null) {
			accounts[0].Current_Admission__c = admissionList[0].Id;
			accounts.add(mergeAccount1);
			accounts.add(mergeAccount2);
			upsert accounts;
		}
		// upsert mergeAccount1;
		// upsert mergeAccount2;

		List<Admissions_Requirement__c> admissionReqList = new List<Admissions_Requirement__c>{
			new Admissions_Requirement__c(Completed__c = true, Name = 'Clinical_Test', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = accounts[0].Current_Admission__c, Order__c = 1),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medical', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = accounts[0].Current_Admission__c, Order__c = 2),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medications', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = accounts[0].Current_Admission__c, Order__c = 3),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Motivation', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = accounts[0].Current_Admission__c, Order__c = 4),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Clinical_Test', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission1.Id, Order__c = 1),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medical', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission1.Id, Order__c = 2),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medications', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission1.Id, Order__c = 3),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Motivation', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission1.Id, Order__c = 4),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Clinical_Test', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission2.Id, Order__c = 1),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medical', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission2.Id, Order__c = 2),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Medications', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission2.Id, Order__c = 3),
			new Admissions_Requirement__c(Completed__c = true, Name = 'Motivation', Do_Not_Show_Checkbox_on_Component__c = false, Admission__c = mergeAdmission2.Id, Order__c = 4)
		};
		insert admissionReqList;

		Admissions_Requirement__c mergeAdmissionReq1 = [SELECT Id FROM Admissions_Requirement__c WHERE Admission__c = :mergeAdmission1.Id LIMIT 1];
		Admissions_Requirement__c mergeAdmissionReq2 = [SELECT Id FROM Admissions_Requirement__c WHERE Admission__c = :mergeAdmission2.Id LIMIT 1];

		List<Request_Item__c> reqItemsList = new List<Request_Item__c>{
			new Request_Item__c(Responsible_User__c = UserInfo.getUserId(), Responsible_Contact__c = relatedContacts[0].Contact__c, Action__c = 'Expecting Call', Item_Requested__c = 'Full Inpatient Record', Date_Requested__c = System.today(), Date_Confirmed__c = System.today(), Status__c = 'Open', Notes__c = 'Test', Admissions_Requirement__c = admissionReqList[0].Id),
			new Request_Item__c(Responsible_User__c = UserInfo.getUserId(), Responsible_Contact__c = relatedContacts[0].Contact__c, Action__c = 'Expecting Call', Item_Requested__c = 'Full Inpatient Record', Date_Requested__c = System.today(), Date_Confirmed__c = System.today(), Status__c = 'Open', Notes__c = 'Test', Admissions_Requirement__c = admissionReqList[0].Id),
			new Request_Item__c(Responsible_User__c = UserInfo.getUserId(), Responsible_Contact__c = relatedContacts[0].Contact__c, Action__c = 'Expecting Call', Item_Requested__c = 'Full Inpatient Record', Date_Requested__c = System.today(), Date_Confirmed__c = System.today(), Status__c = 'Open', Notes__c = 'Test', Admissions_Requirement__c = admissionReqList[0].Id),
			new Request_Item__c(Responsible_User__c = UserInfo.getUserId(), Responsible_Contact__c = relatedContacts[0].Contact__c, Action__c = 'Expecting Call', Item_Requested__c = 'Full Inpatient Record', Date_Requested__c = System.today(), Date_Confirmed__c = System.today(), Status__c = 'Open', Notes__c = 'Test', Admissions_Requirement__c = mergeAdmissionReq1.Id),
			new Request_Item__c(Responsible_User__c = UserInfo.getUserId(), Responsible_Contact__c = relatedContacts[0].Contact__c, Action__c = 'Expecting Call', Item_Requested__c = 'Full Inpatient Record', Date_Requested__c = System.today(), Date_Confirmed__c = System.today(), Status__c = 'Open', Notes__c = 'Test', Admissions_Requirement__c = mergeAdmissionReq2.Id)
		};
		insert reqItemsList;
	}

	public static void createPatientWithNote() {
		List<Contact> contactList = new List<Contact>{
			new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient')),
			new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Personal')),
			new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Professional')),
			new Contact(LastName = 'TestPatient_4', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient')),
			new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Personal')),
			new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Professional')),
			new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient')),
			new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeHelper.getIdByName('Contact', 'Patient'))
			//new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingState = 'Alabama', MailingCountry = 'United States', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Personal'+'-'+'Contact')),
			//new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountry = 'Canada', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Professional'+'-'+'Contact')),
			//new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingState = 'Alabama', MailingCountry = 'United States', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact')),
			//new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountry = 'Canada', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
		};
		insert contactList;

		Contact accWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Patient')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = true, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Mother', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Personal')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Father', RecordTypeId = RecordTypeHelper.getIdByName('Related_Contact__c', 'Personal'))
		};
		insert relatedContacts;

		//    List<Task> taskObjs = new List<Task>{
		//            new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)) ,Subject='test',Patient_City__c='test',Calling_Number__c='1234567',Patient_Gender__c='Male',Patient_State__c='AL',Call_Type__c = 'Non-Starter',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName1',WhatId = accWithContact.AccountId,WhoId = accWithContact.Id),
		//            new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)) ,Subject='',Patient_City__c='test',Calling_Number__c='1234567',Patient_Gender__c='Male',Patient_State__c='AL',Call_Type__c = 'Non-Starter',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName1',WhatId = accWithContact.AccountId,WhoId = null),
		//            new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)) ,Subject='test',Patient_City__c='test',Calling_Number__c='1234567',Caller_Gender__c='Male',Patient_State__c='AL',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName',WhatId = null,WhoId = null),
		//            new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)) ,Subject='',Patient_City__c='test',Calling_Number__c='1234567',Caller_Gender__c='Male',Patient_State__c='AL',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName',WhatId = null,WhoId = null)
		//            };
		//    insert taskObjs;

		List<Basic_Note__c> patientNotes = new List<Basic_Note__c>{
			new Basic_Note__c(Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = 'test', Patient_City__c = 'test', Calling_Number__c = '1234567', Patient_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = 'Non-Starter', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName1', Account__c = accWithContact.AccountId, Contact__c = accWithContact.Id),
			new Basic_Note__c(Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = '', Patient_City__c = 'test', Calling_Number__c = '1234567', Patient_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = 'Non-Starter', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName1', Account__c = accWithContact.AccountId, Contact__c = null),
			new Basic_Note__c(Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = 'test', Patient_City__c = 'test', Calling_Number__c = '1234567', Caller_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = '', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName', Account__c = null, Contact__c = null),
			new Basic_Note__c(Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = '', Patient_City__c = 'test', Calling_Number__c = '1234567', Caller_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = '', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName', Account__c = null, Contact__c = null)
		};

		insert patientNotes;
	}

	public static void createPortalFamily(Id accountId) {
		Id familyPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Family Community User' LIMIT 1].Id;

		Contact familyContact = new Contact(LastName = 'TestFamily', FirstName = 'Admitted', AccountId = accountId, RecordTypeId = RecordTypeHelper.getIdByName('Contact', 'Personal'));
		insert familyContact;

		// Portal User
		User familyPortalUser = new User(FirstName = familyContact.FirstName, LastName = familyContact.LastName, ContactId = familyContact.Id, ProfileId = familyPortalProfileId, Username = 'testuserfamily@austenriggs.net', Email = 'testuserfamily@example.com', Alias = 'fam', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');

		insert familyPortalUser;
	}

	public static Id createAdmittedPortalPatient(Id recTypeId, Id profileId) {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		// Id patientPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Patient Community User' LIMIT 1].Id;

		//Account
		List<Account> patientAccounts = new List<Account>{ new Account(RecordtypeId = recTypeId, Name = 'TestPatient_1', Service_Type_Text__c = 'Residential') };
		insert patientAccounts;

		//Contact
		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient', FirstName = 'Admitted', AccountId = patientAccounts[0].Id, RecordTypeId = recordTypeMap.get('Patient-Contact')) };
		insert contactList;

		Contact contactWithAccount = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		//Admission
		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = contactWithAccount.AccountId, Patient_Contact__c = contactWithAccount.Id, Stage__c = 'Waitlist') };
		insert admissionList;

		contactWithAccount = [SELECT Id, AccountId, FirstName, LastName, Account.Current_Admission_Stage__c, Account.Current_Admission__c FROM Contact WHERE Id = :contactWithAccount.Id];

		//Assigned clinician
		List<Assigned_Clinician__c> assignedCliniciansList = new List<Assigned_Clinician__c>();
		Assigned_Clinician__c testClin1 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Team Leader', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		assignedCliniciansList.add(testClin1);
		Assigned_Clinician__c testClin2 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Program Manager', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		assignedCliniciansList.add(testClin2);
		Assigned_Clinician__c testClin3 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Clinical Social Worker', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(-3));
		assignedCliniciansList.add(testClin3);
		Assigned_Clinician__c testClin4 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Psychotherapist', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(500));
		assignedCliniciansList.add(testClin4);
		insert assignedCliniciansList;

		admissionList[0].Consultation_Date__c = System.today();
		admissionList[0].Psychotherapist__c = assignedCliniciansList[0].User__c;
		update admissionList;

		Admission__c currentAdmission = [SELECT Id, Stage__c, Psychotherapist__c, Patient_Account__c, (SELECT Id, Start_Date__c, Role__c FROM Assigned_Clinicians__r WHERE Role__c = 'Psychotherapist') FROM Admission__c WHERE Id = :admissionList[0].Id];

		admissionList[0].Admit_Date__c = System.today();
		admissionList[0].Stage__c = 'Admitted';
		update admissionList;

		Account checkPatientAccount = [SELECT Id, Current_Admission__c, Current_Admission__r.Stage__c, Current_Admission_Stage__c, Recordtype.Name FROM Account WHERE Id = :contactWithAccount.AccountId LIMIT 1];

		// Portal User
		User patientPortalUser = new User(FirstName = contactWithAccount.FirstName, LastName = contactWithAccount.LastName, ContactId = contactWithAccount.Id, ProfileId = profileId, Username = 'testuserpatient@austenriggs.net', Email = 'testuserpatient@example.com', Alias = 'client', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');

		insert patientPortalUser;

		return contactWithAccount.AccountId;
	}

	public static Contact createAdmittedPatient() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
		Id patientPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Patient Community User' LIMIT 1].Id;

		//Account
		List<Account> patientAccounts = new List<Account>{ new Account(RecordtypeId = recordTypeMap.get('Patient-Account'), Name = 'TestPatient_1', Service_Type_Text__c = 'Residential') };
		insert patientAccounts;

		//Contact
		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient', FirstName = 'Admitted', AccountId = patientAccounts[0].Id, RecordTypeId = recordTypeMap.get('Patient-Contact')) };
		insert contactList;

		Contact contactWithAccount = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		//Admission
		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = contactWithAccount.AccountId, Patient_Contact__c = contactWithAccount.Id, Stage__c = 'Waitlist') };
		insert admissionList;

		contactWithAccount = [SELECT Id, AccountId, FirstName, LastName, Account.Current_Admission_Stage__c, Account.Current_Admission__c FROM Contact WHERE Id = :contactWithAccount.Id];

		//Assigned clinician
		List<Assigned_Clinician__c> assignedCliniciansList = new List<Assigned_Clinician__c>();
		Assigned_Clinician__c testClin1 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Team Leader', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		assignedCliniciansList.add(testClin1);
		Assigned_Clinician__c testClin2 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Program Manager', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7));
		assignedCliniciansList.add(testClin2);
		Assigned_Clinician__c testClin3 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Clinical Social Worker', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(-3));
		assignedCliniciansList.add(testClin3);
		Assigned_Clinician__c testClin4 = new Assigned_Clinician__c(Admission__c = contactWithAccount.Account.Current_Admission__c, Role__c = 'Psychotherapist', User__c = UserInfo.getUserId(), Start_Date__c = Date.today().addDays(-7), End_Date__c = Date.today().addDays(500));
		assignedCliniciansList.add(testClin4);
		insert assignedCliniciansList;

		admissionList[0].Consultation_Date__c = System.today();
		admissionList[0].Psychotherapist__c = assignedCliniciansList[0].User__c;
		update admissionList;

		Admission__c currentAdmission = [SELECT Id, Stage__c, Psychotherapist__c, Patient_Account__c, (SELECT Id, Start_Date__c, Role__c FROM Assigned_Clinicians__r WHERE Role__c = 'Psychotherapist') FROM Admission__c WHERE Id = :admissionList[0].Id];

		admissionList[0].Admit_Date__c = System.today();
		admissionList[0].Stage__c = 'Admitted';
		update admissionList;

		Account checkPatientAccount = [SELECT Id, Current_Admission__c, Current_Admission__r.Stage__c, Current_Admission_Stage__c, Recordtype.Name FROM Account WHERE Id = :contactWithAccount.AccountId LIMIT 1];

		return contactWithAccount;
	}

	public static Contact createAdmittedFamily(Id accountId) {
		Id familyPortalProfileId = [SELECT Id FROM Profile WHERE Name = 'ARC Family Community User' LIMIT 1].Id;

		Contact familyContact = new Contact(LastName = 'TestFamily', FirstName = 'Admitted', AccountId = accountId, RecordTypeId = RecordTypeHelper.getIdByName('Contact', 'Personal'));
		insert familyContact;
		return familyContact;
	}

	public static Id createAdminUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

		User adminUser = new User(ProfileId = profileId, LastName = 'RiggsAdmin', FirstName = 'Test', Email = 'testRiggsAdmin0009@test.com', Username = 'testRiggsAdmin0009@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'azked', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert adminUser;
		return adminUser.Id;
	}

	public static Id createAdmissionsUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsAdmissions' LIMIT 1].Id;
		User admissionsUser = new User(ProfileId = profileId, LastName = 'RiggsAdmissions', FirstName = 'Test', Email = 'testRiggsAdmissions@test.com', Username = 'testRiggsAdmissions@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'admis', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert admissionsUser;
		return admissionsUser.Id;
	}

	public static Id createClinicalUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsClinical' LIMIT 1].Id;
		User clinicalUser = new User(ProfileId = profileId, LastName = 'RiggsClinical', FirstName = 'Test', Email = 'testRiggsClinical@test.com', Username = 'testRiggsClinical@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'clinic', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert clinicalUser;
		return clinicalUser.Id;
	}

	public static Id createInternalIntegrationUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsInternalIntegration' LIMIT 1].Id;
		User internalintegrationUser = new User(ProfileId = profileId, LastName = 'RiggsInternalIntegration', FirstName = 'Test', Email = 'testRiggsInternalIntegration@test.com', Username = 'testRiggsInternalIntegration@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'intern', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert internalintegrationUser;
		return internalintegrationUser.Id;
	}

	public static Id createNursingUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsNursing' LIMIT 1].Id;
		User nursingUser = new User(ProfileId = profileId, LastName = 'RiggsNursing', FirstName = 'Test', Email = 'testRiggsNursing@test.com', Username = 'testRiggsNursing@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'nurse', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert nursingUser;
		return nursingUser.Id;
	}

	public static Id createPharmacistUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsPharmacist' LIMIT 1].Id;
		User pharmacistUser = new User(ProfileId = profileId, LastName = 'RiggsPharmacist', FirstName = 'Test', Email = 'testRiggsPharmacist@test.com', Username = 'testRiggsPharmacist@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'pharma', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert pharmacistUser;
		return pharmacistUser.Id;
	}

	public static Id createStaffUser() {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsStaff' LIMIT 1].Id;
		User staffUser = new User(ProfileId = profileId, LastName = 'RiggsStaff', FirstName = 'Test', Email = 'testRiggsStaff@test.com', Username = 'testRiggsStaff@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'staff', TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

		insert staffUser;
		return staffUser.Id;
	}

	public static List<User> createStaffUsers(Integer recs) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'RiggsStaff' LIMIT 1].Id;
		List<User> userList = new List<User>();

		for (Integer i = 0; i < recs; i++) {
			User objUser = new User(ProfileId = profileId, LastName = 'last-' + String.valueOf(i), Email = 'puser000' + String.valueOf(i) + '@amamama.com', Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias-' + String.valueOf(i), TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', IsActive = true);

			userList.add(objUser);
		}

		insert userList;
		return userList;
	}

	public static void createStaffPortalUsers(Integer recs) {
		Id profileId = [SELECT Id FROM Profile WHERE Name = 'ARC Staff Community User' LIMIT 1].Id;
		List<User> userList = new List<User>();

		for (Integer i = 0; i < recs; i++) {
			User objUser = new User(ProfileId = profileId, LastName = 'last-' + String.valueOf(i), Email = 'puser000' + String.valueOf(i) + '@amamama.com', Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias-' + String.valueOf(i), TimeZoneSidKey = 'America/New_York', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US');

			userList.add(objUser);
		}

		insert userList;
	}

	public static void createStaffGroupAndMembers(Id userId) {
		Group__c newGroup = new Group__c(Description__c = 'Test', Duration__c = 'Standing', Type__c = 'Program', Name = 'Create Message');
		insert newGroup;

		Staff_Group_Member__c groupMember = new Staff_Group_Member__c(Staff_Member__c = userId, Role__c = 'Member', Group_Name__c = newGroup.Id, Start_Date__c = System.today().addDays(-10));
		insert groupMember;
	}

	public static void createPatientWithAdmissionsAndCalls() {
		Map<String, Id> recordTypeMap = getRecordTypeInfo();

		Account ptAccount = new Account(Name = 'patient1', RecordTypeId = recordTypeMap.get('Patient-Account'));
		insert ptAccount;

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', AccountId = ptAccount.Id, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Contact')) };
		insert contactList;

		Contact accWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		// Admission__c curAdm = new Admission__c(Patient_Account__c = ptAccount.Id, Patient_Contact__c = accWithContact.Id, Stage__c = 'Consultation Pending', Consultation_Only_Date__c = system.today().addDays(2));
		// Admission__c oldAdm = new Admission__c(Patient_Account__c = ptAccount.Id, Patient_Contact__c = accWithContact.Id, Stage__c = 'Discharged', Admit_Date__c = system.today().addDays(-30));
		Admission__c curAdm = new Admission__c(Patient_Account__c = ptAccount.Id, Patient_Contact__c = accWithContact.Id, Stage__c = 'Consultation Pending', Admit_Date__c = system.today().addDays(-20), Consultation_Only_Date__c = system.today().addDays(2), Team__c = 'A');
		Admission__c oldAdm = new Admission__c(Patient_Account__c = ptAccount.Id, Patient_Contact__c = accWithContact.Id, Stage__c = 'Discharged', Admit_Date__c = system.today().addDays(-30), Team__c = 'A', Discharge_Date__c = system.today());
		insert new List<Admission__c>{ curAdm, oldAdm };

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Role__c = 'Patient', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = contactList[1].Id, Account__c = accWithContact.AccountId, Role__c = 'Mother', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = contactList[2].Id, Account__c = accWithContact.AccountId, Role__c = 'Psychiatrist', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Related_Contact__c'))
		};
		insert relatedContacts;

		ptAccount.Current_Admission__c = curAdm.Id;
		ptAccount.Patient_Contact__c = accWithContact.Id;
		update ptAccount;

		List<Basic_Note__c> bNotes = new List<Basic_Note__c>{
			new Basic_Note__c(Admission__c = curAdm.Id, Rich_Text_Notes__c = 'rtNotes', Caller_Affect_and_Presentation__c = 'affect', Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = 'test', Patient_City__c = 'test', Calling_Number__c = '1234567', Patient_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = 'Non-Starter', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName1', Account__c = accWithContact.AccountId, Contact__c = accWithContact.Id),
			new Basic_Note__c(Admission__c = curAdm.Id, Rich_Text_Notes__c = 'rtNotes', Caller_Affect_and_Presentation__c = 'affect', Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = '', Patient_City__c = 'test', Calling_Number__c = '1234567', Patient_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = 'Non-Starter', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName1', Account__c = accWithContact.AccountId, Contact__c = null),
			new Basic_Note__c(Admission__c = curAdm.Id, Rich_Text_Notes__c = 'rtNotes', Caller_Affect_and_Presentation__c = 'affect', Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = 'test', Patient_City__c = 'test', Calling_Number__c = '1234567', Caller_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = '', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName', Account__c = null, Contact__c = null),
			new Basic_Note__c(Admission__c = curAdm.Id, Rich_Text_Notes__c = 'rtNotes', Caller_Affect_and_Presentation__c = 'affect', Call_Date_Time__c = DateTime.newInstance(System.today(), Time.newInstance(0, 0, 0, 0)), Subject__c = '', Patient_City__c = 'test', Calling_Number__c = '1234567', Caller_Gender__c = 'Male', Patient_State__c = 'AL', Call_Type__c = '', Call_Status__c = 'Logged', Patient_Name__c = 'TestPatient_1', Caller_Name__c = 'test_callerName', Account__c = null, Contact__c = null)
		};
		insert bNotes;

		//     List<Task> taskObjs = new List<Task>{
		//             new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)), Patient_Note__c = ptNotes[0].Id ,Subject='test',Patient_City__c='test',Calling_Number__c='1234567',Patient_Gender__c='Male',Patient_State__c='AL',Call_Type__c = 'Non-Starter',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName1',WhatId = accWithContact.AccountId,WhoId = accWithContact.Id),
		//             new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)), Patient_Note__c = ptNotes[1].Id ,Subject='',Patient_City__c='test',Calling_Number__c='1234567',Patient_Gender__c='Male',Patient_State__c='AL',Call_Type__c = 'Non-Starter',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName1',WhatId = accWithContact.AccountId,WhoId = null),
		//             new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)), Patient_Note__c = ptNotes[2].Id ,Subject='test',Patient_City__c='test',Calling_Number__c='1234567',Caller_Gender__c='Male',Patient_State__c='AL',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName',WhatId = null,WhoId = null),
		//             new Task(Call_Date_Time__c = DateTime.newInstance(System.today(),Time.newInstance(0, 0, 0, 0)), Patient_Note__c = ptNotes[3].Id ,Subject='',Patient_City__c='test',Calling_Number__c='1234567',Caller_Gender__c='Male',Patient_State__c='AL',Call_Type__c = '',Call_Status__c = 'Logged', Patient_Name__c ='TestPatient_1',Caller_Name__c = 'test_callerName',WhatId = null,WhoId = null)
		//             };
		//    insert taskObjs;
	}

	public static void CVCDLInsert() {
		ContentVersion cv = new Contentversion();
		cv.title = 'ABC';
		cv.PathOnClient = 'test';
		Blob b = Blob.valueOf('Unit Test Attachment Body');
		cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
		insert cv;
	}
}