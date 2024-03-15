public class MultiSelectCheckboxCtl {
	@AuraEnabled
	public static List<MultiSelectPicklistCtl.PicklistOption> getMultiSelectCheckboxOptions(String objectName, String fieldName) {
		List<MultiSelectPicklistCtl.PicklistOption> picklistOptionList = MultiSelectPicklistCtl.getMultiSelectPicklistOptions(objectName, fieldName);

		return picklistOptionList;
	}
}