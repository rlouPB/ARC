@IsTest
public class RecordUtilsTests {
    public static testmethod void tests(){
        User u = (User)RecordUtils.getRecord(userinfo.getuserid(),'Name');
        system.assertNotEquals(null, u.Name);

        u = (User)RecordUtils.getRecordBySearchField('User','Username',userinfo.getusername(),'Name');
        system.assertNotEquals(null, u.Name);
    }

    public static testmethod void testsFails(){
        User u = (User)RecordUtils.getRecord(null,'Name');
        system.assertEquals(null, u);

        u = (User)RecordUtils.getRecordBySearchField('User','InvalidField',userinfo.getusername(),'Name');
        system.assertEquals(null, u);

        u = (User)RecordUtils.getRecord('invalidid','Name');
        system.assertEquals(null, u);
    }
}