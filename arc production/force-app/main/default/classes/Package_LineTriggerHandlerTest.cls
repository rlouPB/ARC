@isTest
private class Package_LineTriggerHandlerTest {
	@TestSetup
	static void makeData() {
		List<Account> accountsToInsert = new List<Account>();
		List<Admission__c> admissionsToInsert = new List<Admission__c>();
		List<Package__c> packagesToInsert = new List<Package__c>();
		List<Prescription__c> prescriptionsToInsert = new List<Prescription__c>();
		List<Package_Line__c> packageLinesToInsert = new List<Package_Line__c>();

		// Profiles
		Id pharmacistProfileId = [SELECT Id FROM Profile WHERE Name = 'RiggsPharmacist' LIMIT 1].Id;
		Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

		// Users
		List<User> usersToInsert = new List<User>();
		User testUserAdmin = new User(FirstName = 'testUser', LastName = 'Admin', ProfileId = adminProfileId, Username = 'testuseradmin@austenriggs.net.phase2dev', Email = 'testuseradmin@example.com', Alias = 'admin', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUserAdmin);

		User testUserPharmacist = new User(FirstName = 'testUser', LastName = 'Pharmacist', ProfileId = pharmacistProfileId, Username = 'testuserpharmacist@austenriggs.net.phase2dev', Email = 'testuserpharmacist@example.com', Alias = 'pharm', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', TimeZoneSidKey = 'America/New_York');
		usersToInsert.add(testUserPharmacist);
		insert usersToInsert;

		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		// Patients
		Account testPatient1 = new Account(Name = 'Package Line Test Patient 1', RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Patient'));
		accountsToInsert.add(testPatient1);

		Account testPatient2 = new Account(Name = 'Package Line Test Patient 2', RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Patient'));
		accountsToInsert.add(testPatient2);

		Account testPatient3 = new Account(Name = 'Package Line Test Patient 3', RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Patient'));
		accountsToInsert.add(testPatient3);

		Account testPatient4 = new Account(Name = 'Package Line Test Patient 4', RecordTypeId = RecordTypeHelper.getIdByName('Account', 'Patient'));
		accountsToInsert.add(testPatient4);
		insert accountsToInsert;

		// Admissions
		Admission__c testAdm1 = new Admission__c(Patient_Account__c = testPatient1.Id);
		admissionsToInsert.add(testAdm1);

		Admission__c testAdm2 = new Admission__c(Patient_Account__c = testPatient2.Id);
		admissionsToInsert.add(testAdm2);

		Admission__c testAdm3 = new Admission__c(Patient_Account__c = testPatient3.Id);
		admissionsToInsert.add(testAdm3);

		Admission__c testAdm4 = new Admission__c(Patient_Account__c = testPatient4.Id);
		admissionsToInsert.add(testAdm4);
		insert admissionsToInsert;

		// Packages
		Package__c testPkg1 = new Package__c(Patient__c = testPatient1.Id, Start_Date__c = Date.today().addDays(-1), Dispensed__c = false, Status__c = 'New');
		packagesToInsert.add(testPkg1);

		Package__c testPkg2 = new Package__c(Patient__c = testPatient2.Id, Start_Date__c = Date.today().addDays(-1), Dispensed__c = false, Status__c = 'New');
		packagesToInsert.add(testPkg2);

		Package__c testPkg3 = new Package__c(Patient__c = testPatient3.Id, Start_Date__c = Date.today().addDays(-1), Dispensed__c = false, Status__c = 'New');
		packagesToInsert.add(testPkg3);

		Package__c testPkg4 = new Package__c(Patient__c = testPatient4.Id, Start_Date__c = Date.today().addDays(-1), Dispensed__c = false, Status__c = 'New');
		packagesToInsert.add(testPkg4);
		insert packagesToInsert;

		// Prescriptions
		Prescription__c testRx1 = new Prescription__c(
			Account__c = testPatient1.Id,
			// Admission__c = testAdm1.Id,
			Control_Group__c = '2',
			Medication_Filled_with__c = 'Prescription A',
			Drug_Name__c = 'Prescription A',
			Name = 'Prescription A',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32960
		);
		prescriptionsToInsert.add(testRx1);

		Prescription__c testRx2 = new Prescription__c(
			Account__c = testPatient2.Id,
			// Admission__c = testAdm2.Id,
			Control_Group__c = '4',
			Medication_Filled_with__c = 'Prescription B',
			Drug_Name__c = 'Prescription B',
			Name = 'Prescription B',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32961
		);
		prescriptionsToInsert.add(testRx2);

		Prescription__c testRx3 = new Prescription__c(
			Account__c = testPatient3.Id,
			// Admission__c = testAdm3.Id,
			Control_Group__c = '2',
			Medication_Filled_with__c = 'Prescription C',
			Drug_Name__c = 'Prescription C',
			Name = 'Prescription C',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32962
		);
		prescriptionsToInsert.add(testRx3);

		Prescription__c testRx4 = new Prescription__c(
			Account__c = testPatient4.Id,
			// Admission__c = testAdm4.Id,
			Control_Group__c = '4',
			Medication_Filled_with__c = 'Prescription D',
			Drug_Name__c = 'Prescription D',
			Name = 'Prescription D',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32963
		);
		prescriptionsToInsert.add(testRx4);

		Prescription__c testRx5 = new Prescription__c(
			Account__c = testPatient1.Id,
			// Admission__c = testAdm1.Id,
			Control_Group__c = '2',
			Medication_Filled_with__c = 'Prescription E',
			Drug_Name__c = 'Prescription E',
			Name = 'Prescription E',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32964
		);
		prescriptionsToInsert.add(testRx5);

		Prescription__c testRx6 = new Prescription__c(
			Account__c = testPatient2.Id,
			// Admission__c = testAdm2.Id,
			Control_Group__c = '4',
			Medication_Filled_with__c = 'Prescription F',
			Drug_Name__c = 'Prescription F',
			Name = 'Prescription F',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32965
		);
		prescriptionsToInsert.add(testRx6);

		Prescription__c testRx7 = new Prescription__c(
			Account__c = testPatient3.Id,
			// Admission__c = testAdm3.Id,
			Control_Group__c = '4',
			Medication_Filled_with__c = 'Prescription A',
			Drug_Name__c = 'Prescription A',
			Name = 'Prescription A',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32966
		);
		prescriptionsToInsert.add(testRx7);

		Prescription__c testRx8 = new Prescription__c(
			Account__c = testPatient4.Id,
			// Admission__c = testAdm4.Id,
			Control_Group__c = null,
			Medication_Filled_with__c = 'Prescription H',
			Drug_Name__c = 'Prescription H',
			Name = 'Prescription H',
			Presciber__c = testUserPharmacist.Id,
			External_Prescription_Id__c = 32967
		);
		prescriptionsToInsert.add(testRx8);

		insert prescriptionsToInsert;

		// Package Lines
		Package_Line__c pkgLine1 = new Package_Line__c(Package__c = packagesToInsert[0].Id, Prescription__c = prescriptionsToInsert[0].Id, Prescription_Quantity__c = 1);
		packageLinesToInsert.add(pkgLine1);

		Package_Line__c pkgLine2 = new Package_Line__c(Package__c = packagesToInsert[1].Id, Prescription__c = prescriptionsToInsert[1].Id, Prescription_Quantity__c = 2);
		packageLinesToInsert.add(pkgLine2);

		Package_Line__c pkgLine3 = new Package_Line__c(Package__c = packagesToInsert[1].Id, Prescription__c = prescriptionsToInsert[2].Id, Prescription_Quantity__c = 3);
		packageLinesToInsert.add(pkgLine3);

		Package_Line__c pkgLine4 = new Package_Line__c(Package__c = packagesToInsert[3].Id, Prescription__c = prescriptionsToInsert[3].Id, Prescription_Quantity__c = 4);
		packageLinesToInsert.add(pkgLine4);
		insert packageLinesToInsert;

		// for (Prescription__c p : [
		// 	SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c
		// 	FROM Prescription__c
		// ]) {
		// }

		// for (Package__c p : [
		// 	SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c
		// 	FROM Package__c
		// ]) {
		// }

		// for (Package_Line__c p : [
		// 	SELECT Id, Name, Package__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription_Quantity__c, Efficacy__c
		// 	FROM Package_Line__c
		// ]) {
		// }
	}

	@isTest
	static void testInsertUpdateControlGroup_0_1() {
		Account testAccount3 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 3' LIMIT 1];
		Account testAccount4 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 4' LIMIT 1];
		Admission__c testAdmission3 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount3.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription4 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription D'];

		Package__c testPackage3 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount3.Id];
		Package_Line__c testPackageLine4 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount4.Id];

		Test.startTest();

		System.assertEquals(null, testPackage3.Control_Group__c, 'testInsertUpdateControlGroup_0_1: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage3.Id, Prescription__c = testPrescription4.Id, Prescription_Quantity__c = testPackageLine4.Prescription_Quantity__c, Efficacy__c = testPackageLine4.Efficacy__c);

		insert toInsert;

		testPackage3 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount3.Id];

		System.assertEquals('4', testPackage3.Control_Group__c, 'testInsertUpdateControlGroup_0_1: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testInsertUpdateMedications_0_1() {
		Account testAccount3 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 3' LIMIT 1];
		Account testAccount4 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 4' LIMIT 1];
		Admission__c testAdmission3 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount3.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription4 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription D'];

		Package__c testPackage3 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount3.Id];
		Package_Line__c testPackageLine4 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount4.Id];

		Test.startTest();

		System.assertEquals(null, testPackage3.Medications__c, 'testInsertUpdateMedications_0_1: Package__c.Medications__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage3.Id, Prescription__c = testPrescription4.Id, Prescription_Quantity__c = testPackageLine4.Prescription_Quantity__c, Efficacy__c = testPackageLine4.Efficacy__c);

		insert toInsert;

		testPackage3 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount3.Id];

		System.assertEquals('Prescription D', testPackage3.Medications__c, 'testInsertUpdateMedications_0_1: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testInsertUpdateControlGroup_1_2() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription4 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription D'];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];
		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('2', testPackage1.Control_Group__c, 'testInsertUpdateControlGroup_1_2: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage1.Id, Prescription__c = testPrescription4.Id, Prescription_Quantity__c = testPackageLine1.Prescription_Quantity__c, Efficacy__c = testPackageLine1.Efficacy__c);

		insert toInsert;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals('2', testPackage1.Control_Group__c, 'testInsertUpdateControlGroup_1_2: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testInsertUpdateMedications_1_2() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription4 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription D'];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];
		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('Prescription A', testPackage1.Medications__c, 'testInsertUpdateMedications_1_2: Package__c.Medications__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage1.Id, Prescription__c = testPrescription4.Id, Prescription_Quantity__c = testPackageLine1.Prescription_Quantity__c, Efficacy__c = testPackageLine1.Efficacy__c);

		insert toInsert;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals('Prescription A, Prescription D', testPackage1.Medications__c, 'testInsertUpdateMedications_1_2: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testInsertUpdateControlGroup_1_2_Dupes() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription8 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription A' AND Control_Group__c = '4'];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];
		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('2', testPackage1.Control_Group__c, 'testInsertUpdateControlGroup_1_2_Dupes: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage1.Id, Prescription__c = testPrescription8.Id, Prescription_Quantity__c = testPackageLine1.Prescription_Quantity__c, Efficacy__c = testPackageLine1.Efficacy__c);

		insert toInsert;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals('2', testPackage1.Control_Group__c, 'testInsertUpdateControlGroup_1_2_Dupes: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testInsertUpdateMedications_1_2_Dupes() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Prescription__c testPrescription8 = [SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c FROM Prescription__c WHERE Name = 'Prescription A' AND Control_Group__c = '4'];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];
		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('Prescription A', testPackage1.Medications__c, 'testInsertUpdateMedications_1_2_Dupes: Package__c.Medications__c has unexpected value.');

		Package_Line__c toInsert = new Package_Line__c(Package__c = testPackage1.Id, Prescription__c = testPrescription8.Id, Prescription_Quantity__c = testPackageLine1.Prescription_Quantity__c, Efficacy__c = testPackageLine1.Efficacy__c);

		insert toInsert;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals('Prescription A', testPackage1.Medications__c, 'testInsertUpdateMedications_1_2_Dupes: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testDeleteUpdateMedications_1_0() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__c = :testPackage1.Id];

		Test.startTest();

		System.assertEquals('Prescription A', testPackage1.Medications__c, 'testDeleteUpdateMedications_1_0: Package__c.Medications__c has unexpected value.');

		Package_Line__c toDelete = new Package_Line__c(Id = testPackageLine1.Id);

		delete toDelete;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals(null, testPackage1.Medications__c, 'testDeleteUpdateMedications_1_0: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testDeleteUpdateMedications_2_1() {
		Account testAccount2 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 2' LIMIT 1];
		Admission__c testAdmission2 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount2.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Package__c testPackage2 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount2.Id];

		List<Package_Line__c> testPackageLines2 = [SELECT Id, Name, Package__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__c = :testPackage2.Id ORDER BY Prescription__r.Name];

		Test.startTest();

		System.assertEquals('Prescription B, Prescription C', testPackage2.Medications__c, 'testDeleteUpdateMedications_2_1: Package__c.Medications__c has unexpected value.');

		Package_Line__c toDelete = new Package_Line__c(Id = testPackageLines2[0].Id);

		delete toDelete;

		testPackage2 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount2.Id];

		System.assertEquals('Prescription C', testPackage2.Medications__c, 'testDeleteUpdateControlGroup_2_1: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testDeleteUpdateControlGroup_1_0() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Control_Group__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__c = :testPackage1.Id];

		Test.startTest();

		System.assertEquals('2', testPackage1.Control_Group__c, 'testDeleteUpdateControlGroup_1_0: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toDelete = new Package_Line__c(Id = testPackageLine1.Id);

		delete toDelete;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		System.assertEquals(null, testPackage1.Control_Group__c, 'testDeleteUpdateControlGroup_1_0: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testDeleteUpdateControlGroup_2_1() {
		Account testAccount2 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 2' LIMIT 1];
		Admission__c testAdmission2 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount2.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		Package__c testPackage2 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount2.Id];

		List<Package_Line__c> testPackageLines2 = [SELECT Id, Name, Package__c, Package__r.Name, Prescription__c, Prescription__r.Name, Prescription__r.Control_Group__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__c = :testPackage2.Id ORDER BY Prescription__r.Name];

		Test.startTest();

		System.assertEquals('2', testPackage2.Control_Group__c, 'testDeleteUpdateControlGroup_2_1: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toDelete = new Package_Line__c(Id = testPackageLines2[0].Id);

		delete toDelete;

		testPackage2 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount2.Id];

		System.assertEquals('2', testPackage2.Control_Group__c, 'testDeleteUpdateControlGroup_2_1: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testUpdateUpdateControlGroup_1_1() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		// Prescription__c testPrescription8 = [
		// 	SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c
		// 	FROM Prescription__c
		// 	WHERE Name = 'Prescription D' AND Control_Group__c = '2'
		// ];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('2', testPackage1.Control_Group__c, 'testUpdateUpdateControlGroup_1_2: Package__c.Control_Group__c has unexpected value.');

		Package_Line__c toUpdate = new Package_Line__c(Id = testPackageLine1.Id, Prescription_Quantity__c = 0);
		update toUpdate;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		System.assertEquals(null, testPackage1.Control_Group__c, 'testUpdateUpdateControlGroup_1_2: Package__c.Control_Group__c has unexpected value.');

		Test.stopTest();
	}

	@isTest
	static void testUpdateUpdateMedications_1_1() {
		Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Package Line Test Patient 1' LIMIT 1];
		Admission__c testAdmission1 = [SELECT Id, Stage__c FROM Admission__c WHERE Patient_Account__c = :testAccount1.Id LIMIT 1];
		User testPharmacistUser = [SELECT Id FROM User WHERE Email = 'testuserpharmacist@example.com' LIMIT 1];
		// Prescription__c testPrescription8 = [
		// 	SELECT Id, Name, Quantity_to_Package__c, Medication_Filled_with__c, Control_Group__c
		// 	FROM Prescription__c
		// 	WHERE Name = 'Prescription D' AND Control_Group__c = '2'
		// ];

		Package__c testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		Package_Line__c testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		Test.startTest();

		System.assertEquals('Prescription A', testPackage1.Medications__c, 'testUpdateUpdateMedications_1_1: Package__c.Medications__c has unexpected value.');

		Package_Line__c toUpdate = new Package_Line__c(Id = testPackageLine1.Id, Prescription_Quantity__c = 0);
		update toUpdate;

		testPackage1 = [SELECT Id, Name, Patient__c, Patient__r.Name, Start_Date__c, End_Date__c, Control_Group__c, Status__c, Medications__c FROM Package__c WHERE Patient__c = :testAccount1.Id];

		testPackageLine1 = [SELECT Id, Name, Package__c, Package__r.Name, Package__r.Patient__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c, Efficacy__c FROM Package_Line__c WHERE Package__r.Patient__c = :testAccount1.Id];

		System.assertEquals(null, testPackage1.Medications__c, 'testUpdateUpdateMedications_1_1: Package__c.Medications__c has unexpected value.');

		Test.stopTest();
	}
}