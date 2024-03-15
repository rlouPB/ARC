public without sharing class PatientNoteSnapshot {
	private static final string STATUS_ACTIVE = 'active';
	private static final String[] PRESCRIPTION_STATUSES_TO_INCLUDE = new List<String>{ 'Active', 'Discontinued' };

	public Map<Id, Patient_Note__c> patientNoteMap;

	//added for Snapshot Subsets: Patient Note field to store rendered Html
	Map<String, String> subsetNameTosubsetFieldNameMap = new Map<String, String>();
	//added for Snapshot Subsets: rendered Html
	Map<String, String> subsetNameToHtmlMap = new Map<String, String>();

	private Map<Id, Allergy__c[]> allergiesByPatientIdMap;

	private Map<Id, Physical_Monitor__c[]> monitorsByPatientIdMap;

	private Map<Id, Prescription__c[]> prescriptionsByPatientIdMap;

	private Map<Id, Diagnosis__c[]> diagnosesByCurrentAdmissionMap = new Map<Id, Diagnosis__c[]>();

	private Map<Id, Admission__c> admissionMap = new Map<Id, Admission__c>();

	private Map<Id, Intervention__c[]> interventionsByPatientIdMap;
	private Map<Id, Intervention__c[]> interventionsByPatientIdMapAll;

	private Map<string, Group__c> groupsByNameMap = new Map<string, Group__c>();

	private Map<String, Group__c> groupMembershipsByGroupNameMap = new Map<String, Group__c>();

	private Map<string, User> groupMembersByGroupName = new Map<string, User>();

	private Map<Id, Assigned_Clinician__c[]> assignedCliniciansByPatientIdMap = new Map<Id, Assigned_Clinician__c[]>();

	private Map<Id, Note_Definition__mdt[]> noteDefinitionsByPatientNoteIdMap;

	public Map<string, Note_Item__mdt[]> noteItemsByNoteLabel = new Map<string, Note_Item__mdt[]>();

	private List<Snapshot__c> snapshotsToInsert = new List<Snapshot__c>();

	private list<Note_Definition__mdt> noteDefinitionList = new List<Note_Definition__mdt>();

	private set<id> patientNoteIds = new Set<id>();

	private map<id, Account> patientMap = new Map<id, Account>();

	private Patient_Note__c[] patientNoteList;

	public static map<string, Schema.DescribeFieldResult> patientNoteFieldMap {
		get {
			if (patientNoteFieldMap == null) {
				patientNoteFieldMap = new Map<string, Schema.DescribeFieldResult>();
				for (Schema.SObjectField field : Schema.getGlobalDescribe().get('Patient_Note__c').getDescribe().fields.getMap().values()) {
					Schema.DescribeFieldResult dfr = field.getDescribe();
					patientNoteFieldMap.put(dfr.getName(), dfr);
				}
			}
			return patientNoteFieldMap;
		}
		private set;
	}

	static map<string, string> getTeamMembersByRole_cache = new Map<string, string>();
	public string getTeamMembersByRole(id patientId, string roleName) {
		string key = '' + patientId + '-' + roleName;
		if (!getTeamMembersByRole_cache.containsKey(key)) {
			string[] members = new List<string>{};
			Assigned_Clinician__c[] clinitians = this.assignedCliniciansByPatientIdMap.get(patientId);
			if (clinitians != null && !clinitians.isEmpty()) {
				for (Assigned_Clinician__c ac : clinitians) {
					if (ac.Role__c == roleName && string.isNotEmpty(ac.User_Name__c)) {
						members.add(ac.User_Name__c);
					}
				}
			}
			getTeamMembersByRole_cache.put(key, string.join(members, ', '));
		}
		return getTeamMembersByRole_cache.containsKey(key) ? getTeamMembersByRole_cache.get(key) : '';
	}

	public PatientNoteSnapshot(Set<Id> patientNoteIds) {
		set<id> patientIds = new Set<id>();
		set<id> currentAdmissionIds = new Set<id>();
		set<string> groupNames = new Set<string>();

		if (patientNoteIds.isEmpty()) {
			return;
		}

		List<Patient_Note__c> patientNotes = [SELECT Id, Type__c FROM Patient_Note__c WHERE Id IN :patientNoteIds];

		//ARC-2039 collect the note types that associated with patient notes as in input parameter
		List<String> patientNoteTypes = new List<String>();
		for (Patient_Note__c note : patientNotes) {
			patientNoteTypes.add(note.Type__c);
		}

		//removed 220412 JN Not currently referenced
		// Set<String> embeddedParamFields = new Set<String>();

		string noteItemsQuery = QueryUtils.getQueryAll('Note_Item__mdt', new List<string>{ 'Note_Definition__r.Note_Label__c' }) + ' WHERE Note_Definition__r.Note_Label__c in :patientNoteTypes and active__c = true order by Order__c asc';
		Note_Item__mdt[] noteItems = (Note_Item__mdt[]) Database.query(noteItemsQuery);

		set<string> extraPatientNoteFields = new Set<string>();

		for (Note_Item__mdt ni : noteItems) {
			// if(ni.Note_definition__r.Note_Label__c == 'Psychotherapy Monthly Progress Note') {
			//     system.debug('===========order= name=' +  ni.Note_definition__r.Note_Label__c + ' order = ' + ni.Order__c);
			// }
			if (!this.noteItemsByNoteLabel.containsKey(ni.Note_definition__r.Note_Label__c)) {
				this.noteItemsByNoteLabel.put(ni.Note_Definition__r.Note_Label__c, new List<Note_Item__mdt>());
			}
			this.noteItemsByNoteLabel.get(ni.Note_definition__r.Note_Label__c).add(ni);

			// if (string.isNotBlank(ni.Embedded_Component_Parameters__c)){
			//     for( string f : ni.Embedded_Component_Parameters__c.trim().replace('__r,','__r\\.').split(',') ){
			//         if(string.isNotBlank(f)){
			//             embeddedParamFields.add(f);
			//         }
			//     }
			// }

			if (string.isnotblank(ni.Field_Name__c) && string.isNotBlank(ni.Field_Name__c.trim())) {
				extraPatientNoteFields.add(ni.Field_Name__c.trim());
			}
		}

		this.patientNoteIds.addAll(patientNoteIds);

		extraPatientNoteFields.addAll(new List<string>{ 'Account__r.Name', 'Account__r.Current_Case__c', 'Account__r.Current_Admission__c', 'Account__r.Team__c', 'Admission__r.Admit_Date__c' });
		this.patientNoteList = (Patient_Note__c[]) Database.query(QueryUtils.getQueryAll('Patient_Note__c', new List<String>(extraPatientNoteFields)) + ' WHERE Id IN :patientNoteIds and Account__c != null');

		this.patientNoteMap = new Map<Id, Patient_Note__c>(patientNoteList);

		if (patientNoteList.isEmpty()) {
			return;
		}

		for (Patient_Note__c pn : patientNoteList) {
			patientIds.add(pn.Account__c);
			if (pn.Account__r?.Current_Admission__c != null) {
				currentAdmissionIds.add(pn.Account__r.Current_Admission__c);
			}
			if (string.isNotBlank(pn.Account__r?.Team__c)) {
				groupNames.add('Team ' + pn.Account__r.Team__c);
			}
		}

		patientMap = new Map<Id, Account>([SELECT Id, Name, Current_Admission__r.Team__c, Current_Admission__r.CreatedDate, Current_Admission__r.Psychotherapist__r.Name, Current_Admission__r.Psychotherapist__r.Professional_Name__c, Current_Admission__r.Current_Admitted_Program__r.Name FROM Account WHERE Id IN :patientIds]);

		//-----------Filling Maps----------//
		this.diagnosesByCurrentAdmissionMap = new Map<Id, Diagnosis__c[]>();
		for (Diagnosis__c diag : [SELECT Id, Source__c, Type__c, Clinical_Code_Description__c, Admission__c, Patient_Note__c, Additional_Specifiers__c, Marked_for_Delete__c, Clinical_Code__c, Clinical_Code__r.Name, Clinical_Code__r.Description__c, Admission__r.Principal_Diagnosis__c, Patient_Note__r.Status__c FROM Diagnosis__c WHERE Admission__c IN :currentAdmissionIds AND Source__c != NULL AND Type__c != NULL AND Patient_Note__r.Status__c = 'Finalized' AND Status__c = 'Finalized']) {
			if (!this.diagnosesByCurrentAdmissionMap.containsKey(diag.admission__c)) {
				this.diagnosesByCurrentAdmissionMap.put(diag.admission__c, new List<Diagnosis__c>{});
			}
			this.diagnosesByCurrentAdmissionMap.get(diag.admission__c).add(diag);
		}
		System.debug('------------------patientIds=' + patientIds);
		System.debug('------------------currentAdmissionIds=' + currentAdmissionIds);
		System.debug('------------------diagnosesByCurrentAdmissionMap=' + diagnosesByCurrentAdmissionMap);

		//removed 220826 JN this query is not right, but it doesn't matter because the map is not used
		//Group Memberships
		for (Group__c g : [SELECT Id, Name, (SELECT Id, Name, Role__c, Staff_Member__c, Staff_Member__r.Name FROM Staff_Group_Members__r) FROM Group__c WHERE Name IN :groupNames]) {
			groupMembershipsByGroupNameMap.put(g.Name, g);
		}

		//Assigned Clinicians
		for (Assigned_Clinician__c ac : [SELECT Id, Patient_Account__c, User_Name__c, Role__c FROM Assigned_Clinician__c WHERE Patient_Account__c IN :patientIds]) {
			if (!assignedCliniciansByPatientIdMap.containsKey(ac.Patient_Account__c)) {
				assignedCliniciansByPatientIdMap.put(ac.Patient_Account__c, new List<Assigned_Clinician__c>());
			}
			assignedCliniciansByPatientIdMap.get(ac.Patient_Account__c).add(ac);
		}

		//removed JN 220412. Not referenced?
		//Diagnosis
		// Diagnosis__c[] diagnosisList = (Diagnosis__c[])Database.query(
		//         QueryUtils.getQueryAll('Diagnosis__c',
		//         new string[]{'Clinical_Code__r.Name','Clinical_Code__r.Description__c','Patient_Note__r.Account__r.Current_Admission__c'})
		//         + ' WHERE Patient_Note__c in :patientNoteIds and Marked_for_Delete__c!=true'
		// );

		//Interventions
		set<string> allowedDisiplines = SnapshotHelper.getAllowedDisplines(patientIds);
		Intervention__c[] interventionList = (Intervention__c[]) Database.query(QueryUtils.getQueryAll('Intervention__c', new List<String>{ 'Case__r.AccountId', 'Case__r.Account.Current_Case__c' }) + ' WHERE Case__r.AccountId in :patientIds AND Discipline__c IN :allowedDisiplines AND End_Date__c = null');
		this.interventionsByPatientIdMap = new Map<Id, Intervention__c[]>();
		for (Intervention__c inter : interventionList) {
			if (!this.interventionsByPatientIdMap.containsKey(inter.Case__r.AccountId)) {
				this.interventionsByPatientIdMap.put(inter.Case__r.AccountId, new List<Intervention__c>{});
			}
			this.interventionsByPatientIdMap.get(inter.Case__r.AccountId).add(inter);
		}

		Intervention__c[] interventionListAll = (Intervention__c[]) Database.query(QueryUtils.getQueryAll('Intervention__c', new List<String>{ 'Case__r.AccountId', 'Case__r.Account.Current_Case__c' }) + ' WHERE Case__r.AccountId in :patientIds AND End_Date__c = null');
		this.interventionsByPatientIdMapAll = new Map<Id, Intervention__c[]>();
		for (Intervention__c inter : interventionListAll) {
			if (!this.interventionsByPatientIdMapAll.containsKey(inter.Case__r.AccountId)) {
				this.interventionsByPatientIdMapAll.put(inter.Case__r.AccountId, new List<Intervention__c>{});
			}
			this.interventionsByPatientIdMapAll.get(inter.Case__r.AccountId).add(inter);
		}

		//Prescription
		Prescription__c[] prescriptionList = (Prescription__c[]) Database.query(QueryUtils.getQueryAll('Prescription__c', new List<string>{}) + ' WHERE Account__c in :patientIds and Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE AND Medication_Filled_with__c != null AND IRIS_Fill_Datetime__c != null Order By As_Needed__c ASC, Medication_Filled_with__c ASC');
		prescriptionsByPatientIdMap = new Map<Id, Prescription__c[]>();
		for (Prescription__c presp : prescriptionList) {
			if (!prescriptionsByPatientIdMap.containsKey(presp.Account__c)) {
				prescriptionsByPatientIdMap.put(presp.Account__c, new List<Prescription__c>{});
			}
			prescriptionsByPatientIdMap.get(presp.Account__c).add(presp);
		}

		//Allergies
		Allergy__c[] allergyList = (Allergy__c[]) Database.query(QueryUtils.getQueryAll('Allergy__c', new List<string>{}) + ' WHERE Account__c IN :patientIds and Allergy_Status__c IN :PRESCRIPTION_STATUSES_TO_INCLUDE');
		allergiesByPatientIdMap = new Map<Id, Allergy__c[]>();
		for (Allergy__c al : allergyList) {
			if (!allergiesByPatientIdMap.containskey(al.Account__c)) {
				allergiesByPatientIdMap.put(al.Account__c, new List<Allergy__c>{});
			}
			allergiesByPatientIdMap.get(al.Account__c).add(al);
		}

		//Physical Monitors
		Physical_Monitor__c[] monitorList = (Physical_Monitor__c[]) Database.query(QueryUtils.getQueryAll('Physical_Monitor__c', new List<string>{}) + ' WHERE Account__c in :patientIds');
		monitorsByPatientIdMap = new Map<id, Physical_Monitor__c[]>();
		for (Physical_Monitor__c pm : monitorList) {
			if (!monitorsByPatientIdMap.containskey(pm.Account__c)) {
				monitorsByPatientIdMap.put(pm.Account__c, new List<Physical_Monitor__c>{});
			}
			monitorsByPatientIdMap.get(pm.Account__c).add(pm);
		}

		this.patientNoteIds = patientNoteIds;
	}

	public void generateSnapshots() {
		for (Id patientNoteId : this.patientNoteIds) {
			Patient_Note__c patientNote = this.patientNoteMap.get(patientNoteId);
			Account patient = patientMap.get(patientNote.Account__c);
			if (patientNote != null) {
				//Full Snapshot
				//string html = getHtmlHeader(patientNote);
				String html = getHtmlNoteItems(patientNote, null);

				SnapshotHelper.HtmlFooterMapping[] footer = new List<SnapshotHelper.HtmlFooterMapping>{};
				if (patientNote.Completed_Date_Time__c != null) {
					footer.add(new SnapshotHelper.HtmlFooterMapping('Completed By', ParserHelper.ToString(patientNote, 'Completed_By_Professional_Name__c')));
					footer.add(new SnapshotHelper.HtmlFooterMapping('Completed Date/Time', ParserHelper.ToDateTimeFormat(patientNote, 'Completed_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)));
					footer.add(new SnapshotHelper.HtmlFooterMapping('SEPARATOR', null));
				}
				if (patientNote.Finalized_Date_Time__c != null) {
					footer.add(new SnapshotHelper.HtmlFooterMapping('Finalized By', ParserHelper.ToString(patientNote, 'Finalized_By_Professional_Name__c')));
					footer.add(new SnapshotHelper.HtmlFooterMapping('Finalized Date/Time', ParserHelper.ToDateTimeFormat(patientNote, 'Finalized_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)));
				}
				String decoratedFooter = SnapshotHelper.getHtmlFooter(patient, footer);
				html += decoratedFooter;

				String psychiatrist = getTeamMembersByRole(patientNote.Account__c, 'Psychiatrist');
				String psychotherapist = getTeamMembersByRole(patientNote.Account__c, 'Psychotherapist');

				Snapshot__c newSnapshot = new Snapshot__c(Html__c = html, Patient_Name__c = ParserHelper.toString(patient, 'Name'), Patient_Note__c = patientNoteId, Title__c = patientNote.Type__c, Psychiatrist__c = psychiatrist, Psychotherapist__c = psychotherapist, Team_Members__c = null, Finalized_By__c = patientNote.Finalized_By_Professional_Name__c, Finalized_Date_Time__c = patientNote.Finalized_Date_Time__c, Completed_By__c = patientNote.Completed_By_Professional_Name__c, Completed_Date_Time__c = patientNote.Completed_Date_Time__c);

				//Snapshot Subsets added 220412 JN
				List<Note_Item__mdt> noteItemMdts = this.noteItemsByNoteLabel.get(patientNote.Type__c);
				Set<String> subsetNames = getSnapshotSubsets(noteItemMdts);
				for (String subsetName : subsetNames) {
					String subsetHtmlFieldName = subsetName.replace(' ', '_').replace('-', '_') + '_Html__c';
					String renderedSubsetHtml = getHtmlNoteItems(patientNote, subsetName);
					renderedSubsetHtml += decoratedFooter; //same footer as main snapshot

					if (renderedSubsetHtml != '') {
						newSnapshot.put(subsetHtmlFieldName, renderedSubsetHtml);
					}
				}
				this.snapshotsToInsert.add(newSnapshot);
			}
		}
		if (this.snapshotsToInsert.size() > 0) {
			insert this.snapshotsToInsert;
		}
	}

	Set<String> getSnapshotSubsets(List<Note_Item__mdt> noteItemMdts) {
		Set<String> returnSet = new Set<String>();
		for (Note_Item__mdt noteItemMdt : noteItemMdts) {
			if (noteItemMdt.Snapshot_Subsets__c != null) {
				List<String> subsetNames = noteItemMdt.Snapshot_Subsets__c.split(',');
				for (String subsetName : subsetNames) {
					returnSet.add(subsetName.trim());
				}
			}
		}
		return returnSet;
	}

	public static string getFirstNotEmpty(string[] arr) {
		if (arr != null) {
			for (string v : arr) {
				if (string.isNotEmpty(v)) {
					return v;
				}
			}
		}
		return '';
	}

	// public String getHtmlHeader(Patient_Note__c patientNote) {
	//     string html = '';
	//     Account patient = patientMap.get(patientNote.Account__c);
	//     return html;
	// }

	public string getHtmlPatientNoteItemHeaders(Note_Item__mdt noteItem) {
		string html = '';
		if (string.isNotBlank(noteItem?.Title__c)) {
			html += string.format('<h1 class="slds-text-heading_small title" style="font-weight:bold;">{0}</h1>', new List<string>{ noteItem.Title__c });
		}
		if (string.isNotBlank(noteItem?.SubTitle__c)) {
			html += string.format('<div class="slds-text-title">{0}</div>', new List<string>{ noteItem.SubTitle__c });
		}
		return html;
	}

	public string getHtmlNoteItemField(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';

		Schema.DescribeFieldResult dfr = patientNoteFieldMap.get(noteItem.Field_Name__c);
		string value = '';

		if (dfr.getType() == Schema.DisplayType.DATETIME) {
			value = ParserHelper.ToDateTimeFormat(patientNote, noteItem.Field_Name__c, SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE);
		} else if (dfr.getType() == Schema.DisplayType.DATE) {
			value = ParserHelper.ToDateFormat(patientNote, noteItem.Field_Name__c);
		} else if (dfr.getType() == Schema.DisplayType.PICKLIST || dfr.getType() == Schema.DisplayType.MULTIPICKLIST) {
			value = ParserHelper.ToString(patientNote, noteItem.Field_Name__c).replaceAll(';', '; ');
		} else {
			value = ParserHelper.ToString(patientNote, noteItem.Field_Name__c);
		}

		html += '<div class="slds-form-element c">';
		if (dfr.getType() == Schema.DisplayType.BOOLEAN) {
			String yesNoAnswer = 'true'.EqualsIgnoreCase(value) ? 'Yes' : 'No';
			html += string.format('<div class="slds-form-element__control">{0}</div>', new List<string>{ yesNoAnswer });
		} else {
			html += string.format('<div class="slds-form-element__control">{0}</div>', new List<string>{ value });
		}
		html += '</div>';

		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlNoteDiagnosis(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string fieldNoteItemName = getFirstNotEmpty(new List<string>{ noteItem.Title__c, noteItem.SubTitle__c, 'Diagnoses' });
		string html = '';
		string emptyMsg = 'No diagnosis recorded';
		html += '<br>';
		if (patientNote.Account__c != null) {
			Account patient = patientMap.get(patientNote.Account__c);

			map<string, string> params = string.isNotBlank(noteItem.Embedded_Component_Parameters__c) ? (map<string, string>) JSON.deserialize(noteItem.Embedded_Component_Parameters__c, map<string, string>.class) : new Map<string, string>();
			string source = params.get('source');

			string currentAdmissionId = patientNote?.Account__r?.Current_Admission__c;

			Diagnosis__c[] diagnoses = diagnosesByCurrentAdmissionMap.containsKey(currentAdmissionId) ? this.diagnosesByCurrentAdmissionMap.get(currentAdmissionId) : new List<Diagnosis__c>{};

			Diagnosis__c[] principalDiagnoses = new List<Diagnosis__c>{};
			Diagnosis__c[] comorbidDiagnoses = new List<Diagnosis__c>{};

			Diagnosis__c principal = null;
			system.debug('----------NoteDiagnosisCtl diagnoses =' + diagnoses);
			Integer idx = 0;
			for (Diagnosis__c item : diagnoses) {
				if (item.Source__c == source && item.Type__c == 'Principal') {
					//default to the first principal
					if (idx == 0) {
						principal = item;
						idx++;
					}

					if (item.admission__r.Principal_Diagnosis__c == item.Id) {
						principal = item;
					}
				} else if (item.Source__c == source && item.Type__c == 'Comorbid') {
					comorbidDiagnoses.add(item);
				}
			}
			principalDiagnoses.add(principal);
			system.debug('----------NoteDiagnosisCtl principalDiagnoses =' + principalDiagnoses);
			if (principalDiagnoses.size() > 0) {
				html += '<h1 style="font-weight:bolder;font-size:larger;">Principal Diagnosis</h1>';
				html += '<br>';
				html += '<table>';
				html += '<tr style="font-weight:bold">';
				html += '<th style="overflow-wrap: break-word;width:30%">DSM Diagnosis</th>';
				html += '<th style="overflow-wrap: break-word;width:20%">ICD Code</th>';
				html += '<th style="overflow-wrap: break-word;width:50%">Additional Specifiers</th>';
				html += '</tr>';

				for (Diagnosis__c item : principalDiagnoses) {
					html += '<tr>';
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.toString(item, 'Clinical_Code_Description__c') });
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.ToString(item, 'Clinical_Code__r.Name') });
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.toString(item, 'Additional_Specifiers__c') });
					html += '</tr>';
				}

				html += '</table>';
				html += '<br>';
			}

			// ### IN CASE WANTS TO SHOW EMPTY MESSAGE FOR THE DIAGNOSES ###
			// else{
			//     html += '<p>'+emptyMsg+'</p>';
			// }

			if (comorbidDiagnoses.size() > 0) {
				html += '<h1 style="font-weight:bolder;font-size:larger;">Comorbid Diagnosis</h1>';
				html += '<br>';
				html += '<table>';
				html += '<tr style="font-weight:bold">';
				html += '<th style="overflow-wrap: break-word;width:30%">DSM Diagnosis</th>';
				html += '<th style="overflow-wrap: break-word;width:20%">ICD Code</th>';
				html += '<th style="overflow-wrap: break-word;width:50%">Additional Specifiers</th>';
				html += '</tr>';

				for (Diagnosis__c item : comorbidDiagnoses) {
					html += '<tr>';
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.toString(item, 'Clinical_Code_Description__c') });
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.ToString(item, 'Clinical_Code__r.Name') });
					html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new List<string>{ ParserHelper.toString(item, 'Additional_Specifiers__c') });
					html += '</tr>';
				}

				html += '</table>';
			}

			// ### IN CASE WANTS TO SHOW EMPTY MESSAGE FOR THE DIAGNOSES ###
			// else{
			//     html += '<p>'+emptyMsg+'</p>';
			// }

			if (comorbidDiagnoses.size() <= 0 && principalDiagnoses.size() <= 0) {
				html += '<p>' + emptyMsg + '</p>';
			}

			/*
            if(diagnoses.size() > 0){
                html += '<h1 style="font-weight:bolder;font-size:larger;">Principal Diagnosis</h1>';
                html += '<br>';
                html += '<table>';
                html += '<tr style="font-weight:bold">';
                html += '<th style="overflow-wrap: break-word;width:30%">DSM Description</th>';
                html += '<th style="overflow-wrap: break-word;width:20%">ICD Code</th>';
                html += '<th style="overflow-wrap: break-word;width:50%">Additional Specifiers</th>';
                html += '</tr>';
                if( diagnoses != null ){
                    for(Diagnosis__c item : diagnoses){
                        if( item.Source__c == source && item.Type__c=='Principal'){
                            html += '<tr>';
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.toString(item,'Clinical_Code_Description__c')});
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.ToString(item, 'Clinical_Code__r.Name')});
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.toString(item,'Additional_Specifiers__c')});
                            html += '</tr>';
                        }
                    }
                }
                html += '</table>';
                html += '<br>';
                html += '<h1 style="font-weight:bolder;font-size:larger;">Comorbid Diagnosis</h1>';
                html += '<br>';
                html += '<table>';
                html += '<tr style="font-weight:bold">';
                html += '<th style="overflow-wrap: break-word;width:30%">DSM Description</th>';
                html += '<th style="overflow-wrap: break-word;width:20%">ICD Code</th>';
                html += '<th style="overflow-wrap: break-word;width:50%">Additional Specifiers</th>';
                html += '</tr>';
                if( diagnoses != null ){
                    for(Diagnosis__c item : diagnoses){
                        if( item.Source__c == source && item.Type__c=='Comorbid'){
                            html += '<tr>';
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.toString(item,'Clinical_Code_Description__c')});
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.ToString(item, 'Clinical_Code__r.Name')});
                            html += string.format('<td style="overflow-wrap: break-word;">{0}</td>', new string[]{ParserHelper.toString(item,'Additional_Specifiers__c')});
                            html += '</tr>';
                        }
                    }
                }
                html += '</table>';
            }
            else{
                html += '<p>'+emptyMsg+'</p>';
            }

            */
		}
		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlNoteItemAllergies(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';
		string emptyMsg = 'No allergies recorded';
		if (patientNote.Account__c != null) {
			Allergy__c[] allergies = this.allergiesByPatientIdMap.get(patientNote.Account__c);

			if (allergies != null && allergies.size() > 0) {
				html += '<table>';
				html += '<tr>';
				html += '<th>Name</th>';
				html += '<th>Type</th>';
				html += '<th>Reaction</th>';
				html += '<th>Severity</th>';
				html += '</tr>';
				for (Allergy__c item : allergies) {
					html += '<tr>';
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Name__c') });
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Adverse_Event_Code_Text__c') });
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Reaction_Text__c') });
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Severity_Code_Text__c') });
					html += '</tr>';
				}
				html += '</table>';
			} else {
				html += '<p>' + emptyMsg + '</p>';
			}
		}
		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlPhysicalMonitors(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';
		string emptyMsg = 'No physical monitors recorded';
		if (patientNote.Account__c != null) {
			Physical_Monitor__c[] monitors = this.monitorsByPatientIdMap.get(patientNote.Account__c);

			if (monitors != null && monitors.size() > 0) {
				html += '<table>';
				html += '<tr>';
				html += '<th>Performed Date/Time</th>';
				html += '<th>Status</th>';
				html += '<th>Finalized By</th>';
				html += '</tr>';

				for (Physical_Monitor__c item : monitors) {
					html += '<tr>';
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Date_Time__c') });
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Status__c') });
					html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Finalized_By_Name__c') });
					html += '</tr>';
				}
				html += '</table>';
			} else {
				html += '<p>' + emptyMsg + '</p>';
			}
		}
		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlNoteItemInterventions(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		String html = '';
		string emptyMsg = 'No interventions recorded';
		System.debug('getHtmlNoteItemInterventions - noteItem.Embedded_Component_Parameters__c : ' + noteItem.Embedded_Component_Parameters__c);

		String discipline;
		if (null != noteItem.Embedded_Component_Parameters__c) {
			JSONParser parser = JSON.createParser(noteItem.Embedded_Component_Parameters__c);
			while (parser.nextToken() != null) {
				if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'discipline')) {
					parser.nextToken();
					discipline = parser.getText();
				}
			}
		}

		if (patientNote.Account__c != null) {
			Intervention__c[] interventions;
			if (null != discipline) {
				Intervention__c[] tempInterventions = this.interventionsByPatientIdMapAll.get(patientNote.Account__c);
				interventions = new List<Intervention__c>();
				if (null != tempInterventions) {
					for (Intervention__c intervention : tempInterventions) {
						if (intervention.Discipline__c == discipline) {
							interventions.add(intervention);
						}
					}
				}
			} else {
				interventions = this.interventionsByPatientIdMap.get(patientNote.Account__c);
			}

			if (interventions != null && interventions.size() > 0) {
				html += '<table>';
				html += '<tr>';
				html += '<th class="slds-p-left_small">Discipline</th>';
				html += '<th class="slds-p-left_small">Intervention</th>';
				html += '<th class="slds-p-left_small">Patient-specific Details</th>';
				html += '<th class="slds-p-left_small">Start Date</th>';
				html += '<th class="slds-p-left_small">End Date</th>';
				html += '</tr>';

				for (Intervention__c inter : interventions) {
					html += '<tr>';
					html += string.format('<td class="slds-p-left_small">{0}</td>', new List<string>{ ParserHelper.toString(inter, 'Discipline__c') });
					html += string.format('<td class="slds-p-left_small">{0}</td>', new List<string>{ ParserHelper.toString(inter, 'Description__c') });
					html += string.format('<td class="slds-p-left_small">{0}</td>', new List<string>{ ParserHelper.toString(inter, 'Patient_specific_Details__c') });
					html += string.format('<td class="slds-p-left_small">{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(inter, 'Start_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
					html += string.format('<td class="slds-p-left_small">{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(inter, 'End_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
					html += '</tr>';
				}

				html += '</table>';
			} else {
				html += '<p>' + emptyMsg + '</p>';
			}
		}
		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public Prescription__c[] getMatchedMonthlyPrescriptions(Patient_Note__c patientNote) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();
		if (patientNote.Contact_Date__c != null && prescriptions != null && prescriptions.size() > 0) {
			Integer numberOfDays = Date.daysInMonth(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month());
			Date firstDayOfMonth = Date.newInstance(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month(), 1);
			Date lastDayOfMonth = Date.newInstance(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month(), numberOfDays);
			for (Prescription__c prep : prescriptions) {
				if (prep.Start_Date__c != null) {
					Date startDate = prep.Start_Date__c;
					Date endDate = prep.End_Date__c;
					if (((startDate <= lastDayOfMonth) && (endDate == null)) || ((startDate <= lastDayOfMonth) && (endDate >= firstDayOfMonth))) {
						matchedPrescriptions.add(prep);
					}
				}
			}
		}
		return matchedPrescriptions;
	}
	public Prescription__c[] getMatchedThisMonthPrescriptions(Patient_Note__c patientNote) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();
		if (patientNote.Contact_Date__c != null && prescriptions != null && prescriptions.size() > 0) {
			Integer numberOfDays = Date.daysInMonth(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month());
			Date firstDayOfMonth = Date.newInstance(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month(), 1);
			Date lastDayOfMonth = Date.newInstance(patientNote.Contact_Date__c.year(), patientNote.Contact_Date__c.month(), numberOfDays);
			for (Prescription__c prep : prescriptions) {
				if (prep.Start_Date__c != null) {
					Date startDate = prep.Start_Date__c;
					Date endDate = prep.End_Date__c;
					if (((startDate <= lastDayOfMonth) && (startDate >= firstDayOfMonth)) || ((endDate <= lastDayOfMonth) && (endDate >= firstDayOfMonth))) {
						matchedPrescriptions.add(prep);
					}
				}
			}
		}
		return matchedPrescriptions;
	}
	public Prescription__c[] getMatchedNoteDatePrescriptions(Patient_Note__c patientNote, Note_Item__mdt noteItem) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		System.debug('getMatchedNoteDatePrescriptions - prescriptions : ' + prescriptions);
		System.debug('getMatchedNoteDatePrescriptions - patientNote.Contact_Date__c : ' + patientNote.Contact_Date__c);
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();

		map<string, string> params = string.isNotBlank(noteItem.Embedded_Component_Parameters__c) ? (map<string, string>) JSON.deserialize(noteItem.Embedded_Component_Parameters__c, map<string, string>.class) : new Map<string, string>();
		String forMSA = params.get('forMSA');
		String forAway = params.get('forAway');
		Boolean forMSAOrAway = (null != forMSA && 'true'.equalsIgnoreCase(forMSA)) || (null != forAway && 'true'.equalsIgnoreCase(forAway));
		if (patientNote.Contact_Date__c != null && prescriptions != null && prescriptions.size() > 0) {
			for (Prescription__c prep : prescriptions) {
				if (prep.Start_Date__c != null) {
					Date startDate = prep.Start_Date__c;
					Date endDate = prep.End_Date__c;
					if (((startDate <= patientNote.Contact_Date__c) && (endDate == null)) || ((startDate <= patientNote.Contact_Date__c) && (endDate == patientNote.Contact_Date__c))) {
						if (forMSAOrAway) {
							if ('Active' == prep.Status__c)
								matchedPrescriptions.add(prep);
						} else {
							matchedPrescriptions.add(prep);
						}
					}
				}
			}
		}
		return matchedPrescriptions;
	}
	public Prescription__c[] getMatchedAdmitDatePrescriptions(Patient_Note__c patientNote) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();
		date admitDate = patientNote?.Admission__r?.Admit_Date__c;
		if (prescriptions != null) {
			for (Prescription__c prep : prescriptions) {
				if (prep.Start_Date__c != null) {
					Date startDate = prep.Start_Date__c;
					if (startDate == admitDate) {
						matchedPrescriptions.add(prep);
					}
				}
			}
		}
		return matchedPrescriptions;
	}
	public Prescription__c[] getMatchedFirstOfMonthPrescriptions(Patient_Note__c patientNote) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();
		if (patientNote.Contact_Date__c != null && prescriptions != null && prescriptions.size() > 0) {
			Date firstDayOfMonth = patientNote.Contact_Date__c.toStartOfMonth();
			for (Prescription__c prep : prescriptions) {
				if (prep.Start_Date__c != null) {
					Date startDate = prep.Start_Date__c;
					Date endDate = prep.End_Date__c;
					if (((startDate <= firstDayOfMonth) && (endDate == null)) || ((startDate <= firstDayOfMonth) && (endDate >= firstDayOfMonth))) {
						matchedPrescriptions.add(prep);
					}
				}
			}
		}
		return matchedPrescriptions;
	}
	public Prescription__c[] getMatchedPrescriptions(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		Prescription__c[] prescriptions = this.prescriptionsByPatientIdMap.get(patientNote.Account__c);
		map<string, string> params = string.isNotBlank(noteItem.Embedded_Component_Parameters__c) ? (map<string, string>) JSON.deserialize(noteItem.Embedded_Component_Parameters__c, map<string, string>.class) : new Map<string, string>();
		string medicationQuery = params.get('medicationQuery');
		List<Prescription__c> matchedPrescriptions = new List<Prescription__c>();
		switch on medicationQuery {
			when 'Monthly' {
				matchedPrescriptions = getMatchedMonthlyPrescriptions(patientNote);
			}
			when 'This Month' {
				matchedPrescriptions = getMatchedThisMonthPrescriptions(patientNote);
			}
			when 'Note Date' {
				matchedPrescriptions = getMatchedNoteDatePrescriptions(patientNote, noteItem);
			}
			when 'Admit Date' {
				matchedPrescriptions = getMatchedAdmitDatePrescriptions(patientNote);
			}
			when 'First of Month' {
				matchedPrescriptions = getMatchedFirstOfMonthPrescriptions(patientNote);
			}
		}
		return matchedPrescriptions;
	}

	public String getMedRecordDocumentTypeName(Note_Item__mdt noteItem) {
		Note_Item__mdt note = [SELECT Note_Definition__r.Med_Records_Document_Type__c FROM Note_Item__mdt WHERE id = :noteItem.Id];
		system.debug(note);
		system.debug(note.Note_Definition__r.Med_Records_Document_Type__c);
		Med_Records_Document_Type__mdt name = [SELECT MasterLabel FROM Med_Records_Document_Type__mdt WHERE Id = :note.Note_Definition__r.Med_Records_Document_Type__c];
		system.debug('Master Label == ' + name.MasterLabel);
		return name.MasterLabel;
	}

	public string getHtmlNoteItemPrescriptions(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		system.debug('noteItem');
		system.debug(noteItem);
		system.debug('getHtmlNoteItemPrescriptions - patientNote :');
		system.debug(patientNote);

		string masterLabel = this.getMedRecordDocumentTypeName(noteItem);

		string html = '';
		string emptyMsg = 'No prescriptions recorded';
		if (patientNote.Account__c != null) {
			Prescription__c[] prescriptions = this.getMatchedPrescriptions(noteItem, patientNote);
			system.debug('getHtmlNoteItemPrescriptions -- prescriptions size=' + prescriptions.size());
			// Check to see if we need to get the dispensing history and include adherence in our snapshot.
			map<string, string> params = string.isNotBlank(noteItem.Embedded_Component_Parameters__c) ? (map<string, string>) JSON.deserialize(noteItem.Embedded_Component_Parameters__c, map<string, string>.class) : new Map<string, string>();
			String includeAdherence = params.get('includeAdherence');
			String suppressStatus = params.get('suppressStatus');
			String forAway = params.get('forAway');
			String forMSA = params.get('forMSA');
			system.debug('getHtmlNoteItemPrescriptions -- includeAdherence=' + includeAdherence);
			system.debug('getHtmlNoteItemPrescriptions -- forAway=' + forAway);
			system.debug('getHtmlNoteItemPrescriptions -- forMSA=' + forMSA);
			Map<Id, List<Medication_Administration_Line__c>> dispensingHistoryForPrescriptions = null;
			Date contactDate = patientNote.Contact_Date__c;
			if ('true'.equalsIgnoreCase(includeAdherence)) {
				Id[] prescriptionIds = new List<Id>{};
				for (Prescription__c p : prescriptions) {
					prescriptionIds.add(p.Id);
				}

				Date firstDayOfNoteMonth = Date.newInstance(contactDate.year(), contactDate.month(), 1);
				Date lastDayOfNoteMonth = Date.newInstance(contactDate.year(), contactDate.month(), Date.daysInMonth(contactDate.year(), contactDate.month()));

				// Date startDate = Date.today().toStartOfMonth();
				// Date endDate = Date.today();
				dispensingHistoryForPrescriptions = DispensingService.getDispensingHistoryForPrescriptions(prescriptionIds, firstDayOfNoteMonth, lastDayOfNoteMonth);
			}

			// Patient_Note__c tempPN = [SELECT Id, Away_First_Date__c, Away_Last_Date__c, Away_Number_of_Days__c, Final_Discharge_Med_Order__c, Days_To_Package__c FROM Patient_Note__c WHERE ID = :patientNote.Id];
			// System.debug('tempPN : ' + tempPN);

			html += '<table>';
			// html += '<tr>';
			// html += '<th>Drug Name</th>';
			// html += '<th>Drug Format</th>';
			// html += '<th>Start Date</th>';
			// html += '<th>Indication Text</th>';
			// html += '<th>Status</th>';
			// html += '</tr>';
			if (prescriptions != null && prescriptions.size() > 0) {
				//Getting patientNote.type__c value from metadata for comparison so that the Prescription table can be rendered accordingly

				// if(masterLabel == 'Away_Discharge_Med_Order' || masterLabel == 'Away Medication Order'){
				system.debug('getHtmlNoteItemPrescriptions -- forAway=' + forAway);
				system.debug('getHtmlNoteItemPrescriptions -- forMSA=' + forMSA);
				system.debug('getHtmlNoteItemPrescriptions -- includeAdherence=' + includeAdherence);
				system.debug('getHtmlNoteItemPrescriptions -- patientNote.Away_First_Date__c=' + patientNote.Away_First_Date__c);
				system.debug('getHtmlNoteItemPrescriptions -- patientNote.Away_Last_Date__c=' + patientNote.Away_Last_Date__c);
				system.debug('getHtmlNoteItemPrescriptions -- patientNote.Away_Number_of_Days__c=' + patientNote.Away_Number_of_Days__c);
				if ('true'.equalsIgnoreCase(forAway)) {
					if (patientNote.Final_Discharge_Med_Order__c) {
						html += '<tr><td>Final Discharge Med Order</td><td></td></tr>';
						html += '<tr><td style="width:20%">Discharge Date</td><td>' + ParserHelper.ToDateTimeFormat(patientNote, 'Away_First_Date__c', SnapshotHelper.DATEFORMAT, 'UTC') + '</td></tr>';
						html += '<tr><td>Days to Package</td><td>' + ParserHelper.toString(patientNote, 'Days_to_Package__c') + '</td></tr>';
					} else {
						html += '<tr><td style="width:20%">First Day Away</td><td>' + ParserHelper.ToDateTimeFormat(patientNote, 'Away_First_Date__c', SnapshotHelper.DATEFORMAT, 'UTC') + '</td></tr>';
						html += '<tr><td>Last Day Away</td><td>' + ParserHelper.ToDateTimeFormat(patientNote, 'Away_Last_Date__c', SnapshotHelper.DATEFORMAT, 'UTC') + '</td></tr>';
						html += '<tr><td>Days Away</td><td>' + ParserHelper.toString(patientNote, 'Away_Number_of_Days__c') + '</td></tr>';
					}
					html += '</table><table>';
					html += '<tr>';
					html += '<th>Medication</th>';
					html += '<th>Medication Format</th>';
					html += '<th>As Needed</th>';
					html += '<th>Package Instruction</th>';
					html += '<th>Quantity To Package</th>';
					html += '<th>End Date</th>';
					html += '</tr>';
					for (Prescription__c item : prescriptions) {
						html += '<tr>';
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Filled_with__c') });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Format__c') });
						html += string.format('<td>{0}</td>', new List<string>{ item.As_Needed__c ? '&#10003;' : '' });
						String awayPckInstruction = ParserHelper.toString(item, 'away_package_Instruction__c');
						html += string.format('<td>{0}</td>', new List<string>{ null == awayPckInstruction || awayPckInstruction.equals('') ? 'Not Specified' : awayPckInstruction });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Quantity_to_Package_Temp__c') });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(item, 'End_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
						html += '</tr>';
					}
				} else if ('true'.equalsIgnoreCase(forMSA)) {
					//else if( masterLabel == 'Medication Self-Administration Order' || masterLabel == 'Medication Self-Administration (MSA) Order') {
					html += '<tr>';
					html += '<th>Medication</th>';
					html += '<th>Medication Format</th>';
					html += '<th>As Needed</th>';
					html += '<th>Location</th>';
					// html += '<th>On Going Quantity</th>';
					html += '<th>End Date</th>';
					html += '</tr>';
					for (Prescription__c item : prescriptions) {
						html += '<tr>';
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Filled_with__c') });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Format__c') });
						html += string.format('<td>{0}</td>', new List<string>{ item.As_Needed__c ? '&#10003;' : '' });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Location__c') });
						// html += string.format('<td>{0}</td>', new string[]{ParserHelper.toString(item,'On_Going_Quantity__c')});
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(item, 'End_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
						html += '</tr>';
					}
				} else {
					system.debug('getHtmlNoteItemPrescriptions -- includeAdherence=' + includeAdherence);
					html += '<tr>';
					html += '<th>Medication</th>'; // replace with Medication
					html += '<th>Medication Format</th>'; // replace with Medication Format
					html += '<th>As Needed</th>';
					html += '<th>Start Date</th>';
					html += '<th>End Date</th>';
					html += '<th>Prescriber</th>';
					// html += '<th>Indication Text</th>';

					if (null == suppressStatus || !'true'.equalsIgnoreCase(suppressStatus)) {
						html += '<th>Status</th>';
					}

					if ('true'.equalsIgnoreCase(includeAdherence)) {
						html += '<th>Adherence</th>';
					}

					html += '</tr>';
					system.debug('getHtmlNoteItemPrescriptions -- prescriptions size=' + prescriptions.size());
					for (Prescription__c item : prescriptions) {
						html += '<tr>';
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Filled_with__c') }); // Changes here too
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Medication_Format__c') }); // Changes here too
						html += string.format('<td>{0}</td>', new List<string>{ item.As_Needed__c ? '&#10003;' : '' });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(item, 'Start_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.ToDateTimeFormat(item, 'End_Date__c', SnapshotHelper.DATEFORMAT, SnapshotHelper.TIMEZONE) });
						// html += string.format('<td>{0}</td>', new string[]{ParserHelper.toString(item,'Indication_Text__c')});
						html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Prescriber_Professional_Name__c') });

						if (null == suppressStatus || !'true'.equalsIgnoreCase(suppressStatus)) {
							html += string.format('<td>{0}</td>', new List<string>{ ParserHelper.toString(item, 'Status__c') });
						}

						system.debug('getHtmlNoteItemPrescriptions -- includeAdherence=' + includeAdherence);
						if ('true'.equalsIgnoreCase(includeAdherence)) {
							for (Id prescriptionId : dispensingHistoryForPrescriptions.keySet()) {
								String adherence = '';
								if (prescriptionId == item.Id) {
									Medication_Administration_Line__c[] marLines = dispensingHistoryForPrescriptions.get(prescriptionId);
									Integer marLinesCount = marLines.size();
									if (null != item.Daily_Dosage_Quantity__c && !item.As_Needed__c) {
										Integer daysSoFarInNoteMonth = contactDate.month() < Date.today().month() ? Date.daysInMonth(contactDate.year(), contactDate.month()) : Date.today().day();
										Integer daysInNoteMonthPatientShouldHaveTakenPrep = daysSoFarInNoteMonth;
										Date startDate = item.Start_Date__c;
										Date endDate = item.End_Date__c;
										System.debug('startDate : ' + startDate);
										if (null != startDate) {
											daysInNoteMonthPatientShouldHaveTakenPrep = startDate < Date.newInstance(contactDate.year(), contactDate.month(), 1) ? daysSoFarInNoteMonth : daysSoFarInNoteMonth - startDate.day();
										}
										if (null != endDate) {
											daysInNoteMonthPatientShouldHaveTakenPrep = endDate < Date.newInstance(contactDate.year(), contactDate.month(), Date.daysInMonth(contactDate.year(), contactDate.month())) ? null == startDate || startDate < Date.newInstance(contactDate.year(), contactDate.month(), 1) ? endDate.day() + 1 : endDate.day() - startDate.day() + 1 : daysInNoteMonthPatientShouldHaveTakenPrep;
										}

										if (null != endDate) {
											endDate = endDate.addDays(1); // Increment to the next day so we inlude any entries on the end date.
										}

										if (null != startDate) {
											marLinesCount = 0;
											for (Medication_Administration_Line__c marLine : marLines) {
												if (startDate <= marLine.CreatedDate) {
													if (null != endDate) {
														if (marLine.CreatedDate <= endDate) {
															marLinesCount++;
														}
													} else {
														marLinesCount++;
													}
												}
											}
										}

										if (null == startDate && null != endDate) {
											marLinesCount = 0;
											for (Medication_Administration_Line__c marLine : marLines) {
												if (marLine.CreatedDate <= endDate) {
													marLinesCount++;
												}
											}
										}

										// Integer daysSoFarInMonth = Date.today().day();
										Decimal expectedDailyQuantity = item.Daily_Dosage_Quantity__c;
										Decimal totalExpectedDispensingSoFar = expectedDailyQuantity * daysInNoteMonthPatientShouldHaveTakenPrep;
										Decimal adherencePercentage = marLinesCount / totalExpectedDispensingSoFar * 100;
										Decimal adherencePercentageRounded = adherencePercentage.setScale(2, RoundingMode.HALF_UP);
										html += '<td>CD: ' + adherencePercentageRounded + '%</td>';
									} else {
										if (1 == marLinesCount) {
											html += '<td>CD: 1 Dose</td>';
										} else if (1 < marLinesCount) {
											html += '<td>CD: ' + marLinesCount + ' Doses</td>';
										}
									}
								}
							}
						}

						html += '</tr>';
					}
				}
			} else {
				html += '<p>' + emptyMsg + '</p>';
			}
			html += '</table>';
			html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
			System.Debug('Just formatted prescriptions for Snapshot.');
		}
		return html;
	}

	public string getHtmlNoteInitialConsultationRecommendations(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		Schema.DescribeFieldResult dfrRecommendations = patientNoteFieldMap.get('Recommendations__c');
		Schema.DescribeFieldResult dfrComments = patientNoteFieldMap.get('Comments__c');
		string html = '<br>';
		html += '<table>';
		html += '<tr>';
		html += string.format(SnapshotHelper.FIELD_TEMPLATE, new List<object>{ dfrRecommendations.getLabel(), ParserHelper.ToString(patientNote, 'Recommendations__c') });
		html += '</tr>';
		html += '<tr>';
		html += string.format(SnapshotHelper.FIELD_TEMPLATE, new List<object>{ dfrComments.getLabel(), ParserHelper.ToString(patientNote, 'Comments__c') });
		html += '</tr>';
		html += '</table>';
		html += '<br><hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlNoteAttendance(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';

		html += '<div class="slds-text-heading_small title" style="font-weight:bold;">Attendance</div>';
		html += ParserHelper.ToString(patientNote, 'NoteAttendanceHtml__c');

		html += '<div class="slds-text-heading_small title" style="font-weight:bold;">Comments</div>';
		html += ParserHelper.ToString(patientNote, 'Attendance_Comments__c');

		html += '<br>';
		return html;
	}

	public string getHtmlNoteAdmittedPrograms(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';
		try {
			String subsetHtml = (String) patientNote.get('SOH_History_Program__c');
			if (String.isNotBlank(subsetHtml)) {
				html += '<div class="slds-text-heading_small title" style="font-weight:bold;">' + noteItem.Label + '</div>';
				html += subsetHtml;
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, e.getStackTraceString());
		}

		html += '<br>';
		return html;
	}
	public string getHtmlNoteSOH(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';
		try {
			String parameterJSON = noteItem.Embedded_Component_Parameters__c;
			Map<String, Object> parameters = (Map<String, Object>) JSON.deserializeUntyped(parameterJSON);
			String subsetType = String.valueOf(parameters.get('subsetType'));
			String subsetHtml = String.valueOf(patientNote.get(String.valueOf(parameters.get('subsetField'))));
			if (String.isNotBlank(subsetHtml)) {
				html += '<div class="slds-text-heading_small title" style="font-weight:bold;">' + noteItem.Title__c + '</div>';
				html += subsetHtml;
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, e.getStackTraceString());
		}

		html += '<br>';
		return html;
	}

	public string getHtmlNoteUserLookup(Note_Item__mdt noteItem, Patient_Note__c patientNote) {
		string html = '';

		string value = ParserHelper.ToString(patientNote, noteItem.Field_Name__c);

		html += '<div class="slds-form-element">';
		html += string.format('<div class="slds-form-element__control">{0}</div>', new List<string>{ value });
		html += '</div>';

		html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';

		return html;
	}

	public string getHtmlNoteItemSectionHeader(Note_Item__mdt noteItem, string className) {
		string html = '';
		html += '<br/>';
		html += string.format('<div class="{1}" style="{2}">{0}</div>', new List<string>{ ParserHelper.toString(noteItem, 'Title__c'), className, 'font-weight: bold' });
		html += getHtmlNoteItemsSubTitles(noteItem, 'Subtitle__c');
		html += getHtmlNoteItemsSubTitles(noteItem, 'Helptext__c');
		// removed 220826 JN ARC-2199
		// html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public string getHtmlNoteItemSectionHeader1(Note_Item__mdt noteItem) {
		return getHtmlNoteItemSectionHeader(noteItem, 'slds-text-heading_large');
	}

	public string getHtmlNoteItemSectionHeader2(Note_Item__mdt noteItem) {
		return getHtmlNoteItemSectionHeader(noteItem, 'slds-text-heading_medium');
	}

	public string getHtmlNoteItemSectionHeader3(Note_Item__mdt noteItem) {
		return getHtmlNoteItemSectionHeader(noteItem, 'slds-text-heading_small');
	}

	public string getHtmlNoteItemsSubTitles(Note_Item__mdt noteItem, string fieldPath) {
		string html = '';
		string subtitle = ParserHelper.ToString(noteItem, fieldPath);
		if (string.isNotBlank(subTitle)) {
			html += string.format('<div class="slds-text-title">{0}</div>', new List<string>{ subtitle });
		}
		return html;
	}

	//public String getHtmlNoteItems(Patient_Note__c patientNote) {
	public String getHtmlNoteItems(Patient_Note__c patientNote, String subsetName) {
		string html = '';
		Note_Item__mdt[] noteItems = this.noteItemsByNoteLabel.get(patientNote.Type__c);

		if (noteItems != null) {
			for (Note_Item__mdt noteItem : noteItems) {
				//only include if subsetName is null or specified for this noteitem
				if (subsetName != null && noteItem.Snapshot_Subsets__c != null && !noteItem.Snapshot_Subsets__c.contains(subsetName))
					continue;

				if (
					subsetName == null || (noteItem.Snapshot_Subsets__c != null && noteItem.Snapshot_Subsets__c.contains(subsetName)) //Full snapshot //subset snapshot
				) {
					//TODO
					// System.debug('getHtmlNoteItems subsetName ' + subsetName + ' noteItem.Title__c ' + noteItem.Title__c + ' noteItem.Snapshot_Subsets__c ' + noteItem.Snapshot_Subsets__c);
					// System.debug('subsetName != null? ' + (subsetName != null));
					// System.debug('noteItem.Snapshot_Subsets__c != null? ' + (noteItem.Snapshot_Subsets__c != null));
					// if (noteItem.Snapshot_Subsets__c != null && subsetName != null) {
					//     System.debug('noteItem.Snapshot_Subsets__c.contains(subsetName)? ' + (noteItem.Snapshot_Subsets__c.contains(subsetName)));
					// } else {
					//     System.debug('noteItem.Snapshot_Subsets__c is null or subsetName is null');
					// }

					// Only include if conditional Note Item display says yes
					if (NoteDefinition.calculateHideNoteItem(noteItem.Hide_Conditions__c, patientNote))
						continue;
					system.debug('_____Note_Order____: ' + noteItem.Order__c);

					if (noteItem.Embedded_Component_Name__c == 'c:NoteUserLookup') {
						//NoteUserLookup
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteUserLookup(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteDiagnosis') {
						//Note Diagnosis
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteDiagnosis(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:AllergiesNoteItem') {
						//Allergies
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteItemAllergies(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NotePhysicalMonitorRelatedList') {
						//PhysicalMonitor
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlPhysicalMonitors(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:PrescriptionsNoteItem') {
						//Prescriptions
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteItemPrescriptions(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteInterventions') {
						//Interventions
						html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteItemInterventions(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteInitialConsultationRecommendations') {
						//NoteInitialConsultationRecommendations
						html += getHtmlNoteInitialConsultationRecommendations(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteAttendance') {
						//NoteAttendance
						// html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteAttendance(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteAdmittedPrograms') {
						//NoteAttendance
						// html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteAdmittedPrograms(noteItem, patientNote);
					} else if (noteItem.Embedded_Component_Name__c == 'c:NoteItemSOH') {
						//NoteAttendance
						// html += getHtmlPatientNoteItemHeaders(noteItem);
						html += getHtmlNoteSOH(noteItem, patientNote);
					} else if (noteItem.Type__c == 'Field' && string.isNotBlank(noteItem.Field_Name__c.trim()) && string.isNotBlank(ParserHelper.ToString(patientNote, noteItem.Field_Name__c))) {
						//Fields
						Schema.DescribeFieldResult dfr = patientNoteFieldMap.get(noteItem.Field_Name__c);
						if (dfr.getType() == Schema.DisplayType.BOOLEAN) {
							if (boolean.valueOf(patientNote.get(noteItem.Field_Name__c))) {
								html += getHtmlPatientNoteItemHeaders(noteItem);
							}
						} else {
							html += getHtmlPatientNoteItemHeaders(noteItem);
							html += getHtmlNoteItemField(noteItem, patientNote);
						}
					} else if (NoteItem.Type__c == 'Section Header 1') {
						//Section Header 1
						html += getHtmlNoteItemSectionHeader1(noteItem);
					} else if (NoteItem.Type__c == 'Section Header 2') {
						//Section Header 2
						html += getHtmlNoteItemSectionHeader2(noteItem);
					} else if (NoteItem.Type__c == 'Section Header 3') {
						html += getHtmlNoteItemSectionHeader3(noteItem);
					}
				}
			}
			html += '<br>';
		}
		return html;
	}

	public static void process() {
		set<id> noteIdsToProcess = new Set<id>();
		map<id, SObject> oldMap = Trigger.oldMap != null ? Trigger.oldMap : new Map<Id, SObject>();
		for (Patient_Note__c pn : (Patient_Note__c[]) Trigger.new) {
			Patient_Note__c oldPn = (Patient_Note__c) (oldMap.containsKey(pn.Id) ? oldMap.get(pn.Id) : null);
			if ((pn.Status__c == 'Finalized' || pn.Status__c == 'Completed') && (oldPn == null || pn.Status__c != oldPn.Status__c)) {
				noteIdsToProcess.add(pn.Id);
			}
		}
		if (noteIdsToProcess.size() > 0) {
			new PatientNoteSnapshot(noteIdsToProcess).generateSnapshots();
		}
	}
}