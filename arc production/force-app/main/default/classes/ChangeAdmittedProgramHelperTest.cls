@IsTest
public class ChangeAdmittedProgramHelperTest {
    @TestSetup
    public static void setup(){
        Profile riggsClinicalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'RiggsClinical'
            LIMIT 1
        ];

        List<User> usersToInsert = new List<User>();
        User testUser1 = new User(
            FirstName = 'Intervention Test 1',
            LastName = 'Test',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'test@example.com',
            Alias = 'test1',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        usersToInsert.add(testUser1);
        insert usersToInsert;

        List<Account> accountsToInsert = new List<Account>();
        Account testPatient1 = new Account(
            Name = 'Admission Test Patient 1'
        );
        accountsToInsert.add(testPatient1);
        insert accountsToInsert;

        List<Admission__c> admissionsToInsert = new List<Admission__c>();
        Admission__c testAdm1 = new Admission__c(
            Patient_Account__c = testPatient1.Id,
            Discharge_Date__c = system.today().addDays(1),
            Stage__c='Discharged'
        );
        admissionsToInsert.add(testAdm1);
        insert admissionsToInsert;

        Case draftTP = new Case(
            Admission__c = testAdm1.Id,
            Status = 'Draft'
        );
        insert draftTP;

        update new Account(ID=testPatient1.Id,Current_Case__c=draftTP.Id);

        Assigned_Clinician__c ac = new Assigned_Clinician__c(
            Admission__c = testAdm1.Id,
            Start_Date__c = Date.today(),
            User__c = UserInfo.getUserId(),
            Role__c = 'Psychotherapist'
        );
        insert ac;

        List<EGO__c> egosToInsert = new List<EGO__c>();
        EGO__c testEGO1 = new EGO__c(
            Admission__c = testAdm1.Id
        );
        egosToInsert.add(testEGO1);
        insert egosToInsert;

        Program__c p = new Program__c(Short_Name__c='test');
        insert p;

        Admitted_Program__c ap = new Admitted_Program__c(Program__c=p.Id,start_date__c=system.today());
        
        insert ap;
        
        update new Admission__c(id=testAdm1.Id, current_admitted_program__c=ap.id);

        string status = Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()[0].getValue();

        Admitted_Program_Status__c aps = new Admitted_Program_Status__c(
			Admitted_Program__c = ap.Id,
			Start_Date_Time__c = system.now(),
            End_Date_Time__c = System.now(),
			Status__c = status
		);
        insert aps;
    }

    public static testmethod void testDischargeEndDateProcess(){
        Admission__C adm = [Select Id from Admission__c limit 1];
        test.startTest();
        update new Admission__c(Id=adm.Id, Stage__c='Discharged',Discharge_Date__c=system.today().addDays(2));
        test.stopTest();
    }



    public static testmethod void testValidation(){
        TriggerFactory.Recursions.clear();        
        Admission__C adm = [Select Id from Admission__c limit 1];
        update new Admission__c(Id=adm.Id, Stage__c='Discharged',Discharge_Date__c=system.today().addDays(1));
        
        Admitted_Program__c admit = [SELECT Id, Name, End_Date__c FROM Admitted_Program__c LIMIT 1];
        admit.End_Date__c = system.today().addDays(1);
        
        update admit;

        string errorThrown = '';

        test.startTest();
        try{         
            TriggerFactory.Recursions.clear();   
            update new Admission__c(Id=adm.Id,Discharge_Date__c=system.today().addDays(4));
        }catch(Exception ex){
            errorThrown = ex.getMessage();
        }
        test.stopTest();

        system.assertEquals(true, string.isNotBlank(errorThrown),'Should have thrown an error');
        system.assertEquals(true, errorThrown.contains( ChangeAdmittedProgramHelper.dischargeDatesOnChildsErrorMessage ),'Should have thrown the dischargeDatesOnChildsErrorMessage error');
    }
}