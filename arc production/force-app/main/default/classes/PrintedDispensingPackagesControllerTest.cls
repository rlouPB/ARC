@isTest with sharing class PrintedDispensingPackagesControllerTest {
   
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
            insert usersToCreate;
        }

        Account patient=[SELECT Id, Name,Current_Admission__c FROM Account limit 1];
        patient.Current_Admission__c = admissionList[1].Id;
        update patient;
        patient=[SELECT Id, Name,Current_Admission__c FROM Account limit 1];

        Account a = (Account)TestFactory_Patient.createSObject(new Account());
        a.Name = 'Test Account';
        insert a;
        
        Contact con = new Contact(LastName = 'Test Contact', AccountId = a.Id);
        insert con;
        
        List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
            new Related_Contact__c(Contact__c  = con.Id, Account__c = a.Id)
        };
        insert relatedContacts;
        
        Admission__c adm = new Admission__c(
            Admit_Date__c=system.today(),
            Stage__c = 'Admitted',
            Psychotherapist__c = System.UserInfo.getUserId(),
            Patient_Account__c = a.Id
        );
        insert adm;
        
        disco__Form_Template__c[] formTemplates = new disco__Form_Template__c[]{
            new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use')
        };
        insert formTemplates;
        
        Package__c pckgd = new Package__c(Start_Date__c =system.today(), End_Date__c = date.today() , Control_Group__c = '2');
        insert pckgd;
        
        List<disco__Form__c> discoForms = new List<disco__Form__c>{
            new disco__Form__c(
                disco__Form_Account__c = a.Id,
                Related_Contact__c = relatedContacts[0].Id,
                disco__Form_Template__c = formTemplates[0].Id,
                disco__Archived__c = true,
                Admission__c = adm.Id,
                disco__Form_Contact__c = con.Id,
                disco__Mobile_ID__c = '123',
                package__c = pckgd.Id
            )
        };
        insert discoForms;
        
        List<disco__Section__c> discoSections = new List<disco__Section__c>{
            new disco__Section__c(
                Name = 'Return',
                disco__Form_Template__c = formTemplates[0].Id
            ),
                new disco__Section__c(
                Name = 'Package Details',
                disco__Form_Template__c = formTemplates[0].Id
            ),
			new disco__Section__c(
                Name = 'Return',
                disco__Form_Template__c = formTemplates[1].Id
            ),
                new disco__Section__c(
                Name = 'Package Details',
                disco__Form_Template__c = formTemplates[1].Id
            )
        };
        insert discoSections;
        
        List<disco__Question__c> discoQuestions = new List<disco__Question__c>{
            new disco__Question__c(
                disco__Label__c = 'Medication & Format'
            ),
            new disco__Question__c(
                disco__Label__c = 'Quantity Dispensed'
            ),
            new disco__Question__c(
                disco__Type__c = 'Field Link',
                disco__Label__c = 'Medication & Format',
                disco__Section__c = discoSections[0].Id
            ),
                new disco__Question__c(
                disco__Type__c = 'Free Text',
                    disco__Label__c = 'Medication & Format',
                disco__Section__c = discoSections[1].Id
            )
        };
        insert discoQuestions;
        
        List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{
            new disco__Answer__c(
                disco__Form__c = discoForms[0].Id,
                disco__Question__c = discoQuestions[0].Id,
                disco__Answer__c = 'Test'
            ),
            new disco__Answer__c(
                disco__Form__c = discoForms[0].Id,
                disco__Question__c = discoQuestions[1].Id
            ),
            new disco__Answer__c(
                disco__Form__c = discoForms[0].Id,
                disco__Question__c = discoQuestions[2].Id
            ),
         
                new disco__Answer__c(
                disco__Form__c = discoForms[0].Id,
                disco__Question__c = discoQuestions[3].Id
            ),
                new disco__Answer__c(
                disco__Form__c = discoForms[0].Id,
                disco__Question__c = discoQuestions[0].Id
            )
        };
        insert discoAnswers;
        
        SDocCallableParent__c request = new SDocCallableParent__c();
        insert request;
        
        Package__c pckg = new Package__c(Patient__c = a.Id, Form__c = discoForms[0].Id, SDocCallableParent__c = request.Id);
        insert pckg;
    }
    @isTest private static void unitTest1() {
        SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];
        
        PageReference pageRef = Page.PrintedDispensingPackagesPDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ids',request.Id);
        PrintedDispensingPackagesController controller = new PrintedDispensingPackagesController();
        controller.init();
    }
}