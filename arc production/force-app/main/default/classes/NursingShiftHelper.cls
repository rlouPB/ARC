public without sharing class NursingShiftHelper {
	// public static void assignNursesToShiftItems(Nursing_Shift_Item__c[] newItems, Map<Id,SObject> oldMap){
	//     Set<Id> nursingShiftIds = new Set<Id>();
	//     for (Nursing_Shift_Item__c nsi : newItems){
	//         if (nsi.Nursing_Shift__c != null && nsi.Nursing_Shift_Assignment__c == null){
	//             nursingShiftIds.add(nsi.Nursing_Shift__c);
	//         }
	//     }

	//     if ( nursingShiftIds.isEmpty() ) {
	//         return;
	//     }

	//     Nursing_Shift_Assignment__c[] nsaToInsert = new Nursing_Shift_Assignment__c[]{};

	//     Nursing_Shift_Assignment__c[] nsaList = [Select Owner__c, Nursing_Shift__c from Nursing_Shift_Assignment__c WHERE Nursing_Shift__c in :nursingShiftIds ];

	//     for (Nursing_Shift_Item__c nsi : newItems){
	//         Nursing_Shift_Item__c oldNsi = (oldMap != null)? (Nursing_Shift_Item__c)oldMap.get(nsi.Id) : null;
	//         if( nsi.Nurse__c != null && (oldNsi == null || ( nsi.Nurse__c != oldNsi.Nurse__c ) ) ){
	//             if( !checkNurseInShiftForAssignment(nsi.Nurse__c, nsi.Nursing_Shift__c, nsaList) ){
	//                 nsaToInsert.add(new Nursing_Shift_Assignment__c(
	//                     Nursing_Shift__c = nsi.Nursing_Shift__c,
	//                     Owner__c = nsi.Nurse__c
	//                 ));
	//             }
	//         }
	//     }

	//     if(nsaToInsert.size() > 0){
	//         insert nsaToInsert;
	//     }
	// }

	public static void assignNursesToShiftItemsOnBeforeInsert(Nursing_Shift_Item__c[] newItems, Map<Id, SObject> oldMap) {
		Set<Id> nursingShiftIds = new Set<Id>();
		for (Nursing_Shift_Item__c nsi : newItems) {
			if (nsi.Nursing_Shift__c != null && nsi.Nursing_Shift_Assignment__c == null) {
				nursingShiftIds.add(nsi.Nursing_Shift__c);
			}
		}

		if (nursingShiftIds.isEmpty()) {
			return;
		}

		Nursing_Shift_Assignment__c[] nsaToUpdate = new List<Nursing_Shift_Assignment__c>{};

		Nursing_Shift_Assignment__c[] nsaList = [SELECT Owner__c, Nursing_Shift__c FROM Nursing_Shift_Assignment__c WHERE Nursing_Shift__c IN :nursingShiftIds];

		for (Nursing_Shift_Item__c nsi : newItems) {
			Nursing_Shift_Item__c oldNsi = (oldMap != null) ? (Nursing_Shift_Item__c) oldMap.get(nsi.Id) : null;
			if (nsi.Nurse__c != null && (oldNsi == null || (nsi.Nurse__c != oldNsi.Nurse__c))) {
				Id nsaId = getShiftForAssignmentForNurse(nsi.Nurse__c, nsi.Nursing_Shift__c, nsaList);
				if (nsaId != null) {
					nsi.Nursing_Shift_Assignment__c = nsaId;
				}
			}
		}
	}

	public static Id getShiftForAssignmentForNurse(Id nurseId, Id nurseShiftId, Nursing_Shift_Assignment__c[] nursingShiftAssignmentIds) {
		for (Nursing_Shift_Assignment__c nsa : nursingShiftAssignmentIds) {
			if (nsa.Nursing_Shift__c == nurseShiftId && nsa.Owner__c == nurseId) {
				return nsa.Id;
			}
		}
		return null;
	}

	// public static boolean checkNurseInShiftForAssignment(Id nurseId, Id nurseShiftId, Nursing_Shift_Assignment__c[] nursingShiftAssignmentIds){
	//     for(Nursing_Shift_Assignment__c nsi : nursingShiftAssignmentIds){
	//         if (nsi.Nursing_Shift__c == nurseShiftId && nsi.Owner__c == nurseId){
	//             return true;
	//         }
	//     }
	//     return false;
	// }
}