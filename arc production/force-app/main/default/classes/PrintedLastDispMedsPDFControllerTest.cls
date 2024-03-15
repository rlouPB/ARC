@isTest public with sharing class PrintedLastDispMedsPDFControllerTest {
    @TestSetup
    static void makeData(){
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();
        List<Contact> patientContactList = new List<Contact> {
            new Contact(LastName = 'TestPatient_0', RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact'))
        };
        insert patientContactList;   
            
        List<Contact> accWithContacts = [SELECT Id, LastName, AccountId  
                                        FROM Contact 
                                        WHERE Id IN :patientContactList 
                                        ORDER BY LastName];
            
        List<Admission__c> admissionList = new List<Admission__c> 
        {
                new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id, 
                            Stage__c='Discharged', Service_Type__c = 'Residential', Discharge_Date__c=Date.Today().addMonths(-12), 
                            Admit_Date__c=Date.Today().addMonths(-15), Psychotherapist__c = Userinfo.getUserId()), //good
                
                new Admission__c(Patient_Account__c = accWithContacts[0].AccountId, Patient_Contact__c = accWithContacts[0].Id,
                             Stage__c = 'Discharged', Service_Type__c = 'Residential', Discharge_Date__c=Date.Today().addDays(-12), 
                             Admit_Date__c=Date.Today().addMonths(-1), Psychotherapist__c = Userinfo.getUserId())
               
                //,new Admission__c(Patient_Account__c = accWithContacts[3].AccountId, Patient_Contact__c = accWithContacts[3].Id, Stage__c='Waitlist') //not a Patient
        };
        insert admissionList;
        
        //create Users
		Profile riggsClinicalProfile = [select Id from Profile where Name = 'RiggsClinical' LIMit 1];
		Profile riggsStaffProfile = [select Id from Profile where Name = 'RiggsStaff' LIMit 1];
		Id staffRtId = recordTypeMap.get('ARC_Staff'+'-'+'Contact');
		Map<String, User> staffUserNameMap;
		User adminNotMe = [SELECT Id 
					 		FROM User 
							WHERE Profile.Name = 'System Administrator' 
									AND IsActive = true 
									AND Id != :Userinfo.getUserId()
							LIMIT 1];
		
        User testUserPharmacist;
        System.runAs(adminNotMe)
		{
			List<User> usersToCreate = new List<User>();
			

			//good: all staff
			usersToCreate.add( new User(
				FirstName = 'AGMTestnonclinicalAllstaff',
				LastName = 'Test',
				ProfileId = riggsStaffProfile.Id,
				Username = 'nonclinicalAllstaff@austenriggs.net.Phase2Dev',
				Email = 'nonclinicalAllstaff@example.com',
				Alias = 'noncl',
				EmailEncodingKey = 'ISO-8859-1',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				TimeZoneSidKey = 'America/New_York',
				IsActive = true 
			));

            testUserPharmacist = new User(
                FirstName = 'testUser',
                LastName = 'Pharmacist',
                ProfileId = riggsStaffProfile.Id,
                Username = 'testuserpharmacist@austenriggs.net.phase2dev',
                Email = 'testuserpharmacist@example.com',
                Alias = 'pharm',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/New_York'
            );
            usersToCreate.add(testUserPharmacist);
            insert usersToCreate;
        }

        Account patient=[SELECT Id, Name,Current_Admission__c, External_Patient_Id__c FROM Account limit 1];
        patient.Current_Admission__c = admissionList[1].Id;
        update patient;
        patient=[SELECT Id, Name,Current_Admission__c, External_Patient_Id__c FROM Account limit 1];

        Account a = (Account)TestFactory_Patient.createSObject(new Account());
        a.Name = 'Test Account';
        insert a;
        
        Contact con = new Contact(LastName = 'Test Contact', AccountId = a.Id);
        insert con;

        Allergy__c[] allergies = new List<Allergy__c>();
        Allergy__c allergy = new Allergy__c();
        allergy.Name__c = 'Accu-Chek Comfort Curve Test';
        allergy.Account__c = patient.Id;
        allergy.Patient_Id__c = 123;
        allergy.Allergy_Type__c = '13148';
        allergy.Adverse_Event_Code__c = '414285001';
        allergy.Reaction__c = '1';
        allergy.Comment__c = 'Test';
        allergy.Archive__c = '0';
        allergy.Onset_Date__c = Date.today();

        allergy.Severity_Code__c = '2';
        allergy.IRIS_Only__c = false;
        allergies.add(allergy);
        // insert allergies;

        Prescription__c[] prescriptionsToInsert = new List<Prescription__c>();
        Prescription__c testRx1 = new Prescription__c(
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
			Account__c = patient.Id,
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
    }
    @isTest private static void unitTest1() {
        Account a = [SELECT Id from Account LIMIT 1];
        PageReference pageRef = Page.PrintedLastDispensedMedsPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('accountId',a.Id);
        PrintedLastDispensedMedsPDFController controller = new PrintedLastDispensedMedsPDFController();
        controller.init();
    }
}