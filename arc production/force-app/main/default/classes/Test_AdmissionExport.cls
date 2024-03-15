@isTest
class Test_AdmissionExport 
{

	@testSetup
	static void setupData()
	{
		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
		//patient
		//patient contact
		//admission
		//related contacts
		//List<Contact> cons = new List<Contact>
		//{

		//};
		//insert cons;
		//calls (tasks and patient notes)

	}

	static testmethod void testExport()
	{
		Account testPatient = [SELECT Id, Patient_Contact__r.LastName
								FROM  Account 
								WHERE Patient_Contact__r.Recordtype.Name = 'Patient' 
								LIMIT 1];
		test.startTest();
			AdmissionExport ax = new AdmissionExport(new ApexPages.standardController(testPatient));
			String filename = ax.csvFilename;
			String csv = ax.getCsv();
		test.stopTest();
			system.assertNotEquals(null, csv);
			system.assert(filename.containsIgnoreCase(testPatient.Patient_Contact__r.LastName + ' export'), filename);
	}

}