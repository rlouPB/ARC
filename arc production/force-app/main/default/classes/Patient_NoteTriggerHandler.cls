/**
* @author ben.efigenio@synapticap.com
* @date 08/19/2010
*
* @group Patient_Note__c
*
* @description Patient_NoteTriggerHandler for the Patient Note SObject. This class implements the ITrigger
*  Please check ITrigger and TriggerFactory to understand the order execution and methods used
*/
public without sharing class Patient_NoteTriggerHandler implements ITrigger {
	private final List<String> SOHTypes = new List<String>{'Psychopharmacology Monthly Note', 'Medical Office Discharge Note'};

	/* @description List of Alerts to be published in the andFinally method
	*/
	private List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();

    private static Map<Id, Account> accountsMap;
    private static Map<String, Id> groupIdsByName;

	private List<Action_Item__c> actionItemsToInsert = new List<Action_Item__c>();
	private Map<String, Map<String, String>> docTypeSnapShotMap = new Map<String, Map<String, String>> ();

	public static disco__Form_Template__c VERIFICATION_REC_PSYCHIATRIST_TRANSFER_FORM_TEMPLATE = [
		SELECT Id
		FROM disco__Form_Template__c
		WHERE DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer' AND disco__Status__c = 'In Use' LIMIT 1
	];
	public static Group MEDICAL_RECORDS_GROUP = [SELECT Id FROM Group WHERE DeveloperName = 'Medical_Records'];

	public static List<String> stagesToShareWithClinical = new List<String>{
		'Consultation Pending',
		'Admitted'
	};

	static Map<Id, Account> accountsByIdMap;

	/*******************************************************************************************************
	* @description This method is called prior to execution of a BEFORE trigger. Use this to cache
	* any data required into maps prior execution of the trigger.
	*/
	public void bulkBefore() {
		Set<Id> accountIds = new Set<Id>();
		if (Trigger.isInsert) {
			boolean isSOH = false;
			System.debug('Patient_NoteTriggerHandler bulkBefore');
			Set<Id> patientIds = new Set<Id>();
		
			for (Patient_Note__c pNote: (List<Patient_Note__c>)Trigger.new)
			{
				if(pNote.Type__c == 'Summation of Hospitalization') {
					System.debug('Patient_NoteTriggerHandler pNote---' + pNote);
					patientIds.add(pNote.Account__c);
					isSOH = true;
				}

				if(null != pNote.Account__c){
					accountIds.add(pNote.Account__c);
				}
			}
            if(test.isRunningTest()){
                SOHTypes.add('Summation of Hospitalization');
            }
			System.debug('Patient_NoteTriggerHandler patientNoteIds = ' + patientIds);
			List<SnapShot__c> snapshots = [SELECT Id ,SOH_Html__c,Patient_Note__r.type__c, Patient_Note__c, Patient_Note__r.Account__c FROM Snapshot__c
				WHERE Patient_Note__r.Account__c in :patientIds
					AND Patient_Note__r.type__c in :SOHTypes
					AND Patient_Note__r.Status__c='Finalized' ORDER BY Finalized_Date_Time__c ASC];
			System.debug('Patient_NoteTriggerHandler snapshots = ' + snapshots);
			for(SnapShot__c s : snapshots) {
				if(!docTypeSnapShotMap.containsKey(s.Patient_Note__r.Account__c)) {
					docTypeSnapShotMap.put(s.Patient_Note__r.Account__c, new Map<String, String>());
				}
				Map<String, String> sohSnapShot = docTypeSnapShotMap.get(s.Patient_Note__r.Account__c);
				sohSnapShot.put(s.Patient_Note__r.type__c, s.SOH_Html__c);
			}
			if(isSOH){
				for(Id pId : patientIds) {
					String h = getSnapshotHtml('Admitted_Program__c', 'List_View_Fields', pId, 'Start_Date__c desc');
					h += '<br>';
					h += getSnapshotHtml('Admitted_Program_Status__c', 'List_View_Fields', pId, 'Start_Date_Time__c desc');
					System.debug('Patient_NoteTriggerHandler ' + h);
					if(!docTypeSnapShotMap.containsKey(pId)) {
						docTypeSnapShotMap.put(pId, new Map<String, String>());
					}
					Map<String, String> sohSnapShot = docTypeSnapShotMap.get(pId);
					if(sohSnapShot != null) {
						sohSnapShot.put('History Program', h);
					}
				}
			}
			System.debug('Patient_NoteTriggerHandler docTypeSnapShotMap = ' + docTypeSnapShotMap);
		}

		for (Patient_Note__c pNote: (List<Patient_Note__c>)Trigger.new){
			if(null != pNote.Account__c){
				accountIds.add(pNote.Account__c);
			}
		}
		accountsByIdMap = new Map<Id, Account>([SELECT Id, Patient_Contact__c FROM Account WHERE Id IN :accountIds]);
		System.debug('in bulkBefore - accountsByIdMap : ' + accountsByIdMap);
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
			OutstandingItems.deleteRelatedTags(trigger.old);
		}
		System.debug('System is after.');
		System.debug('Is system insert? ' + Trigger.isInsert);
		System.debug('Is system update? ' + Trigger.isUpdate);
		if (Trigger.isInsert || Trigger.isUpdate)
		{
			TrackFieldHistory.trackFields(trigger.new, trigger.oldMap);
		}

		If (Trigger.isInsert || Trigger.isUpdate)
		{
			Set<Id> accountIds = new Set<Id>();
			for (Patient_Note__c pNote: (List<Patient_Note__c>)Trigger.new)
			{
				accountIds.add(pNote.Account__c);
			}

			accountsMap = new Map<Id, Account>([
				SELECT Id, Current_Admission__r.Stage__c, Current_Admission__r.Chart_Closed__c
				FROM Account
				WHERE Id IN: accountIds
			]);

			List<Group> allGroups = [
				SELECT Name
				FROM Group
			];
			groupIdsByName = new Map<String, Id>();
			for (Group currentGroup: allGroups)
			{
				groupIdsByName.put(currentGroup.Name, currentGroup.Id);
			}
		}

		if(Trigger.IsInsert) {
			PatientNoteCtl.cloneDiagnosesWithPatientNote((List<Patient_Note__c>)Trigger.new);
		}

		if((Trigger.IsInsert || Trigger.IsUpdate)){
			closeRelatedNursingShiftItems();
			cancelRelatedNursingShiftItems();
			PatientNoteSnapshot.process();
			clearAwayOrderPackageInstructions();
		}
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be inserted during a BEFORE
	* trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
	*/
	public void beforeInsert(SObject so) {
		Patient_Note__c pNote = (Patient_Note__c) so;
		if(docTypeSnapShotMap.containsKey(pNote.Account__c)) {
			Map<String, String> sohSnapShot = docTypeSnapShotMap.get(pNote.Account__c);
			pNote.SOH_Med_Office_Discharge__c = sohSnapShot.get('Medical Office Discharge Note');
			pNote.SOH_Psychophram_Monthly_Note__c = sohSnapShot.get('Psychopharmacology Monthly Note');
			pNote.SOH_History_Program__c = sohSnapShot.get('History Program');
		}
		System.debug('Patient_NoteTriggerHandler pNote SOH_Med_Office_Discharge__c= ' + pNote.SOH_Med_Office_Discharge__c);
		System.debug('Patient_NoteTriggerHandler pNote SOH_Psychophram_Monthly_Note__c= ' + pNote.SOH_Psychophram_Monthly_Note__c);
		System.debug('Patient_NoteTriggerHandler pNote SOH_History_Program__c= ' + pNote.SOH_History_Program__c);

		if(null != pNote.Account__c && null != accountsByIdMap.get(pNote.Account__c) && null != accountsByIdMap.get(pNote.Account__c).Patient_Contact__c) {
			pNote.Contact__c = accountsByIdMap.get(pNote.Account__c).Patient_Contact__c;
		}
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be updated during a BEFORE
	* trigger.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
        Patient_Note__c newPatientNote = (Patient_Note__c) so;
        Patient_Note__c oldPatientNote = (Patient_Note__c) oldSo;
        newPatientNote = newPatientNote.Status__c == 'Finalized' && oldPatientNote.Status__c != 'Finalized' && oldPatientNote.SDoc_Junction__c == null ? createSdDocJunction(newPatientNote) : newPatientNote;
    
		if(null != newPatientNote.Account__c && null != accountsByIdMap.get(newPatientNote.Account__c) && null != accountsByIdMap.get(newPatientNote.Account__c).Patient_Contact__c) {
			System.debug('conditions were true setting contact');
			newPatientNote.Contact__c = accountsByIdMap.get(newPatientNote.Account__c).Patient_Contact__c;
		}
		System.debug('newPatientNote.Contact__c : ' + newPatientNote.Contact__c);
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record to be deleted during a BEFORE
	* trigger.
	*/
	public void beforeDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record inserted during an AFTER
	* trigger. Always put field validation in the 'After' methods in case another trigger
	* has modified any values. The record is 'read only' by this point.
	*/
	public void afterInsert(SObject so) {

		Patient_Note__c newPatientNote = (Patient_Note__c) so;

		String triggerObject = String.valueOf(Trigger.new.getSObjectType());

		AlertsFilter.execute(null, newPatientNote, alertsToBePublished, triggerObject, 'Insert');

        Account account = accountsMap.get(newPatientNote.Account__c);

        List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Admissions')};

        if (account != null && account.Current_Admission__c != null && account.Current_Admission__r.Stage__c != null &&
				(stagesToShareWithClinical.contains(account.Current_Admission__r.Stage__c) || ('Discharged' == account.Current_Admission__r.Stage__c && !account.Current_Admission__r.Chart_Closed__c)))
        {
            groupsToShare.add(groupIdsByName.get('Clinical'));
        }

		if('Discharge Medication Order' == newPatientNote.Type__c) {
			groupsToShare.add(groupIdsByName.get('Med Office'));

			Assigned_Clinician__c[] assignedPsychiatrists = [SELECT Id, Start_Date__c, End_Date__c, Patient_Account__c, Professional_Name__c, Role__c, User__c
				FROM Assigned_Clinician__c WHERE Patient_Account__c = '0012i00000bWX7jAAG' AND Role__c = 'Psychiatrist' AND Start_Date__c <= TODAY AND (End_Date__c = null OR End_Date__c >= TODAY)];

			for(Assigned_Clinician__c ac : assignedPsychiatrists) {
				groupsToShare.add(ac.User__c);
			}

		}

        String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, groupsToShare, 'Edit');
        System.debug('CaseTriggerHandler afterInsert shareResult: ' + shareResult);

		//PatientNoteSnapshot.processFromAfterUpdateInsert();
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record updated during an AFTER
	* trigger.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {

		Patient_Note__c oldPatientNote = (Patient_Note__c) oldSo;
		Patient_Note__c newPatientNote = (Patient_Note__c) so;

		String triggerObject = String.valueOf(Trigger.new.getSObjectType());

		AlertsFilter.execute(oldPatientNote, newPatientNote, alertsToBePublished, triggerObject, 'Update');

		//Manage Queue sharing for Completed Patient Note
		if (newPatientNote.Status__c == 'Finalized' && oldPatientNote.Status__c != 'Finalized') {
			//Get the Clinical Public Group
			List<Group> gList = [SELECT Id, Name FROM Group WHERE Name = 'Clinical' LIMIT 1];
			if (!gList.isEmpty()) {
				SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, new List<Id>{gList[0].Id}, 'Read');
			} else {
				ProcessLogging.quickProcessLog('Patient_NoteTriggerHandler', 'Patient_NoteTriggerHandler.afterUpdate', 'No Clinical group was found');
			}

			// Create a Form and an Action Items when a Psychopharmacology Services Transfer Note is finalized.
			if('Psychopharmacology Services Transfer Note' == newPatientNote.Type__c) {
				disco__Form__c df = new disco__Form__c(
					disco__Form_Account__c = newPatientNote.Account__c,
					disco__Form_Template__c = VERIFICATION_REC_PSYCHIATRIST_TRANSFER_FORM_TEMPLATE.Id,
					disco__Form_Contact__c = newPatientNote.Contact__c,
					Admission__c = newPatientNote.Admission__c
				);
				insert df;

				Action_Item__c ai = new Action_Item__c(
					OwnerId=newPatientNote.New_Prescriber_User__c,
					Form__c=df.Id,
					Account__c=newPatientNote.Account__c,
					Status__c='Open',
					Description__c='Please open and submit the form below and mark this as Complete afterward.',
					RecordTypeId=RecordTypeHelper.getIdByName('Action_Item__c','Basic'),
					Type__c='Psychopharmacology Services Transfer Note',
					Assignment_Type__c='Individual'
				);
				actionItemsToInsert.add(ai);

				Action_Item__c ai2 = new Action_Item__c(
					OwnerId=MEDICAL_RECORDS_GROUP.Id,
					Account__c=newPatientNote.Account__c,
					Status__c='Open',
					Description__c='Please update the assigned clinician and click Complete when done.',
					RecordTypeId=RecordTypeHelper.getIdByName('Action_Item__c','Basic'),
					Type__c='Psychopharmacology Services Transfer Note',
					Assignment_Type__c='Queue'
				);
				actionItemsToInsert.add(ai2);
			}

			// Create an Action Items when a Psychotherapy Transfer Note Note is finalized.
			if('Psychotherapy Transfer Note' == newPatientNote.Type__c) {
				Action_Item__c ai = new Action_Item__c(
					OwnerId=MEDICAL_RECORDS_GROUP.Id,
					Account__c=newPatientNote.Account__c,
					Description__c='Please update the patient\'s assigned clinicians then complete this action item.',
					Status__c='Open',
					RecordTypeId=RecordTypeHelper.getIdByName('Action_Item__c','Basic'),
					Type__c='Psychotherapy Transfer Note',
					Assignment_Type__c='Queue'
				);
				actionItemsToInsert.add(ai);
			}

			if('Discharge Medication Order' == newPatientNote.Type__c) {
				List<Id> groupAndUserIds = new List<Id>();
				groupAndUserIds.add(groupIdsByName.get('Med Office'));
	
				Assigned_Clinician__c[] assignedPsychiatrists = [SELECT Id, Start_Date__c, End_Date__c, Patient_Account__c, Professional_Name__c, Role__c, User__c
					FROM Assigned_Clinician__c WHERE Patient_Account__c = '0012i00000bWX7jAAG' AND Role__c = 'Psychiatrist' AND Start_Date__c <= TODAY AND (End_Date__c = null OR End_Date__c >= TODAY)];
	
				for(Assigned_Clinician__c ac : assignedPsychiatrists) {
					groupAndUserIds.add(ac.User__c);
				}

				String result = SharingRecord_Utils.deleteSharingRecords(new List<Id>{newPatientNote.Id}, groupAndUserIds);
				result = SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, groupAndUserIds, 'Read');
			}
		}

		if (newPatientNote.Status__c == 'Completed' && oldPatientNote.Status__c != 'Completed') {
			// Id authSignersQueueId = AuthorizedSigners.getAuthSignersQueueId(newPatientNote.Admission__c);
			// SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, new List<Id>{authSignersQueueId}, 'Edit');

			Account account = accountsMap.get(newPatientNote.Account__c);

			List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Admissions')};

			if (account != null && account.Current_Admission__c != null && account.Current_Admission__r.Stage__c != null &&
					stagesToShareWithClinical.contains(account.Current_Admission__r.Stage__c))
			{
				groupsToShare.add(groupIdsByName.get('Clinical'));
			}

			String shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, groupsToShare, 'Edit');

			shareResult = SharingRecord_Utils.createSharingRecords(new List<Id>{newPatientNote.Id}, new List<Id>{oldPatientNote.OwnerId}, 'Read');
		}
	}

	/*******************************************************************************************************
	* @description This method is called iteratively for each record deleted during an AFTER
	* trigger.
	*/
	public void afterDelete(SObject so) {}

	/*******************************************************************************************************
	* @description This method is called once all records have been processed by the trigger. Use this
	* method to accomplish any final operations such as creation or updates of other records.
	*/
	public void andFinally() {
		if(alertsToBePublished.size() > 0) {
			EventBus.publish(alertsToBePublished);
		}

		if(!actionItemsToInsert.isEmpty()){
			insert actionItemsToInsert;
		}
	}

    public static Patient_Note__c createSdDocJunction(Patient_Note__c newPatientNote){
        SDoc_Junction__c sDocJunction = new SDoc_Junction__c(Patient_Note__c = newPatientNote.Id);
        insert sDocJunction;
        newPatientNote.SDoc_Junction__c = sDocJunction.Id;
        return newPatientNote;
    }

	public static void closeRelatedNursingShiftItems(){
		Id[] patientNoteIds = new Id[]{};
		if(Trigger.IsAfter && Trigger.IsUpdate){
			for (Patient_Note__c pn : (Patient_Note__c[])Trigger.new) {
				if( pn.Status__c == 'Finalized' && pn.Status__c != ((Patient_Note__c)Trigger.oldmap.get(pn.Id)).Status__c) {
					patientNoteIds.add(pn.Id);
				}
			}
			if(patientNoteIds.size() > 0){
				Nursing_Shift_Item__c[] items = [SELECT Id FROM Nursing_Shift_Item__c WHERE Patient_Note__c in :patientNoteIds and Status__c != 'Closed' and Status__c != 'Cancelled'];
				for ( Nursing_Shift_Item__c item : items ) {
					item.Status__c = 'Closed';
				}
				if(items.size() > 0){
					update items;
				}
			}
		}
	}

	public static void cancelRelatedNursingShiftItems(){
		Id[] patientNoteIds = new Id[]{};
		if(Trigger.IsAfter && Trigger.IsUpdate){
			for (Patient_Note__c pn : (Patient_Note__c[])Trigger.new) {
				if( pn.Status__c == 'Cancelled' && pn.Status__c != ((Patient_Note__c)Trigger.oldmap.get(pn.Id)).Status__c) {
					patientNoteIds.add(pn.Id);
				}
			}
			if(patientNoteIds.size() > 0){
				Nursing_Shift_Item__c[] items = [SELECT Id FROM Nursing_Shift_Item__c WHERE Patient_Note__c in :patientNoteIds and Status__c != 'Closed' and Status__c != 'Cancelled'];
				for ( Nursing_Shift_Item__c item : items ) {
					item.Status__c = 'Cancelled';
				}
				if(items.size() > 0){
					update items;
				}
			}
		}
	}

	public static void clearAwayOrderPackageInstructions(){
		Id[] accountIds = new Id[]{};
		if(Trigger.IsAfter && Trigger.IsUpdate){
			for (Patient_Note__c pn : (Patient_Note__c[])Trigger.new) {
				if('Finalized' == pn.Status__c && pn.Status__c != ((Patient_Note__c)Trigger.oldmap.get(pn.Id)).Status__c && 'Away Medication Order' == pn.Type__c) {
					accountIds.add(pn.Account__c);
				}
			}
			if(accountIds.size() > 0){
				Prescription__c[] items = [SELECT Id, away_package_Instruction__c, Quantity_to_Package__c, Quantity_to_Package_Temp__c FROM Prescription__c WHERE Account__c IN :accountIds];

				for (Prescription__c item : items ) {
					item.away_package_Instruction__c = null;
					item.Quantity_to_Package__c = item.Quantity_to_Package_Temp__c;
					item.Quantity_to_Package_Temp__c = null;
				}
				if(items.size() > 0){
					System.Debug('Clearing away package prescriptions - items : ' + items);
					update items;
				}
			}
		}
	}
	public String getSnapshotHtml(String sObjectName, String fieldSetName, Id patientId, String orderBy) {
		String query = '';
		Set<String> setFieldsToQuery = new Set<String>();
		Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(sObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		List<String> labels = new List<String>();
		List<String> dataTypes = new List<String>();
		List<String> fields = new List<String>();
		List<Field> fieldDataTypes = new List<Field>();

		for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
			labels.add(String.valueOf(eachFieldSetMember.getLabel()) );
			String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            if(dataType == 'picklist') {
                dataType = 'string';
            }
			fields.add(String.valueOf(eachFieldSetMember.getFieldPath()).toLowerCase());
			fieldDataTypes.add(new Field(dataType, String.valueOf(eachFieldSetMember.getFieldPath()).toLowerCase()));

		}
		query = 'SELECT ' + String.join(fields, ',') +
                    ' FROM ' + sObjectName + ' WHERE Account__c = :patientId';
		if(String.isNotBlank(orderBy)){
			query += ' Order By ' + orderBy;
		}

		System.debug('query---' + query);
        List<SObject> objects = Database.query(query);
		String html = '<table class="history_program"><theader><tr>';
		for(String label : labels) {
			html += '<th>' + label + '</th>';
		}

		html += '</tr></theader><tbody>';
		for(SObject obj : objects) {
			html += '<tr>';
			for(Field f : fieldDataTypes) {
				html += '<td>';
				string h = String.valueOf(obj.get(f.name));
				if(f.type=='datetime') {
					h='';
					if(obj.get(f.name) != null) {
						h = DateTime.valueOf(obj.get(f.name)).format('MM/dd/yy', 'America/New_York');
					}
				} else if(f.type=='date') {
					h='';
					if(obj.get(f.name) != null) {
						h = Date.valueOf(obj.get(f.name)).format();
					}
				}
				html += h;
				html += '</td>';
			}
			html += '</tr>';
		}
		html += '</tbody></table>';
		return html;
	}

	class Field {
		Field(String t, String n) {
			type = t;
			name = n;
		}
		String type;
		String name;
	}

}