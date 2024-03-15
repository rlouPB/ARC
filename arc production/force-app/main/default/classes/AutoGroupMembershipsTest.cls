@isTest
public class AutoGroupMembershipsTest {
	@TestSetup
	static void makeData() {
		Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

		List<String> allGroupNameList = new List<String>(AutoGroupMemberships.syncDefMap.keySet());
		Integer groupCount = allGroupNameList.size();
		allGroupNameList.sort(); //alpha so I can get the same order in test

		List<Group__c> existingGroups = new List<Group__c>();
		//leave the last GroupName in allGroupNameList out of the loop
		for (Integer i = 0; i < groupCount - 2; i++) {
			AutoGroupMemberships.SyncDefinition def = AutoGroupMemberships.syncDefMap.get(allGroupNameList[i]);
			existingGroups.add(new Group__c(Name = def.groupMembershipName, Active__c = true, Attendance_Tracking__c = 'Do not Track Attendance', Closed_Membership__c = false, Description__c = 'Automatically maintained Group Membership', Duration__c = 'Standing', Planned_End_Date__c = null, Primary_Function__c = def.memberType, Type__c = 'Center-wide'));
		}
		insert existingGroups;

		//make patients
		List<Contact> patientContactList = new List<Contact>{ new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_1', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_2', RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact')), new Contact(LastName = 'TestPatient_3', RecordTypeId = recordTypeMap.get('Personal' + '-' + 'Contact')) };
		insert patientContactList;

		List<Contact> accWithContacts = [SELECT Id, LastName, AccountId FROM Contact WHERE Id IN :patientContactList ORDER BY LastName];

		List<Admission__c> admissionList = new List<Admission__c>{
			new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, Stage__c = 'Consultation Pending', Service_Type__c = 'Residential'), //good
			new Admission__c(Patient_Account__c = accWithContacts[1].AccountId, Patient_Contact__c = accWithContacts[1].Id, Stage__c = 'Consultation Pending', Service_Type__c = 'IOP'), //bad service type
			new Admission__c(Patient_Account__c = accWithContacts[2].AccountId, Patient_Contact__c = accWithContacts[2].Id, Stage__c = 'Active Inquiry', Service_Type__c = 'Residential') //bad Stage
			//,new Admission__c(Patient_Account__c = accWithContacts[3].AccountId, Patient_Contact__c = accWithContacts[3].Id, Stage__c='Waitlist') //not a Patient
		};
		insert admissionList;

		//JNTODO

		//update Admissions to Admitted
		admissionList[0].Psychotherapist__c = Userinfo.getUserId();
		admissionList[0].Stage__c = 'Admitted';
		update admissionList[0];
		admissionList[1].Psychotherapist__c = Userinfo.getUserId();
		admissionList[1].Stage__c = 'Admitted';
		update admissionList[1];

		//create Users
		Profile riggsClinicalProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsClinical' LIMIT 1];
		Profile riggsStaffProfile = [SELECT Id FROM Profile WHERE Name = 'RiggsStaff' LIMIT 1];
		Id staffRtId = recordTypeMap.get('ARC_Staff' + '-' + 'Contact');
		Map<String, User> staffUserNameMap;
		User adminNotMe = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE AND Id != :Userinfo.getUserId() LIMIT 1];
		System.runAs(adminNotMe) {
			List<User> usersToCreate = new List<User>();

			//good: all staff
			usersToCreate.add(new User(FirstName = 'AGMTestnonclinicalAllstaff', LastName = 'Test', ProfileId = riggsStaffProfile.Id, Username = 'nonclinicalAllstaff@austenriggs.net.Phase2Dev', Email = 'nonclinicalAllstaff@example.com', Alias = 'noncl', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));
			//good: all staff and all clinical staff
			usersToCreate.add(new User(FirstName = 'AGMTestClinicalAllstaff', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'ClinicalAllstaff@austenriggs.net.Phase2Dev', Email = 'ClinicalAllstaff@example.com', Alias = 'Clini', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));

			//bad: User Not Active
			usersToCreate.add(new User(FirstName = 'AGMTestInactiveUser', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'InactiveUser@austenriggs.net.Phase2Dev', Email = 'InactiveUser@example.com', Alias = 'Inact', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = false));
			//bad: Contact Not Active Employee
			usersToCreate.add(new User(FirstName = 'AGMTestNoActiveContact', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'NoActiveContact@austenriggs.net.Phase2Dev', Email = 'NoActiveContact@example.com', Alias = 'NoAct', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));
			//bad: Contact wrong recordType
			usersToCreate.add(new User(FirstName = 'AGMTestBadContact', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'BadContact@austenriggs.net.Phase2Dev', Email = 'BadContact@example.com', Alias = 'BadCo', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));
			//bad: No Contact
			usersToCreate.add(new User(FirstName = 'AGMTestNoContact', LastName = 'Test', ProfileId = riggsClinicalProfile.Id, Username = 'NoContact@austenriggs.net.Phase2Dev', Email = 'NoContact@example.com', Alias = 'NoCon', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York', IsActive = true));
			insert usersToCreate;

			staffUserNameMap = getFirstNameUserMap(usersToCreate);
			// System.assertEquals(userstoCreate.size(), staffUserNameMap.size());

			//Clinical Permission Staff on clinical
			PermissionSet clinPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Clinical' LIMIT 1];
			PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = staffUserNameMap.get('AGMTestClinicalAllstaff').Id, PermissionSetId = clinPermSet.Id);
			insert psa;
		}
		//end adminNotMe
		//staff user Contacts
		List<Contact> staffContacts = new List<Contact>();
		staffContacts.add(new Contact(RecordtypeId = staffRtId, LastName = 'AGMTestnonclinicalAllstaff', Active_Employee__c = true, Staff_User__c = staffUserNameMap.get('AGMTestnonclinicalAllstaff').Id));
		staffContacts.add(new Contact(RecordtypeId = staffRtId, LastName = 'AGMTestClinicalAllstaff', Active_Employee__c = true, Staff_User__c = staffUserNameMap.get('AGMTestClinicalAllstaff').Id));

		staffContacts.add(new Contact(RecordtypeId = staffRtId, LastName = 'AGMTestInactiveUser', Active_Employee__c = true, Staff_User__c = staffUserNameMap.get('AGMTestInactiveUser').Id));
		staffContacts.add(new Contact(RecordtypeId = staffRtId, LastName = 'AGMTestNoActiveContact', Active_Employee__c = false, Staff_User__c = staffUserNameMap.get('AGMTestNoActiveContact').Id));
		staffContacts.add(new Contact(RecordtypeId = recordTypeMap.get('Patient' + '-' + 'Contact'), LastName = 'AGMTestBadContact', Active_Employee__c = true, Staff_User__c = staffUserNameMap.get('AGMTestBadContact').Id));
		//NoContact gets no contact
		insert staffContacts;

		//populate existing members
		List<Staff_Group_Member__c> sgms = new List<Staff_Group_Member__c>();
		List<Patient_Group_Member__c> pgms = new List<Patient_Group_Member__c>();
		for (Group__c groupMembership : existingGroups) {
			AutoGroupMemberships.SyncDefinition def = AutoGroupMemberships.syncDefMap.get(groupMembership.Name);
			List<String> sObjDetails = AutoGroupMemberships.memberType2SobjectField.get(def.memberType).split('\\.');
			String memberObjectName = sObjDetails[0];
			String memberObjectField = sObjDetails[1];

			if (groupMembership.Primary_Function__c == 'Staff') {
				for (String userFirstName : staffUserNameMap.keySet()) {
					if (userfirstName == 'AGMTestnonclinicalAllstaff')
						continue; //this will sync back in

					User staffUser = staffUserNameMap.get(userFirstName);

					Staff_Group_Member__c newMember = new Staff_Group_Member__c(Group_Name__c = groupMembership.Id, Role__c = 'Member', Staff_Member__c = staffUser.Id, Start_Date__c = System.today().addDays(-100));
					sgms.add(newMember);
				}
			} else if (groupMembership.Primary_Function__c == 'Patient') {
				for (Contact pcon : patientContactList) {
					if (pcon.LastName == 'TestPatient_3')
						continue; //sync will create

					Patient_Group_Member__c newMember = new Patient_Group_Member__c(Group_Name__c = groupMembership.Id, Role__c = 'Member', Patient__c = pcon.Id, Start_Date__c = System.today().addDays(-100));

					pgms.add(newMember);
				}
			}
		}

		insert sgms;
		insert pgms;

		//
	}

	static Map<String, User> getFirstNameUserMap(List<User> users) {
		if (users == null) {
			users = [SELECT Id, Firstname FROM User WHERE FirstName LIKE 'AGMTest'];
		}
		Map<String, User> returnMap = new Map<String, User>();
		for (User u : users) {
			returnMap.put(u.FirstName, u);
		}
		return returnMap;
	}

	@isTest
	static void testSync() {
		List<String> allGroupNameList = new List<String>(AutoGroupMemberships.syncDefMap.keySet());
		allGroupNameList.sort();

		Test.startTest();
		AutoGroupMemberships.syncToGroupMemberships();

		Test.stopTest();
		List<Process_Log__c> plogs = [SELECT Id, Process__c, Detail__c, Stack_Trace__c FROM Process_Log__c];
		// System.assertEquals(0, plogs.size(), plogs);

		//TODO: asserts
		//groupMemberships
		//sgms
		//pgms
	}

	@isTest
	static void testSIP1() {
		String query = SystemScheduling.scheduledItemDefQueryString + ' WHERE ScheduledItemProcessor_to_Use__c = \'AutoGroupMemberships\' LIMIT 1';
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = (List<Scheduled_Item_Definition__mdt>) Database.query(query);

		Scheduled_Item_Definition__mdt currentDef = scheduledItemDefs[0];

		Scheduled_Item_Run__c testRun = new Scheduled_Item_Run__c(Name = currentDef.MasterLabel, Scheduled_Item_Def__c = currentDef.ID, Scheduled_Item_Def_Status__c = 'Active', Retry_Count__c = 0);
		insert testRun;

		// try {
		// 	system.assert(false, 'message');
		// } catch (Exception e)
		// {
		// 	ex = e;
		// }

		Test.startTest();

		Savepoint sp = Database.setSavepoint();
		CustomException cex = new CustomException();

		SIP_AutoGroupMemberships.process(scheduledItemDefs);

		SIP_AutoGroupMemberships.handleDefCatch(sp, testRun, cex);
		SIP_AutoGroupMemberships.handleFinalCatch(new List<Scheduled_Item_Run__c>{ testRun }, cex);

		Test.stopTest();
		List<Process_Log__c> plogs = [SELECT Id, Process__c, Detail__c, Stack_Trace__c FROM Process_Log__c];
		// System.assertEquals(0, plogs.size(), plogs);
	}

	@isTest
	static void testSIP2() {
		//no Run to start with

		String query = SystemScheduling.scheduledItemDefQueryString + ' WHERE ScheduledItemProcessor_to_Use__c = \'AutoGroupMemberships\' LIMIT 1';
		List<Scheduled_Item_Definition__mdt> scheduledItemDefs = (List<Scheduled_Item_Definition__mdt>) Database.query(query);
		Test.startTest();

		SIP_AutoGroupMemberships.process(scheduledItemDefs);

		Test.stopTest();
		List<Process_Log__c> plogs = [SELECT Id, Process__c, Detail__c, Stack_Trace__c FROM Process_Log__c];
		// System.assertEquals(0, plogs.size(), plogs);
	}
}