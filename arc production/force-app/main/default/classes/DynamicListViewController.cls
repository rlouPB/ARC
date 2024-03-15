/**
 * @author
 * @date 2022
 *
 *
 * @description Create a lightning-datatable based on configuration inputs to create lists, related lists, filtered lists, and filtered related lists.
 *   Based off of http://sfdcmonkey.com/2018/01/05/lightning-datatable-base-component/
 */
public with sharing class DynamicListViewController {
	/*
    Purpose:  Create a lightning-datatable based on configuration inputs to create lists, related lists, filtered lists, and filtered related lists.
    Based off of http://sfdcmonkey.com/2018/01/05/lightning-datatable-base-component/
    */
	@AuraEnabled(cacheable=true)
	public static DataTableResponse getSobjectRecords(String sObjectName, String fieldSetName, String sObjectLookupIDField, String additionalWhereClause, String recordId, Boolean includeName, String orderBy, Boolean showMyRecordsOnly, Boolean enableColumnSorting) {
		//List to hold table headers
		List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
		//Fields to be queried from fieldset
		List<String> lstFieldsToQuery = new List<String>();
		//Final wrapper response to return to component
		DataTableResponse response = new DataTableResponse();

		//Get the fields from FieldSet
		Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(sObjectName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		//Replace NOW() with current datetime
		if (!String.isEmpty(additionalWhereClause)) {
			if (additionalWhereClause.contains('NOW()')) {
				DateTime currentDateTime = Datetime.now();
				additionalWhereClause = additionalWhereClause.replace('NOW()', ':currentDateTime');
			}
		}
		for (Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields()) {
			String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
			//This way we can set the type of a column
			//We do not get the exact type from schema object which matches to lightning-datatable component structure
			if (dataType == 'datetime') {
				dataType = 'date';
			} else if (dataType == 'picklist') {
				dataType = 'string';
			}
			//Create a wrapper instance and store label, fieldname and type.
			DataTableColumns datacolumns = new DataTableColumns(String.valueOf(eachFieldSetMember.getLabel()), String.valueOf(eachFieldSetMember.getFieldPath()), dataType, Boolean.valueOf(enableColumnSorting));
			lstDataColumns.add(datacolumns);
			lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()).toLowercase());
		}
		String queryStartsWith = 'SELECT ';
		lstFieldsToQuery.add('id');
		//if Name field is included (option on component)
		if (includeName) {
			lstFieldsToQuery.add('name');
		}
		//remove duplicate fields
		Set<String> fieldsToQuerySet = new Set<String>(lstFieldsToQuery);
		lstFieldsToQuery = new List<String>(fieldsToQuerySet);
		//SOQL Queries for different lists:  lists, related lists, filtered lists, and filtered related lists
		String query = '';

		if (!lstDataColumns.isEmpty() && String.isEmpty(recordId) && String.isEmpty(additionalWhereClause) && String.isEmpty(sObjectLookupIDField)) {
			//List
			query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName;
		} else if (!lstDataColumns.isEmpty() && String.isEmpty(additionalWhereClause)) {
			//Related List
			query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName + ' WHERE ' + sObjectLookupIDField + ' = \'' + recordId + '\'';
		} else if (!lstDataColumns.isEmpty() && String.isEmpty(recordId)) {
			//Filtered List
			query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName + ' WHERE (' + additionalWhereClause + ' )';
		} else {
			//Filtered Related List
			query = queryStartsWith + String.join(lstFieldsToQuery, ',') + ' FROM ' + sObjectName + ' WHERE ' + sObjectLookupIDField + '= \'' + recordId + '\'' + ' AND ( ' + additionalWhereClause + ' )';
		}
		if (showMyRecordsOnly) {
			Schema.SObjectType convertedType = Schema.getGlobalDescribe().get(sObjectName);
			if (convertedType.getDescribe().fields.getMap().keySet().contains('ownerid')) {
				if (query.indexOf('WHERE') == -1) {
					query += ' WHERE ';
				} else {
					query += ' AND ';
				}
				String userId = UserInfo.getUserId();
				query += 'OwnerId = :userId';
			}
		}
		if (!String.isEmpty(orderBy)) {
			query = query + ' order by ' + orderBy;
		}

		response.dataTableData = Database.query(query);
		response.listColumns = lstDataColumns;
		return response;
	}

	/*******************************************************************************************************
	 * @description Wrapper class to hold Columns with headers
	 */
	public class DataTableColumns {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String fieldName { get; set; }
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public String typeAttributes { get; set; }
		@AuraEnabled
		public Boolean sortable { get; set; }

		/*******************************************************************************************************
		 * @description Constructor: Create and set variables required by lightning-datatable (label, fieldname, and type)
		 * @param label field label
		 * @param fieldName the name of the field to display
		 * @param type the data type
		 */
		public DataTableColumns(String label, String fieldName, String type, Boolean sortable) {
			this.label = label;
			this.fieldName = fieldName;
			this.sortable = sortable;
			if (type == 'datetime') {
				this.type = 'date';
			} else if (type == 'date') {
				this.type = 'date-local';
			} else if (type == 'textarea') {
				this.type = 'richtextfield';
			} else {
				this.type = type;
			}
			//richTextfield
		}
	}

	public class FieldAttribute {
	}

	/*******************************************************************************************************
	 * @description Wrapper calss to hold response
	 *
	 */
	public class DataTableResponse {
		@AuraEnabled
		public List<DataTableColumns> listColumns { get; set; }
		@AuraEnabled
		public List<sObject> dataTableData { get; set; }

		public DataTableResponse() {
			listColumns = new List<DataTableColumns>();
			dataTableData = new List<sObject>();
		}
	}
}