public with sharing class PatientChartController {
	@AuraEnabled(cacheable=true)
	public static List<Object> getChartMetricData(String objectName, String fieldName1, String fieldName2, String fieldName3, String fieldName4, String patientField, String asOfDateStr, String dateField, Id patientId) {
		String soqlQuery = '';
		if (asOfDateStr == null) {
			asOfDateStr = String.valueOf(Date.today());
			asOfDateStr = asOfDateStr.removeEnd(' 00:00:00');
		} else {
			asOfDateStr = asOfDateStr.removeEnd(' 00:00:00');
		}

		if (fieldName2 != null) {
			if (fieldName3 != null) {
				if (fieldName4 != null) {
					soqlQuery += 'SELECT Id, ' + fieldName1 + ', ' + fieldName2 + ', ' + fieldName3 + ', ' + fieldName4 + ' FROM ' + objectName;
				} else {
					soqlQuery += 'SELECT Id, ' + fieldName1 + ', ' + fieldName2 + ', ' + fieldName3 + ' FROM ' + objectName;
				}
			} else {
				soqlQuery += 'SELECT Id, ' + fieldName1 + ', ' + fieldName2 + ' FROM ' + objectName;
			}
		} else {
			soqlQuery += 'SELECT Id, ' + fieldName1 + ' FROM ' + objectName;
		}

		soqlQuery += ' WHERE ' + patientField + ' = \'' + patientId + '\'';
		soqlQuery += ' AND ' + dateField + ' <= ' + asOfDateStr;
		soqlQuery += ' ORDER BY ' + dateField + ' ASC';
		soqlQuery += ' LIMIT 20';
		List<Object> q = Database.query(soqlQuery);

		if (q == null) {
			q = new List<Object>();
		}

		return q;
	}

	@AuraEnabled
	public static List<String> getPicklistValues(String objectName, String fieldName) {
		// Get dataset list/dataset count from picklist values
		List<String> picklistVals = new List<String>();
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
		for (String fn : fieldsMap.keySet()) {
			if (fn == fieldName) {
				Schema.DescribeFieldResult fieldRes = fieldsMap.get(fn).getDescribe();
				List<Schema.PicklistEntry> ple = fieldRes.getPicklistValues();
				for (Schema.PicklistEntry f : ple) {
					picklistVals.add(String.valueOf(f.getValue()));
				}
			}
		}

		return picklistVals;
	}

	/*   Outer joins are difficult when querying for aggregate values, such as record counts.
     Child relationships in SOQL do not allow for aggregate values, so Salesforce's version of an outer join is taken out of play.
     getAggregateChartData() creates a default list of all expected 'records' returned in the dataset, all counts defaulted to 0.
     Then, using the SOQL query results, it 'overlays' the count in the matching default ObjectWrapper
     So the return List<ObjectWrapper> is an outer join result, except it uses a different process to get to the return value. */
	@AuraEnabled
	public static List<ObjectWrapper> getAggregateChartData(String objectName, String fieldName, String patientField, String dateRange, String dateField, String isDateTime, Id accountId) {
		List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
		List<ObjectWrapper> updateWrapperList = new List<ObjectWrapper>();
		String soqlQuery = '';
		String dateLiteral = convertDateRangeToSOQLConstant(dateRange);
		DateInfoWrapper dateWrapper = new DateInfoWrapper(dateLiteral);
		Boolean endDateIsToday = isEndDateToday(dateRange);
		Integer numMonths = getNumberMonthsFromDateRange(dateRange);
		List<String> datasets = getPicklistValues(objectName, fieldName);

		// Seed the dataset, which uses ObjectWrapper
		objectWrappers = createDefaultObjectWrappers(datasets, dateLiteral, numMonths, dateWrapper.startMonth, dateWrapper.startYear);

		// Construct SOQL query
		soqlQuery += 'SELECT  ' + fieldName + ' aggDatasetVal, CALENDAR_MONTH(' + dateField + ') aggMonth, CALENDAR_YEAR(' + dateField + ') aggYear, COUNT(' + patientField + ') aggCount';
		soqlQuery += ' FROM ' + objectName;
		soqlQuery += ' WHERE ' + patientField + ' = \'' + accountId + '\'';
		soqlQuery += ' AND ' + dateField + ' = ' + dateLiteral;
		soqlQuery += ' GROUP BY ' + fieldName + ', CALENDAR_YEAR(' + dateField + '), CALENDAR_MONTH(' + dateField + ')';
		soqlQuery += ' ORDER BY CALENDAR_YEAR(' + dateField + '), CALENDAR_MONTH(' + dateField + '), ' + fieldName;
		soqlQuery += ' LIMIT 20';

		// Execute SOQL query
		List<AggregateResult> queryresult = Database.query(soqlQuery);

		if (queryresult == null) {
			// If no queryresult, prepare empty wrapper for return
			objectWrappers = new List<ObjectWrapper>();
		} else {
			// Overwrite counts in ObjectWrapper when applicable
			for (AggregateResult o : queryresult) {
				for (ObjectWrapper ow : objectWrappers) {
					if (ow.picklistValue == o.get('aggDatasetVal') && ow.month == Integer.valueOf(o.get('aggMonth')) && ow.year == Integer.valueOf(o.get('aggYear'))) {
						ow.count = Integer.valueOf(o.get('aggCount'));
						updateWrapperList.add(ow);
					}
				}
			}
		}
		return objectWrappers;
	}

	@AuraEnabled(cacheable=true)
	public static List<Object> getChartTimeData(String objectName, String fieldName, String patientField, String dateField, Id patientId) {
		String soqlQuery = '';
		soqlQuery += 'SELECT Id, ' + dateField + ', ' + fieldName + ' FROM ' + objectName;
		soqlQuery += ' WHERE ' + patientField + ' = \'' + patientId + '\'';
		soqlQuery += ' AND ' + fieldName + ' != null';
		soqlQuery += ' ORDER BY ' + dateField + ' DESC NULLS LAST';
		soqlQuery += ' LIMIT 20';
		List<Object> q = Database.query(soqlQuery);
		if (q == null) {
			q = new List<Object>();
		}
		return q;
	}

	@AuraEnabled(cacheable=true)
	public static String convertDateRangeToSOQLConstant(String dateRange) {
		if (dateRange == 'This Year') {
			return 'THIS_YEAR';
		} else if (dateRange == 'This Quarter') {
			return 'THIS_QUARTER';
		} else if (dateRange == 'This Month') {
			return 'THIS_MONTH';
		} else if (dateRange == 'Last Year') {
			return 'LAST_YEAR';
		} else if (dateRange == 'Last Quarter') {
			return 'LAST_QUARTER';
		} else if (dateRange == 'Last Month') {
			return 'LAST_MONTH';
		} else if (dateRange == 'Last 6 Months') {
			return 'LAST_N_MONTHS:6';
		} else if (dateRange == 'Last 12 Months') {
			return 'LAST_N_MONTHS:12';
		} else if (dateRange == 'All-Time') {
			return null;
		} else {
			return 'THIS_YEAR';
		}
	}

	public static Boolean isEndDateToday(String dateRange) {
		if (dateRange == 'This Year') {
			return true;
		} else if (dateRange == 'This Quarter') {
			return true;
		} else if (dateRange == 'This Month') {
			return true;
		} else if (dateRange == 'Last Year') {
			return false;
		} else if (dateRange == 'Last Quarter') {
			return false;
		} else if (dateRange == 'Last Month') {
			return false;
		} else if (dateRange == 'Last 6 Months') {
			return true;
		} else if (dateRange == 'Last 12 Months') {
			return true;
		} else {
			return true;
		}
	}

	@AuraEnabled(cacheable=true)
	public static Integer getNumberMonthsFromDateRange(String dateRange) {
		if (dateRange == 'This Year') {
			return Integer.valueOf(Date.today().month());
		} else if (dateRange == 'This Quarter') {
			if (Integer.valueOf(Date.today().month()) == 1 || Integer.valueOf(Date.today().month()) == 4 || Integer.valueOf(Date.today().month()) == 7 || Integer.valueOf(Date.today().month()) == 10) {
				return 1;
			} else if (Integer.valueOf(Date.today().month()) == 2 || Integer.valueOf(Date.today().month()) == 5 || Integer.valueOf(Date.today().month()) == 8 || Integer.valueOf(Date.today().month()) == 11) {
				return 2;
			} else {
				return 3;
			}
		} else if (dateRange == 'This Month') {
			return 1;
		} else if (dateRange == 'Last Year') {
			return 12;
		} else if (dateRange == 'Last Quarter') {
			return 3;
		} else if (dateRange == 'Last Month') {
			return 1;
		} else if (dateRange == 'Last 6 Months') {
			return 6;
		} else if (dateRange == 'Last 12 Months') {
			return 12;
		} else if (dateRange == 'All-Time') {
			return null;
		} else {
			return Integer.valueOf(Date.today().month());
		}
	}

	@AuraEnabled(cacheable=true)
	public static String getAccountId(Id recordId, String accountField) {
		String objectName = getObjectNameFromRecordId(recordId);
		String soqlQuery = '';

		if (objectName == 'Account') {
			soqlQuery += 'SELECT Id FROM Account';
		} else {
			soqlQuery += 'SELECT ' + accountField + ' FROM ' + objectName;
		}

		soqlQuery += ' WHERE Id = \'' + recordId + '\'';
		soqlQuery += ' LIMIT 1';
		sObject obj = Database.query(soqlQuery);

		if (objectName == 'Account') {
			return String.valueOf(obj.get('Id'));
		} else {
			return String.valueOf(obj.get(accountField));
		}
	}

	public static String getObjectNameFromRecordId(Id recordId) {
		String objectName = '';
		String idPrefix = String.valueOf(recordId).substring(0, 3);
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Schema.SObjectType stype : gd.values()) {
			Schema.DescribeSObjectResult r = stype.getDescribe();
			String prefix = r.getKeyPrefix();

			if (prefix != null && prefix.equals(idPrefix)) {
				objectName = r.getName();
				break;
			}
		}
		return objectName;
	}

	@AuraEnabled(cacheable=true)
	public static String getAccountNameFromId(Id accountId) {
		String soqlQuery = '';
		soqlQuery += 'SELECT Id, Name FROM Account';
		soqlQuery += ' WHERE Id = \'' + accountId + '\'';
		soqlQuery += ' LIMIT 1';
		sObject obj = Database.query(soqlQuery);
		return String.valueOf(obj.get('Name'));
	}

	@AuraEnabled(cacheable=true)
	public static String getFieldLabel(String objectName, String fieldName) {
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
		Schema.DescribeFieldResult fieldRes = fieldsMap.get(fieldName).getDescribe();
		return fieldRes.getLabel();
	}

	@AuraEnabled(cacheable=true)
	public static List<String> getFieldLabels(String objectName, String fieldName1, String fieldName2, String fieldName3, String fieldName4) {
		List<String> labels = new List<String>();
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
		Schema.DescribeFieldResult fieldRes = fieldsMap.get(fieldName1).getDescribe();
		labels.add(fieldRes.getLabel());
		if (fieldName2 != null) {
			fieldRes = fieldsMap.get(fieldName2).getDescribe();
			labels.add(fieldRes.getLabel());
		}
		if (fieldName3 != null) {
			fieldRes = fieldsMap.get(fieldName3).getDescribe();
			labels.add(fieldRes.getLabel());
		}
		if (fieldName4 != null) {
			fieldRes = fieldsMap.get(fieldName4).getDescribe();
			labels.add(fieldRes.getLabel());
		}
		return labels;
	}

	@AuraEnabled
	public static String getFormattedLabel(Integer mon, Integer yr) {
		if (mon == 1) {
			return 'January ' + String.valueOf(yr);
		} else if (mon == 2) {
			return 'February ' + String.valueOf(yr);
		} else if (mon == 3) {
			return 'March ' + String.valueOf(yr);
		} else if (mon == 4) {
			return 'April ' + String.valueOf(yr);
		} else if (mon == 5) {
			return 'May ' + String.valueOf(yr);
		} else if (mon == 6) {
			return 'June ' + String.valueOf(yr);
		} else if (mon == 7) {
			return 'July ' + String.valueOf(yr);
		} else if (mon == 8) {
			return 'August ' + String.valueOf(yr);
		} else if (mon == 9) {
			return 'September ' + String.valueOf(yr);
		} else if (mon == 10) {
			return 'October ' + String.valueOf(yr);
		} else if (mon == 11) {
			return 'November ' + String.valueOf(yr);
		} else {
			return 'December ' + String.valueOf(yr);
		}
	}

	@AuraEnabled
	public static List<ObjectWrapper> createDefaultObjectWrappers(List<String> datasetNames, String dateLiteral, Integer numMonths, Integer startMonth, Integer startYear) {
		List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
		if (dateLiteral == 'LAST_YEAR') {
			for (Integer j = 0; j < datasetNames.size(); j++) {
				for (Integer i = 0; i < 12; i++) {
					objectWrappers.add(new ObjectWrapper(datasetNames[j], i + 1, startYear));
				}
			}
		} else {
			for (Integer j = 0; j < datasetNames.size(); j++) {
				for (Integer i = numMonths - 1; i > -1; i--) {
					objectWrappers.add(new ObjectWrapper(datasetNames[j], Date.today().addMonths(-i).month(), Date.today().addMonths(-i).year()));
				}
			}
		}

		return objectWrappers;
	}
	public class ObjectWrapper {
		@AuraEnabled
		public Integer count { get; set; }
		@AuraEnabled
		public Integer month { get; set; }
		@AuraEnabled
		public Integer year { get; set; }
		@AuraEnabled
		public String formattedMonthYear { get; set; }
		@AuraEnabled
		public String picklistValue { get; set; }

		public ObjectWrapper(AggregateResult agg, String field) {
			count = (Integer) agg.get('aggCount');
			formattedMonthYear = getFormattedLabel((Integer) agg.get('aggMonth'), (Integer) agg.get('aggYear'));
			month = (Integer) agg.get('aggMonth');
			picklistValue = (String) agg.get(field);
			year = (Integer) agg.get('aggYear');
		}
		public ObjectWrapper(String datasetNm, Integer mon, Integer yr) {
			count = 0;
			formattedMonthYear = getFormattedLabel(mon, yr);
			month = mon;
			picklistValue = datasetNm;
			year = yr;
		}
	}

	public class DateInfoWrapper {
		@AuraEnabled
		public Integer thisMonth { get; set; }
		@AuraEnabled
		public Integer thisQuarter { get; set; }
		@AuraEnabled
		public Integer thisYear { get; set; }
		@AuraEnabled
		public Integer lastMonth { get; set; }
		@AuraEnabled
		public Integer lastQuarter { get; set; }
		@AuraEnabled
		public Integer lastYear { get; set; }
		@AuraEnabled
		public Integer startMonth { get; set; }
		@AuraEnabled
		public Integer startYear { get; set; }
		@AuraEnabled
		public Integer endMonth { get; set; }
		@AuraEnabled
		public Integer endYear { get; set; }
		@AuraEnabled
		public Integer numMonths { get; set; }

		public DateInfoWrapper(String dateLiteral) {
			thisMonth = Date.today().month();
			lastMonth = Date.today().addMonths(-1).month();
			thisYear = Date.today().year();
			lastYear = Date.today().addYears(-1).year();

			if (thisMonth >= 1 && thisMonth <= 3) {
				thisQuarter = 1;
				lastQuarter = 4;
			} else if (thisMonth >= 4 && thisMonth <= 6) {
				thisQuarter = 2;
				lastQuarter = 1;
			} else if (thisMonth >= 7 && thisMonth <= 9) {
				thisQuarter = 3;
				lastQuarter = 2;
			} else {
				thisQuarter = 4;
				lastQuarter = 3;
			}

			if (dateLiteral == 'THIS_YEAR') {
				startMonth = 1;
				startYear = Integer.valueOf(Date.today().year());
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = Integer.valueOf(Date.today().month());
			} else if (dateLiteral == 'THIS_QUARTER') {
				if (thisQuarter == 1) {
					startMonth = 1;
				} else if (thisQuarter == 2) {
					startMonth = 4;
				} else if (thisQuarter == 3) {
					startMonth = 7;
				} else if (thisQuarter == 4) {
					startMonth = 10;
				}

				startYear = Integer.valueOf(Date.today().year());
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = Integer.valueOf(Date.today().month());
			} else if (dateLiteral == 'THIS_MONTH') {
				startMonth = thisMonth;
				startYear = thisYear;
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = Integer.valueOf(Date.today().month());
			} else if (dateLiteral == 'LAST_YEAR') {
				startMonth = 1;
				startYear = lastYear;
				endMonth = 12;
				endYear = lastYear;
				numMonths = 12;
			} else if (dateLiteral == 'LAST_QUARTER') {
				numMonths = 3;
				if (lastQuarter == 4) {
					startMonth = 10;
					startYear = lastYear;
					endMonth = 12;
					endYear = lastYear;
				} else {
					startYear = thisYear;
					endYear = thisYear;
					if (lastQuarter == 3) {
						startMonth = 7;
						endMonth = 9;
					} else if (lastQuarter == 2) {
						startMonth = 4;
						endMonth = 6;
					} else if (lastQuarter == 1) {
						startMonth = 1;
						endMonth = 3;
					}
				}
			} else if (dateLiteral == 'LAST_MONTH') {
				startMonth = lastMonth;
				endMonth = lastMonth;
				if (thisMonth == 1) {
					startYear = lastYear;
					endYear = lastYear;
				} else {
					startYear = thisYear;
					endYear = thisYear;
				}
				numMonths = 1;
			} else if (dateLiteral == 'LAST_N_MONTHS:12') {
				startMonth = thisMonth + 1;
				startYear = lastYear;
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = 12;
			} else if (dateLiteral == 'LAST_N_MONTHS:6') {
				startMonth = Integer.valueOf(Date.today().addMonths(-6).month());
				startYear = Integer.valueOf(Date.today().addMonths(-6).year());
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = 6;
			} else {
				startMonth = 1;
				startYear = Integer.valueOf(Date.today().year());
				endMonth = thisMonth;
				endYear = thisYear;
				numMonths = Integer.valueOf(Date.today().month());
			}
		}
	}
}