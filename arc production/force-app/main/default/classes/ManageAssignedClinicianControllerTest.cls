@IsTest
public without sharing class ManageAssignedClinicianControllerTest {
    @TestSetup
    static void setup(){
        system.runAs(usr()){
            CaseTeamRole[] roles = new list<CaseTeamRole>();
            roles.add( new CaseTeamRole(Name='Substance Use Counselor', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Registered Dietitian Nutritionist', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Community Program Rep', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Program Manager', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Psychotherapist', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Psychiatrist', AccessLevel='Edit'));
            roles.add( new CaseTeamRole(Name='Team Leader', AccessLevel='Edit'));
            insert roles;
        }
        Account a = new account(
            Name='ParentName',
            recordtypeid = RecordTypeHelper.getIdByName('Account','Patient')
        );
        insert a;
        Case tp = new Case(AccountId=a.Id);
        insert tp;
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

        update new Account(Id=a.Id,Current_Case__c = tp.Id,Current_Admission__c=adm.Id);

        
        // system.runAs(usr()){
        //     CaseTeamMember[] ctm = new list<CaseTeamMember>();
        //     for(CaseTeamRole r : [Select Id from CaseTeamRole limit 1]){
        //         ctm.add(new CaseTeamMember(MemberId=Userinfo.getUserId(), ParentId=tp.Id, TeamRoleId=r.Id));
        //     }
        //     insert ctm;
        // }
    }

    static User usr(){return [Select Id from User where Id=:UserInfo.getUserId()];}

    static Case getCase(){ return [Select id,AccountId from Case limit 1];}

    public static testmethod void testGetterMethods(){
        test.startTest();
        Case c = getCase();
        system.runAs(usr()){
            insert new CaseTeamMember(MemberId=Userinfo.getUserId(), ParentId=c.Id, TeamRoleId=[Select Id from CaseTeamRole][0].Id);
        }
        ManageAssignedClinicianController.getCaseTeamMember( c.AccountId );
        ManageAssignedClinicianController.getCaseTeamMember( c.AccountId );
        ManageAssignedClinicianController.getCaseTeamMemberInstance();
        ManageAssignedClinicianController.getCaseTeamMemberRole().size();
        test.stopTest();
    }

    public static testmethod void testSaveMethods(){
        Case c = getCase();
        test.startTest();
        ManageAssignedClinicianController.JSONCTMParser d = new ManageAssignedClinicianController.JSONCTMParser();
        d.MemberId = userinfo.getuserid();
        d.TeamRoleId = [Select Id from CaseTeamRole][0].Id;
        d.isDeleted = 'false';
        try{
            ManageAssignedClinicianController.saveCaseTeamMember(   
                JSON.serialize( new ManageAssignedClinicianController.JSONCTMParser []{ d } ),
                 c.AccountId 
            );
        }catch(exception e){}
        test.stopTest();
    }

    public static testmethod void testDeleteMethods(){
        test.startTest();
        Case c = getCase();
        system.runAs(usr()){
            insert new CaseTeamMember(MemberId=Userinfo.getUserId(), ParentId=c.Id, TeamRoleId=[Select Id from CaseTeamRole][0].Id);
        }
        ManageAssignedClinicianController.deleteCaseTeamMemberInstance([Select Id from CaseTeamMember limit 1][0].Id );
        test.stopTest();
        system.assertEquals(0, [select count() from CaseTeamMember]);
    }
}