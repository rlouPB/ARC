@IsTest
public class ChangeAdmittedProgramControllerTest {
	ChangeAdmittedProgramController capc = new ChangeAdmittedProgramController();
	public static Account getAccount() {
		return [SELECT id, Current_Admission__c, Current_Admission__r.Current_Admitted_Program__c FROM Account LIMIT 1];
	}
	@TestSetup
	public static void setup() {
		PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
		Program__c p = new Program__c(Short_Name__c = 'test');
		insert p;
		Admitted_Program__c ap = new Admitted_Program__c(Program__c = p.Id, start_date__c = system.today());
		insert ap;
		Account a = (Account) TestFactory_Patient.createSObject(new Account());
		a.Name = 'Test Account';
		insert a;
		Admission__c adm = new Admission__c(Admit_Date__c = system.today(), Stage__c = 'Admitted', Psychotherapist__c = System.UserInfo.getUserId(), Patient_Account__c = a.Id, Current_Admitted_Program__c = ap.Id);
		insert adm;
		a.Current_Admission__c = adm.Id;
		update a;
		//update new Admission__c(id=patient.current_admission__c, current_admitted_program__c=ap.id);
	}

	public static testMethod void testLoading() {
		Account acc = getAccount();
		ChangeAdmittedProgramController.PatientAccount patient = ChangeAdmittedProgramController.getAccountInfo(acc.Id);

		system.assertNotEquals(null, patient);
	}
	public static testMethod void testChangeProgram() {
		Account acc = getAccount();
		program__c ap = [SELECT id FROM program__c LIMIT 1];
		Admitted_Program__c apg = [SELECT Id, Program__c, Name, Admission__c, Account__c FROM Admitted_Program__c LIMIT 1];
		apg.Id = null;
		ChangeAdmittedProgramController.SaveParams params = new ChangeAdmittedProgramController.SaveParams();
		params.programId = ap.Id;
		params.programManagerId = userinfo.getuserid();
		params.chosenFunction = 'Change Program';
		params.accountId = acc.Id;
		params.newAdmittedProgram = apg;
		ChangeAdmittedProgramController.Response resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));
	}

	public static testMethod void testNewStatus() {
		Account acc = getAccount();
		ChangeAdmittedProgramController.SaveParams params = new ChangeAdmittedProgramController.SaveParams();
		params.status = Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()[0].getValue();
		params.chosenFunction = 'New Status';
		params.accountId = acc.Id;
		ChangeAdmittedProgramController.Response resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));
		ChangeAdmittedProgramController.SaveParams params2 = new ChangeAdmittedProgramController.SaveParams();

		Admitted_Program_Status__c aps = new Admitted_Program_Status__c(Admitted_Program__c = acc.Current_Admission__r.Current_Admitted_Program__c, Start_Date_Time__c = system.now(), Status__c = params.status);
		insert aps;
		params2.admittedProgramStatusRecord = aps;
		params2.status = Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()[0].getValue();
		params2.chosenFunction = 'New Status';
		params2.accountId = acc.Id;
		ChangeAdmittedProgramController.Response resp2 = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params2));
	}

	public static testMethod void testUpdateStatus() {
		Account acc = getAccount();
		string status = Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()[0].getValue();
		Admitted_Program_Status__c aps = new Admitted_Program_Status__c(Admitted_Program__c = acc.Current_Admission__r.Current_Admitted_Program__c, Start_Date_Time__c = system.now(), End_Date_Time__c = date.today().addMonths(1), Status__c = status);
		insert aps;

		ChangeAdmittedProgramController.SaveParams params = new ChangeAdmittedProgramController.SaveParams();
		params.statusId = aps.Id;
		params.chosenFunction = 'Update Status';
		params.accountId = acc.Id;
		params.endDateTime = system.now();
		params.admittedProgramStatusRecord = aps;
		ChangeAdmittedProgramController.Response resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));

		//
		ChangeAdmittedProgramController.SaveParams params2 = new ChangeAdmittedProgramController.SaveParams();
		params2.statusId = aps.Id;
		params2.chosenFunction = 'Update Status';
		params2.accountId = acc.Id;
		params2.endDateTime = system.now();
		params2.admittedProgramStatusRecord = aps;
		ChangeAdmittedProgramController.Response resp2 = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params2));

		//'Change Program'
		ChangeAdmittedProgramController.SaveParams params3 = new ChangeAdmittedProgramController.SaveParams();
		params3.statusId = aps.Id;
		params3.chosenFunction = 'Dummy';
		params3.accountId = acc.Id;
		params3.endDateTime = system.now();
		params3.admittedProgramStatusRecord = aps;
		ChangeAdmittedProgramController.Response resp3 = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params3));
	}

	public static testMethod void testChangeProgramValidations() {
		Account acc = getAccount();
		ChangeAdmittedProgramController.SaveParams params = new ChangeAdmittedProgramController.SaveParams();
		ChangeAdmittedProgramController.Response resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));

		//NoProgram
		params = new ChangeAdmittedProgramController.SaveParams();
		params.chosenFunction = 'Change Program';
		params.accountId = acc.Id;
		resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));

		//NoProgram Manger Selected
		Program__c p = new Program__c(Short_Name__c = 'test');
		insert p;
		params = new ChangeAdmittedProgramController.SaveParams();
		params.chosenFunction = 'Change Program';
		params.accountId = acc.Id;
		params.programId = p.Id;
		resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));

		//Current Admission doesn't exists
		if (acc.current_admission__c != null) {
			database.delete(acc.current_admission__c);
		}
		p.Program_Manager__c = userinfo.getuserid();
		update p;
		params = new ChangeAdmittedProgramController.SaveParams();
		params.chosenFunction = 'Change Program';
		params.accountId = acc.Id;
		params.programId = p.Id;
		params.programManagerId = userinfo.getuserid();
		resp = ChangeAdmittedProgramController.saveRecord(JSON.serialize(params));
		resp = ChangeAdmittedProgramController.saveRecord(null);
	}
}