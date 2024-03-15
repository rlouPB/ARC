@isTest
private class SharingRecord_UtilsTest {

    @TestSetup
    static void makeData()
    {
        Profile riggsClinicalProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'RiggsClinical'
            LIMIT 1
        ];

        List<User> usersToInsert = new List<User>();
        User testUser1 = new User(
            FirstName = 'Share Test 1',
            LastName = 'Test_Share',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser1@austenriggs.net.Phase2Dev',
            Email = 'sharetest@example.com',
            Alias = 'test1',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        usersToInsert.add(testUser1);
        User testUser2 = new User(
            FirstName = 'Share Test 2',
            LastName = 'Test_Share',
            ProfileId = riggsClinicalProfile.Id,
            Username = 'testuser2@austenriggs.net.Phase2Dev',
            Email = 'sharetest@example.com',
            Alias = 'test2',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York'
        );
        usersToInsert.add(testUser2);
        insert usersToInsert;

        List<Case> treatmentPlansToInsert = new List<Case>();
        Case tPlan1 = new Case(
            SuppliedName = 'tPlan1 test Treatment Plan'
        );
        treatmentPlansToInsert.add(tPlan1);
        insert treatmentPlansToInsert;
    }

    @isTest
    private static void testCreateSharingRecords()
    {
        List<User> users = [
            SELECT FirstName
            FROM User
            WHERE LastName = 'Test_Share'
            AND Email = 'sharetest@example.com'
        ];
        Map<String, Id> userIdByName = new Map<String, Id>();
        List<Id> userIds = new List<Id>();
        for (User currentUser: users)
        {
            userIdByName.put(currentUser.FirstName, currentUser.Id);
            userIds.add(currentUser.Id);
        }

        Case tPlan1 = [
            SELECT Id
            FROM Case
            WHERE SuppliedName = 'tPlan1 test Treatment Plan'
            LIMIT 1
        ];
        List<Id> recordIds = new List<Id>();
        recordIds.add(tPlan1.Id);

        List<UserRecordAccess> user1RecordAccess = [
            SELECT RecordId, MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :userIdByName.get('Share Test 1')
            AND RecordId = :tPlan1.Id
            LIMIT 1
        ];
        //System.assertEquals('None', user1RecordAccess[0].MaxAccessLevel);

        List<UserRecordAccess> user2RecordAccess = [
            SELECT RecordId, MaxAccessLevel
            FROM UserRecordAccess
            WHERE UserId = :userIdByName.get('Share Test 2')
            AND RecordId = :tPlan1.Id
            LIMIT 1
        ];
        // System.assertEquals('None', user2RecordAccess[0].MaxAccessLevel);

        Test.startTest();
        SharingRecord_Utils.createSharingRecords(recordIds, userIds, 'Edit');
        Test.stopTest();
        List<CaseShare> caseUserShare = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 1')
        ];

        // System.assertEquals('Edit', caseUserShare[0].CaseAccessLevel);

        List<CaseShare> caseUser2Share = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 2')
        ];
        // System.assertEquals('Edit', caseUser2Share[0].CaseAccessLevel);
    }

    @isTest
    private static void testDeleteSharingRecords()
    {
        List<User> users = [
            SELECT FirstName
            FROM User
            WHERE LastName = 'Test_Share'
            AND Email = 'sharetest@example.com'
        ];
        Map<String, Id> userIdByName = new Map<String, Id>();
        List<Id> userIds = new List<Id>();
        for (User currentUser: users)
        {
            userIdByName.put(currentUser.FirstName, currentUser.Id);
            userIds.add(currentUser.Id);
        }

        Case tPlan1 = [
            SELECT Id
            FROM Case
            WHERE SuppliedName = 'tPlan1 test Treatment Plan'
            LIMIT 1
        ];
        List<Id> recordIds = new List<Id>();
        recordIds.add(tPlan1.Id);
        SharingRecord_Utils.createSharingRecords(recordIds, userIds, 'Edit');

        List<CaseShare> caseUserShare = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 1')
        ];
        // System.assertEquals('Edit', caseUserShare[0].CaseAccessLevel);

        List<CaseShare> caseUser2Share = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 2')
        ];
        // System.assertEquals('Edit', caseUser2Share[0].CaseAccessLevel);

        Test.startTest();
        SharingRecord_Utils.deleteSharingRecords(recordIds, userIds);
        Test.stopTest();

        List<CaseShare> caseUserShareDelete = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 1')
        ];
        // System.assert(caseUserShareDelete.isEmpty());

        List<CaseShare> caseUser2ShareDelete = [
            SELECT Id, CaseAccessLevel, CaseId, UserOrGroupId
            FROM CaseShare
            WHERE UserOrGroupId =: userIdByName.get('Share Test 2')
        ];
        // System.assert(caseUser2ShareDelete.isEmpty());
    }

}