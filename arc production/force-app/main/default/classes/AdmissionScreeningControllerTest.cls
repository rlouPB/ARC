@isTest
public class AdmissionScreeningControllerTest {
  @testSetup
  public static void setup() {
    Contact c = (Contact) TestFactory_Patient.createSObject(
      new Contact(LastName = 'Test_Patient'),
      true
    );
    Contact accountWithContact = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Id = :c.Id
    ];

    Admission__c admission = (Admission__c) TestFactory_Patient.createSObject(
      new Admission__c(
        Patient_Account__c = accountWithContact.AccountId,
        Patient_Contact__c = c.Id,
        Team__c = 'A'
      ),
      true
    );
    admission.Service_Type__c = 'Residential';
    update admission;

    disco__Form_Template__c discoFormTemplate = (disco__Form_Template__c) TestFactory_Patient.createSObject(
      new disco__Form_Template__c(
        Name = 'Admissions Screening Checklist 1',
        disco__Status__c = 'In Use'
      ),
      true
    );

    List<Account> accounts = [
      SELECT
        Id,
        Name,
        Current_Admission__c,
        Current_Admission__r.Service_Type__c
      FROM Account
      WHERE Id = :accountWithContact.AccountId
    ];
    accounts[0].Current_Admission__c = admission.Id;
    upsert accounts;

    List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>{
      new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id),
      new Related_Contact__c(Contact__c = c.Id, Account__c = accounts[0].Id)
    };
    insert relatedContacts;

    List<disco__Form__c> discoForms = new List<disco__Form__c>{
      new disco__Form__c(
        disco__Form_Account__c = accounts[0].Id,
        Related_Contact__c = relatedContacts[0].Id,
        disco__Form_Template__c = discoFormTemplate.Id,
        disco__Archived__c = true,
        Admission__c = admission.Id,
        disco__Form_Contact__c = c.Id,
        disco__Mobile_ID__c = '123'
      ),
      new disco__Form__c(
        disco__Form_Account__c = accounts[0].Id,
        Related_Contact__c = relatedContacts[1].Id,
        disco__Form_Template__c = discoFormTemplate.Id,
        disco__Archived__c = true,
        Admission__c = admission.Id,
        disco__Form_Contact__c = c.Id,
        disco__Mobile_ID__c = '1231'
      )
    };
    insert discoForms;

    List<disco__Question__c> discoQuestions = new List<disco__Question__c>{
      new disco__Question__c(
        disco__Form_Template__c = discoFormTemplate.Id,
        disco__Label__c = 'test',
        disco__Type__c = 'Picklist',
        Selected_Question_Order__c = 1,
        disco__Order__c = 1,
        Alternate_Question_Order__c = 1
      )
    };
    insert discoQuestions;

    List<disco__Answer__c> discoAnswers = new List<disco__Answer__c>{
      new disco__Answer__c(
        disco__Answer__c = 'test',
        disco__Form__c = discoForms[1].Id,
        disco__Question__c = discoQuestions[0].Id
      ),
      new disco__Answer__c(
        disco__Answer__c = 'test',
        disco__Form__c = discoForms[0].Id,
        disco__Question__c = discoQuestions[0].Id
      ),
      new disco__Answer__c(
        disco__Form__c = discoForms[0].Id,
        disco__Question__c = discoQuestions[0].Id
      ),
      new disco__Answer__c(
        disco__Answer__c = 'test12',
        disco__Form__c = discoForms[0].Id,
        disco__Question__c = discoQuestions[0].Id
      ),
      new disco__Answer__c(
        disco__Form__c = discoForms[0].Id,
        disco__Question__c = discoQuestions[0].Id
      )
    };
    insert discoAnswers;
  }
  private static testMethod void getQuestionsTest() {
    Contact c = [
      SELECT
        Id,
        AccountId,
        Account.Current_Admission__c,
        Account.Current_Admission__r.Service_Type__c
      FROM Contact
      WHERE LastName = 'Test_Patient'
    ];
    test.startTest();
    AdmissionScreeningController.QuestionSetWrapper admissQues = AdmissionScreeningController.getQuestions(
      c.AccountId,
      c.Account.Current_Admission__c,
      c.Account.Current_Admission__r.Service_Type__c
    );
    test.stopTest();

    System.assertEquals(AdmissQues.relatedContacts.size(), 2);
    System.assertEquals(AdmissQues.selectedQuestions.size(), 1);
    System.assertEquals(AdmissQues.allQuestions.size(), 1);
  }
  private static testMethod void getQuestionsTestWithEmpty() {
    Contact c = (Contact) TestFactory_Patient.createSObject(
      new Contact(LastName = 'Test_Patient'),
      true
    );
    Contact accountWithContact = [
      SELECT
        Id,
        AccountId,
        Account.Current_Admission__c,
        Account.Current_Admission__r.Service_Type__c
      FROM Contact
      WHERE Id = :c.Id
    ];

    List<Account> acc = [SELECT Id FROM Account WHERE Name = 'Test Account2'];
    AdmissionScreeningController.QuestionSetWrapper admissQues = AdmissionScreeningController.getQuestions(
      accountWithContact.AccountId,
      c.Account.Current_Admission__c,
      c.Account.Current_Admission__r.Service_Type__c
    );

    System.assertEquals(AdmissQues.relatedContacts.size(), 0);
    System.assertEquals(AdmissQues.selectedQuestions.size(), 0);
    System.assertEquals(AdmissQues.allQuestions.size(), 0);
  }
}