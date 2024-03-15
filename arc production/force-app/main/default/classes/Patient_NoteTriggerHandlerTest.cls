@istest 
public class Patient_NoteTriggerHandlerTest {
    @testSetup
    static void setup(){ 
        disco__Form_Template__c dft = new disco__Form_Template__c (DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer' , disco__Status__c = 'In Use' );
        insert dft;
        account acc = new account();
        acc.Name = 'test';
        insert acc;
        
        Snapshot__c ss = new Snapshot__c();
        Patient_Note__c pn = new Patient_Note__c();
        pn.Account__c = acc.id;
        pn.type__c = 'Summation of Hospitalization';
        insert pn;
        
        ss.Patient_Note__c =pn.id;
        insert ss;
        
    }
    static testmethod void test()
    {
        Patient_Note__c pn = [select id from  Patient_Note__c];
        
        
        pn.Status__c='Finalized'; 
        pn.Type__c ='Psychopharmacology Services Transfer Note';
        try{
            update pn;
        }
        catch(exception ex){
            
        }
        pn.Status__c='Finalized'; 
        pn.Type__c ='Psychotherapy Transfer Note';
        try{
            update pn;
        }
        catch(exception ex){
            
        }
        
        
        delete pn;
        
    }
    static testmethod void test2()
    {
        Patient_Note__c pn = [select id from  Patient_Note__c];
        pn.Status__c = 'completed';
        try{
            update pn;
        }
        catch(exception ex){
            
        }
    }
}