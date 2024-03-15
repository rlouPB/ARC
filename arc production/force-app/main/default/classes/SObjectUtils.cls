global class SObjectUtils {
	public static Map<String, SObjectType> globalDescribe {
		get {
			if (globalDescribe == null) {
				globalDescribe = Schema.getGlobalDescribe();
			}
			return globalDescribe;
		}
		private set;
	}

	public static Boolean isValidSObject(String objectName) {
		return globalDescribe.containsKey(objectName);
	}

	public static Boolean isSObjectAccessible(String objectName) {
		if (isValidSObject(objectName)) {
			SObject so = globalDescribe.get(objectName).newSObject();
			return so.getSobjectType().getDescribe().isAccessible();
		}
		return null;
	}

	public static Schema.DescribeFieldResult getAccessibleDescribeFieldResult(String objectName, String fieldName) {
		List<Schema.DescribeFieldResult> accessibleDescribeFieldResultList = getAccessibleDescribeFieldResultList(objectName, new Set<String>{ fieldName });
		if (!accessibleDescribeFieldResultList.isEmpty()) {
			return accessibleDescribeFieldResultList[0];
		}
		return null;
	}

	public static List<Schema.PicklistEntry> getAccessiblePicklistEntryList(String objectName, String fieldName) {
		if (getAccessibleDescribeFieldResult(objectName, fieldName) != null) {
			return getAccessibleDescribeFieldResult(objectName, fieldName).getPicklistValues();
		}
		return null;
	}

	public static List<Schema.DescribeFieldResult> getDescribeFieldResultList(String objectName) {
		List<Schema.DescribeFieldResult> describeFieldResultList = new List<Schema.DescribeFieldResult>();
		Map<String, Schema.SObjectField> sObjectFieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();

		for (Schema.SObjectField sObjectField : sObjectFieldMap.values()) {
			describeFieldResultList.add(sObjectField.getDescribe());
		}
		return describeFieldResultList;
	}

	public static List<Schema.DescribeFieldResult> getReferenceDescribeFieldResultList(String objectName) {
		List<Schema.DescribeFieldResult> referenceDescribeFieldResultList = new List<Schema.DescribeFieldResult>();

		for (Schema.DescribeFieldResult describeFieldResult : getDescribeFieldResultList(objectName)) {
			if (describeFieldResult.getType() == DisplayType.Reference) {
				referenceDescribeFieldResultList.add(describeFieldResult);
			}
		}
		return referenceDescribeFieldResultList;
	}

	public static Boolean isValidField(String objectName, String fieldName) {
		List<String> fieldNameSplit = fieldName.split('\\.');
		if (isValidSObject(objectName)) {
			SObject so = globalDescribe.get(objectName).newSObject();
			return so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName);
		}
		return null;
	}

	public static Set<String> getValidFieldNameSet(String objectName, Set<String> fieldNameSet) {
		Set<String> validFieldNameSet = new Set<String>();

		if (isValidSObject(objectName)) {
			SObject so = globalDescribe.get(objectName).newSObject();
			Map<String, Schema.SObjectField> fieldMap = so.getSobjectType().getDescribe().fields.getMap();
			List<Schema.DescribeFieldResult> referenceDescribeResultList = getReferenceDescribeFieldResultList(objectName);

			for (String fieldName : fieldNameSet) {
				List<String> fieldNameSplit = fieldName.split('\\.');
				if (!fieldNameSplit.isEmpty() && fieldNameSplit.size() == 1) {
					if (fieldMap.containsKey(fieldName)) {
						validFieldNameSet.add(fieldName);
					}
				} else if (!fieldNameSplit.isEmpty() && fieldNameSplit.size() > 1) {
					if (fieldMap.containsKey(fieldNameSplit[0])) {
						Schema.DescribeFieldResult describeFieldResult = fieldMap.get(fieldNameSplit[0]).getDescribe();
					}
				}
			}
		}
		return validFieldNameSet;
	}

	public static Set<String> getAccessibleFieldNameSet(String objectName, Set<String> fieldNameSet) {
		Set<String> accessibleFieldSet = new Set<String>();
		Set<String> validFieldNameSet = getValidFieldNameSet(objectName, fieldNameSet);

		if (!validFieldNameSet.isEmpty()) {
			if (isSObjectAccessible(objectName)) {
				SObject so = globalDescribe.get(objectName).newSObject();
				for (String fieldName : validFieldNameSet) {
					if (so.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().isAccessible()) {
						accessibleFieldSet.add(fieldName);
					}
				}
			}
		}

		return accessibleFieldSet;
	}

	public static List<Schema.DescribeFieldResult> getAccessibleDescribeFieldResultList(String objectName, Set<String> fieldNameSet) {
		List<Schema.DescribeFieldResult> accessibleDescribeFieldResultList = new List<Schema.DescribeFieldResult>();

		Set<String> validFieldNameSet = getValidFieldNameSet(objectName, fieldNameSet);

		if (!validFieldNameSet.isEmpty()) {
			if (isSObjectAccessible(objectName)) {
				SObject so = globalDescribe.get(objectName).newSObject();
				for (String fieldName : validFieldNameSet) {
					if (so.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().isAccessible()) {
						accessibleDescribeFieldResultList.add(so.getSobjectType().getDescribe().fields.getMap().get(fieldName).getDescribe());
					}
				}
			}
		}

		return accessibleDescribeFieldResultList;
	}

	//Recursively get value from field, including traversing relationships
	//useful for dynamic SOQL and getting field value from e.g. 'Account__r.Patient_Contact__r.FirstName'
	public static Object getFieldValue(sObject sObj, String fieldString) {
		if (fieldString.contains('.')) {
			List<String> pieces = fieldString.split('\\.', 2);
			return getFieldValue(sObj.getsObject(pieces[0]), pieces[1]);
		}
		return sObj.get(fieldString);
	}

	@AuraEnabled
	public static String getCurrentAppName() {
		UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
		AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition WHERE DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
		return appDefinition.Label;
	}
}