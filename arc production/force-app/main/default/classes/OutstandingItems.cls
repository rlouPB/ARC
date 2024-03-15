public class OutstandingItems {
	public static List<Outstanding_Item_Rule__mdt> rules;
	List<ID> recordIDs;
	@TestVisible
	List<sObject> records;
	String objectType;
	@TestVisible
	static Map<String, List<String>> objectTypeToImportantFieldsMap;
	@TestVisible
	List<Outstanding_Tag__c> tagsToDelete;
	@TestVisible
	List<Outstanding_Tag__c> tagsToInsert;
	@TestVisible
	static Map<String, List<Outstanding_Item_Rule__mdt>> objectTypeToOutstandingItemRulesMap;
	@TestVisible
	Map<String, Outstanding_Tag__c> existingTagMap;
	@TestVisible
	Map<String, Outstanding_Tag__c> draftTagMap;
	@TestVisible
	static Map<ID, Filter_Expression__mdt> filterExpressions;
	public static String outstandingItemRulesQueryString;

	public OutstandingItems(List<ID> recordIDs, String objectType) {
		this.recordIDs = recordIDs;
		this.objectType = objectType;

		objectTypeToImportantFieldsMap = new Map<String, List<String>>();
		objectTypeToOutstandingItemRulesMap = new Map<String, List<Outstanding_Item_Rule__mdt>>();
		existingTagMap = new Map<String, Outstanding_Tag__c>();
		draftTagMap = new Map<String, Outstanding_Tag__c>();
		tagsToDelete = new List<Outstanding_Tag__c>();
		tagsToInsert = new List<Outstanding_Tag__c>();

		try {
			queryRules();
			queryRecords();
			queryExistingTags();
			buildDraftTags();
			compareTags();
		} catch (Exception e) {
			//create new and send all
			ProcessLogging.addProcessLog('OutstandingItems constructor', e.getStackTraceString(), e.getMessage() + '\n\nRecord Ids:\n' + this.recordIDS);
		}
		ProcessLogging.commitProcessLogs();
	}

	// remove static for method
	private static void queryRules() {
		if (objectTypeToOutstandingItemRulesMap.isEmpty()) {
			rules = [SELECT sObject__c, DeveloperName, Assigned_To_Field__c, Tag_Create_Date_Reference_Field__c, Target_Date_Reference_Field__c, Tag_Create_Delay__c, Target_Date_Delay__c, Entry_Filter_Expression__r.Expression__c, Assignment_Type__c, Entry_Filter_Expression__c, Patient_Lookup_Field__c, Long_Tag_Label_Format__c, Document_Type__c, Document_Type__r.MasterLabel, MasterLabel, Queue_Name__c, Record_to_Link_To_Field__c FROM Outstanding_Item_Rule__mdt];

			List<ID> expressionIDs = new List<ID>();
			for (Outstanding_Item_Rule__mdt currentRule : rules) {
				expressionIDs.add(currentRule.Entry_Filter_Expression__c);
			}

			filterExpressions = new Map<ID, Filter_Expression__mdt>([SELECT ID, Expression__c FROM Filter_Expression__mdt WHERE ID IN :expressionIDs]);

			for (Outstanding_Item_Rule__mdt currentRule : rules) {
				List<String> listOfFields = objectTypeToImportantFieldsMap.get(currentRule.sObject__c);
				if (listOfFields == null) {
					listOfFields = new List<String>();
				}
				Set<String> importantFields = new Set<String>(listOfFields);
				// Important field string format is
				// "Outstanding_Item_Rule__mdt.DeveloperName:Field API name on Outstanding_Tag__c:Field value from
				// Outstanding_Item_Rule__mdt"
				// if (currentRule.Assigned_To_Field__c != null) {
				if ((currentRule.Assignment_Type__c == null || currentRule.Assignment_Type__c.contains('Individual')) && currentRule.Assigned_To_Field__c != null) {
					importantFields.add(currentRule.DeveloperName + ':OwnerId:' + currentRule.Assigned_To_Field__c);
				}
				// Set outstanding_tag field to "Create Date" because while the reference field is needed for SOQL,
				// special application is needed in buildDraftTags()
				if (currentRule.Tag_Create_Date_Reference_Field__c != null) {
					importantFields.add(currentRule.DeveloperName + ':Create Date:' + currentRule.Tag_Create_Date_Reference_Field__c);
				}
				if (currentRule.Target_Date_Reference_Field__c != null) {
					importantFields.add(currentRule.DeveloperName + ':Target_Date__c:' + currentRule.Target_Date_Reference_Field__c);
				}
				if (currentRule.Patient_Lookup_Field__c != null && currentRule.Patient_Lookup_Field__c != 'n/a') {
					importantFields.add(currentRule.DeveloperName + ':Patient__c:' + currentRule.Patient_Lookup_Field__c);
				}
				if (currentRule.Record_to_Link_To_Field__c != null) {
					importantFields.add(currentRule.DeveloperName + ':Record_ID_to_link_to__c:' + currentRule.Record_to_Link_To_Field__c);
				}

				// Deserialize Entry Filter Expression and add needed fields to list.
				if (currentRule.Entry_Filter_Expression__c != null && currentRule.Entry_Filter_Expression__r.Expression__c != null) {
					DefinedFilters.Expression exp = (DefinedFilters.Expression) JSON.deserialize(currentRule.Entry_Filter_Expression__r.Expression__c, DefinedFilters.Expression.class);
					List<String> allExpressionFields = getFieldsFromExpression(exp);
					importantFields.addAll(allExpressionFields);
				}
				if (currentRule.Long_Tag_Label_Format__c != null) {
					sObject sobj;
					List<String> fieldsFromFormat = processLabelFormat(currentRule.Long_Tag_Label_Format__c, sobj);
					// Pattern patt = Pattern.compile('\\{\\{.*\\}\\}');
					// Matcher match = patt.matcher(currentRule.Long_Tag_Label_Format__c);
					// while (match.find())
					// {
					// 	String m = match.group(0);
					// 	m = m.replace('{{', '');
					// 	m = m.replace('}}', '');
					// 	importantFields.add(m);
					// }
					importantFields.addAll(fieldsFromFormat);
				}

				objectTypeToImportantFieldsMap.put(currentRule.sObject__c, new List<String>(importantFields));

				List<Outstanding_Item_Rule__mdt> currentSObjectRules = objectTypeToOutstandingItemRulesMap.get(currentRule.sObject__c);
				if (currentSObjectRules == null) {
					currentSObjectRules = new List<Outstanding_Item_Rule__mdt>();
				}
				currentSObjectRules.add(currentRule);
				objectTypeToOutstandingItemRulesMap.put(currentRule.sObject__c, currentSObjectRules);
			}
		}
	}

	// Helper method to pull all field APIs from Expression object
	private static list<String> getFieldsFromExpression(DefinedFilters.Expression exp) {
		List<String> namesToReturn = new List<String>();
		if (exp.fieldName == null) {
			for (DefinedFilters.Expression subExp : exp.expressions) {
				namesToReturn.addAll(getFieldsFromExpression(subExp));
			}
		} else {
			namesToReturn.add(exp.fieldName);
		}

		return namesToReturn;
	}

	private void queryRecords() {
		if (recordIDs.size() >= 1) {
			outstandingItemRulesQueryString = 'SELECT ';
			Set<String> fieldAPIs = new Set<String>();
			List<String> importantFields = objectTypeToImportantFieldsMap.get(objectType);
			if (importantFields == null) {
				fieldAPIs.add('id');
			} else {
				for (String currentString : importantFields) {
					if (currentString.contains(':')) {
						fieldAPIs.add((currentString.substringAfterLast(':')).toLowerCase());
					} else {
						fieldAPIs.add(currentString.toLowerCase());
					}
				}
			}
			// fieldAPIs.remove(null);
			// fieldAPIs.remove('null');
			outstandingItemRulesQueryString += String.join(new List<String>(fieldAPIs), ', ');

			outstandingItemRulesQueryString += ' FROM ' + objectType + ' WHERE ID IN :recordIDs';

			this.records = Database.query(outstandingItemRulesQueryString);
		} else {
			this.records = new List<sObject>();
		}
	}

	private void queryExistingTags() {
		List<Outstanding_Tag__c> existingTags = [SELECT Outstanding_Item_Rule__c, Patient__c, Target_Date__c, OwnerId, Record_ID__c FROM Outstanding_Tag__c WHERE Object__c = :this.objectType AND Record_ID__c IN :this.recordIDs];

		for (Outstanding_Tag__c currentTag : existingTags) {
			existingTagMap.put(currentTag.Record_ID__c + UserInfo.getUserId() + currentTag.Outstanding_Item_Rule__c + currentTag.Target_Date__c, currentTag);
		}
	}

	private void buildDraftTags() {
		List<Outstanding_Item_Rule__mdt> sObjectRules = objectTypeToOutstandingItemRulesMap.get(objectType);
		if (sObjectRules == null) {
			sObjectRules = new List<Outstanding_Item_Rule__mdt>();
		}
		List<String> importantFields = objectTypeToImportantFieldsMap.get(objectType);
		if (importantFields == null) {
			importantFields = new List<String>();
		}

		//Collect Patient IDs
		Set<Id> setPatientIDs = new Set<Id>();
		set<string> queueNames = new Set<string>();

		for (sObject currentRecord : records) {
			for (Outstanding_Item_Rule__mdt currentRule : sObjectRules) {
				if (getFilterResult(currentRecord, currentRule) && currentRule.Patient_Lookup_Field__c != null && currentRule.Patient_Lookup_Field__c != 'n/a') {
					//setPatientIDs.add((Id)currentRecord.get(currentRule.Patient_Lookup_Field__c));
					setPatientIds.add((Id) SObjectUtils.getFieldValue(currentRecord, currentRule.Patient_Lookup_Field__c));
				}
				if (currentRule.Assignment_Type__c == 'Queue' && String.isNotBlank(currentRule.Queue_Name__c)) {
					queueNames.add(currentRule.Queue_Name__c);
				}
			}
		}

		Map<Id, Map<String, Id>> mapPatientQueue = ClinicalTeams.getTeamQueueIdByPatientMap(setPatientIDs);
		map<string, Group> queuesMap = new Map<string, Group>();
		for (Group q : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN :queueNames]) {
			queuesMap.put(q.Name, q);
		}

		for (sObject currentRecord : records) {
			for (Outstanding_Item_Rule__mdt currentRule : sObjectRules) {
				// Check filter entry criteria.
				if (getFilterResult(currentRecord, currentRule)) {
					Boolean cancelDraft = false;
					String docTypeString = ((currentRule.Document_Type__c != null) ? currentRule.Document_Type__r.MasterLabel : currentRule.MasterLabel);

					String longTagLabel = docTypeString;
					Id patientLookupId = (currentRule.Patient_Lookup_Field__c != 'n/a' && currentRule.Patient_Lookup_Field__c != null) ? (Id) SObjectUtils.getFieldValue(currentRecord, currentRule.Patient_Lookup_Field__c) : null;
					Outstanding_Tag__c newTag = new Outstanding_Tag__c(
						//Patient__c = (Id)currentRecord.get(currentRule.Patient_Lookup_Field__c),
						Patient__c = patientLookupId,
						Outstanding_Item_Rule__c = currentRule.ID,
						Document_Type__c = docTypeString,
						Object__c = this.objectType,
						Record_ID__c = currentRecord.ID
					);
					newTag.Long_Tag_Label__c = buildLongTagLabel(currentRecord, currentRule, docTypeString);

					if (!cancelDraft) {
						for (String currentString : importantFields) {
							if (currentString.substringBefore(':') == currentRule.DeveloperName) {
								// Only create draft if today matches Create Date criteria based on Rule fields.
								if (currentString.substringBetween(':') == 'Create Date') {
									DateTime compareDate = (DateTime) currentRecord.get(currentString.substringAfterLast(':'));
									compareDate = compareDate.addDays((Integer) currentRule.Tag_Create_Delay__c);
									if (Date.today() >= Date.valueOf(compareDate)) {
										cancelDraft = true;
										// break; // DA : 6-May-2022 : commented out as other fields don't get set if we break.
									}
								} else if (currentString.substringBetween(':') == 'Target_Date__c') {
									//Steve M 9/19/20  current string contains field api name, not date
									//DateTime compareDate = (DateTime)currentRecord.get(currentString.substringAfterLast(':'));
									Object fieldValue = currentRecord.get(currentString.substringAfterLast(':'));
									DateTime compareDate = (DateTime) fieldValue;
									//Steve M 9/19/20 -end
									if (currentRule.Target_Date_Delay__c != null) {
										if (compareDate == null) {
											compareDate = Date.today();
										}
										compareDate = compareDate.addDays((Integer) currentRule.Target_Date_Delay__c);
									}
									if (Date.today() >= Date.valueOf(compareDate)) {
										cancelDraft = true;
										// break; // DA : 6-May-2022 : commented out as other fields don't get set if we break.
									}
									newTag.put('Target_Date__c', Date.valueOf(compareDate));
								} else if (currentString.contains(':')) {
									String fieldAPIName = currentString.substringBetween(':');
									String recordFieldAPIName = currentString.substringAfterLast(':');
									// Get the value from the field name provided
									//Object fieldValue = currentRecord.get(recordFieldAPIName);
									Object fieldValue = SObjectUtils.getFieldValue(currentRecord, recordFieldAPIName);
									// Put the value into the new tag's proper field
									newTag.put(fieldAPIName, fieldValue);
								}
							}
						}

						if (currentRule.Assignment_Type__c == 'Team' || currentRule.Assignment_Type__c == 'Team Authorized Signers') {
							string ruleName = currentRule.DeveloperName;
							String queueType = currentRule.Assignment_Type__c;
							String patientId = newTag.Patient__c;
							Map<String, Id> queueTypeMap = mapPatientQueue.get(patientId);
							Object queueTypeObj = queueTypeMap.get(queueType);
							Id newOwnerId = (Id) queueTypeObj;
							newTag.OwnerId = newOwnerId;
						} else if (currentRule.Assignment_Type__c == 'Queue' && queuesMap.containsKey(currentRule.Queue_Name__c)) {
							newTag.OwnerId = queuesMap.get(currentRule.Queue_Name__c).Id;
						} else if (currentRule.Assignment_Type__c == 'Queue' && queuesMap.containsKey(currentRule.Queue_Name__c) != true) {
							throw new CustomException('Queue Name [' + currentRule.Queue_Name__c + '] not found.');
						}
						draftTagMap.put(newTag.Record_ID__c + newTag.OwnerId + newTag.Outstanding_Item_Rule__c + newTag.Target_Date__c, newTag);
					}
				}
			}
		}
	}

	private Boolean getFilterResult(sObject record, Outstanding_Item_Rule__mdt rule) {
		Boolean result = false;
		Filter_Expression__mdt filter = filterExpressions.get(rule.Entry_Filter_Expression__c);
		DefinedFilters currentInstance = new DefinedFilters(filter);

		for (DefinedFilters.Expression currentExp : currentInstance.expressionList) {
			result = currentExp.includes(record);
			if (result == false) {
				break;
			}
		}

		return result;
	}

	public String buildLongTagLabel(sObject record, Outstanding_Item_Rule__mdt rule, String docTypeString) {
		String longTagString = docTypeString;
		if (rule.Long_Tag_Label_Format__c != null) {
			List<String> labelStrings = processLabelFormat(rule.Long_Tag_Label_Format__c, record);
			longTagString = labelStrings[0];
		}
		return longTagString;
	}
	//returns list<String>, first String in list is formatted string, the rest of are the fieldnames
	public static List<String> processLabelFormat(String genericString, sObject record) {
		List<String> pieces = genericString.split('\\{\\{');
		Set<String> fields = new Set<String>();
		for (String piece : pieces) {
			if (piece.contains('}}')) {
				List<String> subPieces = piece.split('\\}\\}');
				fields.add(subPieces[0]);
			}
		}

		if (record == null)
			return new List<String>(fields);

		pieces = genericString.split('\\{\\{');
		String newString = '';
		for (String piece : pieces) {
			if (piece.contains('}}')) {
				List<String> subPieces = piece.split('\\}\\}');
				subPieces.add(''); //protect against merge field at end of expression

				String fieldName = subPieces[0];
				if (fieldName.contains('.')) {
					List<String> fieldPieces = fieldName.split('\\.');
					String fieldValue = String.valueOf(record.getSobject(fieldPieces[0]).get(fieldPieces[1]));
					newString += fieldValue;
				} else {
					newString += String.valueOf(record.get(fieldName));
				}
				newString += subPieces[1];
			} else {
				newString += piece;
			}
		}
		List<String> returnList = new List<String>{ newString };
		returnList.addAll(fields);

		return returnList;
	}

	public static Object getFieldValue(sObject record, String longFieldName) {
		if (longFieldName.contains('.')) {
			List<String> fieldNames = longFieldName.split('\\.');
			sObject newObject = record.getSobject(fieldNames[0]);
			String newLongFieldName = '';

			for (Integer i = 1; i < fieldNames.size(); i++) {
				newLongFieldName = +fieldNames[i];
			}
			return getFieldValue(newObject, newLongFieldName);
		} else {
			return record.get(longFieldName);
		}
	}

	private void compareTags() {
		for (String currentKey : draftTagMap.keySet()) {
			if (existingTagMap.containsKey(currentKey)) {
				existingTagMap.remove(currentKey);
				draftTagMap.remove(currentKey);
			} else {
				tagsToInsert.add(draftTagMap.get(currentKey));
			}
		}

		tagsToDelete.addAll(existingTagMap.values());
	}

	public void commitTags() {
		try {
			delete tagsToDelete;
			insert tagsToInsert;
		} catch (Exception ex) {
			ProcessLogging.quickProcessLog('OutstandingItems.commitTags', ex.getStackTraceString(), 'tagsToInsert: ' + String.valueOf(tagsToInsert) + '\n\nMessage: ' + ex.getMessage());
		}
	}

	public static void checkOutstandingItems(List<Check_Outstanding__e> eventRecords) {
		Map<String, List<Check_Outstanding__e>> objectTypeToCheckEvent = new Map<String, List<Check_Outstanding__e>>();

		for (Check_Outstanding__e currentEvent : eventRecords) {
			List<Check_Outstanding__e> objectTypeEvents = objectTypeToCheckEvent.get(currentEvent.Object_type__c);
			if (objectTypeEvents == null) {
				objectTypeEvents = new List<Check_Outstanding__e>();
			}
			objectTypeEvents.add(currentEvent);
			objectTypeToCheckEvent.put(currentEvent.Object_type__c, objectTypeEvents);
		}

		for (String currentObject : objectTypeToCheckEvent.keySet()) {
			List<Check_Outstanding__e> objectEvents = objectTypeToCheckEvent.get(currentObject);
			Set<ID> recordIDs = new Set<ID>();
			for (Check_Outstanding__e currentEvent : objectEvents) {
				recordIDs.add(currentEvent.RecordId__c);
			}
			OutstandingItems newInstance = new OutstandingItems(new List<ID>(recordIDs), currentObject);
			newInstance.commitTags();
		}
	}

	public static void fireCheckOutstandingEvent(List<sObject> records) {
		String objectType = String.valueOf(records[0].getSObjectType());
		List<Check_Outstanding__e> checksToInsert = new List<Check_Outstanding__e>();
		for (sObject currentRecord : records) {
			Check_Outstanding__e currentCheck = new Check_Outstanding__e(Object_type__c = objectType, RecordId__c = currentRecord.ID);
			checksToInsert.add(currentCheck);
		}
		EventBus.publish(checksToInsert);
	}

	public static void deleteRelatedTags(List<sObject> records) {
		List<String> recordIDs = new List<String>();
		for (sObject currentRecord : records) {
			recordIDs.add(currentRecord.ID);
		}

		List<Outstanding_Tag__c> openItemsToDelete = [SELECT ID FROM Outstanding_Tag__c WHERE Record_ID__c IN :recordIDs];
		delete openItemsToDelete;
	}
}