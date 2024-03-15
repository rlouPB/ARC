@IsTest
public with sharing class PermissionUtilsTest {
    @TestSetup
    static void setup(){
        Profile riggsProfile = [Select ID from Profile where Name = 'RiggsPharmacist' limit 1];
        User usr = TestUtils.createUser(null, riggsProfile.Id, 'PermissionUtilsTest', 'PermissionUtilsTest');
        insert usr;
    }
    public static testmethod void test() {
        User u = [Select Id from User Where FirstName = 'PermissionUtilsTest' limit 1];

        System.runAs(u){
            system.assertEquals(false, PermissionUtils.checkPerms('someCustomPermission'));
            system.assertEquals(false, PermissionUtils.checkPerms(null));
            system.assertEquals(false, PermissionUtils.checkPerms(''));
            //system.assertEquals(true, PermissionUtils.checkPerms('DispensingShowPackagePrintBtns'));
        }
    }
}