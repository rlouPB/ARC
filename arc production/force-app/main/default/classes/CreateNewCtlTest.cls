@IsTest 
public class CreateNewCtlTest {
    @IsTest static void test(){
        CreateNewCtl.getFLowNameByDocTypeName('test');
        CreateNewCtl.getFormTemplateIdByDocTypeName('test');
    }

    @isTest
    private static void testCheckduplicates()
    {

        Account testAcc = new Account(
            Name = 'testacc'
        );
        insert testAcc;
        Test.startTest();
            Map<String, String> ddrResultMap = CreateNewCtl.checkBlockedDuplicates(testAcc.Id, 'Discharge Disposition and Recommendations', 'Discharge_Disposition__c');
            System.assertEquals('true', ddrResultMap.get('allowCreate'), ddrResultMap);
            Map<String, String> caResultMap1 = CreateNewCtl.checkBlockedDuplicates(testAcc.Id, 'Initial Case Abstract', 'Case_Abstract__c');
            System.assertEquals('true', caResultMap1.get('allowCreate'), caResultMap1);
            Map<String, String> caResultMap2 = CreateNewCtl.checkBlockedDuplicates(testAcc.Id, 'Re-Presentation Case Abstract', 'Case_Abstract__c');
            System.assertEquals('true', caResultMap2.get('allowCreate'), caResultMap2);
            Map<String, String> awayResultMap = CreateNewCtl.checkBlockedDuplicates(testAcc.Id, 'Away Medication Order', 'Patient_Note__c');
            System.assertEquals('true', awayResultMap.get('allowCreate'), awayResultMap);
            Map<String, String> msaResultMap = CreateNewCtl.checkBlockedDuplicates(testAcc.Id, 'Medication Self-Administration (MSA) Order', 'Patient_Note__c');
            System.assertEquals('true', msaResultMap.get('allowCreate'), msaResultMap);

        Test.stopTest();
    }    
}