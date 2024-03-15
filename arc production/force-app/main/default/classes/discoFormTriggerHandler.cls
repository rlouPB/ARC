public class discoFormTriggerHandler implements ITrigger {
	static list<Admission__c> admissionsToUpdate = new List<Admission__c>();
	static map<String, String> professionalNameMap = new Map<String, String>();
	static list<disco__Form__c> afterInsertforms = new List<disco__Form__c>();
	// static Boolean hasRunLockForms = false;

	static User currentUser;
	static Datetime lockedDateTime;

	/**
	 * bulkBefore
	 *
	 * This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (
			Trigger.isUpdate // && !System.isFuture()
		) {
			//moved to beforeUpdate() JN 220929
			// Set<Id> formsToLockIds = new Set<Id>();
			// Datetime lockedDateTime;
			// User currentUser;
			// for (disco__Form__c form : (disco__Form__c[]) Trigger.New)
			// {
			// 	disco__Form__c old = (disco__Form__c)Trigger.oldMap.get(form.Id);
			// 	if ((form.Finalize_and_Lock_Application__c == true && old.Finalize_and_Lock_Application__c == false)
			// 		|| (form.disco__Locked__c == true && old.disco__Locked__c == false)
			// 		|| (form.disco__Save_Complete__c == true && old.disco__Save_Complete__c == false))
			// 	{
			// 		formsToLockIds.add(form.Id);

			// 		if (currentUser == null) currentUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
			// 		if (lockedDateTime == null) lockedDateTime = System.now();
			// 		form.Finalized_By__c = currentUser.Id;
			// 		form.Finalized_By_Professional_Name__c = currentUser.Professional_Name__c;
			// 		form.Finalized_Date_Time__c = lockedDateTime;
			// 		form.disco__Locked__c = true;
			// 	}
			// }
			// if (formsToLockIds.size() > 0  && !System.isFuture()) {
			// 	lockForms(formsToLockIds, lockedDateTime);
			// }
		}
	}

	// @future
	// static void lockForms(Set<Id> formIds, Datetime lockedDateTime)
	// {
	// 	try
	// 	{
	// 		User currentUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
	// 		Map<Id, disco__Form__c> formMap = new Map<Id, disco__Form__c>([SELECT Id, disco__Locked__c, disco__Save_Complete__c, Finalized_By__c, Finalized_By_Professional_Name__c, Finalized_Date_Time__c
	// 											FROM disco__Form__c
	// 											WHERE Id IN :formIds
	// 											FOR UPDATE]);
	// 		List<disco__Form__c> formsToLock = new List<disco__Form__c>();
	// 		for (Id formId : formIds)
	// 		{
	// 			disco__Form__c queriedForm = formMap.get(formId);
	// 			if (queriedForm.Finalized_Date_Time__c != lockedDateTime)
	// 			{
	// 				formsToLock.add(
	// 					new disco__Form__c(
	// 						Id = formId,
	// 						disco__Save_Complete__c = true,
	// 						disco__Locked__c = true,
	// 						Finalized_By__c = currentUser.Id,
	// 						Finalized_By_Professional_Name__c = currentUser.Professional_Name__c,
	// 						Finalized_Date_Time__c = lockedDateTime
	// 					)
	// 				);
	// 			}
	// 		}
	// 		update formsToLock;
	// 	} catch (Exception e) { ProcessLogging.quickProcessLog('discoFormTriggerHandler.lockForms() [in future]', e.getStackTraceString(), e.getMessage()); }
	// }

	/**
	 * bulkAfter
	 *
	 * This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		if (!Trigger.isDelete) {
			Set<id> formIdsSet = new Set<Id>();
			for (disco__Form__c form : (disco__Form__c[]) Trigger.New) {
				formIdsSet.add(form.Id);
			}
			closeNursingShiftsWhenSubmit(formIdsSet);

			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
			// List<String> formIds = new List<String>();
			// if (Trigger.isUpdate) {
			// for (disco__Form__c form : (disco__Form__c[]) Trigger.New) {
			// 	formIds.add(form.Id);
			// }
			// afterInsertforms = [
			// 	SELECT Id, Finalized_By__r.Professional_Name__c
			// 	FROM disco__Form__c
			// 	WHERE Id IN :formIds
			// 	WITH SECURITY_ENFORCED
			// ];
			// for (disco__Form__c f : afterInsertforms) {
			// 	f.Finalized_By_Professional_Name__c = f.Finalized_By__r?.Professional_Name__c;
			// }
			// }
		} else {
			OutstandingItems.deleteRelatedTags(Trigger.old);
		}
	}

	/**
	 * beforeInsert
	 *
	 * This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
	}

	/**
	 * beforeUpdate
	 *
	 * This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
		disco__Form__c old = (disco__Form__c) oldSo;
		disco__Form__c form = (disco__Form__c) so;

		if ((form.Finalize_and_Lock_Application__c == true && (old.Finalize_and_Lock_Application__c == false || form.disco__Locked__c == false)) || (form.disco__Locked__c == true && old.disco__Locked__c == false) || (form.disco__Save_Complete__c == true && old.disco__Save_Complete__c == false)) {
			if (currentUser == null)
				currentUser = [SELECT Id, Professional_Name__c FROM User WHERE Id = :Userinfo.getUserId()];
			if (lockedDateTime == null)
				lockedDateTime = System.now();
			form.Finalized_By__c = currentUser.Id;
			form.Finalized_By_Professional_Name__c = currentUser.Professional_Name__c;
			form.Finalized_Date_Time__c = lockedDateTime;
			form.Finalize_and_Lock_Application__c = true;
			form.disco__Save_Complete__c = true;
			form.disco__Locked__c = true;
			if (form.disco__Original_Submitted_Date__c == null) {
				form.disco__Original_Submitted_Date__c = System.today();
				form.disco__Originally_Submitted_By__c = currentUser.Id;
			}
		}
		if (form.disco__Original_Submitted_Date__c != null && form.disco__Original_Submitted_Date__c != old?.disco__Original_Submitted_Date__c && null != form.Package__c) {
			form.Available_in_Community__c = false;
		}
	}

	/**
	 * beforeDelete
	 *
	 * This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/**
	 * afterInsert
	 *
	 * This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
		//JN 220929 removed, there is no use case for inserting a Form that is already Locked
		// if (!Trigger.isDelete) {
		// 	disco__Form__c newform = (disco__Form__c) so;

		// 	if (newform.disco__Status__c == 'LOCKED' && newform.Template_Doc_Name__c == 'Consent_to_Attendance_of_Visitors_at_Cl')
		// 		admissionsToUpdate.add(updateAdmissionVisitorClinicalField(newform));
		// }
	}

	/**
	 * afterUpdate
	 *
	 * This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
		if (!Trigger.isDelete) {
			disco__Form__c newform = (disco__Form__c) so;
			disco__Form__c oldform = (disco__Form__c) oldSo;

			if (newform.disco__Status__c == 'LOCKED' && oldform.disco__Status__c != newform.disco__Status__c && newform.Template_Doc_Name__c == 'Consent_to_Attendance_of_Visitors_at_Cl') {
				admissionsToUpdate.add(updateAdmissionVisitorClinicalField(newform));
			}
		}
	}

	/**
	 * afterDelete
	 *
	 * This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/**
	 * andFinally
	 *
	 * This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
		if (Trigger.isAfter) {
			update admissionsToUpdate;

			update afterInsertforms;
		}

		//OR CALL discoFormTriggerHandlerHelper.updateAdmissionVisitorClinicalField [class with "Without sharing enableb! Might do the work"]
		//discoFormTriggerHandlerHelper.updateAdmissionVisitorClinicalField(admissionsToUpdate);
	}

	public static void closeNursingShiftsWhenSubmit(Set<Id> formIdsSet) {
		Id[] formIds = new List<Id>{};
		Nursing_Shift_Item__c[] itemsToClose = new List<Nursing_Shift_Item__c>{};

		for (disco__Form__c form : [SELECT Id, disco__Original_Submitted_Date__c FROM disco__Form__c WHERE Id IN :formIdsSet]) {
			if (form.disco__Original_Submitted_Date__c != null) {
				formIds.add(form.Id);
			}
		}

		if (formIds.size() > 0) {
			List<Procedure_Result__c> resultsToUpdate = new List<Procedure_Result__c>();
			itemsToClose = [SELECT Id, Status__c, Procedure_Result__c FROM Nursing_Shift_Item__c WHERE Form__c IN :formIds AND Status__c != 'Closed' AND Status__c != 'Cancelled'];

			for (Nursing_Shift_Item__c ns : itemsToClose) {
				ns.Status__c = 'Closed';
				if (ns.Procedure_Result__c != null) {
					resultsToUpdate.add(new Procedure_Result__c(Id = ns.Procedure_Result__c, Status__c = 'Received'));
				}
			}
			update itemsToClose;
			update resultsToUpdate;
		}
	}

	public Admission__c updateAdmissionVisitorClinicalField(disco__Form__c form) {
		Admission__c admission = new Admission__c();
		admission.id = form.admission__c;
		admission.Visitors_Clinical_Conferences__c = form.Visitors_Clinical_Conferences__c;
		return admission;
	}

	//removed to avoid collision/recursion with Youreka managed triggers
	// public static void populateFinalizedInformation() {
	// 	if (Trigger.isUpdate && Trigger.isBefore) {
	// 		Set<Id> formIds = new Set<Id>();
	// 		User u = [SELECT Id, Professional_Name__c FROM user WHERE Id = :userInfo.getUserId() WITH SECURITY_ENFORCED];
	// 		for (disco__Form__c form : (disco__Form__c[]) Trigger.New) {
	// 			disco__Form__c old = Trigger.oldMap?.containsKey(form.Id) == true ? (disco__Form__c) Trigger.oldMap?.get(form.Id) : null;
	// 			if ((form.disco__Save_Complete__c ) && (!old.disco__Save_Complete__c )) {
	// 				form.Finalized_By__c = u.Id;
	// 				form.Finalized_Date_Time__c = Datetime.now();
	// 				form.Finalized_By_Professional_Name__c = u.Professional_Name__c;
	// 				formIds.add(form.Id);
	// 			}
	// 		}
	// 		if (formIds.size() > 0) {
	// 			List<disco__Answer__c> answersToUpdate = new List<disco__Answer__c>();
	// 			List<disco__Answer__c> subAnswers = [
	// 				SELECT Id, disco__Form__c, disco__Answer__c, disco__Question__r.disco__Link_Field__c
	// 				FROM disco__Answer__c
	// 				WHERE
	// 					disco__Link_Object__c = 'disco__Form__c'
	// 					AND (disco__Question__r.disco__Link_Field__c = 'Finalized_By__c'
	// 					OR disco__Question__r.disco__Link_Field__c = 'Finalized_Date_Time__c'
	// 					OR disco__Question__r.disco__Link_Field__c = 'Finalized_By_Professional_Name__c')
	// 					AND disco__Form__c IN :formIds
	// 				WITH SECURITY_ENFORCED
	// 			];
	// 			for (disco__Answer__c ans : subAnswers) {
	// 				if (ans.disco__Answer__c == null || ans.disco__Answer__c == '') {
	// 					if (ans.disco__Question__r.disco__Link_Field__c == 'Finalized_By__c') {
	// 						ans.disco__Lookup_Id__c = u.id;
	// 						ans.disco__Lookup_Answer__c = u.Professional_Name__c;
	// 					} else if (ans.disco__Question__r.disco__Link_Field__c == 'Finalized_By_Professional_Name__c') {
	// 						ans.disco__Text_Answer__c = u.Professional_Name__c;
	// 					} else // then d/t
	// 					{
	// 						ans.disco__Date_Time_Answer__c = ((disco__Form__c) (Trigger.newMap.get(ans.disco__Form__c)))
	// 							.Finalized_Date_Time__c;
	// 					}
	// 					answersToUpdate.add(ans);
	// 				}
	// 			}

	// 			update answersToUpdate;
	// 			// System.enqueueJob(new updateFormAnswer(answersToUpdate));

	// 		}
	// 	}
	// }
	// public class updateFormAnswer implements Queueable {
	// 	List<disco__Answer__c> answersToUpdate = new List<disco__Answer__c>();

	// 	public updateFormAnswer(List<disco__Answer__c> answersToUpdate) {
	// 		this.answersToUpdate = answersToUpdate;
	// 	}
	// 	public void execute(QueueableContext context) {
	// 		if(answersToUpdate != null && answersToUpdate.size() > 0) {
	// 			if(!Test.isRunningTest()) {
	// 				update answersToUpdate;
	// 			}
	// 		}
	// 	}
	// }
}