public without sharing class PackageLineHelper {
	/*******************************************************************************************************
	 *  handlePackageLineChange (Map <Id, Package__c>, Map <Id, Package_Line__c>)
	 *  @description This method is called by Apex class Package_LineTriggeerHandler.
	 *  1) When a new package line is created, Package__c.Medications__c is refreshed and updated if applicable.
	 */
	public static void handlePackageLineChange(Map<Id, Package__c> packageMap, Map<Id, Package_Line__c> packageLineMap, Boolean isInsert) {
		List<Package__c> pkgsToUpdate = new List<Package__c>();
		List<String> medsList = new List<String>();
		String medsListStr = null;

		String controlGroup = null;

		if (isInsert) {
			for (Id pkgKey : packageMap.keySet()) {
				String maxControlGroup = null;
				for (Id lineKey : packageLineMap.keySet()) {
					if (pkgKey == packageLineMap.get(lineKey).Package__c) {
						if (null == maxControlGroup || null == packageMap.get(pkgKey).Control_Group__c || ((packageLineMap.get(lineKey).Prescription__r.Control_Group__c < packageMap.get(pkgKey).Control_Group__c) && (packageLineMap.get(lineKey).Prescription__r.Control_Group__c < maxControlGroup))) {
							maxControlGroup = packageLineMap.get(lineKey).Prescription__r.Control_Group__c;
						} else {
							if (maxControlGroup > packageMap.get(pkgKey).Control_Group__c) {
								maxControlGroup = packageMap.get(pkgKey).Control_Group__c;
							}
						}
						medsList.add(packageLineMap.get(lineKey).Prescription__r.Medication_Filled_with__c);
						medsListStr = cleanAndSortMedsList(medsList);
					}
				}

				pkgsToUpdate.add(new Package__c(Id = pkgKey, Control_Group__c = maxControlGroup, Medications__c = medsListStr));
				medsList = new List<String>();
				medsListStr = null;
			}
		} else {
			for (Id pkgKey : packageMap.keySet()) {
				Package__c pkg = packageMap.get(pkgKey);
				pkg.Control_Group__c = null;
				pkg.Medications__c = null;
				packageMap.put(pkgKey, pkg);

				for (Id lineKey : packageLineMap.keySet()) {
					if (pkgKey == packageLineMap.get(lineKey).Package__c && packageLineMap.get(lineKey).Prescription_Quantity__c > 0) {
						Package_Line__c packageLine = packageLineMap.get(lineKey);
						if (controlGroup == null) {
							controlGroup = packageLine.Prescription__r.Control_Group__c;
							pkg.Control_Group__c = controlGroup;
						} else {
							if (null != packageLine.Prescription__r.Control_Group__c && controlGroup > packageLine.Prescription__r.Control_Group__c) {
								controlGroup = packageLine.Prescription__r.Control_Group__c;
								pkg.Control_Group__c = controlGroup;
							}
						}

						packageMap.put(pkgKey, pkg);
						medsList.add(packageLineMap.get(lineKey).Prescription__r.Medication_Filled_with__c);
						medsListStr = cleanAndSortMedsList(medsList);
					}
				}

				if (medsList.size() == 0) {
					medsListStr = packageMap.get(pkgKey).Medications__c;
				}
				pkgsToUpdate.add(new Package__c(Id = pkgKey, Control_Group__c = controlGroup, Medications__c = medsListStr));
				medsList = new List<String>();
				medsListStr = null;
			}
		}

		update pkgsToUpdate;
	}

	/*******************************************************************************************************
	 *  handlePackageLineRemove ( Map<Id, Prescription__c>,  Map<Id, Package_Line__c>)
	 *  @description This method is called by method handlePackageLineChange.
	 *  1) removes duplicate package lines
	 *  2) then sorts the results of 1)
	 *  3) parses the results of 2)
	 *  4) generates and returns a comma-seeparated list from the results of 3).
	 */
	public static void handlePackageLineRemove(Map<Id, Package__c> packageMap, Map<Id, Package_Line__c> packageLineMap) {
		List<Package__c> pkgsToUpdate = new List<Package__c>();
		List<String> medsList = new List<String>();
		String medsListStr = null;

		for (Id pkgKey : packageMap.keySet()) {
			Package__c pkg = packageMap.get(pkgKey);
			pkg.Control_Group__c = null;
			pkg.Medications__c = null;
			packageMap.put(pkgKey, pkg);
			for (Id lineKey : packageLineMap.keySet()) {
				if (pkgKey == packageLineMap.get(lineKey).Package__c) {
					Package_Line__c packageLine = packageLineMap.get(lineKey);
					pkg.Control_Group__c = packageLine.Prescription__r.Control_Group__c;
					packageMap.put(pkgKey, pkg);
					medsList.add(packageLineMap.get(lineKey).Prescription__r.Medication_Filled_with__c);
					medsListStr = cleanAndSortMedsList(medsList);
				}
			}

			if (medsList.size() == 0) {
				medsListStr = packageMap.get(pkgKey).Medications__c;
			}
			pkgsToUpdate.add(new Package__c(Id = pkgKey, Control_Group__c = packageMap.get(pkgKey).Control_Group__c, Medications__c = medsListStr));
			medsList = new List<String>();
			medsListStr = null;
		}

		update pkgsToUpdate;
	}

	/*******************************************************************************************************
	 * @description This method is called by method handlePackageLineChange.
	 *  cleanAndSortMedsList (List <String>)
	 *  1) removes duplicate package lines
	 *  2) then sorts the results of 1)
	 *  3) parses the results of 2)
	 *  4) generates and returns a comma-seeparated list from the results of 3).
	 */
	private static String cleanAndSortMedsList(List<String> medsList) {
		String returnStr = null;

		// Remove any duplicate medication values from list parameter
		Set<String> medsSet = new Set<String>(medsList);

		// Repopulate and sort the cleansed list
		medsList = new List<String>(medsSet);
		medsList.sort();

		// Iterate medsList and assemble the return string
		for (String m : medsList) {
			if (returnStr == null) {
				returnStr = m;
			} else {
				returnStr += (', ' + m);
			}
		}

		return returnStr;
	}
}