@isTest 
class ProgramGroupMembershipsTest 
{
    @TestSetup
    static void makeData()
    {
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

        Account patAcct = new Account(
            Name = 'testPatient',
            RecordtypeId = recordTypeMap.get('Patient-Account')
        );
        insert patAcct;

		Contact patCon = new Contact(
            LastName = 'TestPatient_1', 
            RecordTypeId = recordTypeMap.get('Patient' + '-' + 'Contact'),
            AccountId = patAcct.Id);
		insert patCon;
		
		Case tp = new Case(AccountId = patAcct.Id);
        insert tp;
		
		update new Account(Id = patAcct.Id, Patient_Contact__c = patCon.Id, Current_Case__c = tp.Id);

		List<Admission__c> admissionList = new List<Admission__c>{
			new Admission__c(
                Patient_Account__c = patAcct.Id, 
                Patient_Contact__c = patCon.Id,
                Stage__c = 'Waitlist')
		};
		insert admissionList; 

	    Account testA = [SELECT Id, Patient_Contact__c, Current_Admission__c, Current_Case__c
                        FROM Account 
                        WHERE Id = :patAcct.Id];

        User testUser = [SELECT Id
                        FROM User
                        WHERE IsActive = true AND Profile.Name = 'RiggsClinical'
                        LIMIT 1];

        Assigned_Clinician__c clin = new Assigned_Clinician__c(
            Role__c = 'Psychotherapist',
            Admission__c = admissionList[0].Id,
            Patient_Account__c = patAcct.Id,
            Start_Date__c = System.today().addDays(-2),
            Treatment_Plan__c = tp.Id,
            User__c = testUser.Id
        );
        insert clin;

        update new Admission__c(
            Id = admissionList[0].Id,
            Stage__c = 'Admitted',
            Admit_Date__c = System.today(),
            Psychotherapist__c = clin.User__c
        );
    }
    
    @isTest static void testSync()
    {
        makeData();

        Account myPatient = [SELECT Id, Name, Current_Admission__c, Current_Admission_Stage__c, Patient_Contact__c
                            FROM Account
                            WHERE Recordtype.Name = 'Patient' AND Current_Admission__c != null
                            LIMIT 1];
        
        Program__c newProg = new Program__c(
            Name = 'newProg',
            Is_Parent_Program__c = true,
            Short_Name__c = 'newp'
        );
        insert newProg;

        Admitted_Program__c newAdmProg = new Admitted_Program__c(
            Account__c = myPatient.Id,
            Admission__c = myPatient.Current_Admission__c,
            Program__c = newProg.Id,
            Start_Date__c = System.today().addDays(-1)
        );

        Test.startTest();
            ProgramGroupMemberships.hasSyncedGroups = false;
            insert newAdmProg;
            // ProgramGroupMemberships.syncAdmittedProgramsToGroup();
        Test.stopTest();

        List<Group__c> groups = [SELECT Id, Name, Program__c,
                                    (SELECT Id, Patient__c, Role__c, Start_Date__c
                                        FROM Patient_Group_Members__r)
                                
                                FROM Group__c];
        System.assertEquals(1, groups.size());
        System.assertEquals(newProg.Id, groups[0].Program__c);
        System.assertEquals(1, groups[0].Patient_Group_Members__r.size());
        System.assertEquals(myPatient.Patient_Contact__c, groups[0].Patient_Group_Members__r[0].Patient__c);
        System.assertEquals('Member', groups[0].Patient_Group_Members__r[0].Role__c);
        

    }
}