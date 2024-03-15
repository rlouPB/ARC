@isTest class Contact_TriggerHelperTest
{
	static Id conStaffRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('ARC Staff').getRecordtypeId();
	static Id conPatientRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordtypeId();

	static testmethod void testUpdateAccountName()
	{
		PatientFileTestDataUtil.createPatientWithAdmission();

        Contact con = [SELECT Id, FirstName, Preferred_First_Name__c, LastName, AccountId, Account.Name, RecordtypeId
        				FROM Contact
        				WHERE Name = 'TestPatient_1'
        				LIMIT 1];
        List<Contact> triggernew = new List<Contact>{ con };

		Map<Id, Contact> triggerOldMap = new Map<Id, Contact>();
		triggerOldMap.put(con.Id, new Contact(LastName = 'differentname'));

		test.startTest();

		Contact_TriggerHelper.updatePatientAccountsFromContact(triggerNew, triggerOldMap);

		test.stopTest();

		Account acc = [SELECT Name
						FROM Account
						WHERE Id = :con.AccountId];
		// System.assertNotEquals(con.Account.Name, acc.Name);
	}

	@isTest
	static void testUpdateLegalName()
	{
		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();

        Contact con = [SELECT Id, FirstName, Preferred_First_Name__c, LastName, AccountId, Account.Name, RecordtypeId
        				FROM Contact
        				WHERE Name = 'TestPatient_1'
        				LIMIT 1];
        con.FirstName = 'ContactFirstName';
		update con;

		List<Contact> triggernew = new List<Contact>{ con };

		Map<Id, Contact> triggerOldMap = new Map<Id, Contact>();
		triggerOldMap.put(con.Id, new Contact(LastName = 'differentname'));

		Legal_Name__c legalName = new Legal_Name__c(
			Current_Last_Name__c = con.LastName,
			Patient__c = con.AccountId
		);
		insert legalName;

		test.startTest();

		Contact_TriggerHelper.updateLegalNamesFromContact(triggerNew, triggerOldMap);

		test.stopTest();
	}

	@isTest
	static void testInsertContactsUserFields()
	{
		Profile riggsClinicalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'RiggsClinical'
            LIMIT 1
        ];

		User testUser1 = new User(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'testuser@example.com',
            Alias = 'test1',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
		insert testUser1;


			Contact contact = new Contact(
				LastName = 'TestLastName',
				RecordtypeId = conStaffRtId,
				Staff_User__c = testUser1.Id,
				Suffix_Credentials__c = 'PhD'
			);

		test.startTest();
			insert contact;
			contact.Suffix_Credentials__c = 'PhD;MD';


			update contact;
			contact = [Select Professional_Name__c from Contact where Id = :contact.Id];

		test.stopTest();

		testUser1 = [Select Contact_Professional_Name__c From User where Id = :testUser1.Id];
		// System.assertEquals(contact.Professional_Name__c, testUser1.Contact_Professional_Name__c);
	}

@isTest
	static void testUpdateContactsUserFields()
	{
		Profile riggsClinicalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'RiggsClinical'
            LIMIT 1
        ];

		User testUser1 = new User(
            FirstName = 'TestFirstName',
            LastName = 'TestLastName',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'testuser@example.com',
            Alias = 'test1',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
		insert testUser1;

		Contact contact = new Contact(
			LastName = 'TestLastName',
			RecordtypeId = conStaffRtId,
			Staff_User__c = testUser1.Id,
			Suffix_Credentials__c = 'PhD'
		);
		insert contact;

		Contact checkInsertContact = [Select Professional_Name__c from Contact where Id = :contact.Id];
		// System.assertEquals('PhD', checkInsertContact.Professional_Name__c.right(3), checkInsertContact.Professional_Name__c);

		test.startTest();

			contact.Suffix_Credentials__c = 'PhD;MD';
			update contact;

		test.stopTest(); //future method should run here

		Contact checkUpdateContact = [Select Professional_Name__c from Contact where Id = :contact.Id];
		String suffix = checkUpdateContact.Professional_Name__c.right(7);
		// System.assert(suffix.contains('MD'), checkUpdateContact.Professional_Name__c);
		// System.assert(suffix.contains('PhD'), checkUpdateContact.Professional_Name__c);

		testUser1 = [Select Contact_Professional_Name__c From User where Id = :testUser1.Id];
		// System.assertEquals(checkUpdateContact.Professional_Name__c, testUser1.Contact_Professional_Name__c, 'actual Contact Professional Name: ' + testUser1.Contact_Professional_Name__c);
	}
}