@isTest
public class SDocsCallableDispensingTest {
	@TestSetup
	static void initiateData() {
		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(LastName = 'Test_Patient'), true);
		Contact accountWithContact = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id];

		Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(new Admission__c(Patient_Account__c = accountWithContact.AccountId, Patient_Contact__c = c.Id, Team__c = 'A'), true);
		disco__Form_Template__c discoFormTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(new disco__Form_Template__c(Name = 'Admissions Screening Checklist 1', disco__Status__c = 'In Use'), true);

		List<Account> accounts = [SELECT Id, Name, Current_Admission__c FROM Account WHERE Id = :accountWithContact.AccountId];
		accounts[0].Current_Admission__c = admission.Id;
		upsert accounts;

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{ new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id) };
		insert relatedContacts;

		List<disco__Form__c> discoForms = new List<disco__Form__c>{ new disco__Form__c(disco__Form_Account__c = accounts[0].Id, Related_Contact__c = relatedContacts[0].Id, disco__Form_Template__c = discoFormTemplate.Id, disco__Archived__c = true, Admission__c = admission.Id, disco__Form_Contact__c = c.Id, disco__Mobile_ID__c = '123') };
		insert discoForms;

		disco__Question__c discoQuestions = new disco__Question__c(disco__Label__c = 'Medication & Format');
		insert discoQuestions;

		disco__Answer__c discoAnswers = new disco__Answer__c(disco__Form__c = discoForms[0].Id, disco__Question__c = discoQuestions.Id);
		insert discoAnswers;

		SDocCallableParent__c request = new SDocCallableParent__c();
		insert request;

		Package__c pckg = new Package__c(Patient__c = accounts[0].Id, Form__c = discoForms[0].Id, SDocCallableParent__c = request.Id);
		insert pckg;
	}

	@isTest
	private static void getPackagesAsSDocTableTest() {
		SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];

		SDocsCallableDispensing diapense = new SDocsCallableDispensing();
		diapense.getPackagesAsSDocTable(request.Id);
	}

	@isTest
	private static void getPackagesAsSDocTableMatrixTest() {
		SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];

		SDocsCallableDispensing diapense = new SDocsCallableDispensing();
		diapense.getPackagesAsSDocTableMatrix(request.Id);
	}

	@isTest
	private static void getPackagesAsSDocTableQualityTest() {
		List<disco__Question__c> question = [SELECT Id, disco__Label__c FROM disco__Question__c LIMIT 1];
		question[0].disco__Label__c = 'Quantity Dispensed';
		update question;

		SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];
		SDocsCallableDispensing diapense = new SDocsCallableDispensing();
		diapense.getPackagesAsSDocTable(request.Id);
	}

	@isTest
	private static void getPackagesAsSDocTableMatrixQualityTest() {
		List<disco__Question__c> question = [SELECT Id, disco__Label__c FROM disco__Question__c LIMIT 1];
		question[0].disco__Label__c = 'Quantity Dispensed';
		update question;

		SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];
		SDocsCallableDispensing diapense = new SDocsCallableDispensing();
		diapense.getPackagesAsSDocTableMatrix(request.Id);
	}

	@isTest
	private static void callTest() {
		SDocCallableParent__c request = [SELECT Id FROM SDocCallableParent__c LIMIT 1];

		Map<String, Object> callMap = new Map<String, Object>{ request.Id => request.Id };
		SDocsCallableDispensing dispense = new SDocsCallableDispensing();
		dispense.call('getPackagesAsSDocTable', callMap);
	}
}