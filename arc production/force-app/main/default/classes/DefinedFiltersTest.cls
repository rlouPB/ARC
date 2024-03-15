@isTest
public class DefinedFiltersTest {

	@TestSetup
	static void makeData(){
		List<Account> accountsToInsert = new List<Account>();
		Account testAccount1 = new Account(
			Name = 'Test Account 1'
		);
		testAccount1 = (Account)TestFactory_Patient.createSObject(testAccount1);
		accountsToInsert.add(testAccount1);
		insert accountsToInsert;

		List<Contact> contactsToInsert = new List<Contact>();
		Contact testContact1 = new Contact(
			FirstName = 'Test',
			LastName = 'Contact 1'
		);
		testContact1 = (Contact)TestFactory_Patient.createSObject(testContact1);
		contactsToInsert.add(testContact1);
		insert contactsToInsert;

        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

		List<Patient_Note__c> notesToInsert = new List<Patient_Note__c>();
		Patient_Note__c testNote1 = new Patient_Note__c(
			Account__c = testAccount1.ID,
			Contact__c = testContact1.ID,
			Consultation_Completed_Date__c = Date.newInstance(2019, 1, 1)
		);
		notesToInsert.add(testNote1);
		Patient_Note__c testNote2 = new Patient_Note__c(
			Account__c = testAccount1.ID,
			Contact__c = testContact1.ID,
			Consultation_Completed_Date__c = Date.newInstance(2019, 1, 15)
		);
		notesToInsert.add(testNote2);
		insert notesToInsert;
	}

	@isTest
	static void testCompareEquals() {
		List<Filter_Expression__mdt> filters = [SELECT Expression__c
												FROM Filter_Expression__mdt
												WHERE DeveloperName = 'Test_Compare_Function_Equals'];
		Patient_Note__c note = [SELECT Consultation_Completed_Date__c
								FROM Patient_Note__c
								WHERE Consultation_Completed_Date__c = :Date.newInstance(2019, 1, 1)];
		Boolean response;

		Test.startTest();
		DefinedFilters testInstance = new DefinedFilters(filters);

		for (DefinedFilters.Expression currentExp: testInstance.expressionList) {
			response = currentExp.includes(note);
		}
		System.assertEquals(true, response);
		Test.stopTest();
	}
	static testmethod void testCompareNotEqual(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '!=';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}

	static testmethod void testCompareLessThan(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '<';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}


	static testmethod void testCompareContains(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= 'contains';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='Nana'));
	}

	static testmethod void testCompareNotContains(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '!contains';
		ex.value='e';
		ex.fieldName='Name';
		ex.includes(new Account(Name='Nana'));
	}
	static testmethod void testCompareStatsWith(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= 'startsWith';
		ex.value='e';
		ex.fieldName='Name';
		ex.includes(new Account(Name='Nana'));
	}

	static testmethod void testCompareEndsWith(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= 'endsWith';
		ex.value='e';
		ex.fieldName='Name';
		ex.includes(new Account(Name='Nana'));
	}

	static testmethod void testCompareGreatedThen(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '>';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}
	static testmethod void testCompareLessOrEqualTo(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '<=';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}
	static testmethod void testCompareGreaterOrEqualTo(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '>=';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}
	static testmethod void testCompareOr(){
		DefinedFilters.Expression ex = new DefinedFilters.Expression();
		ex.function = 'compare';
		ex.operator= '>=';
		ex.value='a';
		ex.fieldName='Name';
		ex.includes(new Account(Name='a'));
	}
}