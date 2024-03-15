public class ViewOutstandingItemsApexController {
	public static Integer MAX_RESULTS = 5;
	public final static String outstandingTagQueryString = 'SELECT Document_Type__c, Patient__r.Name, CreatedDate, Overdue_Days__c, Target_Date__c, Record_ID__c, Long_Tag_Label__c, Record_ID_to_link_to__c, Owner.Name' + ' FROM Outstanding_Tag__c';

	public static Set<String> allCategories;

	@AuraEnabled
	public static OutstandingResult getResult(String selectedUserID, String patientId, String mode) {
		List<String> chosenCategories = null;
		return getFilteredResult(selectedUserID, chosenCategories, patientId, mode);
	}

	@AuraEnabled
	public static OutstandingResult getFilteredResult(String selectedUserID, List<String> chosenCategories, String patientId, String mode) {
		String whereClause = buildWhereClause(selectedUserID, chosenCategories, patientId, mode);
		String queryString = outstandingTagQueryString + whereClause;
		List<Outstanding_Tag__c> currentTags = (List<Outstanding_Tag__c>) Database.query(queryString);

		List<OutstandingWrapper> currentWrappers = new List<OutstandingWrapper>();
		allCategories = new Set<String>();
		for (Outstanding_Tag__c currentTag : currentTags) {
			if (currentTag.Document_Type__c != null) {
				allCategories.add(currentTag.Document_Type__c);
			} else {
				allCategories.add('Unknown');
			}

			OutstandingWrapper currentWrap = new OutstandingWrapper(currentTag);
			currentWrappers.add(currentWrap);
		}
		List<String> listOfCategories = new List<String>();
		listOfCategories.addAll(allCategories);

		OutstandingResult result = new OutstandingResult(currentWrappers, listOfCategories, Userinfo.getUserId());
		return result;
	}

	private static String buildWhereClause(String selectedUserID, List<String> chosenCategories, String patientId, String mode) {
		List<String> whereClauseItems = new List<String>();

		if (patientId != '' && patientId != null) {
			whereClauseItems.add('Patient__c = \'' + patientId + '\'');
		}

		// set<string> queueEnabledNames = new Set<string>();
		// for (Group__c g : [SELECT Name FROM Group__c WHERE Queue_Enabled__c = TRUE]) {
		// 	queueEnabledNames.add(g.Name);
		// }

		String ownerIdSetString = '(';
		if (mode == 'Open Items') {
			ownerIdSetString += '\'' + selectedUserID + '\'';
		} else if (mode == 'Shared Open Items') {
			ownerIdSetString += 'null';
			// for (GroupMember gm : [
			// 	SELECT GroupId
			// 	FROM GroupMember
			// 	WHERE
			// 		Group.Type = 'Queue'
			// 		AND (Group.Name LIKE 'Team%'
			// 		OR Group.Name IN :queueEnabledNames)
			// 		AND UserOrGroupId = :selectedUserID
			// ]) {
			for (GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :selectedUserID]) {
				ownerIdSetString += ', \'' + gm.GroupId + '\'';
			}
		}
		ownerIdSetString += ')';
		whereClauseItems.add('OwnerID IN ' + ownerIdSetString);

		//if chosenCategories is null, do not filter on Doc Type
		if (chosenCategories != null) {
			String chosenCategoriesString = '(null';
			for (String category : chosenCategories) {
				chosenCategoriesString += ', \'' + category + '\'';
			}
			chosenCategoriesString += ')';
			whereClauseItems.add('Document_Type__c IN ' + chosenCategoriesString);
		}

		return ' WHERE ' + String.join(whereClauseItems, ' AND ');
	}

	// @AuraEnabled(Cacheable=true)
	// public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
	// 	// Prepare query paramters
	// 	searchTerm = '%' + searchTerm + '%';

	// 	List<User> userList = [
	// 		SELECT Id, Name
	// 		FROM User
	// 		WHERE Name LIKE :searchTerm AND Id NOT IN :selectedIds AND IsActive = TRUE
	// 		LIMIT :MAX_RESULTS
	// 	];

	// 	// Prepare results
	// 	List<LookupSearchResult> results = new List<LookupSearchResult>();

	// 	String userIcon = 'standard:user';
	// 	for (User currentUser : userList) {
	// 		String subtitle = currentUser.Name;
	// 		results.add(new LookupSearchResult(currentUser.Id, 'User', userIcon, currentUser.Name, subtitle));
	// 	}

	// 	// Optionnaly sort all results on title
	// 	results.sort();

	// 	return results;
	// }

	// @AuraEnabled(Cacheable=true)
	// public static List<LookupSearchResult> getRecentlyViewed() {
	// 	List<LookupSearchResult> results = new List<LookupSearchResult>();
	// 	// Get recently viewed records of type Account or Opportunity
	// 	List<RecentlyViewed> recentRecords = [
	// 		SELECT Id, Name, Type
	// 		FROM RecentlyViewed
	// 		WHERE Type = 'Account' OR Type = 'Opportunity'
	// 		ORDER BY LastViewedDate DESC
	// 		LIMIT 5
	// 	];
	// 	// Convert recent records into LookupSearchResult
	// 	for (RecentlyViewed recentRecord : recentRecords) {
	// 		if (recentRecord.Type == 'Account') {
	// 			results.add(
	// 				new LookupSearchResult(
	// 					recentRecord.Id,
	// 					'Account',
	// 					'standard:account',
	// 					recentRecord.Name,
	// 					'Account • ' + recentRecord.Name
	// 				)
	// 			);
	// 		} else {
	// 			results.add(
	// 				new LookupSearchResult(
	// 					recentRecord.Id,
	// 					'Opportunity',
	// 					'standard:opportunity',
	// 					recentRecord.Name,
	// 					'Opportunity • ' + recentRecord.Name
	// 				)
	// 			);
	// 		}
	// 	}
	// 	return results;
	// }

	public class OutstandingWrapper {
		@AuraEnabled
		public String ID;
		@AuraEnabled
		public String DocumentType;
		@AuraEnabled
		public String LongTagLabel;
		@AuraEnabled
		public String DocTypeShort;
		@AuraEnabled
		public String PatientName;
		@AuraEnabled
		public String PatientShort;
		@AuraEnabled
		public Date DocDate;
		@AuraEnabled
		public Integer Overdue;
		@AuraEnabled
		public Date TargetDate;
		@AuraEnabled
		public String RecordID;
		@AuraEnabled
		public String recordLink;
		@AuraEnabled
		public String OwnerName;

		public OutstandingWrapper(Outstanding_Tag__c currentTag) {
			this.ID = currentTag.ID;

			this.DocumentType = 'Unknown';
			this.DocTypeShort = 'Unknown';
			if (currentTag.Document_Type__c != null && currentTag.Document_Type__c != '') {
				this.DocumentType = currentTag.Document_Type__c;
				// this.DocTypeShort = currentTag.Document_Type__c;
				// if (this.DocumentType.length() > 20) {
				this.DocTypeShort = this.DocumentType.left(20);
				// }
			}
			this.LongTagLabel = currentTag.Long_Tag_Label__c;

			this.PatientName = '';
			this.PatientShort = '';
			if (currentTag.Patient__c != null) {
				this.PatientName = currentTag.Patient__r.Name;
				// this.PatientShort = currentTag.Patient__r.Name;
				// if (this.PatientName.length() > 20) {
				this.PatientShort = this.PatientName.left(20);
				// }
			}

			this.DocDate = Date.valueOf(currentTag.CreatedDate);
			this.Overdue = (currentTag.Overdue_Days__c != null) ? Integer.valueOf(currentTag.Overdue_Days__c) : 0;
			this.TargetDate = (currentTag.Target_Date__c != null) ? currentTag.Target_Date__c : null;
			this.recordLink = '/' + ((currentTag.Record_ID_to_link_to__c != null) ? currentTag.Record_ID_to_link_to__c : currentTag.Record_ID__c);
			this.OwnerName = currentTag.Owner.Name;

			this.RecordID = currentTag.Record_ID__c;
			if (currentTag.Record_ID__c == null) {
				this.RecordID = currentTag.ID;
			}
		}
	}

	public class OutstandingResult {
		@AuraEnabled
		public List<OutstandingWrapper> outstandingWrappers;
		@AuraEnabled
		public List<String> categories;
		@AuraEnabled
		public String currentUserName;
		@AuraEnabled
		public Boolean hasManagerPermission = false;

		public OutstandingResult(List<OutstandingWrapper> wrapperList, List<String> categories, Id userId) {
			this.outstandingWrappers = wrapperList;
			this.categories = categories;
			this.findUserInfo(userId);
		}

		private void findUserInfo(Id userId) {
			User thisUser = [SELECT Id, Name, Professional_Name__c, Profile.Name FROM User WHERE Id = :userId];
			this.currentUserName = thisUser.Name;
			if (PermissionSets.hasPermissionSet(userId, 'Outstanding Items Manager') || thisUser.Profile.Name == 'System Administrator') {
				this.hasManagerPermission = true;
			}
		}
	}
}