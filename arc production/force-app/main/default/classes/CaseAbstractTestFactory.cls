public class CaseAbstractTestFactory {
	//Count of patients created; set to another number if desired
	public static Integer patientCount = 3;

	public static Map<String, Id> rtNameToIdMap = PatientFileTestDataUtil.getRecordTypeInfo();

	public static List<Program__c> testPrograms = new List<Program__c>();

	public static List<Account> patientAccounts = new List<Account>();
	public static List<Contact> patientContacts = new List<Contact>();
	public static List<Admission__c> currentAdmissions = new List<Admission__c>();
	public static List<Admitted_Program__c> admPrograms = new List<Admitted_Program__c>();

	public static void createPatientsForCaseAbstract() {
		createAdmittedPatients();
		addAdmittedPrograms();
	}

	public static void createAdmittedPatients() {
		for (Integer i = 0; i < patientCount; i++) {
			Account newAcc = new Account(RecordtypeId = rtNameToIdMap.get('Patient-Account'), Name = 'Patient ' + i);
			// System.assert(false, 'Account ' + i);
			patientAccounts.add(newAcc);
		}
		insert patientAccounts;
		// System.assertEquals(patientCount, patientAccounts.size(), '32 ' + patientAccounts);

		for (Integer i = 0; i < patientCount; i++) {
			Contact newCon = new Contact(AccountId = patientAccounts[i].Id, FirstName = 'Test', LastName = 'Patient' + i);
			patientContacts.add(newCon);
		}
		insert patientContacts;

		for (Integer i = 0; i < patientCount; i++) {
			Admission__c newAdmission = new Admission__c(Patient_Account__c = patientAccounts[i].Id, Patient_Contact__c = patientContacts[i].Id, Stage__c = 'Waitlist');
			currentAdmissions.add(newAdmission);
		}
		insert currentAdmissions;

		List<Admission__c> queriedAdmissions = [SELECT Id, Stage__c, Patient_Account__c, Patient_Account__r.Current_Admission__c, Patient_Contact__c FROM Admission__c WHERE Id IN :currentAdmissions ORDER BY Patient_Account__r.Name ASC];
		// System.assertEquals(patientCount, queriedAdmissions.size());
		// System.assertEquals(queriedAdmissions[0].Id, queriedAdmissions[0].Patient_Account__r.Current_Admission__c);
	}

	public static void addAdmittedPrograms() {
		for (Integer i = 0; i < patientCount; i++) {
			testPrograms.add(new Program__c(Active__c = true, Category__c = 'Residential', Name = 'Inn Residential Program - ' + i, Parent_Program__c = null, PAS_Allowed__c = true, Product_Code__c = 'IRP-' + i, Short_Name__c = 'IRP - ' + i, Program_Manager__c = Userinfo.getUserId()));
		}
		insert testPrograms;

		// ChangeAdmittedProgramController
		for (Integer i = 0; i < patientCount; i++) {
			Admission__c thisAdm = currentAdmissions[i];
			Admitted_Program__c newAdmProgram = new Admitted_Program__c(Admission__c = thisAdm.Id, Start_Date__c = System.today().addDays(-5), Program_Manager__c = testPrograms[i].Program_Manager__c, Program__c = testPrograms[i].Id);
			admPrograms.add(newAdmProgram);
		}
		insert admPrograms;
	}
}