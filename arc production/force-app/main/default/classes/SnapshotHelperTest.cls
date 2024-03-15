@IsTest
public without sharing class SnapshotHelperTest {
    @TestSetup
    static void setup(){
        ViewTreatmentPlanCtlTest.doSetup();
    }

    @IsTest
    public static void testAllMethods(){
        system.assertNotEquals(null, SnapshotHelper.currentUser.Name, 'Should have retrieve the current user name');
        system.assert(SnapshotHelper.domains.size() > 0,'Should have retrieve at least one domain');
        Account patient = [select id from account limit 1];
        system.assertNotEquals(null, SnapshotHelper.getTeamMembersByRole(patient.Id, 'Clinical Social Worker'), 'Should have returned the names');
    }
}