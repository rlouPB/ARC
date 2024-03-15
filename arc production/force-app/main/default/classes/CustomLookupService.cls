public with sharing class CustomLookupService {
	@AuraEnabled(cacheable=true)
	public static SearchResult[] SearchByText(string searchText, string sobjectType, string fieldName) {
		SearchResult[] results = new List<SearchResult>{};
		try {
			string likeSearch = '%' + searchText + '%';
			sobject[] queryResults = database.query('SELECT Id,' + fieldName + ' FROM ' + sobjectType + ' WHERE ' + fieldName + ' LIKE :likeSearch');
			for (Sobject result : queryResults) {
				results.add(new SearchResult(string.valueof(result.get('Id')), string.valueof(result.get(fieldName))));
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('CustomLookupService.Search', ex.getStackTraceString(), ex.getMessage());
		}
		return results;
	}

	@AuraEnabled(cacheable=true)
	public static SearchResult[] SearchByUserGroup(string searchText, string sobjectType, string fieldName) {
		SearchResult[] results = new List<SearchResult>{};
		try {
			string likeSearch = '%' + searchText + '%';
			String query = 'SELECT Id,' + fieldName + ' FROM ' + sobjectType + ' WHERE ' + fieldName + ' LIKE :likeSearch';

			String additionalWhereClause = '';
			if (sobjectType.EqualsIgnoreCase('User')) {
				additionalWhereClause = ' AND isActive = true AND UserType = \'Standard\' AND IsPortalEnabled = false ';
			} else if (sobjectType.EqualsIgnoreCase('Group__c')) {
				additionalWhereClause = ' AND Active__c = true AND Primary_Function__c = \'Staff\'';
			}

			if (String.isNotBlank(additionalWhereClause)) {
				query += additionalWhereClause;
			}

			sobject[] queryResults = database.query(query);

			for (Sobject result : queryResults) {
				results.add(new SearchResult(string.valueof(result.get('Id')), string.valueof(result.get(fieldName))));
			}
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('CustomLookupService.Search', ex.getStackTraceString(), ex.getMessage());
		}
		return results;
	}

	@AuraEnabled(cacheable=true)
	public static SearchResult SearchById(string recordId, string sobjectType, string fieldName) {
		try {
			sobject[] queryResults = database.query('SELECT Id,' + fieldName + ' FROM ' + sobjectType + ' WHERE Id =:recordId');
			for (Sobject result : queryResults) {
				return new SearchResult(string.valueof(result.get('Id')), ParserHelper.ToString(result, fieldName));
			}
		} catch (Exception ex) {
			system.debug('CustomLookupService.SearchById - ERROR: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
		}
		return null;
	}

	// @AuraEnabled(cacheable=true)
	@AuraEnabled
	public static SearchResult GetById(string recordId, string fieldName) {
		try {
			string prefix = recordId.substring(0, 3);
			EntityDefinition ed = [SELECT QualifiedApiName FROM EntityDefinition WHERE KeyPrefix = :prefix];
			sobject[] queryResults = database.query('SELECT Id,' + fieldName + ' FROM ' + ed.QualifiedApiName + ' WHERE Id =:recordId');
			for (Sobject result : queryResults) {
				return new SearchResult(string.valueof(result.get('Id')), ParserHelper.ToString(result, fieldName));
			}
		} catch (Exception ex) {
			system.debug('CustomLookupService.SearchById ( 2 ) - ERROR: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
		}
		return null;
	}

	@future
	static void debug(map<string, string> data) {
		insert new Process_Log__c(Process__c = 'CustomLookupService.SearchById - Debug', Detail__c = JSON.serialize(data));
	}
}