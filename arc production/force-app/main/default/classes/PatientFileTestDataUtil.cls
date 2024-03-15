@isTest
public class PatientFileTestDataUtil {
	public static Map<String, Id> getRecordTypeInfo() {
		Map<String, Id> recordTypeMap = new Map<String, Id>();
		for (RecordType rt : [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = TRUE]) {
			recordTypeMap.put(rt.DeveloperName + '-' + rt.SobjectType, rt.Id);
		}
		return recordTypeMap;
	}

	public static void createPatient() {
		Map<String, Id> recordTypeMap = getRecordTypeInfo();

		List<Account> patientAccountList = new List<Account>{ new Account(Name = 'patient1', RecordtypeId = recordTypeMap.get('Patient' + '-' + 'Account')), new Account(Name = 'patient4', RecordtypeId = recordTypeMap.get('Patient' + '-' + 'Account')), new Account(Name = 'patientmerge2', RecordtypeId = recordTypeMap.get('Patient' + '-' + 'Account')), new Account(Name = 'patientmerge3', RecordtypeId = recordTypeMap.get('Patient' + '-' + 'Account')) };
		insert patientAccountList;

		List<Contact> contactList = new List<Contact>{
			//accWithContact
			new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'), AccountId = patientAccountList[0].Id),
			new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')),
			new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Contact')),
			new Contact(LastName = 'TestPatient_4', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'), AccountId = patientAccountList[1].Id),
			new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')),
			new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingStateCode = 'AB', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Contact')),
			//mergeContact1
			new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingStateCode = 'AL', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'), AccountId = patientAccountList[3].Id),
			//mergeContact2
			new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingStateCode = 'AB', MailingCountryCode = 'CA', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'), AccountId = patientAccountList[2].Id)
		};
		insert contactList;

		Map<String, Contact> nameToContactMap = new Map<String, Contact>();
		for (Contact con : contactList) {
			nameToContactMap.put(con.LastName, con);
		}
		// Contact accWithContact = [SELECT Id, AccountId  FROM Contact WHERE Id =: contactList[0].Id];
		// Contact mergeContact1 = [SELECT Id, AccountId  FROM Contact WHERE LastName = 'TestContactMerge1'];
		// Contact mergeContact2 = [SELECT Id, AccountId  FROM Contact WHERE LastName = 'TestContactMerge2'];
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
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = true, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Mother', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Father', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = mergeContact1.Id, Account__c = mergeContact1.AccountId, Former__c = false, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Patient', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = mergeContact2.Id, Account__c = mergeContact2.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Patient', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c'))
		};
		insert relatedContacts;

		// List<Admission__c> allAdmissions = [SELECT Id, Patient_Account__c, Patient_Account__r.Name, Patient_Contact__c, Stage__c FROM Admission__c];
		// System.assert(allAdmissions.size() > 0);

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = mergeContact1.AccountId, Patient_Contact__c = mergeContact1.Id, Stage__c = 'Open Inquiry'), new Admission__c(Patient_Account__c = mergeContact2.AccountId, Patient_Contact__c = mergeContact2.Id, Stage__c = 'Open Inquiry') };
		insert admissionList;

		Account mergeAccount1 = [SELECT Id, Name, Current_Admission__c, Patient_Contact__c FROM Account WHERE Id = :mergeContact1.AccountId];
		// System.assert(mergeAccount1.Current_Admission__c != null, mergeAccount1);
		Account mergeAccount2 = [SELECT Id, Name, Current_Admission__c, Patient_Contact__c FROM Account WHERE Id = :mergeContact2.AccountId];
		Admission__c mergeAdmission1 = [SELECT Id, Patient_Account__c, Patient_Contact__c FROM Admission__c WHERE Patient_Account__c = :mergeAccount1.Id LIMIT 1];
		Admission__c mergeAdmission2 = [SELECT Id, Patient_Account__c, Patient_Contact__c FROM Admission__c WHERE Patient_Account__c = :mergeAccount2.Id LIMIT 1];

		mergeAccount1.Current_Admission__c = mergeAdmission1.Id;
		mergeAccount1.Patient_Contact__c = mergeContact1.Id;
		mergeAccount2.Current_Admission__c = mergeAdmission2.Id;
		mergeAccount2.Patient_Contact__c = mergeContact2.Id;

		Task task = (Task) TestFactory_Patient.createSObject(new Task(Admission__c = mergeAdmission2.Id), true);
		disco__Form_Template__c formTemplateTest = (disco__Form_Template__c) TestFactory_Patient.createSObject(new disco__Form_Template__c(DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer', disco__Status__c = 'In Use'), true);

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

		whatsMyData();
	}

	public static void createPatientWithNote() {
		Map<String, Id> recordTypeMap = getRecordTypeInfo();

		List<Contact> contactList = new List<Contact>{
			new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')),
			new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')),
			new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Contact')),
			new Contact(LastName = 'TestPatient_4', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')),
			new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')),
			new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingCountryCode = 'US', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Professional' + '-' + 'Contact')),
			new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingCountryCode = 'US', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')),
			new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingCountryCode = 'US', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'))
			//new Contact(LastName = 'TestMerge1', MailingCity = 'Test1 Street', MailingState = 'Alabama', MailingCountry = 'United States', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Personal'+'-'+'Contact')),
			//new Contact(LastName = 'TestMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountry = 'Canada', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Professional'+'-'+'Contact')),
			//new Contact(LastName = 'TestContactMerge1', MailingCity = 'Test1 Street', MailingState = 'Alabama', MailingCountry = 'United States', MailingPostalCode = '123546', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact')),
			//new Contact(LastName = 'TestContactMerge2', MailingCity = 'Test2 Street', MailingState = 'Alberta', MailingCountry = 'Canada', MailingPostalCode = '654321', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
		};
		insert contactList;

		Contact accWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = true, Payor__c = true, Primary_Contact__c = true, Referrer__c = false, Role__c = 'Mother', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Related_Contact__c')),
			new Related_Contact__c(Contact__c = accWithContact.Id, Account__c = accWithContact.AccountId, Former__c = false, Payor__c = false, Primary_Contact__c = false, Referrer__c = true, Role__c = 'Father', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Related_Contact__c'))
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

	public static void createPatientWithAdmission() {
		Map<String, Id> recordTypeMap = getRecordTypeInfo();

		List<Contact> contactList = new List<Contact>{ new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')) };
		insert contactList;

		Contact accWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactList[0].Id];

		List<Admission__c> admissionList = new List<Admission__c>{ new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Waitlist'), new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Waitlist'), new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Waitlist'), new Admission__c(Patient_Account__c = accWithContact.AccountId, Patient_Contact__c = accWithContact.Id, Stage__c = 'Waitlist') };
		insert admissionList;
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

	public static void whatsMyData() {
		List<Account> accounts = [SELECT Id, Name, Current_Admission__c, Patient_Contact__c, RecordType.DeveloperName FROM Account ORDER BY Name];
		for (Account acc : accounts) {
			System.debug(acc);
		}
		List<Contact> contacts = [SELECT Id, LastName, AccountId, RecordType.Name, MailingCity, MailingStateCode, MailingCountryCode, MailingPostalCode FROM Contact ORDER BY LastName];
		for (Contact con : contacts) {
			System.debug(con);
		}
	}
}