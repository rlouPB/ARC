public with sharing class PrintedCaseMedicalRecord extends PrintedMedicalRecordBase {
	public PrintedCaseMedicalRecord() {
		super();
	}
	public override String getSDocJunctionLookupField() {
		return 'Treatment_Plan__c';
	}
	public override String getSObjectName() {
		return 'Case';
	}

	public override String formatLevel2Name(TreeGridNode level2) {
		return noteDefinitionRecTypeMap.get(level2.developerName) + ';' + level2.sObjectName + ';' + patientId;
	}
	public override String formatLevel3Name(SObject sObj) {
		Case note = (Case) sObj;
		return note.CaseNumber + ';Treatment_Plan;' + note.Id + ';Case';
	}

	public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords() {
		Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();
		List<Case> cases = [SELECT Id, CaseNumber, AccountId, Account.Name, Type, Status, Admission__c, Finalized_By__c, Finalized_Date_Time__c, Finalized_By_User__c, Finalized_By_Professional_Name__c, CreatedDate FROM Case WHERE AccountId = :patientId AND Admission__c IN :admissionIdList AND Status = 'Finalized' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
		for (Case aCase : cases) {
			if (!treeGridMap.containsKey('Treatment_Plan')) {
				treeGridMap.put('Treatment_Plan', new List<TreeGridNode>());
			}
			TreeGridNode tg = new TreeGridNode();
			tg.sfID = aCase.Id;
			tg.contactDate = aCase.CreatedDate;
			tg.url = '/' + aCase.Id;
			tg.name = formatLevel3Name(aCase);
			tg.nodeName = aCase.CaseNumber;
			tg.developerName = 'Treatment_Plan';
			tg.finalizedDatetime = aCase.Finalized_Date_Time__c;
			tg.finalizedBy = aCase.Finalized_By_Professional_Name__c;
			List<TreeGridNode> caseItems = treeGridMap.get('Treatment_Plan');
			caseItems.add(tg);
		}

		availableMedicalRecords = treeGridMap;
		return treeGridMap;
	}
	public override List<String> collectSelectedMedicalRecords() {
		List<Printed_Medical_Included_Record__c> includedObjects = [
			SELECT SDoc_Junction__r.Treatment_Plan__r.Id, SDoc_Junction__r.Treatment_Plan__r.CaseNumber, SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c, SDoc_Junction__r.Treatment_Plan__r.CreatedDate, SDoc_Junction__r.Treatment_Plan__r.Finalized_By_User__r.Professional_Name__c, Sort_Order__c
			FROM Printed_Medical_Included_Record__c
			WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Treatment_Plan__c != NULL AND SDoc_Junction__r.Treatment_Plan__r.Status = 'Finalized'
			WITH SECURITY_ENFORCED
			ORDER BY SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c DESC
		];

		List<String> selectedRows = new List<String>();
		for (Printed_Medical_Included_Record__c r : includedObjects) {
			Case note = r.SDoc_Junction__r.Treatment_Plan__r;
			String itemName = formatLevel3Name(note);
			selectedRows.add(itemName);
		}
		selectedMedicalRecords = selectedRows;
		return selectedRows;
	}

	public override List<String> collectSelectedMedicalRecordsInDateRange() {
		List<String> selectedRows = new List<String>();
		String casesQueryFormat = 'SELECT {0} FROM Case WHERE AccountId = :patientId AND Status = \'Finalized\' AND Admission__c in :admissionIdList AND {1} >= :dateFrom AND {1} <= :dateTo ORDER by {1}';
		String casesQueryFields = 'Id , CaseNumber, AccountId , Account.Name, Type , Status , Admission__c , Finalized_By__c , ' + 'Finalized_Date_Time__c , Finalized_By_User__c , Finalized_By_Professional_Name__c , CreatedDate';
		String casesQueryDateField = searchFinalizedDate ? 'Finalized_Date_Time__c' : 'CreatedDate';
		String casesQuery = String.format(casesQueryFormat, new List<String>{ casesQueryFields, casesQueryDateField });
		List<Case> cases = Database.query(casesQuery);

		for (Case aCase : cases) {
			selectedRows.add(formatLevel3Name(aCase));
		}
		selectedMedicalRecordsInDateRange = selectedRows;
		return selectedRows;
	}
	public override List<TreeGridNode> findMedicalRecordsForDocumentType(String docName) {
		List<TreeGridNode> items = new List<TreeGridNode>();
		if (docName == 'Treatment_Plan') {
			List<Case> caseList = [SELECT Id, CaseNumber, AccountId, Account.Name, Type, Status, Admission__c, Finalized_By__c, Finalized_Date_Time__c, Finalized_By_User__c, Finalized_By_Professional_Name__c, CreatedDate FROM Case WHERE AccountId = :patientId AND Status = 'Finalized' WITH SECURITY_ENFORCED];

			for (Case aCase : caseList) {
				TreeGridNode tg = new TreeGridNode();
				tg.sfID = aCase.Id;
				tg.url = '/' + aCase.Id;
				tg.contactDate = aCase.CreatedDate;
				tg.name = formatLevel3Name(aCase);
				tg.nodeName = aCase.CaseNumber;
				tg.finalizedDatetime = aCase.Finalized_Date_Time__c;
				tg.finalizedBy = aCase.Finalized_By_Professional_Name__c;
				tg.children = null;
				tg.childrenCount = 0;
				items.add(tg);
			}
		}
		return items;
	}

	public override List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs() {
		List<TreeGridNode.PrintedIncludedObject> includedObjects = new List<TreeGridNode.PrintedIncludedObject>();
		for (Printed_Medical_Included_Record__c pmir : [SELECT SDoc_Junction__r.Treatment_Plan__r.Snapshot__r.Html__c, SDoc_Junction__r.Treatment_Plan__r.CreatedDate, Sort_Order__c, SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c FROM Printed_Medical_Included_Record__c WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Treatment_Plan__c != NULL AND SDoc_Junction__r.Treatment_Plan__r.Status = 'Finalized' WITH SECURITY_ENFORCED ORDER BY Sort_Order__c]) {
			Integer sortSequence = SDocsYourekaUtils.calculateSortingSequence('Treatment Plan');
			TreeGridNode.PrintedIncludedObject includedObject = new TreeGridNode.PrintedIncludedObject('Treatment Plan', pmir.SDoc_Junction__r.Treatment_Plan__r.Snapshot__r.Html__c, sortSequence);
			includedObject.finalizedTime = pmir.SDoc_Junction__r.Treatment_Plan__r.CreatedDate;
			includedObjects.add(includedObject);
		}

		return includedObjects;
	}
}