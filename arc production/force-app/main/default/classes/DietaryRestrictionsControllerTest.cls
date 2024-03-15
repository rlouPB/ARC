@IsTest
public class DietaryRestrictionsControllerTest {
	@TestSetup
	static void setup() {
		Account a = new Account(Name = 'Test account', Dietary_Restrictions__c = 'Muslim (Halal)', Dietary_Allergy_Comments__c = '');
		insert a;
	}

	@IsTest
	static void testGetDietaryRestrictionsData() {
		Account patient = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
		Test.startTest();

		DietaryRestrictionsController.getDietaryRestrictionsData(patient.Id);
		Test.stopTest();
	}

	@IsTest
	static void testGetOptions() {
		Test.startTest();
		DietaryRestrictionsController.getOptions();
		Test.stopTest();
	}
}