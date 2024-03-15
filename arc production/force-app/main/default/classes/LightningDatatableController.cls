public class LightningDatatableController {
	@AuraEnabled
	public static Integer getTotalCount(String objectName, String filters) {
		Integer total = 0;
		if (SObjectUtils.isSObjectAccessible(objectName)) {
			String query = 'SELECT Count(Id) total FROM ' + objectName;

			if (String.isNotBlank(filters)) {
				List<SOQL_Objects.SOQL_Criterion> criteriaList = (List<SOQL_Objects.SOQL_Criterion>) JSON.deserialize(filters, List<SOQL_Objects.SOQL_Criterion>.class);

				List<SOQL_Objects.SOQL_Criterion> accessibleCriteriaList = SOQL_Utils.getAccessibleCriteriaList(objectName, criteriaList);

				if (!accessibleCriteriaList.isEmpty()) {
					String whereQuery = SOQL_Utils.generateWhereQuery(accessibleCriteriaList);
					query += ' WHERE ' + whereQuery;
				}
			}

			AggregateResult results = Database.query(query);
			total = (Integer) results.get('total');
		}
		return total;
	}

	@AuraEnabled
	public static DatatableResponse getDatatableResponse(String objectName, List<String> fieldNameList, String filters, Integer limitx, Integer offsetx) {
		DatatableResponse datatableResponse = new DatatableResponse();

		if (SObjectUtils.isSObjectAccessible(objectName)) {
			String query = 'SELECT Id';
			if (!fieldNameList.isEmpty()) {
				query += ', ';
				Set<String> fieldNameSet = new Set<String>(fieldNameList);

				Set<String> accessibleFieldNameSet = SObjectUtils.getAccessibleFieldNameSet(objectName, fieldNameSet);
				if (!accessibleFieldNameSet.isEmpty()) {
					query += String.join((Iterable<String>) accessibleFieldNameSet, ', ');

					List<Schema.DescribeFieldResult> accessibleDescribeFieldResultList = SObjectUtils.getAccessibleDescribeFieldResultList(objectName, accessibleFieldNameSet);
					if (!accessibleDescribeFieldResultList.isEmpty()) {
						List<DataTableColumn> datatableColumnList = new List<DataTableColumn>();
						for (Schema.DescribeFieldResult describeFieldResult : accessibleDescribeFieldResultList) {
							String dataType = String.valueOf(describeFieldResult.getType()).toLowerCase();
							//This way we can set the type of a column
							//We do not get the exact type from schema object which matches to lightning:datatable
							//component structure
							if (dataType == 'datetime') {
								dataType = 'date';
							}
							//Create a wrapper instance and store label, fieldname and type.
							DatatableColumn datacolumn = new DataTableColumn(String.valueOf(describeFieldResult.getLabel()), String.valueOf(describeFieldResult.getName()), dataType);
							datatableColumnList.add(datacolumn);
							datatableResponse.datatableColumnList = datatableColumnList;
						}
					}
				}
			}

			query += ' FROM ' + objectName;

			if (String.isNotBlank(filters)) {
				List<SOQL_Objects.SOQL_Criterion> criteriaList = (List<SOQL_Objects.SOQL_Criterion>) JSON.deserialize(filters, List<SOQL_Objects.SOQL_Criterion>.class);

				List<SOQL_Objects.SOQL_Criterion> accessibleCriteriaList = SOQL_Utils.getAccessibleCriteriaList(objectName, criteriaList);

				if (!accessibleCriteriaList.isEmpty()) {
					String whereQuery = SOQL_Utils.generateWhereQuery(accessibleCriteriaList);
					query += ' WHERE ' + whereQuery;
				}
			}

			Integer intLimit = integer.valueof(limitx);
			Integer intOffset = integer.valueof(offsetx);

			query += ' LIMIT ' + intLimit + ' OFFSET ' + intOffset;

			datatableResponse.dataList = Database.query(query);
		}

		return datatableResponse;
	}

	//Wrapper class to hold Columns with headers
	public class DatatableColumn {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String fieldName { get; set; }
		@AuraEnabled
		public String type { get; set; }

		//Create and set three variables label, fieldname and type as required by the lightning:datatable
		public DatatableColumn(String label, String fieldName, String type) {
			this.label = label;
			this.fieldName = fieldName;
			this.type = type;
		}
	}

	//Wrapper class to hold response - This response is used in the lightning:datatable component
	public class DatatableResponse {
		@AuraEnabled
		public List<DataTableColumn> datatableColumnList { get; set; }
		@AuraEnabled
		public List<sObject> dataList { get; set; }

		public DataTableResponse() {
			datatableColumnList = new List<DataTableColumn>();
			dataList = new List<sObject>();
		}
	}
}