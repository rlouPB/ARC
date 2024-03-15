@IsTest
public class AdmittedProgramDaysTest {
    @TestSetup
    public static void setup(){

        Account ptAccount = new Account(Name = 'patient1', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId() );
        insert ptAccount;


        List<Contact> contactList = new List<Contact> {
            new Contact(LastName = 'TestPatient_1', AccountId = ptAccount.Id, RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId()),
            new Contact(LastName = 'TestPatient_2', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Personal').getRecordTypeId()),
            new Contact(LastName = 'TestPatient_3', RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Professional').getRecordTypeId()  )
        };
        insert contactList;

        Contact accWithContact = [SELECT Id, AccountId  FROM Contact WHERE Id =: contactList[0].Id];

        Admission__c curAdm = new Admission__c(Patient_Account__c = ptAccount.Id, 
            Patient_Contact__c = accWithContact.Id, 
            Stage__c = 'Consultation Pending', 
            Consultation_Only_Date__c = system.today().addDays(2), 
            Admitted_Date_Set__c = System.today(),
            Team__c = 'A');

        insert curAdm;



        Account patient = [Select Id,current_admission__c from Account limit 1];
        Program__c p = new Program__c(Short_Name__c='test');
        insert p;
        Admitted_Program__c ap = new Admitted_Program__c(Program__c=p.Id,start_date__c=system.today());
        insert ap;
        Admission__c am = new Admission__c(id=patient.current_admission__c, current_admitted_program__c=ap.id);
        update am;
        update new Admitted_Program__c(Id=ap.Id,Admission__c = am.Id);

        insert new Admitted_Program_Status__c(
			Admitted_Program__c = ap.Id,
			Start_Date_Time__c = system.now(),
            End_Date_Time__c = system.now().addDays(2),
			Status__c = Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()[0].getValue()
		);

        insert new Admitted_Program_Day__c(
            Admission__c = am.Id,
            Admitted_Program__c = ap.Id,
            Patient_Account__c = ptAccount.Id
        );
    }

    public static testmethod void testNormalRun(){
        map<id,admission__c> admissions = new map<id,admission__c>([Select id, patient_Account__c from Admission__c limit 1]);
        system.assertNotEquals(0,  admissions.size());
        Set<Id> admissionsIds = new Set<Id>();
		for(String key: admissions.keySet()){
            admissionsIds.add(key);
        }
        AdmittedProgramDays.syncAdmittedProgramDays();
        AdmittedProgramDays adprd = new AdmittedProgramDays(admissionsIds);
        adprd.compareAlt();
        adprd.getCurrentDates();

        id patientAccountId = admissions.values()[0].patient_Account__c;

        //modifying the apd's types for code coverage
        Admitted_Program_Day__c[] apds = [Select Id,type__c,Admission__c,Admitted_Program__c from Admitted_Program_Day__c];
        for(Admitted_Program_Day__c apd : apds){
            apd.type__c=null;
        }
        update apds;

        //Invalid APD, should be deleted at the end
        Admitted_Program_Day__c toDeleted = new Admitted_Program_Day__c(
            Admission__c=apds[0].admission__c,
            Admitted_Program__c=apds[0].Admitted_Program__c,
            Patient_Account__c = patientAccountId,
            Date__c = system.today().addDays(50)
        );
        insert toDeleted;

        test.startTest();
        AdmittedProgramDays.syncAdmittedProgramDays();

        test.stopTest();


        system.assertNotEquals(0, [select count() from Admitted_Program_Day__c],'Should have created admitted program day records');

        //system.assertEquals(0, [select count() from Admitted_Program_Day__c where id=:toDeleted.Id],'Should have deleted the admitted program day record');
    }

    @isTest
    private static void admittedProgramUtilgetFirstMatchedByDate() {
        Admitted_Program_Day__c[] apds = [Select Id,type__c,Admission__c,Admitted_Program__c from Admitted_Program_Day__c];
        AdmittedProgramDaysUtils.getFirstMatchedByDate(apds);
    }

    @isTest
    private static void admittedProgramUtilGetType() {
        AdmittedProgramDaysUtils.getType(Date.today(), Date.today(), null);
        AdmittedProgramDaysUtils.getType(null, Date.today(), Date.today());

    }

    @isTest
    private static void testBatch()
    {
        AdmittedProgramDaysBatch.admissionQueryString += ' LIMIT 1';

        Test.startTest();
            AdmittedProgramDaysBatch.runBatch();
        Test.stopTest();
    }
   
}