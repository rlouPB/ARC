/**
 * @group Psych_Testing_Request___c
 *
 * @description PsychTestingRequest_TriggerHandler for the Patient Note SObject. This class implements the ITrigger
 *  Please check ITrigger and TriggerFactory to understand the order execution and methods used
 */
public without sharing class Psych_Testing_RequestTriggerHandler implements ITrigger {
	static string cronTimeFormat = '{0} {1} {2} {3} {4} ? {5}';
	static Map<ID, String> psychotherapistByAccountID;
	static Map<ID, String> admissionByAccountID;
	private static Id CUSTOM_NOTE_RECORDTYPE_ID = Schema.SObjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordTypeId();
	private static Map<String, String> requestRecordType2DocTypeMap = new Map<String, String>{ 'Neuropsychological_Screening_Request' => 'Neuropsychological Screening Report', 'Neuropsychological_Testing_Request' => 'Neuropsychological Testing Report', 'Psychological_Testing_Request' => 'Psychological Testing Report' };
	/*******************************************************************************************************
	 * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkBefore() {
		if (!Trigger.isDelete) {
			List<ID> accountIDs = new List<ID>();
			for (Psych_Testing_Request__c currentRequest : (List<Psych_Testing_Request__c>) Trigger.new) {
				accountIDs.add(currentRequest.Patient_Account__c);
			}

			List<Account> relatedAccounts = [SELECT Current_Admission__r.Psychotherapist__c, Current_Admission__c FROM Account WHERE ID IN :accountIDs];

			psychotherapistByAccountID = new Map<ID, String>();
			admissionByAccountID = new Map<ID, String>();
			for (Account currentAccount : relatedAccounts) {
				psychotherapistByAccountID.put(currentAccount.ID, currentAccount.Current_Admission__r.Psychotherapist__c);
				admissionByAccountID.put(currentAccount.ID, currentAccount.Current_Admission__c);
			}
		}
	}

	/*******************************************************************************************************
	 * @description This method is called prior to execution of an AFTER trigger. Use this to cache
	 * any data required into maps prior execution of the trigger.
	 */
	public void bulkAfter() {
		// Check for outstanding items.
		if (!Trigger.isDelete) {
			OutstandingItems.fireCheckOutstandingEvent(Trigger.new);
		} else {
			OutstandingItems.deleteRelatedTags(Trigger.old);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be inserted during a BEFORE
	 * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	 */
	public void beforeInsert(SObject so) {
		Psych_Testing_Request__c psychRequest = (Psych_Testing_Request__c) so;
		if (psychRequest.Patient_Account__c != null && psychRequest.Therapist__c == null) {
			psychRequest.Therapist__c = psychotherapistByAccountID.get(psychRequest.Patient_Account__c);
			psychRequest.admission__c = admissionByAccountID.get(psychRequest.Patient_Account__c);
		}
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be updated during a BEFORE
	 * trigger.
	 */
	public void beforeUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record to be deleted during a BEFORE
	 * trigger.
	 */
	public void beforeDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record inserted during an AFTER
	 * trigger. Always put field validation in the 'After' methods in case another trigger
	 * has modified any values. The record is 'read only' by this point.
	 */
	public void afterInsert(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record updated during an AFTER
	 * trigger.
	 */
	public void afterUpdate(SObject oldSo, SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called iteratively for each record deleted during an AFTER
	 * trigger.
	 */
	public void afterDelete(SObject so) {
	}

	/*******************************************************************************************************
	 * @description This method is called once all records have been processed by the trigger. Use this
	 * method to accomplish any final operations such as creation or updates of other records.
	 */
	public void andFinally() {
	}
	// public static String createPsychTestingReport(Psych_Testing_Request__c req, Date scheduledDate, Date contactDate) {
	//     if(scheduledDate < Date.Today()) {
	//         return null;
	//     }
	//     String day = String.valueOf(scheduledDate.day());
	//     String month = String.valueOf(scheduledDate.month());
	//     String year = String.valueOf(scheduledDate.year());
	//     String second = '0';
	//     String minute = '0';
	//     String hour = '0';
	//     if(scheduledDate == Date.Today()) {
	//         Datetime now = Datetime.now();
	//         hour = String.valueOf(now.hour());
	//         minute = String.valueOf(now.addMinutes(2).minute());
	//     }

	//     String cronJobTimeString = String.format(cronTimeFormat, new List<String>{second, minute, hour, day, month, year});
	//     PsychTestingRequestScheduler sch = new PsychTestingRequestScheduler(req.Patient_Account__c,
	//                                                                         requestRecordType2DocTypeMap.get(req.Record_Type_Name__c),
	//                                                                         req.Admission__c,
	//                                                                         contactDate
	//                                                                     );
	//     String jobID = system.schedule('Create Psych Testing Report -' + System.currentTimeMillis(), cronJobTimeString, sch);
	//     return jobID;
	// }
	public static void handlePsychTestRequestChanges() {
		List<Patient_Note__c> notes = new List<Patient_Note__c>();
		for (Psych_Testing_Request__c req : (Psych_Testing_Request__c[]) Trigger.New) {
			if (req.Report_Writer__c != null && (req.Report_Due_Date__c != null || req.Testing_Report_Due_Date__c != null) && req.Patient_Note__c == null) {
				Patient_Note__c note = new Patient_Note__c(
					Account__c = req.Patient_Account__c,
					Admission__c = req.Admission__c,
					//Contact_Date__c = req.Report_Due_Date__c != null ? req.Report_Due_Date__c : req.Testing_Report_Due_Date__c,
					Contact_Date__c = Date.Today(),
					recordTypeId = CUSTOM_NOTE_RECORDTYPE_ID,
					Type__c = requestRecordType2DocTypeMap.get(req.Record_Type_Name__c),
					Status__c = 'Draft',
					Psych_Testing_Request__c = req.Id,
					OwnerId = req.Report_Writer__c
				);
				notes.add(note);
			}
			// Psych_Testing_Request__c old = Trigger.oldMap?.containsKey(req.Id) == true ? (Psych_Testing_Request__c) Trigger.oldMap?.get(req.Id) : null;
			// if ((req.Seminar_Date__c != null) && (old.Seminar_Date__c  !=  req.Seminar_Date__c) ){
			//     createPsychTestingReport(req, req.Seminar_Date__c, req.Seminar_Date__c);
			// }
			// if ((req.Seminar_Date__c == null) && (req.Report_Due_Date__c != null) && (old.Report_Due_Date__c  !=  req.Report_Due_Date__c) ){
			// 	createPsychTestingReport(req, req.Report_Due_Date__c, req.Report_Due_Date__c);
			// }
		}

		insert notes;
		List<Psych_Testing_Request__c> requests = new List<Psych_Testing_Request__c>();
		for (Patient_Note__c n : notes) {
			requests.add(new Psych_Testing_Request__c(Id = n.Psych_Testing_Request__c, Patient_Note__c = n.Id));
		}

		update requests;
	}
}