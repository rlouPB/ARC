public with sharing class WaitlistReorder {
	//bypass update trigger being fired again due admissions order
	public static Map<String, Set<Id>> serviceToWaitlistAdmissionIdsMap = new Map<String, Set<Id>>();

	//keep track of Admission changing Waitlist Order
	static Map<String, Decimal> serviceToOldOrderMap = new Map<String, Decimal>();
	static Map<String, Decimal> serviceToNewOrderMap = new Map<String, Decimal>();
	static Boolean runningReorder = false;
	static Map<String, Admission__c> serviceToAllowedWaitlistAdmissionRecordForOrderUpdate = new Map<String, Admission__c>();

	static Trigger_Control__c trig;
	static Boolean suspendWaitlistReorder {
		get {
			if (trig == null) {
				trig = Trigger_Control__c.getInstance();
			}
			return trig.Suspend_Waitlist_Reorder__c;
		}
		set;
	}

	public static void addToWaitlist(List<Admission__c> newAdmissions, Map<Id, Admission__c> oldAdmissionMap) {
		//avoid running again
		if (runningReorder || suspendWaitlistReorder)
			return;

		serviceToAllowedWaitlistAdmissionRecordForOrderUpdate = WaitlistReorder.getWaitlistAdmissionRecordAllowedForUpdate(newAdmissions, oldAdmissionMap, 'addToWaitlist');

		if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate != null) {
			for (String service : serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.keySet()) {
				if (serviceToWaitlistAdmissionIdsMap.containsKey(service)) {
					serviceToWaitlistAdmissionIdsMap.get(service).add(serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Id);
				} else {
					serviceToWaitlistAdmissionIdsMap.put(service, new Set<Id>{ serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Id });
				}

				Admission__c oldAdm = oldAdmissionMap.get(serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Id);

				Set<Id> waitlistAdmissionIds = serviceToWaitlistAdmissionIdsMap.get(service);
				//added to waitlist
				if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Stage__c == 'Waitlist') {
					List<Admission__c> highestOrderAdmission = [SELECT Id, Waitlist_Order__c, Service_Type__c FROM Admission__c WHERE Id NOT IN :waitlistAdmissionIds AND Waitlist_Order__c != NULL AND Service_Type__c = :service ORDER BY Waitlist_Order__c DESC NULLS LAST LIMIT 1];

					if (!highestOrderAdmission.isEmpty()) {
						//change numbers while in waitlist, make sure the new number isn't too high
						if (oldAdm.Waitlist_Order__c != null && serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c != null && serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c != oldAdm.Waitlist_Order__c && serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c >= highestOrderAdmission[0].Waitlist_Order__c) {
							serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c = highestOrderAdmission[0].Waitlist_Order__c;
						} else if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Stage__c == 'Waitlist' && oldAdm.Stage__c != 'Waitlist') {
							//new to waitlist
							serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c = highestOrderAdmission[0].Waitlist_Order__c + 1;
						}
					} else {
						serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c = 1;
					}
				} else if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Stage__c != 'Waitlist') {
					//removed from Waitlist
					serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c = null;
					//oldOrder = oldAdmissionMap.get(allowedWaitlistAdmissionRecordForOrderUpdate.Id).Waitlist_Order__c;
					//newOrder = null;
				}

				serviceToOldOrderMap.put(service, oldAdm.Waitlist_Order__c);
				serviceToNewOrderMap.put(service, serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c);
			}
		}
	}

	public static void reorderWaitlist(List<Admission__c> newAdmissions, Map<Id, Admission__c> oldAdmissionMap) {
		//avoid running again
		if (runningReorder || suspendWaitlistReorder)
			return;

		Boolean needsReorder = false;

		for (String service : serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.keySet()) {
			if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service) != null) {
				needsReorder = true;
			}
			if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service) == null) {
				serviceToAllowedWaitlistAdmissionRecordForOrderUpdate = WaitlistReorder.getWaitlistAdmissionRecordAllowedForUpdate(newAdmissions, oldAdmissionMap, 'reorderWaitlist');
				if (serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service) != null) {
					needsReorder = true;
					WaitlistReorder.serviceToOldOrderMap.put(service, oldAdmissionMap.get(serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Id).Waitlist_Order__c);
					WaitlistReorder.serviceToNewOrderMap.put(service, serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Waitlist_Order__c);
				}
			}
			if (needsReorder) {
				//waitlistAdmissionIds.add(allowedWaitlistAdmissionRecordForOrderUpdate.Id);
				List<Admission__c> reOrderedAdmissions = new List<Admission__c>();
				Decimal order = 0;

				Decimal lowerOrder = (serviceToOldOrderMap.get(service) > serviceToNewOrderMap.get(service)) ? serviceToNewOrderMap.get(service) : serviceToOldOrderMap.get(service);
				Decimal higherOrder = (serviceToOldOrderMap.get(service) < serviceToNewOrderMap.get(service)) ? serviceToNewOrderMap.get(service) : serviceToOldOrderMap.get(service);

				//Decimal updatedAdmissionOrderNo = allowedWaitlistAdmissionRecordForOrderUpdate.Waitlist_Order__c;

				for (Admission__c adm : [SELECT Id, Waitlist_Order__c FROM Admission__c WHERE Stage__c = 'Waitlist' AND Id != :WaitlistReorder.serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.get(service).Id AND Service_Type__c = :service ORDER BY Waitlist_Order__c ASC NULLS LAST]) {
					order++;
					//if (order < lowerOrder || order > higherOrder) continue;

					if (order == serviceToNewOrderMap.get(service)) {
						//leave empty for our special record
						order++;
					}

					if (adm.Waitlist_Order__c != order) {
						adm.Waitlist_Order__c = order;
						reOrderedAdmissions.add(adm);
					}
				}

				WaitlistReorder.runningReorder = true;
				update reOrderedAdmissions;
			}
		}
	}

	private static Map<String, Admission__c> getWaitlistAdmissionRecordAllowedForUpdate(List<Admission__c> admissions, Map<Id, Admission__c> oldAdmissionMap, String method) {
		Decimal allowedAdmissionWaitlistWithOrderUpdate = 1;
		Decimal waitlistAdmissionCountWithOrderUpdate = 1;
		Map<String, Admission__c> serviceToAllowedWaitlistAdmissionRecordForOrderUpdate = new Map<String, Admission__c>();
		Map<String, List<Admission__c>> serviceToAdmissionList = new Map<String, List<Admission__c>>();

		for (Admission__c admission : admissions) {
			if (serviceToAdmissionList.containsKey(admission.Service_Type__c)) {
				serviceToAdmissionList.get(admission.Service_Type__c).add(admission);
			} else {
				serviceToAdmissionList.put(admission.Service_Type__c, new List<Admission__c>{ admission });
			}
		}

		for (String service : serviceToAdmissionList.keySet()) {
			for (Admission__c adm : serviceToAdmissionList.get(service)) {
				if (null == oldAdmissionMap)
					break;
				if (!oldAdmissionMap.containsKey(adm.Id))
					continue;

				Admission__c oldAdmission = oldAdmissionMap.get(adm.Id);

				if (adm.Stage__c == 'Waitlist' || oldAdmission.Stage__c == 'Waitlist') {
					if (
						(method == 'addToWaitlist' && ((adm.Stage__c == 'Waitlist' && oldAdmission.Stage__c != 'Waitlist') || (adm.Stage__c != 'Waitlist' && oldAdmission.Stage__c == 'Waitlist') || (adm.Stage__c == 'Waitlist' && oldAdmission.Stage__c == 'Waitlist' && (oldAdmission.Waitlist_Order__c != adm.Waitlist_Order__c || adm.Waitlist_Order__c == null)))) ||
						(method == 'reorderWaitlist' && ((oldAdmission.Waitlist_Order__c != null && adm.Waitlist_Order__c == null) || (oldAdmission.Waitlist_Order__c != null && adm.Waitlist_Order__c != null && oldAdmission.Waitlist_Order__c != adm.Waitlist_Order__c)))
					) {
						if (waitlistAdmissionCountWithOrderUpdate == allowedAdmissionWaitlistWithOrderUpdate) {
							serviceToAllowedWaitlistAdmissionRecordForOrderUpdate.put(service, adm);
						} else if (!serviceToWaitlistAdmissionIdsMap.get(service).contains(adm.Id)) {
							adm.addError('Please update only one Waitlist Order at a time for the ' + service + ' Waitlist');
						}

						waitlistAdmissionCountWithOrderUpdate++;
					}
				}
			}
		}

		return serviceToAllowedWaitlistAdmissionRecordForOrderUpdate;
	}
}