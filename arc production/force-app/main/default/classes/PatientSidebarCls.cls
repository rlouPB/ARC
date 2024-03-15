global with sharing class PatientSidebarCls {
	/**
	 * Class used to get FieldDefinition records
	 */
	public without sharing class finder {
		public finder() {
		}
		public EntityDefinition getDefinition(string recordId) {
			return [SELECT QualifiedAPiName FROM EntityDefinition WHERE KeyPrefix = :recordId.substring(0, 3)];
		}
		public map<string, Schema.DescribeFieldResult> getFieldsByRelationshipName(Schema.DescribeSObjectResult dsor) {
			map<string, Schema.DescribeFieldResult> resMap = new Map<string, Schema.DescribeFieldResult>();
			for (Schema.SObjectField sr : dsor.fields.getMap().values()) {
				Schema.DescribeFieldResult f = sr.getDescribe();
				if (f.getType() == Schema.DisplayType.REFERENCE) {
					resMap.put(f.getRelationshipName(), f);
				}
			}
			return resMap;
		}
	}

	global class Field {
		@auraenabled
		public string name;

		@auraenabled
		public string label;

		@auraenabled
		public string type;

		@auraenabled
		public boolean isAccessible;
	}

	global class ResultWrapper {
		@AuraEnabled
		global sobject record;

		@AuraEnabled
		global Field[] fields;

		@AuraEnabled
		global string errorMessage;

		@AuraEnabled
		global string stackTrace;
	}

	/**
	 * loadRecordData queries and generates a result that the PatientSidebar component will use to show
	 * @param  recordId   The record Id of the target object to the the info of.
	 * @param  fieldNames List of fields to include in the search ( Example: ['Name','Owner.Profile.Name']).
	 * @return            return Instance of ResultWrapper that PatientSidebar will use
	 */
	@AuraEnabled(cacheable=true)
	global static ResultWrapper loadRecordData(string recordId, string[] fieldNames) {
		ResultWrapper result = new ResultWrapper();
		try {
			finder fn = new finder();
			string sobjectType = fn.getDefinition(recordId).QualifiedAPiName;
			map<string, Schema.SObjectType> gdesc = Schema.getGlobalDescribe();
			map<string, Schema.DescribeSObjectResult> dsorMap = new Map<string, Schema.DescribeSObjectResult>{ sobjectType => gdesc.get(sobjectType).getDescribe() };
			set<string> fieldsToInclude = new Set<string>();
			set<string> fieldNamesSet = new Set<string>(fieldNames);
			result.fields = new List<Field>();
			map<String, map<string, Schema.DescribeFieldResult>> relMapCache = new Map<String, map<string, Schema.DescribeFieldResult>>();
			for (string fieldDir : fieldNamesSet) {
				string[] fieldParts = fieldDir.split('\\.');
				string fieldName = fieldParts[fieldParts.size() - 1];
				string currentSobjectType = '' + sobjectType;
				Schema.DescribeSObjectResult currentDsor = dsorMap.get(currentSobjectType);
				if (fieldParts.size() > 1) {
					for (integer i = 0; i < (fieldParts.size() - 1); i++) {
						if (!relMapCache.containsKey(currentDsor.getName())) {
							relMapCache.put(currentDsor.getName(), fn.getFieldsByRelationshipName(currentDsor));
						}
						Schema.DescribeFieldResult rel = relMapCache.get(currentDsor.getName()).get(fieldParts[i]);
						currentDsor = rel.getReferenceTo()[0].getDescribe();
					}
				}

				Schema.DescribeFieldResult descField = currentDsor.fields.getMap().get(fieldName.toLowerCase()).getDescribe();
				if (descField.isAccessible()) {
					fieldsToInclude.add(fieldDir);

					Field newField = new Field();
					newField.name = fieldDir;
					newField.type = '' + descField.getType();
					newField.label = descField.getLabel();

					result.fields.add(newField);
				}
			}

			string query = 'SELECT ' + string.join(new List<string>(fieldsToInclude), ',') + ' FROM ' + sobjectType + ' WHERE Id =:recordId';
			result.record = database.query(query);
		} catch (Exception ex) {
			result.record = null;
			result.fields = null;
			result.errorMessage = ex.getMessage();
			result.stackTrace = ex.getStackTraceString();
		}
		return result;
	}
}