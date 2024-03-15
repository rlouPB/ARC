@IsTest
public with sharing class CustomLookupServiceTest {
    public static testmethod void test(){
        system.assertEquals(UserInfo.getUserName(),CustomLookupService.GetById(userinfo.getUserId(), 'Username')?.label);

        system.assertEquals(UserInfo.getUserName(),CustomLookupService.SearchById(userinfo.getUserId(), 'User', 'Username')?.label);

        System.assertEquals(1,CustomLookupService.SearchByText(UserInfo.getUserName(), 'User', 'Username').size());
        System.assertEquals(1,CustomLookupService.SearchByUserGroup(UserInfo.getUserName(), 'User', 'Username').size());
    }

    public static testmethod void failTest(){
        CustomLookupService.GetById(null, 'Username');

        CustomLookupService.SearchById(null, 'InvalidSobject', 'Username');

        CustomLookupService.SearchByText(null, 'InvalidSobject', 'Username');
    }
}