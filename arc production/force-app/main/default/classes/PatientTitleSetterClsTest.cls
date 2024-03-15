@IsTest
public without sharing class PatientTitleSetterClsTest {
    public static testmethod void test(){
        Account patient = new Account(Name='Test');
        insert patient;
        contact c = new contact(AccountId=patient.Id,FirstName='Test',LastName='Test');
        insert c;
        update new Account(id=patient.Id, Patient_Contact__c=c.Id);
        test.startTest();
        string s = PatientTitleSetterCls.getPageTitle(patient.Id);
        string ss = PatientTitleSetterCls.getPageTitle(c.Id);
        string sss = PatientTitleSetterCls.getPageTitle(null);
        test.stopTest();

        system.assertNotEquals(null, s);
        system.assertNotEquals(null, ss);
        system.assertEquals(null, sss);
    }
}