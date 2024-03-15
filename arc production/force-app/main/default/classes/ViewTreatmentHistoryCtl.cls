public without sharing class ViewTreatmentHistoryCtl {
	public static Map<String, Schema.SObjectType> allObjectsMap = new Map<String, Schema.SObjectType>();

	@AuraEnabled
	public static String getTreatmentHistory(String treatmentHistoryString) {
		TreatmentHistory treatmentHistory = (TreatmentHistory) JSON.deserializeStrict(treatmentHistoryString, TreatmentHistory.class);
		List<HistoryItem> itemList = new List<HistoryItem>();
		try {
			treatmentHistory.hasMedicalRecord = FeatureManagement.checkPermission('Medical_Records');
			if (treatmentHistory.startDate == null) {
				treatmentHistory.startDate = System.today();
			}
			if (treatmentHistory.endDate == null) {
				treatmentHistory.endDate = System.today();
			}
			if (treatmentHistory.lastWeeks != null) {
				treatmentHistory.startDate = System.today().addDays(treatmentHistory.lastWeeks * -7);
				treatmentHistory.endDate = System.today();
			}
			if (treatmentHistory.moveMonths != null && treatmentHistory.moveMonths != 0) {
				treatmentHistory.startDate = treatmentHistory.startDate.addMonths(treatmentHistory.moveMonths);
				treatmentHistory.endDate = treatmentHistory.endDate.addMonths(treatmentHistory.moveMonths);
			}
			Set<Id> expressionIdSet = new Set<Id>();
			Set<String> sObjectSet = new Set<String>();
			Map<Id, Filter_Expression__mdt> filterExpressionMap = new Map<Id, Filter_Expression__mdt>();
			String patientId = treatmentHistory.patientId;
			Date startDate = treatmentHistory.startDate;
			Date endDate = treatmentHistory.endDate.addDays(1);

			List<Treatment_History_Definition__mdt> treatmentHistoryDefinitionList = [SELECT Id, Label__c, MasterLabel, DeveloperName, Query_Fields__c, Detail_to_Display__c, Sobject__c, Patient_Lookup_Field__c, Date_Field__c, Filter_Expression__c, Display_Record_Link__c, Record_to_Link_To_Field__c, Display_Component_Name__c, Display_Component_Parameters__c FROM Treatment_History_Definition__mdt WHERE MasterLabel = :treatmentHistory.viewOptionItemLabelList];
			for (Treatment_History_Definition__mdt treatmentHistoryDefinition : treatmentHistoryDefinitionList) {
				if (String.isNotBlank(treatmentHistoryDefinition.Filter_Expression__c)) {
					expressionIdSet.add(treatmentHistoryDefinition.Filter_Expression__c);
				}

				if (String.isNotBlank(treatmentHistoryDefinition.Sobject__c)) {
					sObjectSet.add(treatmentHistoryDefinition.Sobject__c);
				}
			}
			if (!expressionIdSet.isEmpty()) {
				filterExpressionMap = new Map<ID, Filter_Expression__mdt>([SELECT ID, Expression__c FROM Filter_Expression__mdt WHERE ID IN :expressionIdSet]);
			}
			if (!sObjectSet.isEmpty()) {
				for (String sName : sObjectSet) {
					SObjectType r = ((SObject) Type.forName('Schema', sName).newInstance()).getSObjectType();
					allObjectsMap.put(sName, r);
				}
			}

			List<String> detailFieldList; //used for building {{}} detail
			List<sObject> sObjectList;
			DefinedFilters.Expression expression;

			for (Treatment_History_Definition__mdt treatmentHistoryDefinition : treatmentHistoryDefinitionList) {
				Set<String> queryFieldSet = new Set<String>{ 'Id', 'Name', 'CreatedBy.Name', 'CreatedBy.Professional_Name__c' };

				detailFieldList = new List<String>();
				if (String.isNotBlank(treatmentHistoryDefinition.Query_Fields__c)) {
					List<String> rawStrings = treatmentHistoryDefinition.Query_Fields__c.split(',');
					for (String rawFieldName : rawStrings) {
						detailFieldList.add(rawFieldName.trim());
						queryFieldSet.add(rawFieldName.trim());
					}
				}

				queryFieldSet.add(treatmentHistoryDefinition.Date_Field__c);
				queryFieldSet.add(treatmentHistoryDefinition.Record_to_Link_To_Field__c);

				//add OwnerId if sObject supports it
				List<String> types = new List<String>{ treatmentHistoryDefinition.Sobject__c };
				List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(types);
				if (results.size() > 0 && results[0].fields.getMap().get('OwnerId') != null) {
					queryFieldSet.add('OwnerId');
				}

				//specific object fields
				if ('Case' == treatmentHistoryDefinition.Sobject__c) {
					queryFieldSet.remove('Name');
					queryFieldSet.add('CaseNumber');
				}
				if ('Patient_Note__c' == treatmentHistoryDefinition.Sobject__c) {
					queryFieldSet.add('Psych_Testing_Request__c');
				}

				queryFieldSet.remove('');
				queryFieldSet.remove(null);

				List<String> queryFieldList = new List<String>(queryFieldSet);
				Schema.DisplayType fType = allObjectsMap.get(treatmentHistoryDefinition.Sobject__c).getDescribe().fields.getMap().get(treatmentHistoryDefinition.Date_Field__c).getDescribe().getType();
				String query = 'SELECT ' + String.join(queryFieldList, ',') + ' FROM ' + treatmentHistoryDefinition.Sobject__c + ' WHERE ' + treatmentHistoryDefinition.Patient_Lookup_Field__c + ' =:patientId';
				if (!treatmentHistory.selectAll) {
					if (fType == Schema.DisplayType.DATETIME) {
						query += ' AND DAY_ONLY(convertTimezone(' + treatmentHistoryDefinition.Date_Field__c + ')) >= :startDate';
						query += ' AND DAY_ONLY(convertTimezone(' + treatmentHistoryDefinition.Date_Field__c + ')) < :endDate';
					} else if (fType == Schema.DisplayType.DATE) {
						query += ' AND ' + treatmentHistoryDefinition.Date_Field__c + ' >= :startDate';
						query += ' AND ' + treatmentHistoryDefinition.Date_Field__c + ' < :endDate';
					}
				}

				sObjectList = Database.query(query);
				expression = null;
				if (String.isNotBlank(treatmentHistoryDefinition.Filter_Expression__c)) {
					Filter_Expression__mdt filterExpression = filterExpressionMap.get(treatmentHistoryDefinition.Filter_Expression__c);
					if (filterExpression != null) {
						expression = new DefinedFilters.Expression(filterExpression);
					}
				}
				List<Id> recordIds = new List<Id>();
				for (sObject sObj : sObjectList) {
					if (expression == null || expression.includes(sObj)) {
						recordIds.add(sObj.Id);
					}
				}
				//ARC-2455 View Treatment History: Number of records exceeds limit: 200
				// Boolean userInPatientGroup = false;
				// Account patient = [SELECT Id, Current_Admission__c FROM Account where Id = :patientId];

				// List<Admission__c> admList = [SELECT Id, Team__c FROM Admission__c WHERE Id = :patient.Current_Admission__c];
				// if (!admList.isEmpty()) {
				// 	Admission__c adm = admList[0];
				// 	String team = 'Team '+ adm.Team__c;

				// 	Map<Id, User> mapUsers = new Map<Id, User>([SELECT Id
				// 												FROM User
				// 												WHERE Id IN
				// 														(SELECT Staff_Member__c
				// 														FROM Staff_Group_Member__c
				// 														WHERE Group_Name__r.Type__c = 'Team'
				// 															AND Group_Name__r.Name = : team
				// 															AND (Planned_End_Date__c >= TODAY OR Planned_End_Date__c = null))]);

				// 	Set<Id> groupMemberSet = mapUsers.keySet();

				// 	if(groupMemberSet.contains(userInfo.getUserId())) {
				// 		userInPatientGroup = true;
				// 	}
				// }
				//arc-2426 Completed Notes are shared to same group
				// Set<Id> userHasReadAccessSet = new Set<Id>();
				// Set<Id> userHasEditAccessSet = new Set<Id>();
				// if(recordIds.size() > 0) {
				// 	List<UserRecordAccess> recordAccessList = [SELECT RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess FROM UserRecordAccess where userId = :userInfo.getUserId() AND RecordId in :recordIds];
				// 	for(UserRecordAccess ua : recordAccessList) {
				// 		if(ua.HasReadAccess) {
				// 			userHasReadAccessSet.add(ua.RecordId);
				// 		}
				// 		if(ua.HasEditAccess) {
				// 			userHasEditAccessSet.add(ua.RecordId);
				// 		}
				// 	}
				// }
				for (sObject sObj : sObjectList) {
					if (expression == null || expression.includes(sObj)) {
						HistoryItem item = new HistoryItem(sObj, treatmentHistoryDefinition, detailFieldList, treatmentHistory.context);
						itemList.add(item);
					}
				}
			}
			itemList.sort();
		} catch (Exception e) {
			ProcessLogging.quickProcessLog('ViewTreatmentHistoryCtl', e.getStackTraceString(), e.getMessage());
		}

		treatmentHistory.itemList = itemList;
		return JSON.serialize(treatmentHistory);
	}
}