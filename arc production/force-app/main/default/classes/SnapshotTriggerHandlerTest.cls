@isTest
public class SnapshotTriggerHandlerTest {

    @testSetup
    public static void createData() {
        disco__Form_Template__c discoFormTemplate = new disco__Form_Template__c(
            Name = 'Psychiatrist Transfer from Test',
            disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
        );
        insert discoFormTemplate;

        List<Account> accountsToInsert = new List<Account>();
        Account testPatient1 = new Account(
            Name = 'Admission Test Patient 1'
        );
        accountsToInsert.add(testPatient1);
        insert accountsToInsert;

        List<Admission__c> admissionsToInsert = new List<Admission__c>();
        Admission__c testAdm1 = new Admission__c(
            Patient_Account__c = testPatient1.Id,
            Stage__c = 'Open Inquiry'
        );
        admissionsToInsert.add(testAdm1);
        insert admissionsToInsert;
        EGO__c ego = new EGO__c();
        ego.Admission__c = testAdm1.Id;
        insert ego;
        Snapshot__c snap = new Snapshot__c();
        snap.EGO__c = ego.Id;
        Patient_Note__c patient = new Patient_Note__c();
        patient.Admission__c = testAdm1.id;
        insert patient;
        snap.Patient_Note__c = patient.Id;
        insert snap;
        Assigned_Clinician__c ac = new Assigned_Clinician__c(
            Admission__c = testAdm1.Id,
            Start_Date__c = Date.today(),
            User__c = UserInfo.getUserId(),
            Role__c = 'Psychotherapist'
        );
        insert ac;
    }
    @isTest
    public static void TestFirstCase(){
        Account acc = [select name from account limit 1];
        EGO__c ego = [select Admission__r.Stage__c from EGO__c limit 1];
        Admission__c admission = new Admission__c( Patient_Account__c = acc.Id,Stage__c = ego.Admission__r.Stage__c);
        //insert admission;

    }
    @isTest
    public static void TestSecondCase(){
        Account acc = [select name from account limit 1];
        Patient_Note__c patient = [select Admission__r.Stage__c from Patient_Note__c limit 1];
        Admission__c admission = new Admission__c( Patient_Account__c = acc.Id,Stage__c = patient.Admission__r.Stage__c);
        admission.Stage__c = 'Admitted';
        //insert admission;

    }
}