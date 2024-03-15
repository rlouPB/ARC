@IsTest
public without sharing class ListAssignedCliniciansTest {
    @TestSetup
    public static void setup(){
        Account a = new account(
            Name='ParentName',
            recordtypeid = RecordTypeHelper.getIdByName('Account','Patient')
        );
        insert a;
        insert new Assigned_Clinician__c[]{
            new Assigned_Clinician__c(
                Patient_Account__c=a.Id,
                Start_Date__c = system.today(),
                User__c = userinfo.getuserid()
            ),
            new Assigned_Clinician__c(
                Patient_Account__c=a.Id,
                Start_Date__c = system.today().addDays(-10),
                End_Date__c = system.today().addDays(-5),
                User__c = userinfo.getuserid()
            )
        };
        Contact patientContact = new Contact(FirstName='Test',LastName='Test',AccountId=a.Id);
        insert patientContact;

        Admission__c adm = new Admission__c(
            Admit_Date__c=system.today(),
            Patient_Contact__c=patientContact.Id,
            Patient_Account__c = a.Id
        );
        insert adm;

        update new Account(Id=a.Id,Current_Admission__c=adm.Id);

    }

    static Account getPatient(){
        return [Select Id, Name,Current_Admission__c from Account limit 1];
    }
    public static testmethod void testAssignedCliniciansGetMethods(){
        Account p = getPatient();
        test.startTest();
        system.assertEquals(2,ListAssignedClinicians.getAssignedClinicians(p.Id,'active').size());
        system.assertEquals(3,ListAssignedClinicians.getAssignedClinicians(p.Id,'all').size());
        system.assertNotEquals(null,ListAssignedClinicians.getAssignedClinicianInstance());
        system.assertNotEquals(Null, ListAssignedClinicians.getAdmissionID(p.Id));
        test.stopTest();
    }

    public static testmethod void testAssignedCliniciansSaveMethods(){
        Account p = getPatient();
        test.startTest();
        integer count = [Select count() from Assigned_Clinician__c];
        ListAssignedClinicians.JSONCTMParser j = new ListAssignedClinicians.JSONCTMParser();
        date d = system.today();
        j.startDate = d.Year() +'-'+d.month()+'-'+d.day();
        j.userID = userinfo.getuserid();
        j.role = ListAssignedClinicians.getRoles()[0];
        ListAssignedClinicians.saveAssignedClinicians(JSON.serialize( new ListAssignedClinicians.JSONCTMParser[]{j}), p.Current_Admission__c, p.Id);
        test.stopTest();
        system.assertNotEquals(count,[Select count() from Assigned_Clinician__c]);
    }

    public static testmethod void testActiveAssignedClinicians(){
        Account p = getPatient();
        test.startTest();
        integer count = [Select count() from Assigned_Clinician__c];
        ListAssignedClinicians.JSONCTMParser j = new ListAssignedClinicians.JSONCTMParser();
        date d = system.today();
        j.startDate = d.Year() +'-'+d.month()+'-'+d.day();
        j.userID = userinfo.getuserid();
        j.role = 'Substance Use Counselor';
       ListAssignedClinicians.saveAssignedClinicians(JSON.serialize( new ListAssignedClinicians.JSONCTMParser[]{j}), p.Current_Admission__c, p.Id);
       Boolean isRole = ListAssignedClinicians.updateActiveAssignedClinician(p.Current_Admission__c, 'SUS', true);
       isRole = ListAssignedClinicians.updateActiveAssignedClinician(p.Current_Admission__c, 'Dietician', true);
        test.stopTest();
    }
}