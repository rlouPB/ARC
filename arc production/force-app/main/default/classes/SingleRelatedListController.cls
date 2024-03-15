public with sharing class SingleRelatedListController {
	public static final String FIELDS_PARAM = 'fields';
	public static final String NUMBER_OF_RECORDS_PARAM = 'numberOfRecords';
	public static final String RECORD_ID_PARAM = 'recordId';
	public static final String SOBJECT_API_NAME_PARAM = 'sobjectApiName';
	public static final String SOBJECT_LABEL_PARAM = 'sobjectLabel';
	public static final String SOBJECT_LABEL_PLURAL_PARAM = 'sobjectLabelPlural';
	public static final String PARENT_RELATIONSHIP_API_NAME_PARAM = 'parentRelationshipApiName';
	public static final String RELATED_FIELD_API_NAME_PARAM = 'relatedFieldApiName';
	public static final String SORTED_DIRECTION_PARAM = 'sortedDirection';
	public static final String SORTED_BY_PARAM = 'sortedBy';
	public static final String RECORDS_PARAM = 'records';
	public static final String ICON_NAME_PARAM = 'iconName';

	@AuraEnabled
	public static String initData(String jsonData) {
		Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
		Map<String, Object> responseMap = new Map<String, Object>();
		responseMap.put(RECORDS_PARAM, getRecords(jsonData));

		String sobjectApiName = (String) requestMap.get(SOBJECT_API_NAME_PARAM);
		responseMap.put(ICON_NAME_PARAM, getIconName(sobjectApiName));
		String recordId = (String) requestMap.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String) requestMap.get(RELATED_FIELD_API_NAME_PARAM);
		responseMap.put(PARENT_RELATIONSHIP_API_NAME_PARAM, getParentRelationshipName(recordId, sobjectApiName, relatedFieldApiName));

		Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectApiName);
		Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
		responseMap.put(SOBJECT_LABEL_PARAM, sobjectDescribe.getLabel());
		responseMap.put(SOBJECT_LABEL_PLURAL_PARAM, sobjectDescribe.getLabelPlural());
		return JSON.serialize(responseMap);
	}

	@AuraEnabled
	public static List<Sobject> getRecords(String jsonData) {
		Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
		String sobjectApiName = (String) root.get(SOBJECT_API_NAME_PARAM);

		String fields = (String) root.get(FIELDS_PARAM) == 'all' ? getAllStringFields(sobjectApiName) : (String) root.get(FIELDS_PARAM);
		Integer numberOfRecords = (Integer) root.get(NUMBER_OF_RECORDS_PARAM);
		String recordId = (String) root.get(RECORD_ID_PARAM);
		String relatedFieldApiName = (String) root.get(RELATED_FIELD_API_NAME_PARAM);
		String orderBy = (String) root.get(SORTED_BY_PARAM) + ' ' + (String) root.get(SORTED_DIRECTION_PARAM);

		String query = 'SELECT ' + fields + ' FROM ' + sobjectApiName + ' WHERE ' + relatedFieldApiName + '= :recordId ORDER BY ' + orderBy + ' LIMIT :numberOfRecords';
		return Database.query(String.escapeSingleQuotes(query));
	}

	private static String getParentRelationshipName(Id recordId, String childSobjectApiName, String relatedFieldApiName) {
		Schema.DescribeSObjectResult descrRes = recordId.getSObjectType().getDescribe();
		String name;

		for (Schema.ChildRelationship cr : descrRes.getChildRelationships()) {
			if (cr.getChildSObject().getDescribe().getName() == childSobjectApiName && cr.getField().getDescribe().getName() == relatedFieldApiName) {
				name = cr.getRelationshipName();
				break;
			}
		}
		return name;
	}

	@AuraEnabled
	public static Boolean deleteRecord(Id recordId) {
		Sobject sobj = recordId.getSObjectType().newSObject(recordId);
		Database.DeleteResult result = Database.delete(sobj, true);
		return result.isSuccess();
	}

	@AuraEnabled
	public static String getIconName(String sobjectApiName) {
		String iconName;
		List<Schema.DescribeTabSetResult> tabSetDesc = Schema.DescribeTabs();
		List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
		List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

		for (Schema.DescribeTabSetResult tsr : tabSetDesc) {
			tabDesc.addAll(tsr.getTabs());
		}

		for (Schema.DescribeTabResult tr : tabDesc) {
			if (sobjectApiName == tr.getSobjectName()) {
				if (tr.isCustom()) {
					iconDesc.addAll(tr.getIcons());
				} else {
					iconName = 'standard:' + sobjectApiName.toLowerCase();
				}
			}
		}

		for (Schema.DescribeIconResult ir : iconDesc) {
			if (ir.getContentType() == 'image/svg+xml') {
				iconName = 'custom:' + ir.getUrl().substringBetween('custom/', '.svg').substringBefore('_');
				break;
			}
		}
		return iconName;
	}

	private static UserRecordAccess getRecordAccess(Id recordId) {
		Id userId = System.UserInfo.getUserId();
		return [SELECT RecordId, HasDeleteAccess, HasEditAccess, HasAllAccess FROM UserRecordAccess WHERE UserId = :userId AND RecordId = :recordId];
	}

	@AuraEnabled
	public static Boolean userCanDelete(Id recordId) {
		return getRecordAccess(recordId).HasDeleteAccess;
	}

	@AuraEnabled
	public static Boolean userCanEdit(Id recordId) {
		return getRecordAccess(recordId).HasEditAccess;
	}

	@AuraEnabled
	public static Boolean userCanCreate() {
		return Schema.sObjectType.Physical_Monitor__c.isCreateable();
	}

	@AuraEnabled
	public static List<Field> getFields(String sObjectName) {
		try {
			if (sObjectName == null || sObjectName == '') {
				return null;
			}

			List<Field> fields = new List<Field>();

			SObjectType customSObjecType = Schema.getGlobalDescribe().get(sObjectName);
			Map<String, Schema.SObjectField> mfields = customSObjecType.getDescribe().fields.getMap();

			List<Schema.SObjectField> listFields = mfields.values();
			//listFields.sort();
			List<String> fieldsNames = new List<String>();

			for (Schema.SObjectField curField : listFields) {
				fieldsNames.add(curField.getDescribe().getLabel());
			}

			fieldsNames.sort();

			for (String name : fieldsNames) {
				for (Schema.SObjectField curField : listFields) {
					if (name == String.valueOf(curField.getDescribe().getLabel())) {
						Field newField = new Field();
						newField.ApiName = curField.getDescribe().getName();
						newField.Label = curField.getDescribe().getLabel();

						String type = String.valueOf(curField.getDescribe().getType());

						if (type == 'STRING' || type == 'TEXTAREA' || type == 'PICKLIST') {
							newField.Type = 'text';
						} else if (type == 'DATE' || type == 'DATETIME') {
							newField.Type = 'date';
						} else if (type == 'DOUBLE') {
							newField.Type = 'number';
							//newField.IsDecimal = true;
						} else if (type == 'BOOLEAN') {
							newField.Type = 'boolean';
						} else if (type == 'CURRENCY') {
							newField.Type = 'currency';
						}

						newField.Type = String.valueOf(curField.getDescribe().getType());
						newField.Type = String.valueOf(curField.getDescribe());

						fields.add(newField);
						break;
					}
				}
			}

			//fields.sort();
			return fields;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string getAllStringFields(String sObjectName) {
		try {
			String strFields = '';

			for (Field fld : getFields(sObjectName)) {
				strFields += fld.ApiName + ',';
			}

			// List<Field> fields = getFields(sObjectName);

			// Integer size = fields.size();

			// for (Integer i = 0; i < size; i++) {
			//     strFields += fields[i].ApiName;
			//     if (i == size) {
			//         break;
			//     } else {
			//         strFields += ', ';
			//     }
			// }

			return strFields.removeEnd(',');
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Description: returns a JSON string with the columns for the data-table for the given recordId and api field Name.
	 * @Parameters:
	 * - containerRecordId: Recrod Id where the Json string is sotred.
	 * - containerApiFieldName: Api Name of the field where the Json value is stored.
	 */
	@AuraEnabled
	public static string getPatientCustomColuomns(String strContainerRecordId, String containerApiFieldName) {
		try {
			Id containerRecordId = Id.valueOf(strContainerRecordId);

			if (containerRecordId == null || containerApiFieldName == null || containerApiFieldName == '') {
				return null;
			}

			String objectName = String.valueOf(containerRecordId.getsobjecttype());
			String query = 'SELECT Id, ' + containerApiFieldName + ' FROM ' + objectName + ' WHERE Id =: containerRecordId';
			List<SObject> recordList = Database.query(query);

			if (recordList.isEmpty()) {
				return null;
			}

			String strJsonColumns = String.valueOf(recordList[0].get(containerApiFieldName));
			return strJsonColumns;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string saveCustomColumns(String strJsonColumns, String recordId, String fieldName) {
		try {
			if (strJsonColumns == null || strJsonColumns == '' || recordId == null || recordId == '' || fieldName == null || fieldName == '') {
				return null;
			}

			Id containerRecordId = Id.valueOf(recordId);

			String objectName = String.valueOf(containerRecordId.getsobjecttype());

			String query = 'SELECT Id, ' + fieldName + ' FROM ' + objectName + ' WHERE Id =: containerRecordId LIMIT 1';

			SObject objectResult = Database.query(query);

			objectResult.put(fieldName, strJsonColumns);

			update objectResult;

			return 'Success!!!!';
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class Field {
		@AuraEnabled
		public String ApiName { get; set; }
		@AuraEnabled
		public String Label { get; set; }
		@AuraEnabled
		public String Type { get; set; }
		@AuraEnabled
		public Boolean IsDecimal { get; set; }

		// public Field(String apiName, String label, String type) {
		//     this.ApiName = apiName;
		//     this.Label = label;
		//     this.Type = type;
		// }
	}
}