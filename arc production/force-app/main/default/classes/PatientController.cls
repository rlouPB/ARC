public with sharing class PatientController {
  @AuraEnabled
  public static Contact createPatient(Contact patient) {
    String fullName = patient.FirstName + ' ' + patient.LastName;
    Account patientAccount = new Account(Name = fullName);
    insert patientAccount;

    patient.AccountId = patientAccount.Id;
    insert patient;

    return [SELECT Id, Name FROM Contact WHERE Id = :patient.Id];
  }
  @AuraEnabled
  public static AccountContactWrapper saveContactDetails(
    Contact con,
    Related_Contact__c relatedContact,
    Boolean hasAccount,
    String serviceType
  ) {
    Id accPatientRtId = Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get('Patient')
      .getRecordtypeId();
    Id conPatientRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
      .get('Patient')
      .getRecordtypeId();
    Id rcPatientRtId = Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName()
      .get('Patient')
      .getRecordtypeId();

    Account patientAccount = new Account(
      RecordtypeId = accPatientRtId,
      Name = 'patient',
      Service_Type_Text__c = serviceType
    );
    insert patientAccount;

    con.RecordTypeId = conPatientRtId;
    con.AccountId = patientAccount.Id;

    if (con.MailingCountry == null || con.MailingCountry == '')
      con.MailingCountry = 'United States';
    if (con.OtherCountry == null || con.OtherCountry == '')
      con.OtherCountry = 'United States';
    insert con;

    patientAccount.Patient_Contact__c = con.Id;
    update patientAccount;

    if (relatedContact != null) {
      relatedContact.Contact__c = con.Id;
      relatedContact.Account__c = patientAccount.Id;
      relatedContact.RecordtypeId = rcPatientRtId;
      relatedContact.Role__c = 'Patient';
      insert relatedContact;
    }

    List<Contact> cons = new List<Contact>(
      [
        SELECT
          Id,
          Name,
          AccountId,
          Account.Name,
          Account.Current_Admission__r.Service_Type__c
        FROM Contact
        WHERE Id = :con.Id
      ]
    );

    return new AccountContactWrapper(
      cons[0].AccountId,
      cons[0].Id,
      cons[0].Name,
      cons[0].Account.Name,
      cons[0].Account.Current_Admission__r.Service_Type__c
    );
  }
  @AuraEnabled
  public static RecordTypeInfoWrapper getContactRecordTypeDetails() {
    List<RecordType> contactRecordTypes = [
      SELECT Id, DeveloperName, Name
      FROM RecordType
      WHERE sObjectType = 'Contact'
    ];
    List<RecordType> relatedContactRecordTypes = [
      SELECT Id, DeveloperName, Name
      FROM RecordType
      WHERE sObjectType = 'Related_Contact__c'
    ];

    return new RecordTypeInfoWrapper(
      contactRecordTypes,
      relatedContactRecordTypes
    );
  }

  public class RecordTypeInfoWrapper {
    @AuraEnabled
    public List<RecordType> contactRecordTypes;
    @AuraEnabled
    public List<RecordType> relatedContactRecordTypes;

    public RecordTypeInfoWrapper(
      List<RecordType> contactRecordTypes,
      List<RecordType> relatedContactRecordTypes
    ) {
      this.contactRecordTypes = contactRecordTypes;
      this.relatedContactRecordTypes = relatedContactRecordTypes;
    }
  }

  public class AccountContactWrapper {
    @AuraEnabled
    public String accountId;
    @AuraEnabled
    public String contactId;
    @AuraEnabled
    public String accountName;
    @AuraEnabled
    public String contactName;
    @AuraEnabled
    public String serviceType;

    public AccountContactWrapper(
      String accountId,
      String contactId,
      String accountName,
      String contactName,
      String serviceType
    ) {
      this.accountId = accountId;
      this.contactId = contactId;
      this.accountName = accountName;
      this.contactName = contactName;
      this.serviceType = serviceType;
    }
  }
}