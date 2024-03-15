public without sharing class SharingRecord_Utils {
	public static String createSharingRecords(List<Id> recordIds, List<Id> userOrGroupIds, String accessLevel) {
		// Sort recordIds to optimize chunking. We ran into a production data volume error May 23, 2022 for this.
		recordIds.sort();

		List<SObject> allShares = new List<SObject>();
		// Loop through each record Id and create sharing record for each user or group Id.
		for (Id currentId : recordIds) {
			// Get name of Object to create share record of that type.
			String sObjectName = currentId.getSobjectType().getDescribe().getName();
			String shareName = sObjectName;
			Boolean isCustomObject = shareName.contains('__c') ? true : false;
			if (isCustomObject) {
				shareName = shareName.replace('__c', '__Share');
			} else {
				shareName += 'Share';
			}

			// Loop through user and group IDs to create share record for each one.
			for (Id currentUserOrGroup : userOrGroupIds) {
				Schema.SObjectType shareType = Schema.getGlobalDescribe().get(shareName);
				SObject shareRecord = shareType.newSObject();
				if (isCustomObject) {
					shareRecord.put('ParentId', currentId);
					shareRecord.put('AccessLevel', accessLevel);
				} else {
					shareRecord.put(sObjectName + 'Id', currentId);
					shareRecord.put(sObjectName + 'AccessLevel', accessLevel);
				}
				shareRecord.put('UserOrGroupId', currentUserOrGroup);
				if (sObjectName == 'Account') {
					shareRecord.put('OpportunityAccessLevel', accessLevel);
				}

				allShares.add(shareRecord);
			}
		}

		// Insert records, then process result to see if any failed to save.
		String returnResult = 'Success';
		List<Database.SaveResult> results = Database.insert(allShares, false);
		//for (Database.SaveResult result: results)
		for (Integer i = 0; i > results.size(); i++) {
			Database.SaveResult result = results[i];
			sObject share = allShares[i];

			if (result.isSuccess()) {
				System.debug('Success for sharing record Id: ' + result.getId());
			} else {
				Database.Error err = result.getErrors()[0];
				returnResult = 'Error on at least one sharing record.';
				System.debug('Errors: ');
				String serializedShare = JSON.serializePretty(share);
				for (Database.Error currentErr : result.getErrors()) {
					System.debug(currentErr.getMessage());
					String allField = null != currentErr.getFields() ? string.join(currentErr.getFields(), ',') : '';
					ProcessLogging.quickProcessLog('SharingRecord_Util.createSharingRecords()', 'allFields: ' + allField, 'error creating share: ' + serializedShare + '\n\nError: ' + currentErr.getMessage());
				}
			}
		}

		return returnResult;
	}

	public static String deleteSharingRecords(List<Id> recordIds, List<Id> userOrGroupIds) {
		// Get list of record share IDs to delete
		List<SObject> recordsToDelete = new List<SObject>();
		Set<String> sObjectNames = new Set<String>();
		for (Id currentId : recordIds) {
			String sObjectName = currentId.getSobjectType().getDescribe().getName();
			sObjectNames.add(sObjectName);
		}

		// Get list of record shares and add Id to recordsToDelete
		String returnResult = '';
		for (String sObjectName : sObjectNames) {
			String shareName = sObjectName;
			Boolean isCustomObject = shareName.contains('__c') ? true : false;
			if (isCustomObject) {
				shareName = shareName.replace('__c', '__Share');
			} else {
				shareName += 'Share';
			}
			String query = 'SELECT Id FROM ' + shareName + ' WHERE ';
			if (isCustomObject) {
				query += 'ParentId';
			} else {
				query += sObjectName + 'Id';
			}
			query += ' IN :recordIds AND UserOrGroupId IN :userOrGroupIds AND RowCause = \'Manual\'';

			List<SObject> shareRecords = Database.query(query);

			String shareRecordList = JSON.serializePretty(shareRecords);
			try {
				Database.delete(shareRecords, true);
			} catch (Exception ex) {
				returnResult += 'Error deleting share records: ' + ex.getMessage() + ' | ';
				ProcessLogging.quickProcessLog('SharingRecord_Util.deleteSharingRecords()', ex.getStackTraceString(), 'shareRecordList ' + shareRecordList + '\n\nException: ' + ex.getMessage());
			}

			// for (SObject record: shareRecords)
			// {
			//     // Id recordId = (Id)record.get('Id');
			//     // recordsToDelete.add(recordId);

			//     recordsToDelete.add(record);
			// }
		}

		if (returnResult == '') {
			returnResult = 'Success';
		}

		// Delete records
		// try
		// {
		//     Database.delete(recordsToDelete, true);
		// } catch (Exception ex)
		// {
		//     returnResult = 'Error deleting share records: ' + ex.getMessage();
		// }

		return returnResult;
	}
}