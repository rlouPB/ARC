@isTest
class ViewOptionsCtlTest {
	@isTest
	static void testViewOptions() {
		Test.startTest();
		List<ViewOptionsCtl.OptionSet> optionSets = ViewOptionsCtl.getViewOptionSets('Picture Book');
		//ViewOptionsCtl.OptionItem.buildSelectOptionSetRbOptions();
		ViewOptionsCtl.OptionItem optionItem = new ViewOptionsCtl.OptionItem();
		//optionItem.buildSelectOptionSetRbOptions();
		Test.stopTest();
	}
}