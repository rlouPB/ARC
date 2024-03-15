public with sharing class AdmissionRequirementManagementController {
	static String requestItemQueryString = 'SELECT Id, Recordtype.Name, Responsible__c, Action__c, Item_Requested__c, Date_Requested__c, Date_Confirmed__c, Responsible_User__c, ' + ' Responsible_Contact__c, Responsible_Contact__r.Name, Status__c, Notes__c, Req__c, Admissions_Requirement__c,' + ' Admissions_Requirement__r.Name, Admissions_Requirement__r.Admission__c, Med_Record_Items_Requested__c,' + ' Covered_Range_End__c, Covered_Range_Start__c,' + ' Other_Requested_Items__c' + ' FROM Request_Item__c ';
	static String requestItemOrderBy = ' ORDER BY Admissions_Requirement__r.Order__c ASC, Date_Requested__c DESC';

	//called from aura component
	@AuraEnabled
	public static requestItemsWrapper getAdmissionsRequirement(String parentId, String applicablePhase) {
		requestItemsWrapper requestWrapper = new requestItemsWrapper();
		requestWrapper.recordTypeName2IdMap = new Map<String, String>();
		for (Recordtype rt : [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Request_Item__c' ORDER BY Name]) {
			requestWrapper.recordTypeName2IdMap.put(rt.Name, rt.Id);
			requestWrapper.recordTypeList.add(rt);
		}

		Account acc = [SELECT Id, Current_Admission__c, Current_Admission_Stage__c FROM Account WHERE Id = :parentId LIMIT 1];

		if (acc.Current_Admission__c != null) {
			requestWrapper.currentPhase = applicablePhase;
			// requestWrapper.currentPhase = 'Inquiry';
			// if (acc.Current_Admission_Stage__c == 'Admitted')
			// {
			//     requestWrapper.currentPhase = 'Patient';
			// }

			requestWrapper.admissionRequirements = new List<Admissions_Requirement__c>([SELECT Id, Applicable_Phase__c, Request_Item_Record_Type__c, Total_Open_Request_Items__c, Completed__c, Total_Request_Items__c, Name, Order__c, Do_Not_Show_Checkbox_on_Component__c, Admission__c, Admission__r.Patient_Account__c FROM Admissions_Requirement__c WHERE Admission__c = :acc.Current_Admission__c AND Applicable_Phase__c = :requestWrapper.currentPhase ORDER BY Order__c ASC]);

			for (Request_Item__c req : [SELECT Id, Responsible_User__c, Responsible_Contact__c, Responsible__c, Action__c, Item_Requested__c, Date_Requested__c, Date_Confirmed__c, Status__c, Notes__c, Admissions_Requirement__c, Admissions_Requirement__r.Name, Admissions_Requirement__r.Admission__c, Req__c FROM Request_Item__c WHERE Admissions_Requirement__c IN :requestWrapper.admissionRequirements ORDER BY Admissions_Requirement__r.Order__c ASC, Date_Requested__c DESC]) {
				if (requestWrapper.admissionAndReqMap.containsKey(req.Admissions_Requirement__c)) {
					List<Request_Item__c> tempList = requestWrapper.admissionAndReqMap.get(req.Admissions_Requirement__c);
					tempList.add(req);
					requestWrapper.admissionAndReqMap.put(req.Admissions_Requirement__c, tempList);
				} else {
					requestWrapper.admissionAndReqMap.put(req.Admissions_Requirement__c, new List<Request_Item__c>{ req });
				}
			}
			return requestWrapper;
		}
		return null;
	}

	@AuraEnabled
	public static Admissions_Requirement__c updateAdmissionsRequirement(String admissionReqId, Boolean checkVal) {
		Admissions_Requirement__c newAdReq = new Admissions_Requirement__c(Id = admissionReqId, Completed__c = checkVal);
		update newAdReq;

		return newAdReq;
	}

	@AuraEnabled
	public static List<ContentVersion> getContents(String parentId) {
		//Get document ids from ContentDocumentLink
		set<Id> setDocumentIds = new Set<Id>();
		List<ContentVersion> contentVersions = new List<ContentVersion>();

		List<ContentDocumentLink> fileLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId];

		if (fileLinks != null && fileLinks.size() > 0) {
			for (ContentDocumentLink fileLink : fileLinks) {
				setDocumentIds.add(fileLink.ContentDocumentId);
			}
			if (setDocumentIds.size() > 0) {
				//Get ContentVersions from documents
				contentVersions = [SELECT Id, Title, ContentDocumentId, VersionData, CreatedDate, ContentSize FROM ContentVersion WHERE ContentDocumentId IN :setDocumentIds];
			}
		}
		return contentVersions;
	}

	@AuraEnabled
	public static List<Request_Item__c> requestItems(String currentId, String parentFilter, String childFilter, String accountId, String parentId, String currentPhase) {
		String filterQuery = requestItemQueryString;
		Set<Id> admissionReqIds = new Set<Id>();
		if (String.isNotBlank(currentId)) {
			filterQuery += ' WHERE Id = :currentId';
		} else {
			filterQuery += ' WHERE Admissions_Requirement__c IN :admissionReqIds';

			if (String.isNotBlank(parentId)) {
				admissionReqIds.add(parentId);
			}

			if (String.isNotBlank(accountId)) {
				Account acc = [SELECT Id, Current_Admission__c, Current_Admission_Stage__c FROM Account WHERE Id = :accountId LIMIT 1];

				if (acc.Current_Admission__c != null) {
					for (Admissions_Requirement__c adReqs : [SELECT Id, Admission__c FROM Admissions_Requirement__c WHERE Admission__c = :acc.Current_Admission__c AND Applicable_Phase__c = :currentPhase]) {
						admissionReqIds.add(adReqs.Id);
					}
				}
			}

			// if (String.isNotBlank(parentFilter))
			// {
			//     // if (parentFilter == 'showRequirements')
			//     // {
			//     //     if (String.isNotBlank(childFilter) && childFilter == 'showOpen')
			//     //     {
			//     //         //filterQuery += ' WHERE Admissions_Requirement__c = :parentId AND (Status__c = \'Open\' OR Status__c = \'Received\')';
			//     //         filterQuery += ' AND (Status__c = \'Open\' OR Status__c = \'Received\')';
			//     //     }
			//     //     // else if (String.isNotBlank(parentId))
			//     //     // {
			//     //     //     filterQuery += ' WHERE Admissions_Requirement__c = :parentId';
			//     //     // }
			//     // } else if (parentFilter == 'showAllRequests')
			//     // {
			//     //     // if (String.isNotBlank(childFilter) && childFilter == 'showAll')
			//     //     // {
			//     //     //     // filterQuery += 'WHERE Admissions_Requirement__c = :admissionReqIds';
			//     //     // } else
			//     //     if (String.isNotBlank(childFilter) && childFilter == 'showOpen')
			//     //     {
			//     //         //filterQuery += 'WHERE Admissions_Requirement__c = :admissionReqIds AND (Status__c = \'Open\' OR Status__c = \'Received\')';
			//     //         filterQuery += ' AND (Status__c = \'Open\' OR Status__c = \'Received\')';
			//     //     }
			//     //     // else {
			//     //     //    filterQuery += 'WHERE Admissions_Requirement__c = :admissionReqIds';
			//     //     // }
			//     // }
			// }
			if (String.isNotBlank(parentFilter) && String.isNotBlank(childFilter) && childFilter == 'showOpen') {
				filterQuery += ' AND (Status__c = \'Open\' OR Status__c = \'Received\')';
			}

			// if (String.isNotBlank(parentId) && String.isBlank(parentFilter) && String.isBlank(childFilter))
			// {
			//     // filterQuery += 'WHERE Admissions_Requirement__c =: parentId';
			// }
		}

		filterQuery += requestItemOrderBy;
		List<Request_Item__c> reqItems = database.query(filterQuery);
		return reqItems;
	}

	@AuraEnabled
	public static Request_Item__c dmlRequestItem(String requestItem) {
		Request_Item__c reqItem = (Request_Item__c) JSON.deserialize(requestItem, Request_Item__c.class);
		if (reqItem != null) {
			upsert reqItem;
		}
		return reqItem;
	}

	@AuraEnabled
	public static String uploadCDL(Id accountId, String contentDocumentId) {
		List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

		if (accountId != null && contentDocumentId != null) {
			Account acc = [SELECT Id, Current_Admission__c FROM Account WHERE Id = :accountId];

			/*Linked Account*/
			ContentDocumentLink cdlAcc = new ContentDocumentLink();
			cdlAcc.ContentDocumentId = contentDocumentId;
			cdlAcc.LinkedEntityId = acc.Id;
			cdlAcc.ShareType = 'V';
			cdlAcc.Visibility = 'AllUsers';

			/*Linked Admission*/
			ContentDocumentLink cdlAdmission = cdlAcc.clone(false, false, false, false);
			cdlAdmission.LinkedEntityId = acc.Current_Admission__c;

			cdlList.add(cdlAcc);
			cdlList.add(cdlAdmission);

			if (cdlList.size() > 0 && !Test.isRunningTest()) {
				insert cdlList;
			}
		}

		return JSON.serialize(cdlList);
	}

	public class requestItemsWrapper {
		@AuraEnabled
		public String currentPhase = '';
		@AuraEnabled
		public Map<String, String> recordTypeName2IdMap;
		@AuraEnabled
		public List<RecordType> recordTypeList = new List<RecordType>();
		@AuraEnabled
		public List<Admissions_Requirement__c> admissionRequirements = new List<Admissions_Requirement__c>();
		@AuraEnabled
		public Map<Id, List<Request_Item__c>> admissionAndReqMap = new Map<Id, List<Request_Item__c>>();
	}
}