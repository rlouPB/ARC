@isTest
public class PatientControllerTest {
  @testSetup
  static void setup() {
    Contact c = (Contact) TestFactory_Patient.createSObject(
      new Contact(LastName = 'Test_Patient'),
      true
    );
    Contact accountWithContact = [
      SELECT Id, AccountId
      FROM Contact
      WHERE Id = :c.Id
    ];

    Related_Contact__c relatedContact = (Related_Contact__c) TestFactory_Patient.createSObject(
      new Related_Contact__c(
        Contact__c = c.Id,
        Account__c = accountWithContact.AccountId
      ),
      true
    );
  }
  private static testMethod void createPatientTest() {
    Contact c = [
      SELECT Id, AccountId
      FROM Contact
      WHERE LastName = 'Test_Patient'
    ];
    Contact con = new Contact(
      LastName = 'Test1 Contact1',
      AccountId = c.AccountId
    );

    Contact cons = PatientController.createPatient(con);
    system.assertEquals(
      cons.Id,
      [SELECT Id FROM Contact WHERE Id = :cons.Id]
      .Id
    );
  }
  private static testMethod void saveContactDetailsTest() {
    Contact c = [
      SELECT Id, AccountId
      FROM Contact
      WHERE LastName = 'Test_Patient'
    ];
    Contact con = new Contact(
      LastName = 'Test1 Contact1',
      AccountId = c.AccountId
    );
    Related_Contact__c rc = new Related_Contact__c(Account__c = c.AccountId);

    PatientController.AccountContactWrapper accWrapper = PatientController.saveContactDetails(
      con,
      rc,
      false,
      'Residential'
    );
    system.assertEquals(
      accWrapper.accountId,
      [SELECT Id, Name FROM Account WHERE Id = :accWrapper.accountId]
      .Id
    );
  }
  private static testMethod void getContactRecordTypeDetailsTest() {
    PatientController.RecordTypeInfoWrapper recTypeWrapper = PatientController.getContactRecordTypeDetails();

    List<RecordType> contactRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE sObjectType = 'Contact'
    ];
    List<RecordType> relatedContactRecordTypes = [
      SELECT Id
      FROM RecordType
      WHERE sObjectType = 'Related_Contact__c'
    ];

    system.assertEquals(
      recTypeWrapper.contactRecordTypes.size(),
      contactRecordTypes.size()
    );
    system.assertEquals(
      recTypeWrapper.relatedContactRecordTypes.size(),
      relatedContactRecordTypes.size()
    );
  }
}