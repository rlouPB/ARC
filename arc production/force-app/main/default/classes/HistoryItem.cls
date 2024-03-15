public with sharing class HistoryItem implements Comparable {
	public static Map<String, Map<String, Schema.DescribeFieldResult>> sobjectFieldsBySobjectName = new Map<String, Map<String, Schema.DescribeFieldResult>>();

	public static String dateFormat = 'MM/dd/yyyy';
	public static String dateTimeFormatString = 'MM/dd/yyyy hh:mm a';
	public static String timeZoneString = 'America/New_York'; //always use American Eastern time

	// @AuraEnabled
	// public String sobjectName{get;set;}

	@AuraEnabled
	public sObject record { get; set; }

	@AuraEnabled
	public String details { get; set; }

	// @AuraEnabled
	// public Map<String, String> fieldNameLabelMap{get;set;}

	// @AuraEnabled
	// public Map<String, String> fieldNameValueMap{g7et;set;}

	@AuraEnabled
	public Date itemDate { get; set; }

	@AuraEnabled
	public String URL { get; set; }

	@AuraEnabled
	public String urlLabel { get; set; }

	@AuraEnabled
	public String ownerId { get; set; }

	@AuraEnabled
	public Treatment_History_Definition__mdt definition { get; set; }
	@testVisible
	public HistoryItem() {
	}
	public HistoryItem(sObject sObj, Treatment_History_Definition__mdt treatmentHistoryDefinition, List<String> fieldList, String context) {
		this.definition = treatmentHistoryDefinition;
		this.record = sObj;
		this.details = buildDetails(sObj, treatmentHistoryDefinition.Detail_to_Display__c, fieldList);

		Object fieldValue = SObjectUtils.getFieldValue(sObj, treatmentHistoryDefinition.Date_Field__c);

		Schema.DescribeFieldResult fieldDescribe = sObj.getSobjectType().getDescribe().fields.getMap().get(treatmentHistoryDefinition.Date_Field__c).getDescribe();

		//if (fieldValue instanceOf Datetime)  -- evaluate Contact_Date__c as DateTime, which is not correct
		if (fieldDescribe.getType() == Schema.DisplayType.DATETIME) {
			if (fieldValue != null) {
				this.itemDate = ((Datetime) fieldValue).date(); //jn 220715 change to GMT, was showing date in past
			}
			//this.itemDate = ((Datetime)fieldValue).dateGMT();
		} else if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
			this.itemDate = Date.valueOf(fieldValue);
		}

		this.URL = '';
		this.urlLabel = '';
		if (treatmentHistoryDefinition.Display_Record_Link__c == true) {
			Map<String, Set<String>> contextToAlwaysViewableObjectsMap = new Map<String, Set<String>>{ 'ViewTreatmentHistory' => new Set<String>(), 'PatientDrafts' => new Set<String>{ 'disco__Form__c', 'Procedure_Result__c', 'Psych_Testing_Request__c' } };
			//Boolean canSeeLink =  FeatureManagement.checkPermission('Clinical_Admin') || FeatureManagement.checkPermission('Medical_Records');
			Boolean canSeeLink = FeatureManagement.checkPermission('Clinical_Admin');
			if ('PatientDrafts'.equalsIgnoreCase(context)) {
				//ARC-2406 for all things in Draft - users with custom permission Medical Records should always see the Open link in Drafts list
				canSeeLink = FeatureManagement.checkPermission('Medical_Records') || FeatureManagement.checkPermission('Clinical_Admin');
			}
			if (contextToAlwaysViewableObjectsMap.get(context).contains(this.definition.Sobject__c)) {
				canSeeLink = true;
			} else if (context == 'ViewTreatmentHistory') {
				canSeeLink = true;
			} else {
				Set<String> objectFields = sObj.getSObjectType().getDescribe().fields.getMap().keySet();
				// if (this.definition.Sobject__c == 'disco__Form__c')
				// {
				//     canSeeLink = true;
				// } else
				if (objectFields.contains('psych_testing_request__c') && sObj.get('psych_testing_request__c') != null) {
					String recordTypeName = HistoryItem.getStringFieldValue(sObj, 'Psych_Testing_Request__r.RecordType.DeveloperName');
					Boolean isIndependentTesting = Boolean.valueOf(HistoryItem.getFieldValue(sObj, 'Psych_Testing_Request__r.Independent_Testing__c').rawValue);
					String reportWriter = HistoryItem.getStringFieldValue(sObj, 'Psych_Testing_Request__r.Report_Writer__c');
					String supervisor = HistoryItem.getStringFieldValue(sObj, 'Psych_Testing_Request__r.Testing_Supervisor__c');
					if ((recordTypeName == 'Psychological_Testing_Request') && !isIndependentTesting && (Userinfo.getUserId() == reportWriter || Userinfo.getUserId() == supervisor)) {
						canSeeLink = true;
					}
				} else {
					if (objectFields.contains('ownerid')) {
						//If current User is Owner,
						String objOwnerId = (String) sObj.get('ownerid');
						if (objOwnerId == Userinfo.getUserId()) {
							canSeeLink = true;
						} else if (
							objOwnerId.startsWith('00G') //If Owner is Queue/Group,
						) {
							//query all groupmembers for this user, only direct groupmembers
							List<GroupMember> gmsForThisUser = [SELECT Id, GroupId, Group.Name, Group.Type FROM GroupMember WHERE UserOrGroupId = :Userinfo.getUserId()];
							for (GroupMember gm : gmsForThisUser) {
								if (gm.GroupId == sObj.get('OwnerId')) {
									canSeeLink = true;
									break;
								}
							}
						}
					}
				}
			}
			//arc-2426 Completed Notes are shared to same group
			//canSeeLink = canSeeLink || userInPatientGroup;
			if (canSeeLink) {
				String linkRecordId = sObj.Id;
				if (treatmentHistoryDefinition.Record_to_Link_To_Field__c != null) {
					linkRecordId = (String) sObj.get(treatmentHistoryDefinition.Record_to_Link_To_Field__c);
				}
				this.URL = '/lightning/r/sObject/' + linkRecordId + '/view';
				this.urlLabel = 'Open';
			}
		}
		if (treatmentHistoryDefinition.Query_Fields__c.contains('OwnerId')) {
			Id oId = (String) sObj.get('OwnerId');
			this.ownerId = oId;
		}
	}

	//Merge field values into Details to Display for table view
	public static String buildDetails(sObject sObj, String detailString, List<String> fieldList) {
		String sObjectType = String.valueOf(sObj.getSobjectType());
		for (String fieldString : fieldList) {
			String findString = '\\{\\{' + fieldString + '\\}\\}';
			String fieldValueString = String.valueOf(HistoryItem.getStringFieldValue(sObj, fieldString));
			detailString = detailString.replaceAll(findString, fieldValueString);
		}
		return detailString;
	}

	public static String getStringFieldValue(sObject sObj, String fieldString) {
		TypedFieldValue typedValue = getFieldValue(sObj, fieldString);
		return typedValue.stringValue;
	}
	//recursive method traverses object relationships as necessary, returns either value Object or TypedFieldValue Object
	public static TypedFieldValue getFieldValue(sObject sObj, String fieldString) {
		//If there is a ".", that means we need to recurse one level deeper
		if (fieldString.contains('.') && sObj != null) {
			List<String> pieces = fieldString.split('\\.', 2);
			sObject newSobj = sObj.getsObject(pieces[0]);
			String shorterFieldString = pieces[1];
			return getFieldValue(newSobj, shorterFieldString);
		}

		//no ".", so fieldString must just be a field name for this sObject
		TypedFieldValue typedValue = new TypedFieldValue(sObj, fieldString);
		return typedValue;
	}

	public Integer compareTo(Object compareTo) {
		if (this.itemDate > ((HistoryItem) compareTo).itemDate)
			return -1;
		if (this.itemDate < ((HistoryItem) compareTo).itemDate)
			return 1;
		return 0;
	}

	public static Map<String, Schema.DescribeFieldResult> getSobjectFieldsBySobjectName(String sobjectName) {
		if (!sobjectFieldsBySobjectName.containsKey(sobjectName)) {
			sobjectFieldsBySobjectName.put(sobjectName, new Map<String, Schema.DescribeFieldResult>());
			try {
				Map<String, Schema.SObjectField> m = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap();
				for (Schema.SObjectField field : m.values()) {
					Schema.DescribeFieldResult dfr = field.getDescribe();
					sobjectFieldsBySobjectName.get(sobjectName).put(dfr.getName(), dfr);
				}
			} catch (Exception ex) {
				sobjectFieldsBySobjectName.put(sobjectName, new Map<String, Schema.DescribeFieldResult>());
			}
		}
		return sobjectFieldsBySobjectName.get(sobjectName);
	}

	//used to get String from field value and sObject
	public class TypedFieldValue {
		public sObject sObj;
		public String sObjectType;

		public String fieldName;
		Schema.DescribeFieldResult describeFieldResult;
		public String fieldType;

		public Object rawValue;
		public String stringValue = '';

		//fieldName must be the API name of a field on this sObject, not on some related record
		public TypedFieldValue(sObject sObj, String fieldName) {
			// this.stringValue = fieldName;
			if (sObj == null)
				return;

			this.sObj = sObj;
			this.sObjectType = String.valueof(sObj.getSobjectType());
			Map<String, Schema.DescribeFieldResult> fieldMap = HistoryItem.getSobjectFieldsBySobjectName(this.sObjectType);

			this.fieldName = fieldName;
			this.describeFieldResult = fieldMap.get(this.fieldName);
			this.fieldType = String.valueOf(describeFieldResult.getType());

			this.rawValue = sObj.get(fieldName);
			if (this.rawValue != null) {
				this.stringValue = String.valueOf(this.rawValue);
				switch on (fieldType) {
					when 'DATE' {
						//format according to normal date Format (mm/dd/yyyy)
						this.stringValue = Date.valueOf(rawValue).format();
					}
					when 'DATETIME' {
						//format according to HistoryItem.dateTimeFormatString,
						this.stringValue = DateTime.valueOf(rawValue).format(HistoryItem.dateTimeFormatString, HistoryItem.timeZoneString);
					} //everything else treat as String
					// when 'REFERENCE' //get Name field from referenced object
					// {
					//     String referencedObjectRelationshipName;
					//     if (fieldName.endsWith('__c')) //custom object relationship
					//     {
					//         referencedObjectRelationshipName = fieldName.left(fieldName.length() - 1) + 'r';
					//     } else //standard object
					//     {
					//         referencedObjectRelationshipName = fieldName.left(fieldName.length() - 2);
					//     }
					//     sObject referencedObject = sObj.getSObject(referencedObjectRelationshipName);
					//     stringValue = String.valueOf(referencedObject.get('Name'));
					// }
					when else {
						this.stringValue = String.valueOf(rawvalue);
					}
				}
			}
		}
	} //end TypedFieldValue class
}