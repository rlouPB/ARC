public class MedRecordHierarchy {
	public static List<TreeGridNode> allTreeGridNodes = null;
	public static List<String> medicalRecordSObjectNames = new List<String>();
	static {
		List<Printed_Medical_Record_Config__mdt> mrs = Printed_Medical_Record_Config__mdt.getall().values();
		for (Printed_Medical_Record_Config__mdt mr : mrs) {
			medicalRecordSObjectNames.add(mr.SObject_Name__c);
		}
	}
	@AuraEnabled
	public static List<Category> allCategories {
		get {
			if (allCategories == null) {
				buildAllCategories();
			}
			return allCategories;
		}
		set;
	}

	@AuraEnabled(cacheable=true)
	public static String getAllCategories() {
		return JSON.serialize(allCategories);
	}

	@AuraEnabled(cacheable=true)
	public static String getAdmissions(String patientId) {
		List<Admission__c> admissions = [SELECT Id, Admit_Date__c, Discharge_Date__c, Stage__c, Patient_Account__c FROM Admission__c WHERE Stage__c IN ('Admitted', 'Discharged') AND Patient_Account__c = :patientId AND Admit_Date__c != NULL WITH SECURITY_ENFORCED ORDER BY Admit_Date__c DESC];
		List<TreeGridNode.Option> admissionOptions = new List<TreeGridNode.Option>();
		list<String> admissionIds = new List<String>();
		for (Admission__c adm : admissions) {
			String label = '';
			String value = JSON.serialize(new List<String>{ adm.Id });
			label = formatDate(adm.Admit_Date__c, 'MM/dd/yyyy');
			if (adm.Discharge_Date__c != null) {
				label += ' - ' + formatDate(adm.Discharge_Date__c, 'MM/dd/yyyy');
			}
			admissionOptions.add(new TreeGridNode.Option(label, value));
			admissionIds.add(adm.Id);
		}
		admissionOptions.add(new TreeGridNode.Option('All', JSON.serialize(admissionIds)));
		return JSON.serialize(admissionOptions);
	}

	//'0012i00000XtUSAAA3'

	public static List<PrintedMedicalRecordBase> createMedicalRecordHandlers(String patientId, String requestId, String admissionId) {
		List<PrintedMedicalRecordBase> handlers = new List<PrintedMedicalRecordBase>();
		for (String n : medicalRecordSObjectNames) {
			handlers.add(PrintedMedicalRecordFactory.createHandler(n, patientId, requestId, admissionId));
		}
		return handlers;
	}
	@AuraEnabled(cacheable=true)
	public static TreeGridNode.TreeNodeResult getAllTreeWithLeafNodes(String patientId, String requestId, String admissionId) {
		if (allTreeGridNodes == null) {
			//build top two levels tree nodes
			// - Category - Med_Records_Category__mdt
			// - Document Type - Med_Records_Document_Type__mdt
			buildCategoryAndDocumentTypeNodes();
		}
		//allTreeGridNodes
		// List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = new List<PrintedMedicalRecordBase>{
		//     PrintedMedicalRecordFactory.createHandler('Patient_Note__c', patientId, requestId, admissionId),
		//     PrintedMedicalRecordFactory.createHandler('disco__Form__c', patientId, requestId, admissionId)
		// };
		List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = createMedicalRecordHandlers(patientId, requestId, admissionId);
		String selectedAdmissions = '';
		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
			selectedAdmissions = base.selectedAdmissions;
		}
		MAP<String, String> noteDefinitionRecTypeMap = new Map<String, String>();
		for (Note_Definition__mdt noteDefinition : [SELECT Id, DeveloperName, Active__c, Note_Label__c, Med_Records_Document_Type__r.DeveloperName FROM Note_Definition__mdt WITH SECURITY_ENFORCED]) {
			noteDefinitionRecTypeMap.put(noteDefinition.Med_Records_Document_Type__r.DeveloperName, noteDefinition.Note_Label__c);
		}
		List<String> allSelectedRows = new List<String>();
		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
			base.collectAvailableMedicalRecords();
			base.collectSelectedMedicalRecords();
			if (base.selectedMedicalRecords != null) {
				allSelectedRows.addAll(base.selectedMedicalRecords);
				for (TreeGridNode level1 : allTreeGridNodes) {
					if (level1.children != null) {
						for (TreeGridNode level2 : level1.children) {
							if (base.availableMedicalRecords.containsKey(level2.developerName)) {
								level2 = base.assignDocumentRecord(level2);
								//break;
							}
						}
					}
				}
			}
		}
		// Map<String, List<TreeGridNode>> docTye2PatientNode = MedRecordUtils.collectAvailablePatientNoteMedicalRecords(patientId, requestId);
		// List<String> selectedPatientNodeRows = MedRecordUtils.collectSelectedPatientNoteMedicalRecords(patientId, requestId);
		// Map<String, List<TreeGridNode>> docTye2Form = MedRecordUtils.collectAvailableYourekaFormMedicalRecords(patientId, requestId);
		// List<String> selectedFormRows = MedRecordUtils.collectSelectedYourekaFormMedicalRecords(patientId, requestId);

		// for(TreeGridNode level1 : allTreeGridNodes) {
		//     if(level1.children != null) {
		//         for(TreeGridNode level2: level1.children) {
		//             if(docTye2Form.containsKey(level2.developerName)) {
		//                 level2.children=docTye2Form.get(level2.developerName);
		//                 level2.sObjectName = 'disco__Form__c';
		//                 level2.name = level2.developerName+';'+level2.sObjectName+';'+patientId;
		//             } else if(docTye2PatientNode.containsKey(level2.developerName)) {
		//                 level2.children=docTye2PatientNode.get(level2.developerName);
		//                 level2.sObjectName = 'Patient_Note__c';
		//                 level2.name = noteDefinitionRecTypeMap.get(level2.developerName)+';'+level2.sObjectName+';'+patientId;
		//             }
		//         }
		//     }
		// }
		// List<String> allSelectedRows = new List<String>(selectedPatientNodeRows);
		// allSelectedRows.addAll(selectedFormRows);

		// List<Admission__c> admissions = [SELECT Id, Admit_Date__c, Discharge_Date__c, Stage__c, Patient_Account__c
		//                     FROM Admission__c
		//                     WHERE Stage__c IN ('Admitted','Discharged') AND Patient_Account__c = :patientId
		//                     AND Admit_Date__c != null
		//                     WITH SECURITY_ENFORCED ORDER BY Admit_Date__c DESC];
		// List<TreeGridNode.Option> admissionOptions = new List<TreeGridNode.Option>();
		// for(Admission__c adm : admissions) {
		//     String label ='';
		//     String value = adm.Id;
		//     label = formatDate(adm.Admit_Date__c, 'MM/dd/yyyy');
		//     if(adm.Discharge_Date__c != null) {
		//         label += ' - ' + formatDate(adm.Discharge_Date__c, 'MM/dd/yyyy');
		//     }
		//     admissionOptions.add(new TreeGridNode.Option(label, value));
		// }
		TreeGridNode.TreeNodeResult result = new TreeGridNode.TreeNodeResult();
		result.allTreeNodes = JSON.serialize(allTreeGridNodes);
		result.selectedRows = JSON.serialize(allSelectedRows);
		result.selectedAdmissions = selectedAdmissions;
		return result;
	}
	private static String formatDate(Date input, String format) {
		Datetime output = input;
		return output.formatGmt(format);
	}
	// @AuraEnabled(cacheable=true)
	// public static String getAllTreeGridNodes(String patientId)
	// {
	//     List<TreeGridNode> treeNodes = buildAllTreeNodesWithLeafCount(patientId);
	//     return JSON.serialize(treeNodes);

	// }
	// private static List<TreeGridNode> buildAllTreeNodesWithLeafCount(String patientId) {
	//     if(allTreeGridNodes == null) {
	//         //build top two levels tree nodes
	//         // - Category - Med_Records_Category__mdt
	//         // - Document Type - Med_Records_Document_Type__mdt
	//         buildCategoryAndDocumentTypeNodes();
	//     }

	//     //Patient Note's Type__c is mapped to Note Definition's Note_Label__c, and in turn the Note Definition's Med_Records_Document_Type__r.DeveloperName
	//     //is mapped to Med_Records_Document_Type__mdt.DeveloperName.
	//     MAP<String, String> noteDefinitionRecTypeMap = new MAP<String, String>();
	//     for(Note_Definition__mdt noteDefinition : [SELECT Id, DeveloperName, Active__c, Note_Label__c, Med_Records_Document_Type__r.DeveloperName
	//                                                         FROM Note_Definition__mdt]) {
	//         noteDefinitionRecTypeMap.put(noteDefinition.Note_Label__c, noteDefinition.Med_Records_Document_Type__r.DeveloperName);
	//     }

	//     MAP<String, Integer> formChildrenCountMap = new MAP<String, Integer>();
	//     for(disco__Form__c form : [SELECT Id, disco__Form_Template__r.DocType_Name__c, Master_Date__c
	//                                         FROM disco__Form__c
	//                                         WHERE disco__Form_Account__c = :patientId]) {
	//         if(!formChildrenCountMap.containsKey(form.disco__Form_Template__r.DocType_Name__c)) {
	//             formChildrenCountMap.put(form.disco__Form_Template__r.DocType_Name__c, 0);
	//         }
	//         formChildrenCountMap.put(form.disco__Form_Template__r.DocType_Name__c, formChildrenCountMap.get(form.disco__Form_Template__r.DocType_Name__c)+1);
	//     }

	//     Map<String, String> patientNoteTypeMap = new Map<String, String>();
	//         //SELECT count(Id), Type__c FROM Patient_Note__c where Account__c = '0012i00000XtUSAAA3' group by Type__c
	//     MAP<String, Integer> noteChildrenCountMap = new MAP<String, Integer>();
	//     AggregateResult[] nodeGroupedResults = [SELECT count(Id), Type__c
	//                                         FROM Patient_Note__c
	//                                         WHERE Account__c = :patientId
	//                                         AND Status__c = 'Finalized'
	//                                         GROUP BY Type__c];
	//     for (AggregateResult ar : nodeGroupedResults)  {
	//         String dt = String.valueOf(ar.get('Type__c'));
	//         String docTypeKey = noteDefinitionRecTypeMap.containsKey(dt) ? noteDefinitionRecTypeMap.get(dt) : dt;
	//         noteChildrenCountMap.put(docTypeKey, Integer.valueOf(ar.get('expr0')));
	//         patientNoteTypeMap.put(docTypeKey, dt);
	//     }

	//     for(TreeGridNode category : allTreeGridNodes) {
	//         if(category.children != null) {
	//             for(TreeGridNode docType: category.children) {
	//                 if(formChildrenCountMap.containsKey(docType.developerName)) {
	//                     docType.childrenCount=formChildrenCountMap.get(docType.developerName);
	//                     docType.sObjectName = 'disco__Form__c';
	//                     docType.name = docType.developerName+';'+docType.sObjectName+';'+patientId;
	//                 } else if(noteChildrenCountMap.containsKey(docType.developerName)) {
	//                     docType.childrenCount=noteChildrenCountMap.get(docType.developerName);
	//                     docType.sObjectName = 'Patient_Note__c';
	//                     docType.name = patientNoteTypeMap.get(docType.developerName)+';'+docType.sObjectName+';'+patientId;
	//                 }
	//             }
	//         }
	//     }
	//     return allTreeGridNodes;
	// }
	private static void buildCategoryAndDocumentTypeNodes() {
		Map<Id, Med_Records_Category__mdt> mapIdToMedRecCategories = new Map<Id, Med_Records_Category__mdt>();

		for (Med_Records_Category__mdt objMedRecCat : queryCategories()) {
			mapIdToMedRecCategories.put(objMedRecCat.Id, objMedRecCat);
		}

		Map<Id, List<Med_Records_Document_Type__mdt>> mapIdToMedRecCategoriesDocument = new Map<Id, List<Med_Records_Document_Type__mdt>>();
		for (Med_Records_Document_Type__mdt objMedRecCatDoc : queryDocTypes()) {
			if (mapIdToMedRecCategoriesDocument.containsKey(objMedRecCatDoc.Category__c)) {
				mapIdToMedRecCategoriesDocument.get(objMedRecCatDoc.Category__c).add(objMedRecCatDoc);
			} else {
				mapIdToMedRecCategoriesDocument.put(objMedRecCatDoc.Category__c, new List<Med_Records_Document_Type__mdt>{ objMedRecCatDoc });
			}
		}

		allTreeGridNodes = new List<TreeGridNode>();
		for (Med_Records_Category__mdt medCat : mapIdToMedRecCategories.values()) {
			if (medCat.Active__c) {
				TreeGridNode level1TreeGridNode = new TreeGridNode();
				level1TreeGridNode.isDisplayed = medCat.Active__c;
				level1TreeGridNode.sfId = medCat.Id;
				level1TreeGridNode.url = 'javascript:;';
				level1TreeGridNode.nodeName = medCat.Name__c;
				level1TreeGridNode.name = 'L1_' + medCat.Name__c;
				level1TreeGridNode.sequence = Integer.valueOf(medCat.Sort_Order__c);

				List<MedRecordHierarchy.DocType> lstDocType = new List<MedRecordHierarchy.DocType>();
				List<TreeGridNode> treeNodeChildren = new List<TreeGridNode>();
				if (mapIdToMedRecCategoriesDocument.containsKey(medCat.Id)) {
					for (Med_Records_Document_Type__mdt objMedDoc : mapIdToMedRecCategoriesDocument.get(medCat.Id)) {
						if (objMedDoc.Active__c) {
							TreeGridNode level2TreeGridNode = new TreeGridNode();
							level2TreeGridNode.isDisplayed = objMedDoc.Active__c;
							level2TreeGridNode.sfId = objMedDoc.Id;
							level2TreeGridNode.url = 'javascript: void(0)';
							level2TreeGridNode.nodeName = objMedDoc.Name__c;
							level2TreeGridNode.developerName = objMedDoc.developerName;
							level2TreeGridNode.name = objMedDoc.Name__c;
							if (medCat.Sort_Order__c != null && objMedDoc.Sort_Order__c != null) {
								level2TreeGridNode.sequence = Integer.valueOf(medCat.Sort_Order__c * 100 + objMedDoc.Sort_Order__c);
							}
							treeNodeChildren.add(level2TreeGridNode);
						}
					}
					level1TreeGridNode.children = treeNodeChildren;
				}
				allTreeGridNodes.add(level1TreeGridNode);
			}
		}
		//allTreeGridNodes.sort();
	}

	private static void buildAllCategories() {
		Map<Id, Med_Records_Category__mdt> mapIdToMedRecCategories = new Map<Id, Med_Records_Category__mdt>();

		for (Med_Records_Category__mdt objMedRecCat : queryCategories()) {
			mapIdToMedRecCategories.put(objMedRecCat.Id, objMedRecCat);
		}

		/* Map<Id, List<Med_Records_Category__mdt>> mapIdToMedRecCategories = new Map<Id, List<Med_Records_Category__mdt>>();
        for(Med_Records_Category__mdt objMedRecCat : queryCategories()){
            if(mapIdToMedRecCategories.containsKey(objMedRecCat.Chart__c)){
              mapIdToMedRecCategories.get(objMedRecCat.Chart__c).add(objMedRecCat);
            }
            else{
                mapIdToMedRecCategories.put(objMedRecCat.Chart__c,new List<Med_Records_Category__mdt>{objMedRecCat});
            }

        }*/

		Map<Id, List<Med_Records_Document_Type__mdt>> mapIdToMedRecCategoriesDocument = new Map<Id, List<Med_Records_Document_Type__mdt>>();
		for (Med_Records_Document_Type__mdt objMedRecCatDoc : queryDocTypes()) {
			if (mapIdToMedRecCategoriesDocument.containsKey(objMedRecCatDoc.Category__c)) {
				mapIdToMedRecCategoriesDocument.get(objMedRecCatDoc.Category__c).add(objMedRecCatDoc);
			} else {
				mapIdToMedRecCategoriesDocument.put(objMedRecCatDoc.Category__c, new List<Med_Records_Document_Type__mdt>{ objMedRecCatDoc });
			}
		}

		List<MedRecordHierarchy.Category> lstCategories = new List<MedRecordHierarchy.Category>();
		for (Med_Records_Category__mdt medCat : mapIdToMedRecCategories.values()) {
			MedRecordHierarchy.Category objCat = new MedRecordHierarchy.Category();
			objCat.Obj = medCat;
			objCat.isDisplayed = medCat.Active__c;

			List<MedRecordHierarchy.DocType> lstDocType = new List<MedRecordHierarchy.DocType>();
			if (mapIdToMedRecCategoriesDocument.containsKey(medCat.Id)) {
				for (Med_Records_Document_Type__mdt objMedDoc : mapIdToMedRecCategoriesDocument.get(medCat.Id)) {
					MedRecordHierarchy.DocType objDoc = new MedRecordHierarchy.DocType();
					objDoc.Obj = objMedDoc;
					objDoc.isDisplayed = objMedDoc.Active__c;
					lstDocType.add(objDoc);
				}
			}
			objCat.docTypes = lstDocType;
			lstCategories.add(objCat);
		}

		allCategories = lstCategories;
	}
	/*private static List<Med_Records_Chart__mdt > queryCharts(){
        return [SELECT Active__c,Id,Name__c,Sort_Order__c FROM Med_Records_Chart__mdt ORDER BY Sort_Order__c];
    }*/
	private static List<Med_Records_Category__mdt> queryCategories() {
		return [SELECT Active__c, Id, Name__c, Sort_Order__c FROM Med_Records_Category__mdt WHERE Active__c = TRUE ORDER BY Sort_Order__c];
	}
	private static List<Med_Records_Document_Type__mdt> queryDocTypes() {
		return [SELECT Active__c, Category__c, Id, Name__c, Sort_Order__c, Flow_Name__c, SObject_Name__c, Creatable__c, DeveloperName FROM Med_Records_Document_Type__mdt WHERE Active__c = TRUE ORDER BY Sort_Order__c];
	}

	/*public class Chart implements ChildMarker{
       Med_Records_Chart__mdt obj;
       List<Category> categories;
       Boolean isDisplayed = true;

    }*/
	public class Category {
		Med_Records_Category__mdt obj;
		List<DocType> docTypes;
		Boolean isDisplayed = true;
	}
	public class DocType {
		Med_Records_Document_Type__mdt obj;
		Boolean isDisplayed = true;
	}

	@AuraEnabled(cacheable=true)
	public static TreeGridNode.TreeNodeResult retrieveRecordsInDateRange(String patientId, String fromDate, String toDate, Boolean searchFinalizedDate, String admissionId) {
		Date dateFrom = Date.valueOf(fromDate + ' 00:00:00');
		Date dateTo = Date.valueOf(toDate + ' 00:00:00');

		if (allTreeGridNodes == null) {
			buildCategoryAndDocumentTypeNodes();
		}

		//allTreeGridNodes
		// List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = new List<PrintedMedicalRecordBase>{
		//     PrintedMedicalRecordFactory.createHandler('Patient_Note__c', patientId, null, admissionId),
		//     PrintedMedicalRecordFactory.createHandler('disco__Form__c', patientId, null, admissionId)
		// };
		List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = createMedicalRecordHandlers(patientId, null, admissionId);
		MAP<String, String> noteDefinitionRecTypeMap = new Map<String, String>();
		for (Note_Definition__mdt noteDefinition : [SELECT Id, DeveloperName, Active__c, Note_Label__c, Med_Records_Document_Type__r.DeveloperName FROM Note_Definition__mdt WITH SECURITY_ENFORCED]) {
			noteDefinitionRecTypeMap.put(noteDefinition.Med_Records_Document_Type__r.DeveloperName, noteDefinition.Note_Label__c);
		}
		List<String> allSelectedRows = new List<String>();
		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
			base.dateFrom = dateFrom;
			base.dateTo = dateTo;
			base.searchFinalizedDate = searchFinalizedDate;

			base.collectAvailableMedicalRecords();
			base.collectSelectedMedicalRecordsInDateRange();
			if (base.selectedMedicalRecordsInDateRange != null) {
				allSelectedRows.addAll(base.selectedMedicalRecordsInDateRange);
			}
			for (TreeGridNode level1 : allTreeGridNodes) {
				if (level1.children != null) {
					for (TreeGridNode level2 : level1.children) {
						if (base.availableMedicalRecords.containsKey(level2.developerName)) {
							level2 = base.assignDocumentRecord(level2);
							//break;
						}
					}
				}
			}
		}

		TreeGridNode.TreeNodeResult result = new TreeGridNode.TreeNodeResult();
		result.allTreeNodes = JSON.serialize(allTreeGridNodes);
		result.selectedRows = JSON.serialize(allSelectedRows);
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static String retrieveRecordsToPrint(String docName, String sObjName, String patientId, String admissionId) {
		// List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = new List<PrintedMedicalRecordBase>{
		//     PrintedMedicalRecordFactory.createHandler('Patient_Note__c', patientId, null, admissionId),
		//     PrintedMedicalRecordFactory.createHandler('disco__Form__c', patientId, null, admissionId)
		// };
		List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = createMedicalRecordHandlers(patientId, null, admissionId);
		List<TreeGridNode> items = new List<TreeGridNode>();

		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
			items.addAll(base.findMedicalRecordsForDocumentType(docName));
		}
		items.sort();

		return JSON.serialize(items);
	}

	@AuraEnabled
	public static String savePrintedMedicalRecord(String patientId, String documentObjsTxt, String requestId, String admissionId) {
		Map<String, PrintedMedicalRecordBase> printedMedicalRecordHandlerMap = new Map<String, PrintedMedicalRecordBase>();
		List<PrintedMedicalRecordBase> printedMedicalRecordHandlers = createMedicalRecordHandlers(patientId, requestId, admissionId);
		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlers) {
			printedMedicalRecordHandlerMap.put(base.getSObjectName(), base);
		}
		// Map<String, PrintedMedicalRecordBase> printedMedicalRecordHandlers = new Map<String, PrintedMedicalRecordBase>{
		//     'Patient_Note__c' =>PrintedMedicalRecordFactory.createHandler('Patient_Note__c', patientId, requestId, admissionId),
		//     'disco__Form__c' => PrintedMedicalRecordFactory.createHandler('disco__Form__c', patientId, requestId, admissionId)
		// };
		List<String> documentObjs = (List<String>) JSON.deserialize(documentObjsTxt, List<String>.class);
		Set<String> insertMRs = new Set<String>(documentObjs);

		Set<String> deleteRecords = new Set<String>();
		for (PrintedMedicalRecordBase base : printedMedicalRecordHandlerMap.values()) {
			List<String> selectedRows = base.collectSelectedMedicalRecords();
			for (String rec : selectedRows) {
				if (!documentObjs.contains(rec)) {
					deleteRecords.add(rec);
				}
			}
		}

		Savepoint sp = Database.setSavepoint();
		try {
			MedRecordUtils.createNewMedicalRecords(printedMedicalRecordHandlerMap, insertMRs, requestId);
			MedRecordUtils.deleteMedicalRecords(patientId, deleteRecords, requestId);
			//deleteMedicalRecords(patientId, deleteRecords, requestId);
		} catch (Exception e) {
			system.debug(e.getMessage());
			Database.rollback(sp);
		}
		return requestId;
	}
	@AuraEnabled
	public static String savePDFUrl(String requestId, String pdfUrl) {
		Printed_Medical_Record_Request__c request = new Printed_Medical_Record_Request__c(Id = requestId, Printed_Medical_Record_PDF__c = pdfUrl);
		update request;
		return request.Id;
	}
	/*******************************************************************************************************
	 * @description Returns a Printed_Medical_Included_Record__c Id
	 * @param patientId the Salesforce Id of the patient
	 * @param documentObjsTxt the serialized medical records associated with an instance of Printed_Medical_Included_Record__c
	 * @return the Salesforce Id of an instance of a Printed_Medical_Included_Record__c
	 */
	// @AuraEnabled
	// public static String createPrintJob(String patientId, String documentObjsTxt, String requestId) {
	//     List<String> documentObjs = (List<String>)JSON.deserialize(documentObjsTxt, List<String>.class);

	//     List<SDoc_Junction__c> sDocJunctions = new List<SDoc_Junction__c>();
	//     List<Printed_Medical_Included_Record__c> includedObjs = new List<Printed_Medical_Included_Record__c>();
	//     Printed_Medical_Record_Request__c pmrRequest = new Printed_Medical_Record_Request__c(Patient_Account__c = patientId);
	//     if(Schema.sObjectType.Printed_Medical_Record_Request__c.fields.Patient_Account__c.isCreateable()) {
	//         insert pmrRequest;
	//     }
	//     for(String s : documentObjs) {
	//         String[] parts = s.split(';');
	//         String docType = parts[1];
	//         String objId = parts[2];
	//         String sObjName = parts[3];
	//         SDoc_Junction__c junction = new SDoc_Junction__c(Object_SF_Id__c = pmrRequest.Id+objId);
	//         switch on sObjName {
	//             when 'disco__Form__c' {
	//                 junction.Youreka_Form__c = objId;
	//             }
	//             // when 'EGO__c' {

	//             // }
	//             when 'Patient_Note__c' {
	//                 junction.Patient_Note__c = objId;
	//             }
	//             // when 'Case' {

	//             // }
	//         }
	//         sDocJunctions.add(junction);
	//         includedObjs.add(new Printed_Medical_Included_Record__c(Printed_Medical_Record_Request__c=pmrRequest.Id,
	//                             Document_Type__c = docType,
	//                             SDoc_Junction__r=new SDoc_Junction__c(Object_SF_Id__c=pmrRequest.Id+objId)));
	//     }
	//     if(Schema.sObjectType.SDoc_Junction__c.fields.Object_SF_Id__c.isCreateable()) {
	//         insert sDocJunctions;
	//     }
	//     if(Schema.sObjectType.Printed_Medical_Included_Record__c.fields.Printed_Medical_Record_Request__c.isCreateable()) {
	//         insert includedObjs;
	//     }
	//     return pmrRequest.Id;
	// }
}