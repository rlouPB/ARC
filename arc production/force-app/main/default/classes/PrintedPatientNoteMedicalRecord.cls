public with sharing class PrintedPatientNoteMedicalRecord extends PrintedMedicalRecordBase {
	public PrintedPatientNoteMedicalRecord() {
		super();
	}
	public override String getSDocJunctionLookupField() {
		return 'Patient_Note__c';
	}
	public override String getSObjectName() {
		return 'Patient_Note__c';
	}
	// public override TreeGridNode assignDocumentRecord(TreeGridNode level2) {
	//     if(availableMedicalRecords.containsKey(level2.developerName)) {
	//         level2.children=availableMedicalRecords.get(level2.developerName);
	//         level2.sObjectName = 'Patient_Note__c';
	//         level2.name = formatLevel2Name(level2);
	//     }
	//     return level2;
	// }
	public override String formatLevel2Name(TreeGridNode level2) {
		return noteDefinitionRecTypeMap.get(level2.developerName) + ';' + level2.sObjectName + ';' + patientId;
	}
	public override String formatLevel3Name(SObject sObj) {
		Patient_Note__c note = (Patient_Note__c) sObj;
		return note.Name + ';' + note.Type__c + ';' + note.Id + ';Patient_Note__c';
	}

	public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords() {
		//Patient Note's Type__c is mapped to Note Definition's Note_Label__c, and in turn the Note Definition's Med_Records_Document_Type__r.DeveloperName
		//is mapped to Med_Records_Document_Type__mdt.DeveloperName.
		Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();

		MAP<String, String> noteDefinitionRecTypeMap = new Map<String, String>();
		for (Note_Definition__mdt noteDefinition : [SELECT Id, DeveloperName, Active__c, Note_Label__c, Med_Records_Document_Type__r.DeveloperName FROM Note_Definition__mdt WITH SECURITY_ENFORCED]) {
			noteDefinitionRecTypeMap.put(noteDefinition.Note_Label__c, noteDefinition.Med_Records_Document_Type__r.DeveloperName);
		}
		List<Patient_Note__c> notes = [SELECT Id, Name, Finalized_Date_Time__c, Contact_Date__c, Finalized_By__r.Name, Finalized_By__r.Professional_Name__c, Type__c FROM Patient_Note__c WHERE Account__c = :patientId AND Status__c = 'Finalized' AND Admission__c IN :admissionIdList WITH SECURITY_ENFORCED ORDER BY Contact_Date__c DESC];

		for (Patient_Note__c note : notes) {
			String docType = noteDefinitionRecTypeMap.get(note.Type__c) != null ? noteDefinitionRecTypeMap.get(note.Type__c) : note.Type__c;
			if (!treeGridMap.containsKey(docType)) {
				treeGridMap.put(docType, new List<TreeGridNode>());
			}
			TreeGridNode tg = new TreeGridNode();
			tg.sfID = note.Id;
			tg.contactDate = note.Contact_Date__c;
			tg.url = '/' + note.Id;
			tg.name = formatLevel3Name(note);
			tg.nodeName = note.Name;
			tg.developerName = noteDefinitionRecTypeMap.get(note.Type__c);
			tg.finalizedDatetime = note.Finalized_Date_Time__c;
			tg.finalizedBy = note.Finalized_By__r.Professional_Name__c;
			List<TreeGridNode> noteItems = treeGridMap.get(docType);
			noteItems.add(tg);
		}
		availableMedicalRecords = treeGridMap;
		return treeGridMap;
	}
	public override List<String> collectSelectedMedicalRecords() {
		List<Printed_Medical_Included_Record__c> includedObjects = [
			SELECT SDoc_Junction__r.Patient_Note__r.Id, SDoc_Junction__r.Patient_Note__r.Name, SDoc_Junction__r.Patient_Note__r.Finalized_Date_Time__c, SDoc_Junction__r.Patient_Note__r.Contact_Date__c, SDoc_Junction__r.Patient_Note__r.Finalized_By__r.Professional_Name__c, SDoc_Junction__r.Patient_Note__r.Type__c, Sort_Order__c
			FROM Printed_Medical_Included_Record__c
			WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Patient_Note__c != NULL AND SDoc_Junction__r.Patient_Note__r.Status__c = 'Finalized'
			WITH SECURITY_ENFORCED
			ORDER BY SDoc_Junction__r.Patient_Note__r.Finalized_Date_Time__c DESC
		];

		List<String> selectedRows = new List<String>();
		for (Printed_Medical_Included_Record__c r : includedObjects) {
			Patient_Note__c note = r.SDoc_Junction__r.Patient_Note__r;
			String itemName = formatLevel3Name(note);
			selectedRows.add(itemName);
		}
		selectedMedicalRecords = selectedRows;
		return selectedRows;
	}
	public override List<String> collectSelectedMedicalRecordsInDateRange() {
		// String patientId = req.patientId;
		// Date dateFrom = req.dateFrom;
		// Date dateTo = req.dateTo;
		//Boolean searchFinalizedDate = req.searchFinalizedDate;
		List<String> selectedRows = new List<String>();
		String notesQueryFormat = 'SELECT {0} FROM Patient_Note__c WHERE Account__c = :patientId AND Status__c = \'Finalized\' AND Admission__c in :admissionIdList AND {1} >= :dateFrom AND {1} <= :dateTo ORDER by {1}';
		String notesQueryFields = 'Id, Name, Finalized_Date_Time__c, Contact_Date__c, Finalized_By__r.Name, Finalized_By__r.Professional_Name__c, Type__c';
		String notesQueryDateField = searchFinalizedDate ? 'Finalized_Date_Time__c' : 'Contact_Date__c';
		String notesQuery = String.format(notesQueryFormat, new List<String>{ notesQueryFields, notesQueryDateField });
		List<Patient_Note__c> notes = Database.query(notesQuery);

		for (Patient_Note__c note : notes) {
			selectedRows.add(formatLevel3Name(note));
		}
		selectedMedicalRecordsInDateRange = selectedRows;
		return selectedRows;
	}
	public override List<TreeGridNode> findMedicalRecordsForDocumentType(String docName) {
		List<TreeGridNode> items = new List<TreeGridNode>();
		List<Patient_Note__c> noteList = [SELECT Id, Name, Finalized_Date_Time__c, Contact_Date__c, Finalized_By__r.Name, Finalized_By__r.Professional_Name__c, Type__c FROM Patient_Note__c WHERE Account__c = :patientId AND Type__c = :docName AND Status__c = 'Finalized' WITH SECURITY_ENFORCED];

		for (Patient_Note__c note : noteList) {
			TreeGridNode tg = new TreeGridNode();
			tg.sfID = note.Id;
			tg.url = '/' + note.Id;
			tg.contactDate = note.Contact_Date__c;
			tg.name = formatLevel3Name(note);
			tg.nodeName = note.Name;
			tg.finalizedDatetime = note.Finalized_Date_Time__c;
			tg.finalizedBy = note.Finalized_By__r.Professional_Name__c;
			tg.children = null;
			tg.childrenCount = 0;
			items.add(tg);
		}

		return items;
	}

	public override List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs() {
		List<TreeGridNode.PrintedIncludedObject> includedObjects = new List<TreeGridNode.PrintedIncludedObject>();
		for (Printed_Medical_Included_Record__c pmir : [SELECT SDoc_Junction__r.Patient_Note__r.Snapshot__r.Html__c, SDoc_Junction__r.Patient_Note__r.Contact_Date__c, SDoc_Junction__r.Patient_Note__r.Type__c, Sort_Order__c, SDoc_Junction__r.Patient_Note__r.Finalized_Date_Time__c, SDoc_Junction__r.Patient_Note__r.Name FROM Printed_Medical_Included_Record__c WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Patient_Note__c != NULL AND SDoc_Junction__r.Patient_Note__r.Status__c = 'Finalized' WITH SECURITY_ENFORCED ORDER BY Sort_Order__c]) {
			Integer sortSequence = SDocsYourekaUtils.calculateSortingSequence(pmir.SDoc_Junction__r.Patient_Note__r.Type__c);
			TreeGridNode.PrintedIncludedObject includedObject = new TreeGridNode.PrintedIncludedObject(pmir.SDoc_Junction__r.Patient_Note__r.Type__c, pmir.SDoc_Junction__r.Patient_Note__r.Snapshot__r.Html__c, sortSequence);
			includedObject.finalizedTime = pmir.SDoc_Junction__r.Patient_Note__r.Contact_Date__c;
			includedObject.sfdcName = pmir.SDoc_Junction__r.Patient_Note__r.Name;
			includedObjects.add(includedObject);
		}

		return includedObjects;
	}
}