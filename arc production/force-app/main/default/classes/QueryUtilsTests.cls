@IsTest
public class QueryUtilsTests {
    public static testmethod void testAllMethods()
    {
        Test.startTest();
            QueryUtils.getAllFields('User');
            String allQueryString = QueryUtils.getQueryAll('User', new string[]{'Profile.Name', 'lastName'});   
            String subAllQueryString = QueryUtils.getSubQueryAll('User', 'Users', new string[]{'Profile.Name', 'Name'}, ' WHERE IsActive=True');
        Test.stopTest();
        
        System.assert(allQueryString.contains('lastname'));
        System.assert(!allQueryString.contains('lastName'));
        System.assert(subAllQueryString.contains('profile.name'));
        System.assert(!subAllQueryString.contains('Profile.Name'));
    }
}