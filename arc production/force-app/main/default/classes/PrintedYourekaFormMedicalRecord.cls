public with sharing class PrintedYourekaFormMedicalRecord extends PrintedMedicalRecordBase {
	public static final string FORMAT_SECTION_HEADER = '<div class="section-header">{0}</div><br/>';
	public static final string FORMAT_QUESTION = '<div class="question">{0}</div>';
	public static final string FORMAT_ANSWER = '<div class="answer"><i>{0}</i></div><br/>';
	public static final string FORMAT_SIGNATURE = '<img class="signature" src = {0} /><br/>';
	//%2Fsfc%2Fservlet.shepherd%2Fversion%2FrenditionDownload%3Frendition%3DTHUMB720BY480%26versionId%3D
	public static final string FORMAT_PDFIMG = '<div class="embeddedPDF"><img src="%2Fsfc%2Fservlet.shepherd%2Fversion%2FrenditionDownload%3Frendition%3DTHUMB720BY480%26versionId%3D{0}"/></div>';
	public PrintedYourekaFormMedicalRecord() {
		super();
	}
	public override String getSDocJunctionLookupField() {
		return 'Youreka_Form__c';
	}
	public override String getSObjectName() {
		return 'disco__Form__c';
	}
	public override String formatLevel2Name(TreeGridNode level2) {
		return level2.developerName + ';' + level2.sObjectName + ';' + patientId;
	}
	public override String formatLevel3Name(SObject sObj) {
		disco__Form__c form = (disco__Form__c) sObj;
		return form.Name + ';' + form.disco__Form_Template__r.DocType_Name__c + ';' + form.Id + ';disco__Form__c';
	}

	// public override TreeGridNode assignDocumentRecord(TreeGridNode level2) {
	//     if(availableMedicalRecords.containsKey(level2.developerName)) {
	//         level2.children=availableMedicalRecords.get(level2.developerName);
	//         level2.sObjectName = 'disco__Form__c';
	//         level2.name = formatLevel2Name(level2);
	//     }
	//     return level2;
	// }

	public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords() {
		//Patient Note's Type__c is mapped to Note Definition's Note_Label__c, and in turn the Note Definition's Med_Records_Document_Type__r.DeveloperName
		//is mapped to Med_Records_Document_Type__mdt.DeveloperName.
		Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();
		List<disco__Form__c> forms = [SELECT Id, Name, disco__Original_Submitted_Date__c, disco__Form_Template__r.DocType_Name__c, Finalized_Date_Time__c, Finalized_By__r.Professional_Name__c, Master_Date__c, disco__Originally_Submitted_By__r.Name, disco__Originally_Submitted_By__r.Professional_Name__c FROM disco__Form__c WHERE disco__Form_Account__c = :patientId AND Master_Date__c != NULL AND Admission__c IN :admissionIdList WITH SECURITY_ENFORCED ORDER BY Master_Date__c DESC];
		for (disco__Form__c form : forms) {
			if (!treeGridMap.containsKey(form.disco__Form_Template__r.DocType_Name__c)) {
				treeGridMap.put(form.disco__Form_Template__r.DocType_Name__c, new List<TreeGridNode>());
			}
			TreeGridNode tg = new TreeGridNode();
			tg.sfID = form.Id;
			//tg.contactDate = form.Master_date__c;
			Integer d = form.Master_date__c.day();
			Integer mo = form.Master_date__c.month();
			Integer yr = form.Master_date__c.year();
			tg.contactDate = DateTime.newInstance(yr, mo, d);
			tg.url = '/' + form.Id;
			tg.name = formatLevel3Name(form);
			tg.nodeName = form.Name;
			tg.developerName = form.disco__Form_Template__r.DocType_Name__c;
			tg.finalizedDatetime = form.Finalized_Date_Time__c;
			tg.finalizedBy = form.Finalized_By__r.Professional_Name__c;
			List<TreeGridNode> formItems = treeGridMap.get(form.disco__Form_Template__r.DocType_Name__c);
			formItems.add(tg);
		}

		availableMedicalRecords = treeGridMap;
		return treeGridMap;
	}

	public override List<String> collectSelectedMedicalRecords() {
		List<Printed_Medical_Included_Record__c> includedObjects = [
			SELECT SDoc_Junction__r.Youreka_Form__c, SDoc_Junction__r.Youreka_Form__r.Name, Sort_Order__c, SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c
			FROM Printed_Medical_Included_Record__c
			WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Youreka_Form__c != NULL AND SDoc_Junction__r.Youreka_Form__r.Master_Date__c != NULL AND SDoc_Junction__r.Youreka_Form__r.Admission__c IN :admissionIdList //AND SDoc_Junction__r.Youreka_Form__r.Master_Date__c != null
			WITH SECURITY_ENFORCED
			ORDER BY Sort_Order__c, SDoc_Junction__r.Youreka_Form__r.Master_Date__c DESC
		];

		List<String> selectedRows = new List<String>();

		for (Printed_Medical_Included_Record__c r : includedObjects) {
			disco__Form__c form = r.SDoc_Junction__r.Youreka_Form__r;
			String itemName = formatLevel3Name(form);
			selectedRows.add(itemName);
		}
		selectedMedicalRecords = selectedRows;
		return selectedRows;
	}

	public override List<String> collectSelectedMedicalRecordsInDateRange() {
		List<String> selectedRows = new List<String>();
		Set<String> selectedDocTypes = new Set<String>();
		Set<String> selectedFormTypes = new Set<String>();
		Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();
		String queryFormat = 'SELECT {0} FROM disco__Form__c WHERE disco__Form_Account__c = :patientId AND {1} >= :dateFrom AND {1} <= :dateTo AND Master_Date__c != null AND Admission__c in :admissionIdList ORDER by {1} desc';
		String formQueryFields = 'Id, Name, disco__Original_Submitted_Date__c, disco__Form_Template__r.DocType_Name__c,Finalized_Date_Time__c,Finalized_By__r.Professional_Name__c,';
		formQueryFields += ' Master_Date__c,disco__Originally_Submitted_By__r.Name,disco__Originally_Submitted_By__r.Professional_Name__c';
		String queryDateField = searchFinalizedDate ? 'disco__Original_Submitted_Date__c' : 'Master_Date__c';
		String query = String.format(queryFormat, new List<String>{ formQueryFields, queryDateField });
		List<disco__Form__c> forms = Database.query(query);

		for (disco__Form__c form : forms) {
			selectedRows.add(formatLevel3Name(form));
		}

		selectedMedicalRecordsInDateRange = selectedRows;
		return selectedRows;
	}

	public override List<TreeGridNode> findMedicalRecordsForDocumentType(String docName) {
		List<TreeGridNode> items = new List<TreeGridNode>();
		List<disco__Form__c> formList = [SELECT Id, Name, disco__Original_Submitted_Date__c, disco__Form_Template__r.DocType_Name__c, disco__Originally_Submitted_By__r.Name, disco__Originally_Submitted_By__r.Professional_Name__c, Master_Date__c, Finalized_Date_Time__c, Finalized_By__r.Professional_Name__c FROM disco__Form__c WHERE disco__Form_Account__c = :patientId AND disco__Form_Template__r.DocType_Name__c = :docName AND Master_Date__c != NULL AND Admission__c IN :admissionIdList WITH SECURITY_ENFORCED ORDER BY Master_Date__c DESC];

		for (disco__Form__c form : formList) {
			TreeGridNode tg = new TreeGridNode();
			tg.sfID = form.Id;
			tg.contactDate = form.Master_date__c;
			tg.name = formatLevel3Name(form);
			tg.url = '/' + form.Id;
			tg.nodeName = form.Name;
			tg.finalizedDatetime = form.Finalized_Date_Time__c;
			tg.finalizedBy = form.Finalized_By__r.Professional_Name__c;
			tg.children = null;
			tg.childrenCount = 0;
			items.add(tg);
		}
		return items;
	}
	public override List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs() {
		List<Med_Records_Document_Type__mdt> queryDocTypes = [SELECT Active__c, Category__c, Id, Name__c, Sort_Order__c, Flow_Name__c, SObject_Name__c, Creatable__c, DeveloperName FROM Med_Records_Document_Type__mdt WHERE Active__c = TRUE WITH SECURITY_ENFORCED ORDER BY Sort_Order__c];
		Map<String, String> docTypeNameMap = new Map<String, String>();
		for (Med_Records_Document_Type__mdt mrType : queryDocTypes) {
			docTypeNameMap.put(mrType.DeveloperName, mrtype.Name__c);
		}

		Set<String> formIds = new Set<String>();
		Map<String, TreeGridNode.PrintedIncludedObject> formNameToIncludedObjectMap = new Map<String, TreeGridNode.PrintedIncludedObject>();
		for (
			Printed_Medical_Included_Record__c pmir : [
				SELECT SDoc_Junction__r.Youreka_Form__c, SDoc_Junction__r.Youreka_Form__r.Name, Sort_Order__c, SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c, SDoc_Junction__r.Youreka_Form__r.disco__Form_Template_Name__c, SDoc_Junction__r.Youreka_Form__r.Master_Date__c
				FROM Printed_Medical_Included_Record__c
				WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Youreka_Form__c != NULL //AND disco__Hidden_By_Dep__c = false AND disco__Question__r.disco__Always_Hidden__c = false
				WITH SECURITY_ENFORCED
				ORDER BY Sort_Order__c, SDoc_Junction__r.Youreka_Form__r.Master_Date__c DESC
			]
		) {
			formIds.add(pmir.SDoc_Junction__r.Youreka_Form__c);
			Integer sortSequence = calculateSortingSequenceWithDevName(pmir.SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c);
			TreeGridNode.PrintedIncludedObject includedObj = new TreeGridNode.PrintedIncludedObject(docTypeNameMap.get(pmir.SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c), sortSequence);
			includedObj.finalizedTime = pmir.SDoc_Junction__r.Youreka_Form__r.Master_Date__c;
			includedObj.sfdcName = pmir.SDoc_Junction__r.Youreka_Form__r.Name;
			formNameToIncludedObjectMap.put(pmir.SDoc_Junction__r.Youreka_Form__r.Name, includedObj);
		}
		// List<disco__Answer__c> answers = [SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c,
		//         disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name,
		//         disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c,
		//         disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c,
		//         disco__Number_Answer__c, disco__Text_Answer__c, disco__Form__c, disco__Form__r.name,
		//         (SELECT Id,Title,FileType,ContentSize FROM CombinedAttachments) FROM disco__Answer__c
		//     WHERE disco__Form__c in :formIds
		//     AND disco__Hidden_By_Dep__c = false AND disco__Question__r.disco__Always_Hidden__c = false  AND disco__Question__r.disco__Type__c != 'Image'
		//     WITH SECURITY_ENFORCED
		//     ORDER BY disco__Form__c, disco__Question__r.disco__Order__c asc];

		List<disco__Answer__c> answers = [
			SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c, disco__E_Sig_Image_Id__c, disco__Form__c, disco__Form__r.name, disco__E_Sig_Image_Link__c, (SELECT Id, Title, FileType, ContentSize FROM CombinedAttachments)
			FROM disco__Answer__c
			WHERE disco__Form__c IN :formIds AND disco__Hidden_By_Dep__c = FALSE AND disco__Question__r.disco__Always_Hidden__c = FALSE AND disco__Question__r.disco__Type__c != 'Image' AND LOCUS_Show_Hide_123__c != 'HIDE' AND LOCUS_Show_Hide_4A4B__c != 'HIDE' AND LOCUS_Show_Hide_56__c != 'HIDE'
			ORDER BY disco__Question__r.disco__Section__r.disco__Order__c, disco__Linked_Section_Order__c, disco__Question__r.disco__Order__c
		];

		// Map<String, List<String>> answerAttachments = new Map<String, List<String>>();
		Map<String, String> documentAnswerMap = new Map<String, String>();
		Set<Id> documentIds = new Set<Id>();
		for (disco__Answer__c ans : answers) {
			for (CombinedAttachment d : ans.CombinedAttachments) {
				documentIds.add(d.Id);
				documentAnswerMap.put(d.Id, ans.Id);
			}
		}
		Map<String, String> contentDocumentVersionMap = new Map<String, String>();
		for (ContentVersion v : [SELECT Id, VersionData, FileType, ContentDocumentId FROM ContentVersion WHERE IsLatest = TRUE AND ContentDocumentId IN :documentIds WITH SECURITY_ENFORCED]) {
			// if(!answerAttachments.containsKey(v.ContentDocumentId)) {
			//    answerAttachments.put(v.ContentDocumentId,new List<String>());
			// }
			// answerAttachments.get(v.ContentDocumentId).add(String.format(FORMAT_PDFIMG, new List<String>{v.Id}));
			contentDocumentVersionMap.put(v.ContentDocumentId, v.Id);
		}
		Map<String, List<String>> formAttachments = new Map<String, List<String>>();

		Map<String, List<disco__Answer__c>> formAnswerMap = new Map<String, List<disco__Answer__c>>();
		for (disco__Answer__c ans : answers) {
			if (!formAnswerMap.containsKey(ans.disco__Form__r.name)) {
				formAnswerMap.put(ans.disco__Form__r.name, new List<disco__Answer__c>());
			}
			if (!formAttachments.containsKey(ans.disco__Form__r.name)) {
				formAttachments.put(ans.disco__Form__r.name, new List<String>());
			}
			formAnswerMap.get(ans.disco__Form__r.name).add(ans);
			for (CombinedAttachment d : ans.CombinedAttachments) {
				formAttachments.get(ans.disco__Form__r.name).add(contentDocumentVersionMap.get(d.Id));
			}
		}

		String htmlString = '';
		for (String key : formAnswerMap.keySet()) {
			formNameToIncludedObjectMap.get(key).htmlText = generateYourekaHTML(formAnswerMap.get(key));
			formNameToIncludedObjectMap.get(key).attachments = formAttachments.get(key);
		}

		return formNameToIncludedObjectMap.values();
	}
	public String generateYourekaHTML(List<disco__Answer__c> answers) {
		//a0x2i000001xm1yAAA
		String htmlString = '';
		for (disco__Answer__c ans : answers) {
			if ('logoy.jpg'.equalsIgnoreCase(ans.disco__Question__r.disco__Label__c)) {
				//ignore the logo
				continue;
			}
			String htmlAnswer = '';
			if (ans.disco__Question__r.First_in_Section__c) {
				htmlAnswer += String.format(FORMAT_SECTION_HEADER, new List<string>{ ans.disco__Question__r.disco__Section__r.Name });
			}
			if (ans.disco__Answer__c != null && !('null'.equalsIgnoreCase(ans.disco__Answer__c))) {
				htmlAnswer += String.format(FORMAT_QUESTION, new List<string>{ ans.disco__Question__r.disco__Label__c });
				if (!'signed'.equalsIgnoreCase(ans.disco__Answer__c)) {
					if (ans.disco__Answer__c == null || ('null'.equalsIgnoreCase(ans.disco__Answer__c))) {
						ans.disco__Answer__c = 'N/A';
					}
					htmlAnswer += String.format(FORMAT_ANSWER, new List<string>{ ans.disco__Answer__c });
				}
			}
			if ('E-Signature'.equalsIgnoreCase(ans.disco__Question__r.disco__Type__c)) {
				htmlAnswer += String.format(FORMAT_SIGNATURE, new List<string>{ ans.disco__E_Sig_Image_Link__c });
			}

			htmlString += htmlAnswer;
		}

		return htmlString;
	}
}