@isTest with sharing class PrintPrescriptionControllerTest {
    @TestSetup
    static void makeData()
    {
        createAdmittedPatient();
    }
    public static void createAdmittedPatient()
    {
        //Admitted Patient
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

        List<Account> patientAccounts = new List<Account>
        {
            new Account(
                RecordtypeId = recordTypeMap.get('Patient-Account'), Name = 'TestPatient_1', Service_Type_Text__c = 'Residential')
        };
        insert patientAccounts;

        List<Contact> contactList = new List<Contact>
        {
            new Contact(LastName = 'TestPatient_1', AccountId = patientAccounts[0].Id, RecordTypeId = recordTypeMap.get('Patient-Contact'))
        };
        insert contactList;

        Contact contactWithAccount = [SELECT Id, AccountId  FROM Contact WHERE Id =: contactList[0].Id];

        List<Admission__c> admissionList = new List<Admission__c> {
                new Admission__c(Patient_Account__c = contactWithAccount.AccountId, Patient_Contact__c = contactWithAccount.Id, Stage__c='Waitlist')
        };
        insert admissionList;

        contactWithAccount = [SELECT Id, AccountId, Account.Current_Admission_Stage__c, Account.Current_Admission__c
                        FROM Contact
                        WHERE Id = :contactWithAccount.Id];
        System.assertEquals('Waitlist', contactWithAccount.Account.Current_Admission_Stage__c);
        System.assertEquals(admissionList[0].Id, contactWithAccount.Account.Current_Admission__c);

        //Assigned Clinicians
        List<Assigned_Clinician__c> assignedCliniciansList = new List<Assigned_Clinician__c>
        {
                new Assigned_Clinician__c(
                    Patient_Account__c = contactWithAccount.AccountId,
                    Admission__c = contactWithAccount.Account.Current_Admission__c,
                    User__c = UserInfo.getUserId(),
                    Role__c = 'Psychotherapist',
                    Start_Date__c = Date.Today().addDays(-5)
                    )
        };
        insert assignedCliniciansList;

        admissionList[0].Consultation_Date__c = System.today();
        admissionList[0].Psychotherapist__c = assignedCliniciansList[0].User__c;
        update admissionList;

        Admission__c currentAdmission = [SELECT Id, Stage__c, Psychotherapist__c, Patient_Account__c,
                                            (SELECT Id, Start_Date__c, Role__c
                                            FROM Assigned_Clinicians__r
                                            WHERE Role__c = 'Psychotherapist')
                                        FROM Admission__c
                                        WHERE Id = :admissionList[0].Id];
        System.assertEquals(1, currentAdmission.Assigned_Clinicians__r.size());
        System.assertEquals(assignedCliniciansList[0].User__c, currentAdmission.Psychotherapist__c);


        admissionList[0].Admit_Date__c = System.today();
        admissionList[0].Stage__c = 'Admitted';
        update admissionList;
        Account checkPatientAccount = [SELECT Id, Current_Admission__c, Current_Admission__r.Stage__c, Current_Admission_Stage__c, Recordtype.Name
                                FROM Account
                                WHERE Id = :contactWithAccount.AccountId
                                LIMIT 1];
        System.assertEquals(currentAdmission.Id, checkPatientAccount.Current_Admission__c);
        System.assertEquals('Admitted', checkPatientAccount.Current_Admission__r.Stage__c);
        System.assertEquals('Admitted', checkPatientAccount.Current_Admission_Stage__c);
        System.assertEquals('Patient', checkPatientAccount.Recordtype.Name);
        Prescription__c prep = new Prescription__c(
            Account__c=checkPatientAccount.Id,
            Drug_Name__c='test',
            Medication_Filled_With__c = 'test',
            Medication_Format__c = 'test',
            Presciber__c=userinfo.getuserid(),
            Status__c ='Active',
            Start_Date__c = Date.Today(),
            End_Date__c = Date.Today()
        );
        insert prep;
    }
    @isTest static private void unitTest() {
        Prescription__c p = [SELECT Id FROM Prescription__c limit 1];
        PageReference pageRef = Page.PrintPrescription;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController csStdCtl = new ApexPages.StandardController(p);
        PrintPrescriptionController csController = new PrintPrescriptionController(csStdCtl);
        csController.init();

    } 
    
}