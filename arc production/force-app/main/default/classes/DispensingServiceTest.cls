@isTest
public with sharing class DispensingServiceTest {
	@TestSetup
	static void setup() {
		Account a = (Account) TestFactory_Patient.createSObject(new Account());
		a.Name = 'Test Account';
		insert a;

		Contact con = new Contact(LastName = 'Test Contact', AccountId = a.Id);
		insert con;

		Admission__c adm = new Admission__c(Admit_Date__c = system.today(), Stage__c = 'Admitted', Psychotherapist__c = System.UserInfo.getUserId(), Patient_Account__c = a.Id);
		insert adm;

		a.Current_Admission__c = adm.Id;
		update a;

		disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer');
		insert discoFormTemplate;

		List<Patient_Note__c> notes = new List<Patient_Note__c>{ new Patient_Note__c(Account__c = a.Id, Status__c = 'Draft', Type__c = 'Away Medication Order'), new Patient_Note__c(Account__c = a.Id, Status__c = 'Draft', Type__c = 'Medication Self Administration (MSA) Order'), new Patient_Note__c(Account__c = a.Id, Status__c = 'Finalized', Finalized_Date_Time__c = System.now(), Type__c = 'Medication Self Administration (MSA) Order'), new Patient_Note__c(Account__c = a.Id, Pharmacy_Complete__c = false, Status__c = 'Finalized', Type__c = 'Medication Self Administration (MSA) Order') };
		insert notes;

		Prescription__c prep = new Prescription__c(Account__c = a.Id, Dispensed__c = true, Status__c = 'Active Pending Fill', External_Prescription_Id__c = 123456);
		insert prep;
		disco__Form_Template__c[] formTemplates = new List<disco__Form_Template__c>{ new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'), new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use') };
		insert formTemplates;

		Package__c pckg = new Package__c(Patient__c = a.Id);
		insert pckg;

		Package_Line__c pckgLine = new Package_Line__c(Package__c = pckg.Id);
		insert pckgLine;
		/*disco__Form__c[] forms = new disco__Form__c[]{
            new disco__Form__c(Signature_Attached_Later__c = TRUE, disco__Status__c = 'In Use', Template_Doc_Name__c = 'Patient_Certification_of_Dispensed')
        };
        insert forms;*/
	}

	@isTest
	public static void test() {
		Account a = [SELECT Id FROM Account];
		Package__c pckg = [SELECT Id FROM Package__c];
		Package__c pckg2 = new Package__c(Patient__c = a.Id);
		Prescription__c prescrib = [SELECT Id FROM Prescription__c];
		DispensingService.getPatients();
		// DispensingService.getDraftAwayOrdersForPatient(a.Id);
		// DispensingService.getDraftMSAOrdersForPatient(a.Id);
		DispensingService.getPrescriptions(a.Id);
		DispensingService.getOrders(a.Id);
		DispensingService.getOrdersByAccountId(new Set<Id>{ a.Id });
		DispensingService.getPrescription(prescrib.Id);
		//DispensingService.getControlledSubstanceFormsToAttach();
		DispensingService.getPrescriptionsToProcess();
		DispensingService.getDispensedPrescriptions(a.Id);
		DispensingService.getPatientNoteOrdersToProcess();
		DispensingService.getPackages(a.Id);
		DispensingService.getPackage(pckg.Id);
		DispensingService.getPackageLines(pckg.Id);
		DispensingService.getDispensedPackages(a.Id);
		DispensingService.cleardDispensedPrescriptions(a.Id);
		DispensingService.clearDispensedPrescriptionsForPrescriptions(new List<SObject>{ prescrib });
		DispensingService.clearDispensedPackages(a.Id);
		DispensingService.finalizePrescriptions(new List<Id>{ prescrib.Id }, a.Id);
		DispensingService.dispensePrescriptions(new List<Id>{ prescrib.Id }, a.Id);
		DispensingService.dispensePackages(new List<Id>{ pckg.Id }, a.Id);
		DispensingService.printPackages(new List<Id>{ pckg.Id });
		DispensingService.packageAndPrintForPatients(new List<Id>{a.Id}, Date.today(), Date.today().addDays(15), DateTime.now().addDays(5));
		DispensingService.finalizePackages(new List<Id>{ pckg.Id }, a.Id);
		DispensingService.cancelPackages(new List<Id>{ pckg.Id });
		DispensingService.getFieldDefinitions('Account', new List<String>{ 'Name' });
		DispensingService.insertPackage(pckg2, new List<SObject>{ prescrib });
		DispensingService.getAccounts();
		DispensingService.getMARLinesForMaxDosageValidationForPrescription(prescrib.Id);
	}

	@isTest
	public static void test2() {
		Account a = [SELECT Id FROM Account];
		Package__c pckg = [SELECT Id FROM Package__c];
		Package__c pckg2 = new Package__c(Patient__c = a.Id);
		Prescription__c prescrib = [SELECT Id FROM Prescription__c];

		DispensingService.dispensePrescriptions(new List<Id>{ prescrib.Id }, a.Id);
		DispensingService.finalizePrescriptions(new List<Id>{ prescrib.Id }, a.Id);
		Map<Id, List<Medication_Administration_Line__c>> marLinesByPrescriptionId = DispensingService.getDispensingHistoryForPrescriptions(new List<Id>{ prescrib.Id }, Date.today(), Date.today().addDays(15));
		System.debug('marLinesByPrescriptionId : ' + marLinesByPrescriptionId);
	}
}