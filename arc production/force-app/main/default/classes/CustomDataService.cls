public without sharing class CustomDataService {
	@AuraEnabled
	public static string insertRecord(SObject record) {
		try {
			insert record;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static string updateRecord(SObject record) {
		try {
			update record;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static string updateRecords(SObject[] records) {
		try {
			update records;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}
}