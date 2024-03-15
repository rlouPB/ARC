@IsTest
public with sharing class FLSUtilsTest {
    @TestSetup
    static void setup(){        
        Profile riggsProfile = [Select ID from Profile where Name = 'RiggsPharmacist' limit 1];
        User usr = TestUtils.createUser(null, riggsProfile.Id, 'FLSUtilUser', 'FLSUtilUser');
        insert  usr;
    }
    public static testmethod void test(){
        User u = [Select id from user where firstname='FLSUtilUser' limit 1];
        system.runAs(u){
            Map<String,Boolean> m = FLSUtils.checkUserCanAccessFields('Account.Name'.split(','));
            //system.assertEquals(true, m.containsKey('Account.Name'), 'Should have return Account.Name field.');
            //system.assertEquals(true, m.get('Account.Name'), 'Should have had access to the Account.Name field.');
        }
    }
}