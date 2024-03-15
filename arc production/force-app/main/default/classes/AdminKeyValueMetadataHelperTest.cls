@isTest
private class AdminKeyValueMetadataHelperTest {
	@isTest
	private static void getValueForKeyTest() {
		Test.startTest();
		String value = AdminKeyValueMetadataHelper.getValueForKey('ScriptSure_Process_Logging_Prescriptions');
		Test.stopTest();
	}
}