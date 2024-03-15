public class MultiSelectPicklistCtl {
	@AuraEnabled
	public static List<PicklistOption> getMultiSelectPicklistOptions(String objectName, String fieldName) {
		List<PicklistOption> picklistOptionList = new List<PicklistOption>();

		SObjectType sObjType = ((SObject) Type.forName(objectName).newInstance()).getSObjectType();
		Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();

		List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldName).getDescribe().getPickListValues();
		for (Schema.PicklistEntry picklistEntry : picklistValues) {
			PicklistOption picklistOption = new PicklistOption();
			picklistOption.label = picklistEntry.getLabel();
			picklistOption.value = picklistEntry.getValue();
			picklistOptionList.add(picklistOption);
		}

		return picklistOptionList;
	}

	public class PicklistOption {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
	}
}