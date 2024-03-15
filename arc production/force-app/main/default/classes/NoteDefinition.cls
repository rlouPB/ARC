public class NoteDefinition {
	@AuraEnabled
	public Note theNote;

	private Id patientNoteId;

	private Id noteOwnerId; //used if Note needs to be assigned to a Queue

	private Boolean lockForUpdate { get; set; }

	public static DescribeSObjectResult patientNoteDescribeResult = getPatientNoteDescribeResult();

	public Map<String, Map<String, String>> additionalSourcesMap = new Map<String, Map<String, String>>();

	// public NoteDefinition(Id patientNoteId)
	// {
	//     this(patientNoteId, false);
	// }

	public NoteDefinition(Id patientNoteId, Boolean lockForUpdate) {
		this.patientNoteId = patientNoteId;
		this.lockForUpdate = lockForUpdate;
		String type = getPatientNoteType(patientNoteId);
		theNote = NoteDefinition.getNoteDefinition(type);
		buildAdditionalSourcesMap();
		queryPatientNote(patientNoteId);
	}

	private void buildAdditionalSourcesMap() {
		List<Patient_Note__c> patientNoteList = [SELECT Admission__c FROM Patient_Note__c WHERE Id = :patientNoteId];

		if (!patientNoteList.isEmpty()) {
			//Id admissionID = patientNoteList[0].Account__r.Current_Admission__c;
			Id admissionID = patientNoteList[0].Admission__c;
			Map<String, String> roleToNameMap = new Map<String, String>();
			for (Assigned_Clinician__c assignedClinician : [SELECT Role__c, User__c, User__r.Name, User__r.Professional_Name__c FROM Assigned_Clinician__c WHERE Admission__c = :admissionID AND Start_Date__c <= :Date.today() AND (End_Date__c = NULL OR End_Date__c > :Date.today())]) {
				roleToNameMap.put(assignedClinician.Role__c, assignedClinician.User__r.Professional_Name__c);
			}
		}
	}

	String getPatientNoteType(Id patientNoteId) {
		String type = '';
		Patient_Note__c patientNote = [SELECT Type__c FROM Patient_Note__c WHERE Id = :patientNoteId];
		type = patientNote.Type__c;
		return type;
	}

	void queryPatientNote(Id patientNoteId) {
		Set<String> fields = new Set<String>();
		String noteDefinitionParametersJSON = null;
		if (theNote.NoteDefinition.Parameters__c != null) {
			noteDefinitionParametersJSON = theNote.NoteDefinition.Parameters__c;
		}

		if (String.isNotBlank(noteDefinitionParametersJSON)) {
			NoteDefinitionParameters noteDefinitionParameters = (NoteDefinitionParameters) JSON.deserialize(noteDefinitionParametersJSON, NoteDefinitionParameters.class);
			if (noteDefinitionParameters.header != null && noteDefinitionParameters.header.fieldNames != null && !noteDefinitionParameters.header.fieldNames.isEmpty()) {
				for (FieldName fieldName : noteDefinitionParameters.header.fieldNames) {
					if (fieldName.source != null && fieldName.key != null) {
						if (additionalSourcesMap.containsKey(fieldName.source)) {
							Map<String, String> sourceMap = additionalSourcesMap.get(fieldName.source);
							if (sourceMap.containsKey(fieldName.key)) {
								fieldName.value = sourceMap.get(fieldName.key);
							}
						}
					} else {
						fields.add(fieldName.fieldName);
					}
				}
			}

			if (noteDefinitionParameters.sidebar != null && noteDefinitionParameters.sidebar.fieldNames != null && !noteDefinitionParameters.sidebar.fieldNames.isEmpty()) {
				for (FieldName fieldName : noteDefinitionParameters.sidebar.fieldNames) {
					if (fieldName.source != null && fieldName.key != null) {
						if (additionalSourcesMap.containsKey(fieldName.source)) {
							Map<String, String> sourceMap = additionalSourcesMap.get(fieldName.source);
							if (sourceMap.containsKey(fieldName.key)) {
								fieldName.value = sourceMap.get(fieldName.key);
							}
						}
					} else {
						fields.add(fieldName.fieldName);
					}
				}
			}

			if (noteDefinitionParameters.footer != null && noteDefinitionParameters.footer.fieldNames != null && !noteDefinitionParameters.footer.fieldNames.isEmpty()) {
				for (FieldName fieldName : noteDefinitionParameters.footer.fieldNames) {
					if (fieldName.source != null && fieldName.key != null) {
						if (additionalSourcesMap.containsKey(fieldName.source)) {
							Map<String, String> sourceMap = additionalSourcesMap.get(fieldName.source);
							if (sourceMap.containsKey(fieldName.key)) {
								fieldName.value = sourceMap.get(fieldName.key);
							}
						}
					} else {
						fields.add(fieldName.fieldName);
					}
				}
			}

			if (noteDefinitionParameters.saveToQueue != null) {
				String queueQuery = 'SELECT Id' + ' FROM Group' + ' WHERE Type = \'Queue\' AND Name = \'' + noteDefinitionParameters.saveToQueue + '\'' + ' LIMIT 1';
				List<Group> queues = (List<Group>) Database.query(queueQuery);

				if (queues.size() > 0) {
					noteOwnerId = queues[0].Id;
				}
			}

			Map<String, Object> noteDefinitionParametersMap = (Map<String, Object>) JSON.deserializeUntyped(theNote.NoteDefinition.Parameters__c);
			noteDefinitionParametersMap.putAll((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(noteDefinitionParameters, true)));
			theNote.NoteDefinition.Parameters__c = JSON.serialize(noteDefinitionParametersMap);
		}

		if (!theNote.noteItems.isEmpty()) {
			for (NoteDefinition.NoteItem noteItem : theNote.noteItems) {
				String type = noteItem.noteItem.Type__c;
				if (type == 'Field') {
					fields.add(noteItem.noteItem.Field_Name__c);
					if (noteItem.displayType == 'REFERENCE') {
						fields.add(noteItem.relationshipName + '.' + noteItem.displayField);
					}
				} else if (type == 'Embedded Component') {
					if (String.isNotBlank(noteItem.noteItem.Embedded_Component_Fields__c)) {
						List<String> embeddedComponentFieldsList = noteItem.noteItem.Embedded_Component_Fields__c.split(',');
						fields.addAll(embeddedComponentFieldsList);
					}
				}
			}
		}

		fields.add('Id');
		fields.add('Status__c');
		fields.add('Account__r.Photo_Version_Id__c');
		fields.add('Account__r.Name');
		fields.add('Admission__c');
		fields.add('Photo__c');
		fields.add('OwnerId');
		fields.add('Auto_Saved__c');
		fields.add('Type__c');
		fields.add('Status__c');
		fields.add('Completed_By_Professional_Name__c');
		fields.add('Finalized_By_Professional_Name__c');
		fields.add('Completed_By__c');
		fields.add('Finalized_By__c');
		fields.add('Completed_Date_Time__c');
		fields.add('Finalized_Date_Time__c');
		fields.add('LastModifiedDate');
		fields.add('Snapshot__r.Html__c');
		fields.add('Print_Link__c');
		fields.add('Contact_Date__c');
		fields.add('Psych_Testing_Request__c');
		// fields.add('Completed_By__r.Professional_Name__c');

		//remove unprinted characters
		Set<String> cleanedSet = new Set<String>();
		for (String field : fields) {
			if (field != null) {
				cleanedSet.add(field.trim());
			}
		}

		String queryString = 'SELECT ';
		List<String> fieldsList = new List<String>();
		fieldsList.addAll(cleanedSet);
		queryString += String.join(fieldsList, ', ');
		queryString += ' FROM Patient_Note__c WHERE Id = :patientNoteId';
		if (lockForUpdate) {
			queryString += ' FOR UPDATE';
		}

		List<Patient_Note__c> patientNote = Database.query(queryString);
		if (!patientNote.isEmpty()) {
			theNote.patientNote = patientNote[0];
			if (noteOwnerId != null)
				theNote.patientNote.OwnerId = noteOwnerId;
		}

		if (!theNote.noteItems.isEmpty()) {
			for (NoteDefinition.NoteItem noteItem : theNote.noteItems) {
				String type = noteItem.noteItem.Type__c;
				if (type == 'Field') {
					if (noteItem.displayType == 'DATE') {
						Date patientNoteDate = ((Date) (theNote.patientNote.get(noteItem.noteItem.Field_Name__c)));
						noteItem.stringValue = null;
						if (patientNoteDate != null) {
							noteItem.stringValue = patientNoteDate.format();
						}
					}
					if (noteItem.displayType == 'REFERENCE') {
						SObject relatedObject = theNote.patientNote.getSObject(noteItem.relationshipName);
						noteItem.stringValue = null;
						if (relatedObject != null) {
							noteItem.stringValue = String.valueOf(relatedObject.get(noteItem.displayField));
						}
					}
				}
				//set initial hide value
				noteItem.hideNoteItem = calculateHideNoteItem(noteItem.noteItem.Hide_Conditions__c, theNote.patientNote);
			}
		}
	}

	public static Note getNoteDefinition(String type) {
		List<Note_Definition__mdt> noteDefinitions = [SELECT Id, DeveloperName, MasterLabel, Note_Label__c, Applies_to_Note_Types__c, Parameters__c FROM Note_Definition__mdt WHERE Note_Label__c = :type AND Active__c = TRUE];
		if (!noteDefinitions.isEmpty()) {
			Note newNote = new Note(noteDefinitions[0]);
			Id noteDefinitionId = noteDefinitions[0].Id;

			List<Note_Item__mdt> noteItems = [SELECT Id, DeveloperName, MasterLabel, Note_Definition__c, Type__c, Override_DisplayType__c, Title__c, Subtitle__c, Helptext__c, Item_Parameters__c, Field_Name__c, Is_Read_Only__c, Embedded_Component_Name__c, Embedded_Component_Fields__c, Embedded_Component_Parameters__c, Order__c, Is_Required__c, Hide_Conditions__c FROM Note_Item__mdt WHERE Note_Definition__c = :noteDefinitionId AND Active__c = TRUE ORDER BY Order__c ASC];

			if (!noteItems.isEmpty()) {
				for (Note_Item__mdt noteItem : noteItems) {
					NoteItem newNoteItem = new NoteItem(noteItem);
					try {
						if (noteItem.Type__c == 'Field' && noteItem.Field_Name__c != null) {
							Schema.DescribeFieldResult fieldResult = patientNoteDescribeResult.fields.getMap().get(noteItem.Field_Name__c.toLowerCase()).getDescribe();
							newNoteItem.displayType = String.valueOf(fieldResult.getType());
							//  - create new field Override_DisplayType__c on mdt, then use that to determine for MULTISELECTCHECKBOX,
							// RADIOBUTTON (this is a picklist), modify component to determine by displayType
							if (newNoteItem.displayType == 'REFERENCE') {
								for (Schema.SObjectType reference : fieldResult.getReferenceTo()) {
									newNoteItem.objectName = reference.getDescribe().getName();
									newNoteItem.displayField = 'Name';
									newNoteItem.relationshipName = fieldResult.getRelationshipName();
									if (reference.getDescribe().getName() == 'User') {
										newNoteItem.displayField = 'Professional_Name__c';
									} else if (reference.getDescribe().getName() == 'Contact') {
										newNoteItem.displayField = 'Distinguished_Name__c';
									}
								}
							}

							//else if(newNoteItem.displayType == 'MULTIPICKLIST'){
							if (String.isNotBlank(noteItem.Override_DisplayType__c)) {
								newNoteItem.displayType = noteItem.Override_DisplayType__c;
							}
						}
					} catch (Exception e) {
						ProcessLogging.quickProcessLog('NoteDefinition NoteItem', e.getStackTraceString(), 'error on NoteItem ' + noteItem + '\n\n' + e.getMessage());
					}
					newNote.noteItems.add(newNoteItem);
				}
			}

			return newNote;
		}
		return null;
	}

	public static Note getNote(Id patientNoteId) {
		// NoteDefinition noteDefinition = new NoteDefinition(patientNoteId);
		// return noteDefinition.theNote;
		return getNote(patientNoteId, false);
	}

	public static Note getNote(Id patientNoteId, Boolean lockForUpdate) {
		NoteDefinition noteDefinition = new NoteDefinition(patientNoteId, lockForUpdate);
		return noteDefinition.theNote;
	}

	private static DescribeSObjectResult getPatientNoteDescribeResult() {
		DescribeSObjectResult describeSObjResult;
		if (patientNoteDescribeResult == null) {
			SObjectType sObjType = ((SObject) (Type.forName('Schema.' + 'Patient_Note__c').newInstance())).getSObjectType();
			describeSObjResult = sObjType.getDescribe();
		} else {
			describeSObjResult = patientNoteDescribeResult;
		}

		return describeSObjResult;
	}

	public static Set<Id> authorizedSignerIds(string patientNoteId) {
		return AuthorizedSigners.getSignersByPatientNoteId(patientNoteId);
	}

	//false by default = do not hide by default. conditions is usually Hide_Conditions__c from a Note Item MDT, controllingsObject is usually a Patient Note sObject
	public static Boolean calculateHideNoteItem(String conditions, sObject controllingsObject) {
		Boolean hideNoteItem = false;

		if (conditions != null) {
			Map<String, Object> conditionsMap = (Map<String, Object>) JSON.deSerializeUntyped(conditions);
			if (conditionsMap.containsKey('fieldName') && conditionsMap.containsKey('operator') && conditionsMap.containsKey('fieldValue')) {
				//check for controlling display field value
				String fieldName = String.valueOf(conditionsMap.get('fieldName'));
				String operator = String.valueOf(conditionsMap.get('operator'));

				String controllingsObjectFieldValue = String.valueOf(controllingsObject.get(fieldName));
				String matchFieldValue = String.valueOf(conditionsMap.get('fieldValue'));
				Schema.DescribeFieldResult fieldResult = patientNoteDescribeResult.fields.getMap().get(fieldName.toLowerCase()).getDescribe();
				if (fieldResult.getType() == Schema.DisplayType.BOOLEAN) {
					if (matchFieldValue == '1') {
						matchFieldValue = 'true';
					}
				}
				if (operator == '==') {
					hideNoteItem = (controllingsObjectFieldValue == matchFieldValue);
				} else if (operator == '!=') {
					hideNoteItem = (controllingsObjectFieldValue != matchFieldValue);
				}
			}
		}

		return hideNoteItem;
	}

	public class Note {
		@AuraEnabled
		public Patient_Note__c patientNote;
		@AuraEnabled
		public Note_Definition__mdt noteDefinition;
		@AuraEnabled
		public List<NoteItem> noteItems;
		@AuraEnabled
		public Boolean isAuthSigner;
		@AuraEnabled
		public Boolean canReOpenNote;
		@AuraEnabled
		public Integer numOfSnapshots;
		@AuraEnabled
		public Boolean canSeeCompleteButton;

		public Note(Note_Definition__mdt noteDefinition) {
			this.noteDefinition = noteDefinition;
			this.noteItems = new List<NoteDefinition.NoteItem>();
		}
	}

	public class NoteItem {
		@AuraEnabled
		public Note_Item__mdt noteItem;
		@AuraEnabled
		public Boolean hideNoteItem = false; //if true, note item will be hidden on display and snapshot
		@AuraEnabled
		public String displayType;
		@AuraEnabled
		public String objectName;
		@AuraEnabled
		public String displayField;
		@AuraEnabled
		public String stringValue;
		@AuraEnabled
		public String relationshipName;

		public NoteItem(Note_Item__mdt noteItem) {
			this.noteItem = noteItem;
		}
	}

	public class NoteDefinitionParameters {
		public NoteDefinitionParametersHeader header;
		public NoteDefinitionParametersSidebar sidebar;
		public NoteDefinitionParametersFooter footer;
		public String saveToQueue;
	}

	public class NoteDefinitionParametersHeader {
		List<FieldName> fieldNames;
	}

	public class NoteDefinitionParametersSidebar {
		List<FieldName> fieldNames;
	}

	public class NoteDefinitionParametersFooter {
		List<FieldName> fieldNames;
	}

	public class FieldName {
		public String fieldName;
		public String label;
		public String source;
		public String key;
		public String value;
	}
}