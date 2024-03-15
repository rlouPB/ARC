@isTest
public class AdmissionsHomeButtonsControllerTest {
    public AdmissionsHomeButtonsControllerTest() {

    }

    @isTest
    private static void testGetAdmissions() {
        Test.startTest();
        AdmissionsHomeButtonsController.getOrCreateAdmission();
        Test.stopTest();
    }
}