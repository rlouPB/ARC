@IsTest
public with sharing class RecordViewServiceTest {
    public static testmethod void test(){
        System.assertEquals(userinfo.getUserName(), RecordViewService.getRecord(userinfo.getUserId(), 'Username')?.name);

        System.assertEquals(null, RecordViewService.getRecord(null,null));
    }
}