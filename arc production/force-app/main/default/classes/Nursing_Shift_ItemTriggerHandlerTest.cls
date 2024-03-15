@isTest
public class Nursing_Shift_ItemTriggerHandlerTest {
    @testSetup 
    static void data(){
        disco__Form_Template__c dft = new disco__Form_Template__c (DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer' , disco__Status__c = 'In Use' );
        insert dft;
        
        Patient_Note__c pn = new Patient_Note__c();
        pn.type__c = 'Summation of Hospitalization';
        pn.Contact_Date__c= system.today();
        insert pn;
        Nursing_Shift__c ns = new Nursing_Shift__c();
        ns.Status__c ='Open';
        insert ns;
        Nursing_Shift_Item__c nsi = new Nursing_Shift_Item__c();
        nsi.Nursing_Shift__c = ns.id;
        nsi.Patient_Note__c = pn.id;
        insert nsi;
        Nursing_Shift_Item__c nsi1 = new Nursing_Shift_Item__c();
        nsi1.Shift_Date__c = system.today().addDays(1);
        nsi1.Shift_Number__c = '1st';
        
        nsi1.Patient_Note__c = pn.id;
        insert nsi1;
        
    }
    static testmethod void test1 (){
        
        Nursing_Shift_Item__c nsi1 = new Nursing_Shift_Item__c();
        nsi1.Shift_Date__c = system.today();
        nsi1.Shift_Number__c = '1st';
        
        nsi1.Patient_Note__c = [SELECT ID FROM Patient_Note__c limit 1]?.id;
        insert nsi1;
        
        
    }
    static testmethod void test2Update(){
        Nursing_Shift__c ns = [SELECT ID from Nursing_Shift__c limit 1 ];
        ns.Status__c ='Open';
        ns.Shift_Number__c = '1st';
        ns.Date__c = system.today();
        update ns;
        
        list<Nursing_Shift_Item__c> nsi =  [SELECT ID from Nursing_Shift_Item__c where Shift_Date__c != null limit 1 ];
        update nsi;
        delete nsi;
    }
    
    static testmethod void test3Update(){
        
        
        Nursing_Shift__c ns = [SELECT ID from Nursing_Shift__c limit 1 ];
        ns.Status__c ='Open';
        ns.Shift_Number__c = '1st';
        ns.Date__c = system.today();
        update ns;
        
        list<Nursing_Shift_Item__c> nsi =  [SELECT ID from Nursing_Shift_Item__c where Nursing_Shift__c = null limit 1 ];
        nsi[0].Nursing_Shift__c = ns.id;
        
        try{
            update nsi;
        }
        catch(exception ex){
            
        }
    }
    static testmethod void testnursingshifthelper(){
         Nursing_Shift__c ns = [SELECT ID from Nursing_Shift__c limit 1 ];
       Nursing_Shift_Assignment__c nursingShiftAssignment = new Nursing_Shift_Assignment__c();

        nursingShiftAssignment.Nursing_Shift__c = ns.id;
        insert nursingShiftAssignment;
        NursingShiftHelper.getShiftForAssignmentForNurse(userinfo.getUserId(), ns.id, new list<Nursing_Shift_Assignment__c> {nursingShiftAssignment});
        
    }
}