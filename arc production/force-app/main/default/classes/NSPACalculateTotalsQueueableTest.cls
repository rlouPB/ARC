@IsTest
public with sharing class NSPACalculateTotalsQueueableTest {
    @TestSetup    
    public static void setup(){
        // ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
		// AdmissionScreeningControllerTest.setup();
        // Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        // Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];
        // Case currentCase=new Case(AccountId=patient.Id,Admission__c=admission.Id);
        // insert currentCase;        
        // patient.Current_Case__c=currentCase.Id;
        // update patient;
        // admission.Team__c='A';
        // admission.Stage__c='Admitted';
        // admission.Psychotherapist__c=userinfo.getuserid();
        // update admission;
        // 
        // 
        
        ViewTreatmentPlanCtlTest.createGroupAndGroupMembers();
		
        AdmissionScreeningControllerTest.setup();
        
        Account patient=[SELECT Id, Current_Case__c FROM Account LIMIT 1];
        
        Admission__c admission=[SELECT Id,Team__c FROM Admission__c WHERE Patient_Account__c=:patient.Id limit 1];
        
        update new Admission__c(Id=admission.Id, Stage__c='Admitted', Psychotherapist__c = userinfo.getuserid());

        Test.startTest();
        SIP_DailyNursingShifts.processLogic();
		Test.stopTest();

        //test.startTest();
        //SIP_DailyNursingShifts.today = Date.newInstance(2021, 10, 1);
        //SIP_DailyNursingShifts.processLogic();
        ///test.stopTest();
		/*       
        Nursing_Shift_Item__c[] toInsert = new Nursing_Shift_Item__c[]{};
            
		
        for ( Nursing_Shift__c ns : [Select Id from Nursing_Shift__c] ){
            toInsert.add(new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id,Nurse__c=userinfo.getuserid(), patient__c=patient.id));
        }
		*/
        Nursing_Shift_Item__c[] toInsert = new Nursing_Shift_Item__c[]{};
        Nursing_Shift__c ns = new Nursing_Shift__c(
            Shift_Number__c='1st', 
            Date__c = Date.Today(), 
            Status__c='Open', 
            Shift_Open_Date_Time__c = System.now(),
            Type_of_Day__c='Weekday');
        insert ns;

        Nursing_Shift_Assignment__c nsac = new Nursing_Shift_Assignment__c(
            Owner__c = UserInfo.getUserId(),
            OwnerId = UserInfo.getUserId(),
            Nursing_Shift__c = ns.Id,
            Sign_In_Date_Time__c = System.now(),
            Status__c='Open'
        );
        
        toInsert.add(new Nursing_Shift_Item__c(Nursing_Shift__c = ns.Id,Nurse__c=userinfo.getuserid()));
        
        insert toInsert;

        // Nursing_Shift_Assignment__c[] itemAssignments = new Nursing_Shift_Assignment__c[]{} ;
        Map<Id,Nursing_Shift_Assignment__c> nsiToNsaMap = new Map<Id,Nursing_Shift_Assignment__c>();
        for (Nursing_Shift_Item__c nsi : toInsert){
            Nursing_Shift_Assignment__c nsa = new Nursing_Shift_Assignment__c(
                Owner__c= userinfo.getUserId(),
                Nursing_Shift__c = nsi.Nursing_Shift__c                
            );
            // itemAssignments.add(nsa);
            nsiToNsaMap.put(nsi.Id,nsa);
        }
        // insert itemAssignments;
        insert nsiToNsaMap.values();

        for (Nursing_Shift_Item__c nsi : toInsert){
            nsi.Nursing_Shift_Assignment__c = nsiToNsaMap.get(nsi.Id).Id;
        }
        update toInsert;


        Map<Id,Nursing_Shift_Patient_Assignment__c> nsaToNspaMap = new Map<Id,Nursing_Shift_Patient_Assignment__c>();
        for (Nursing_Shift_Item__c nsi : toInsert){
            Nursing_Shift_Patient_Assignment__c nspa = new Nursing_Shift_Patient_Assignment__c(
                //Owner__c= userinfo.getUserId(),
                Patient__c = patient.Id,//nsi.Patient__c,
                Nursing_Shift_Assignment__c = nsi.Nursing_Shift_Assignment__c,
                Status__c=nsi.Status__c,
                Nursing_Shift__c = nsi.Nursing_Shift__c                
            );
            // itemAssignments.add(nsa);
            nsaToNspaMap.put(nsi.Id,nspa);
        }
        // insert itemAssignments;
        insert nsaToNspaMap.values();
        
        
    }

    @IsTest
    public static void test(){
        test.startTest();
        System.enqueueJob(new NSPACalculateTotalsQueueable(new List<Id>(new Map<Id,Nursing_Shift_Patient_Assignment__c>([Select Id from Nursing_Shift_Patient_Assignment__c]).keyset()) , 'NSPA'));
        //System.enqueueJob(new NSPACalculateTotalsQueueable(new List<Id>(new Map<Id,Nursing_Shift_Item__c>([Select Id from Nursing_Shift_Item__c]).keyset()) , 'NSI'));
        test.stopTest();

        //system.assertNotEquals(0,[SELECT count() FROM Nursing_Shift_Patient_Assignment__c]);
        //system.assertNotEquals(0,[SELECT count() FROM Nursing_Shift_Item__c]);
    }
}