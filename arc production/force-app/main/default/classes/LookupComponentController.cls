public class LookupComponentController {
	//static Integer defaultMaxRows = 5;
	static Date today = Date.today();

	//overload for default maxRows
	//@AuraEnabled
	//public static String fetchRecords(String searchKeyWord,
	//                                  String objectName,
	//                                  String fieldsToSearch,
	//                                  String displayField,
	//                                  String displayFieldValue,
	//                                  String filterStr,
	//                                  Boolean splitSearchTextBySeperator)
	//{
	//    return fetchRecords(searchKeyWord,
	//                        objectName,
	//                        fieldsToSearch,
	//                        displayField,
	//                        displayFieldValue,
	//                        filterStr,
	//                        splitSearchTextBySeperator,
	//                        defaultMaxRows,
	//                        '');
	//}

	@AuraEnabled
	public static String fetchRecords(
		String searchKeyWord,
		String objectName,
		String fieldsToSearch,
		String displayField,
		String displayFieldValue,
		//String filterStr,
		//List<Criterion> filters,
		String serializedFilters,
		Boolean splitSearchTextBySeperator,
		Integer maxRows,
		String specialSearchOptions,
		String orderByClause
	) {
		maxRows = Integer.valueOf(maxRows);
		List<SObject> sobjectList = new List<SObject>();
		List<RecordWrapper> recWrapperList = new List<RecordWrapper>();

		//List<Criterion> filters = (List<Criterion>)JSON.deserialize(serializedFilters, List<Criterion>.class);
		List<Object> filters = (List<Object>) JSON.deserializeUntyped(serializedFilters);

		if (String.isBlank(objectName) || String.isBlank(fieldsToSearch) || String.isBlank(displayField)) {
			return JSON.serialize(recWrapperList);
		}

		if (String.isBlank(displayFieldValue)) {
			displayFieldValue = 'Id';
		}
		Set<String> fieldsToQuery = new Set<String>{ displayFieldValue, displayField };

		if (String.isEmpty(orderByClause)) {
			orderByClause = '';
		} else {
			List<String> pieces = orderByClause.trim().split(',');
			for (String piece : pieces) {
				if (!String.isEmpty(piece)) {
					fieldsToQuery.add(piece.trim().split(' ')[0].trim());
				}
			}
			orderByClause = ' ORDER BY ' + orderByClause.trim();
		}

		String fieldsAndObject = buildfieldsAndObject(fieldsToQuery, objectName);
		String limitClause = ' LIMIT ' + maxRows;

		List<SObject> searchList = new List<SObject>();
		Integer searchResultCount = 0;
		if (!String.isEmpty(specialSearchOptions)) {
			String specialSearchClause = buildSpecialSearchClause(fieldsToSearch, objectName, searchKeyWord, filters, specialSearchOptions);
			String specialSearchQuery = fieldsAndObject + specialSearchClause + orderByClause + limitClause;

			List<SObject> specialSearchList = Database.query(specialSearchquery);

			searchList.addAll(specialSearchList);
			searchResultCount += specialSearchList.size();
		}

		String searchClause = buildSearchClause(fieldsToSearch, searchKeyWord, splitSearchTextBySeperator, filters);
		String searchquery = fieldsAndObject + searchClause + orderByClause + limitClause;
		Set<Id> alreadyFoundIds = new Map<Id, SObject>(searchList).keySet();

		List<SObject> normalSearchList = Database.query(searchquery);
		for (SObject normalObj : normalSearchList) {
			if (
				!alreadyFoundIds.contains(normalObj.Id) // && searchList.size() < maxRows)
			) {
				searchList.add(normalObj);
				searchResultCount++;
			}
		}

		//for (Integer i = 0; i < maxRows; i++)
		Integer recWrapperCount = 0;
		for (SObject rec : searchList) {
			if (recWrapperCount < maxRows) {
				//SObject rec = searchList[i];

				RecordWrapper recWrapper = new RecordWrapper();
				recWrapper.label = (String) getFieldValue(rec, displayField);
				recWrapper.value = (String) getFieldValue(rec, displayFieldValue);
				recWrapper.isRecord = true;
				recWrapperList.add(recWrapper);
				recWrapperCount++;
			}
		}
		return JSON.serialize(recWrapperList);
	}

	static Object getFieldValue(sObject sObj, String fieldString) {
		if (fieldString.contains('.')) {
			List<String> pieces = fieldString.split('\\.', 2);
			return getFieldValue(sObj.getsObject(pieces[0]), pieces[1]);
		}
		return sObj.get(fieldString);
	}

	static String buildfieldsAndObject(Set<String> fieldsToQuery, String objectName) {
		String fieldsAndObject = 'SELECT Id';

		// Set<String> fieldsToQuery = new Set<String>();
		// fieldsToQuery.add(displayField);
		// fieldstoQuery.add(displayFieldValue);

		for (String field : fieldsToQuery) {
			if (field != 'Id') {
				fieldsAndObject += ', ' + field;
			}
		}

		fieldsAndObject += ' FROM ' + objectName;
		return fieldsAndObject;
	}

	//WHERE clause for "special" search if noted in specialSearchOptions
	@TestVisible
	static String buildSpecialSearchClause(
		String fieldsToSearch,
		String objectName,
		String searchKeyWord,
		List<Object> filters,
		String specialSearchOptions //String filterStr,
	) {
		String searchClause = '';
		if (String.isNotBlank(searchKeyWord)) {
			if (specialSearchOptions.containsIgnoreCase('FirstLast|Starting')) {
				String objRel = (objectName == 'Contact') ? '' : 'Patient_Contact__r.';
				//if multiple terms, first term must start FirstName or LastName, the rest of the terms must start LastName or FirstName (opposite of first term)
				//e.g. "Joh Den" will match John Denver or Dennis Johnson, but not John Johnson
				//if single term, must start FirstName or LastName
				List<String> twoTerms = searchKeyWord.split(' ', 2);
				String term1 = twoTerms[0];
				if (twoTerms.size() == 1) {
					searchClause = '(' + objRel + 'FirstName LIKE \'' + String.escapeSingleQuotes(term1).trim() + '%\' OR ' + objRel + 'LastName LIKE \'' + String.escapeSingleQuotes(term1).trim() + '%\')';
				} else {
					String term2 = twoTerms[1];

					searchClause = '((' + objRel + 'FirstName LIKE \'' + String.escapeSingleQuotes(term1).trim() + '%\' AND ' + objRel + 'LastName LIKE \'' + String.escapeSingleQuotes(term2).trim() + '%\')' + ' OR (' + objRel + 'LastName LIKE \'' + String.escapeSingleQuotes(term1).trim() + '%\' AND ' + objRel + 'FirstName LIKE \'' + String.escapeSingleQuotes(term2).trim() + '%\'))';
				}
			}
		}

		//if(String.isNotBlank(filterStr))
		if (!filters.isEmpty()) {
			if (String.isNotBlank(searchClause)) {
				searchClause += ' AND ';
			}
			searchClause += getFilterString(filters);
		}

		if (String.isNotBlank(searchClause))
			searchClause = ' WHERE ' + searchClause;

		return searchClause;
	}

	static String buildSearchClause(
		String fieldsToSearch,
		String searchKeyWord,
		Boolean splitSearchTextBySeperator,
		List<Object> filters //String filterStr)
	) {
		String searchClause = '';
		if (String.isNotBlank(fieldsToSearch) && String.isNotBlank(searchKeyWord)) {
			List<String> fields = fieldsToSearch.split(',');
			List<String> searchwords = new List<String>();

			if (splitSearchTextBySeperator != null && splitSearchTextBySeperator == true) {
				List<String> searchKeyWords = searchKeyWord.split(' ');

				for (String keyWord : searchKeyWords) {
					searchwords.add('%' + String.escapeSingleQuotes(keyWord).trim() + '%');
				}
			} else {
				searchwords.add('%' + String.escapeSingleQuotes(searchKeyWord).trim() + '%');
			}

			//counter to start new field in loop
			String currentField;
			List<String> fieldFilters = new List<String>();
			for (String field : fields) {
				String thisFieldFilter = '';
				for (String searchWord : searchWords) {
					if (currentField != field) {
						currentField = field;
					} else {
						thisFieldFilter += ' AND ';
					}

					thisFieldFilter += field + ' LIKE \'' + searchword + '\'';
				}
				if (thisFieldFilter != '') {
					fieldFilters.add('(' + thisFieldFilter + ')');
				}
			}

			searchClause += '(';
			//combine fields with OR
			Boolean firstField = true;
			for (String fieldFilter : fieldFilters) {
				if (firstField) {
					firstField = false;
				} else {
					searchClause += ' OR';
				}
				searchClause += ' ' + fieldFilter;
			}
			//end clause
			searchClause += ')';
		}

		//if(String.isNotBlank(filterStr))
		//{
		//    searchClause += (String.isNotBlank(searchClause) ? ' AND ' : ' ') + filterStr;
		//}
		if (!filters.isEmpty()) {
			if (String.isNotBlank(searchClause)) {
				searchClause += ' AND ';
			}
			searchClause += getFilterString(filters);
		}

		if (searchClause != '')
			searchClause = ' WHERE ' + searchClause;
		return searchClause;
	}

	static String getFilterString(List<Object> filters) {
		String returnString = '';

		//for (Criterion crit : crits)
		for (Object filterObj : filters) {
			Map<String, Object> filterMap = (Map<String, Object>) filterObj;

			//format value assuming it is a String with no quotes around it that might have single-quotes in it
			String valueString = '\'' + String.valueOf(filterMap.get('value')).replace('\'', '\\\'') + '\'';

			//if condition indicates ('IN') or value looks like a Boolean, do not reformat value
			if (String.valueOf(filterMap.get('condition')).equalsIgnoreCase('IN') || filterMap.get('value') instanceof Boolean) {
				valueString = String.valueOf(filterMap.get('value'));
			}

			String soqlCriteria = String.valueOf(filterMap.get('fieldName')) + ' ' + String.valueOf(filterMap.get('condition')) + ' ' + valueString;

			if (String.isNotBlank(returnString)) {
				returnString += ' AND ';
			}
			returnString += soqlCriteria;
		}
		return returnString;
	}

	@AuraEnabled
	public static String getRecord(String objectName, String displayField, String displayFieldValue, String currentRecordId) {
		List<SObject> sobjectList = new List<SObject>();
		RecordWrapper returnWrapper = new RecordWrapper();

		if (String.isBlank(objectName) || String.isBlank(displayField) || String.isBlank(displayFieldValue) || String.isBlank(currentRecordId)) {
			return JSON.serialize(returnWrapper);
		}
		Set<String> displayFields = new Set<String>{ displayField, displayFieldValue };
		List<SObject> searchList;

		if (!displayFields.isEmpty()) {
			String searchquery = 'SELECT ' + String.join(new List<String>(displayFields), ',') + ' FROM ' + objectName + ' WHERE ' + displayFieldValue + ' = \'' + currentRecordId + '\'';
			searchList = Database.query(searchquery);
		}
		RecordWrapper recWrapper = new RecordWrapper();

		if (!searchList.isEmpty()) {
			recWrapper.label = (String) getFieldValue(searchList[0], displayField);
			recWrapper.value = (String) getFieldValue(searchList[0], displayFieldValue);
			recWrapper.isRecord = true;
		}

		return JSON.serialize(recWrapper);
	}

	public class RecordWrapper {
		public String label;
		public String value;
		public Boolean isRecord;
	}

	//public class Criterion
	//{
	//    public String fieldName;
	//    public String condition;
	//    public String value;

	//    //public Criterion(String fieldName, String fieldValue)
	//    //{
	//    //    this(fieldName, '=', fieldValue);
	//    //}
	//    public Criterion(String fieldName, String condition, String fieldValue)
	//    {
	//        this.fieldName = fieldName;
	//        this.condition = condition;
	//        this.value = fieldValue;
	//    }

	//    //public String getSOQLCriteria()
	//    //{
	//    //    String valueString = '\'' + String.valueOf(this.value).replace('\'', '\\\'') + '\'';
	//    //    //if (value instanceOf Boolean
	//    //    //    || value instanceOf Date
	//    //    //    || value instanceOf Datetime)
	//    //    //{
	//    //    //    valueString = String.valueOf(this.value);
	//    //    //}
	//    //    String soqlCriteria = this.fieldName + ' '  + this.condition + ' ' + valueString;
	//    //    return soqlCriteria;
	//    //}

	//}
}