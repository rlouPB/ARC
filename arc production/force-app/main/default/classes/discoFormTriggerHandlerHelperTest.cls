@IsTest
public class discoFormTriggerHandlerHelperTest {
    @testsetup static void setup(){
        Account a = new Account(Name = 'test patietnm');
            insert a;

            Contact c = new Contact(FirstName = 'test', LastName = 'patient contact', AccountId = a.Id);
            insert c;

        List<Admission__c> admissionList = new List<Admission__c>{
            new Admission__c(
				Patient_Account__c = c.AccountId,
				Patient_Contact__c = c.Id,
				Stage__c = 'Open Inquiry'
			),
			new Admission__c(
				Patient_Account__c = c.AccountId,
				Patient_Contact__c = c.Id,
				Stage__c = 'Open Inquiry'
			),
			new Admission__c(
				Patient_Account__c = c.AccountId,
				Patient_Contact__c = c.Id,
				Stage__c = 'Open Inquiry'
			)

		};
		insert admissionList;
    }

    @IsTest static void test(){
        List<Admission__c> admissionList = [SELECT Id FROM Admission__c ORDER BY CreatedDate DESC LIMIT 3];

        discoFormTriggerHandlerHelper.updateAdmissionVisitorClinicalField(admissionList);
    }
}