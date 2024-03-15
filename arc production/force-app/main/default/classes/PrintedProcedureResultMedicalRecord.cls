public with sharing class PrintedProcedureResultMedicalRecord extends PrintedMedicalRecordBase {
	public PrintedProcedureResultMedicalRecord() {
		super();
	}

	public override String getSDocJunctionLookupField() {
		return 'Procedure_Result__c';
	}
	public override String getSObjectName() {
		return 'Procedure_Result__c';
	}

	public override String formatLevel2Name(TreeGridNode level2) {
		// return noteDefinitionRecTypeMap.get(level2.developerName)+';'+level2.sObjectName+';'+patientId;
		return null;
	}
	public override String formatLevel3Name(SObject sObj) {
		// Case note = (Case) sObj;
		// return note.CaseNumber +';Treatment_Plan;'+note.Id+';Case';
		return null;
	}

	public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords() {
		// Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();
		// List<Case > cases = [ SELECT Id , CaseNumber, AccountId , Account.Name, Type , Status , Admission__c , Finalized_By__c ,
		//                             Finalized_Date_Time__c , Finalized_By_User__c , Finalized_By_Professional_Name__c , CreatedDate
		//                             FROM Case
		//                             WHERE AccountId = :patientId
		//                             AND Admission__c in :admissionIdList AND Status = 'Finalized'
		//                             WITH SECURITY_ENFORCED
		//                             ORDER BY CreatedDate desc];
		// for(Case aCase : cases) {
		//     if(!treeGridMap.containsKey('Treatment_Plan')) {
		//         treeGridMap.put('Treatment_Plan', new List<TreeGridNode>());
		//     }
		//     TreeGridNode tg = new TreeGridNode();
		//     tg.sfID = aCase.Id;
		//     tg.contactDate = aCase.CreatedDate;
		//     tg.url = '/'+aCase.Id;
		//     tg.name = formatLevel3Name(aCase);
		//     tg.nodeName = aCase.CaseNumber;
		//     tg.developerName = 'Treatment_Plan';
		//     tg.finalizedDatetime = aCase.Finalized_Date_Time__c;
		//     tg.finalizedBy = aCase.Finalized_By_Professional_Name__c;
		//     List<TreeGridNode> caseItems = treeGridMap.get('Treatment_Plan');
		//     caseItems.add(tg);
		// }
		// availableMedicalRecords = treeGridMap;
		// return treeGridMap;
		return null;
	}
	public override List<String> collectSelectedMedicalRecords() {
		// List<Printed_Medical_Included_Record__c> includedObjects =[
		//                 SELECT SDoc_Junction__r.Treatment_Plan__r.Id, SDoc_Junction__r.Treatment_Plan__r.CaseNumber,
		//                     SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c,SDoc_Junction__r.Treatment_Plan__r.CreatedDate,
		//                     SDoc_Junction__r.Treatment_Plan__r.Finalized_By_User__r.Professional_Name__c, Sort_Order__c
		//                 FROM Printed_Medical_Included_Record__c
		//                 WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Treatment_Plan__c != null
		//                     AND SDoc_Junction__r.Treatment_Plan__r.Status = 'Finalized' WITH SECURITY_ENFORCED
		//                 ORDER BY SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c DESC];

		// List<String> selectedRows = new List<String>();
		// for(Printed_Medical_Included_Record__c r : includedObjects) {
		//     Case note = r.SDoc_Junction__r.Treatment_Plan__r;
		//     String itemName = formatLevel3Name(note);
		//     selectedRows.add(itemName);
		// }
		// selectedMedicalRecords = selectedRows;
		// return selectedRows;
		return null;
	}

	public override List<String> collectSelectedMedicalRecordsInDateRange() {
		// List<String> selectedRows = new List<String>();
		// String casesQueryFormat = 'SELECT {0} FROM Case WHERE AccountId = :patientId AND Status = \'Finalized\' AND Admission__c in :admissionIdList AND {1} >= :dateFrom AND {1} <= :dateTo ORDER by {1}';
		// String casesQueryFields = 'Id , CaseNumber, AccountId , Account.Name, Type , Status , Admission__c , Finalized_By__c , ' +
		//                             'Finalized_Date_Time__c , Finalized_By_User__c , Finalized_By_Professional_Name__c , CreatedDate';
		// String casesQueryDateField = searchFinalizedDate ? 'Finalized_Date_Time__c' : 'CreatedDate';
		// String casesQuery = String.format(casesQueryFormat, new List<String> {casesQueryFields, casesQueryDateField});
		// List<Case> cases = Database.query(casesQuery);

		// for(Case aCase : cases) {
		//     selectedRows.add(formatLevel3Name(aCase));
		// }
		// selectedMedicalRecordsInDateRange = selectedRows;
		// return selectedRows;
		return null;
	}
	public override List<TreeGridNode> findMedicalRecordsForDocumentType(String docName) {
		// List<TreeGridNode> items = new List<TreeGridNode>();
		// if(docName == 'Treatment_Plan') {
		//     List<Case> caseList = [SELECT Id , CaseNumber, AccountId , Account.Name, Type , Status , Admission__c , Finalized_By__c ,
		//     Finalized_Date_Time__c , Finalized_By_User__c , Finalized_By_Professional_Name__c , CreatedDate
		//             FROM Case
		//             WHERE AccountId = :patientId AND Status = 'Finalized'
		//             WITH SECURITY_ENFORCED];

		//     for(Case aCase : caseList) {
		//     TreeGridNode tg = new TreeGridNode();
		//     tg.sfID = aCase.Id;
		//     tg.url = '/'+aCase.Id;
		//     tg.contactDate = aCase.CreatedDate;
		//     tg.name = formatLevel3Name(aCase);
		//     tg.nodeName = aCase.CaseNumber;
		//     tg.finalizedDatetime = aCase.Finalized_Date_Time__c;
		//     tg.finalizedBy = aCase.Finalized_By_Professional_Name__c;
		//     tg.children = null;
		//     tg.childrenCount =0;
		//     items.add(tg);
		//     }
		// }
		// return items;
		return null;
	}

	public override List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs() {
		// List<TreeGridNode.PrintedIncludedObject> includedObjects = new List<TreeGridNode.PrintedIncludedObject>();
		// for(Printed_Medical_Included_Record__c pmir : [SELECT SDoc_Junction__r.Treatment_Plan__r.Snapshot__r.Html__c, SDoc_Junction__r.Treatment_Plan__r.CreatedDate,
		//                  Sort_Order__c, SDoc_Junction__r.Treatment_Plan__r.Finalized_Date_Time__c
		//             FROM Printed_Medical_Included_Record__c
		//             WHERE Printed_Medical_Record_Request__c = :requestId AND SDoc_Junction__r.Treatment_Plan__c != null
		//             AND SDoc_Junction__r.Treatment_Plan__r.Status = 'Finalized'
		//             WITH SECURITY_ENFORCED
		//             ORDER BY Sort_Order__c]
		//             ) {
		//     Integer sortSequence = SDocsYourekaUtils.calculateSortingSequence('Treatment_Plan');
		//     TreeGridNode.PrintedIncludedObject includedObject = new TreeGridNode.PrintedIncludedObject('Treatment_Plan',
		//                                                                         pmir.SDoc_Junction__r.Treatment_Plan__r.Snapshot__r.Html__c,
		//                                                                         sortSequence);
		//     includedObject.finalizedTime = pmir.SDoc_Junction__r.Treatment_Plan__r.CreatedDate;
		//     includedObjects.add(includedObject);
		// }

		// return includedObjects;
		return null;
	}

	public static final List<String> PROCEDURE_ORDER_FIELDS = new List<String>{ 'Id', 'Name', 'Completed_Date_Time__c', 'Patient_Name__c', 'Completed_By_Name__c', 'Finalized_By__c', 'Finalized_By_User__c', 'Finalized_Date_Time__c' };
	public static final List<String> LAB_OBSERVATION_RESULT_FIELDS = new List<String>{ 'Id', 'Name', 'Sequence__c', 'Placer_Number__c', 'Filler_Number__c', 'Result_Status__c', 'Ordered_Code__c', 'Ordered_Desc__c', 'Collection_Datetime__c', 'Collection_End_Datetime__c', 'Specimen_Received_Datetime__c', 'Ordering_Doctor_Id__c', 'Ordering_Doctor_Last_Name__c', 'Ordering_Doctor_First_Name__c' };
	public static final List<String> LAB_RESULT_ITEM_FIELDS = new List<String>{ 'Id', 'Name', 'Procedure_Order__c', 'Sequence__c', 'Value_Type__c', 'Observation_Id__c', 'Observation_Desc__c', 'Observation_Sub_Id__c', 'Observation_Result__c', 'Units__c', 'Reference_Range__c', 'Collection_DateTime__c', 'Site_Mnemonic__c' };

	public static String convert(Id procedureResultId) {
		Procedure_Result__c pResult = [
			SELECT
				Id,
				Procedure_Order__c,
				Procedure_Order__r.Id,
				Procedure_Order__r.Name,
				Procedure_Order__r.Activation_Date__c,
				Procedure_Order__r.Order_Provider_Name__c,
				Procedure_Order__r.RecordType.Name,
				Procedure_Order__r.Completed_Date_Time__c,
				Procedure_Order__r.Patient_Name__c,
				Procedure_Order__r.Completed_By_Name__c,
				Procedure_Order__r.Finalized_By__c,
				Procedure_Order__r.Finalized_By_User__c,
				Procedure_Order__r.Indication__c,
				Procedure_Order__r.MD_Comments__c,
				Procedure_Order__r.Finalized_Date_Time__c,
				(
					SELECT
						Id,
						Name,
						Procedure_Order__c,
						Sequence__c,
						Value_Type__c,
						Observation_Id__c,
						Observation_Desc__c,
						Observation_Sub_Id__c,
						Observation_Result__c,
						Units__c,
						Reference_Range__c,
						Collection_DateTime__c,
						Site_Mnemonic__c,
						Lab_Observation_Result__c,
						Patient_Name__c,
						Observation_Result_Status__c,
						External_Id__c,
						Comment__c,
						Abnormal_Flags__c,
						Lab_Observation_Result__r.Id,
						Lab_Observation_Result__r.Name,
						Lab_Observation_Result__r.Sequence__c,
						Lab_Observation_Result__r.Placer_Number__c,
						Lab_Observation_Result__r.Filler_Number__c,
						Lab_Observation_Result__r.Result_Status__c,
						Lab_Observation_Result__r.Ordered_Code__c,
						Lab_Observation_Result__r.Ordered_Desc__c,
						Lab_Observation_Result__r.Collection_Datetime__c,
						Lab_Observation_Result__r.Collection_End_Datetime__c,
						Lab_Observation_Result__r.Specimen_Received_Datetime__c,
						Lab_Observation_Result__r.Ordering_Doctor_Id__c,
						Lab_Observation_Result__r.Ordering_Doctor_Last_Name__c,
						Lab_Observation_Result__r.Ordering_Doctor_First_Name__c,
						Lab_Observation_Result__r.Lab_Observation__r.query__c,
						Lab_Observation_Result__r.Lab_Observation__r.query_answer__c
					FROM Lab_Result_Items__r
					ORDER BY Sequence__c
				)
			FROM Procedure_Result__c
			WHERE Id = :procedureResultId
		];
		Procedure_Order__c po = pResult.Procedure_Order__r;
		Map<String, Schema.SObjectField> procedureOrderFieldMap = Procedure_Order__c.getSobjectType().getDescribe().fields.getMap();
		Map<String, Schema.SObjectField> observationResultFieldMap = Lab_Observation_Result__c.getSobjectType().getDescribe().fields.getMap();
		Map<String, Schema.SObjectField> labResultItemFieldMap = Lab_Result_Item__c.getSobjectType().getDescribe().fields.getMap();
		Patient patient = new Patient(po, procedureOrderFieldMap, PROCEDURE_ORDER_FIELDS);

		Map<Id, Lab_Observation_Result__c> observationResultMap = new Map<Id, Lab_Observation_Result__c>();
		Map<Id, List<Lab_Result_Item__c>> resultItemsMap = new Map<Id, List<Lab_Result_Item__c>>();
		List<Lab_Result_Item__c> itemList = pResult.Lab_Result_Items__r;
		for (Lab_Result_Item__c item : itemList) {
			Lab_Observation_Result__c r = item.Lab_Observation_Result__r;
			observationResultMap.put(r.Id, r);
			if (!resultItemsMap.containsKey(r.Id)) {
				resultItemsMap.put(r.Id, new List<Lab_Result_Item__c>());
			}
			List<Lab_Result_Item__c> ilist = resultItemsMap.get(r.Id);
			ilist.add(item);
		}

		List<OBR> obrList = new List<OBR>();
		for (Lab_Observation_Result__c result : observationResultMap.values()) {
			OBR obr = new OBR(result, observationResultFieldMap, LAB_OBSERVATION_RESULT_FIELDS);
			List<Lab_Result_Item__c> resultItems = resultItemsMap.get(result.Id);
			List<OBX> obxList = new List<OBX>();
			for (Lab_Result_Item__c item : resultItems) {
				OBX obx = new OBX(item, labResultItemFieldMap, LAB_RESULT_ITEM_FIELDS);
				obxList.add(obx);
			}
			obr.obxList = obxList;
			obrList.add(obr);
		}
		patient.obrList = obrList;
		return patient.toHtml();
	}
	// public static String convertToHtml(String caption, SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
	//     String html = '<h2>' + caption + '</h2><br/>';
	//     html += '<table width="60%">';
	//     for(String s : fieldList) {
	//         Schema.SObjectField field = fieldMap.get(s);
	//         Schema.DescribeFieldResult dfr = field.getDescribe();
	//         String label = dfr.getLabel();
	//         String value = (obj!=null && obj.get(s) != null) ? String.valueOf(obj.get(s)) : '';
	//         if(String.isNotBlank(value)) {
	//             html += '<tr><td width="40%">' + label + '</td><td width="20%">' + value + '</td></tr>';
	//         }
	//     }
	//     html += '</table><br/>';
	//     return html;
	// }

	public virtual class ConverterBase {
		protected SObject sObj;
		protected Map<String, Schema.SObjectField> fieldMap;
		protected List<String> fieldList;
		public ConverterBase(SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
			this.sObj = obj;
			this.fieldMap = fieldMap;
			this.fieldList = fieldList;
		}

		public virtual String toHtml() {
			Map<String, Schema.SObjectField> procedureOrderFieldMap = Procedure_Order__c.getSobjectType().getDescribe().fields.getMap();
			String html = '<table width="60%">';
			for (String s : fieldList) {
				Schema.SObjectField field = this.fieldMap.get(s);
				if (field != null) {
					Schema.DescribeFieldResult dfr = field.getDescribe();
					String label = dfr.getLabel();
					String value = (sObj != null && sObj.get(s) != null) ? String.valueOf(sObj.get(s)) : '';
					if (String.isNotBlank(value)) {
						html += '<tr><td width="40%">' + label + '</td><td width="20%">' + value + '</td></tr>';
					}
				}
			}
			html += '</table><br/>';
			return html;
		}
	}
	public class OBX extends ConverterBase implements Comparable {
		public OBX(SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
			super(obj, fieldMap, fieldList);
		}
		public override String toHtml() {
			String html = '<div class="obx-section">';
			String html2 = '<table><tr><th>Description</th><th>Abnormal</th><th>Result</th><th>Units</th><th>Range</th></tr>';
			html += super.toHtml();
			html += '</div>';
			return html;
		}
		public Integer compareTo(Object compareTo) {
			return 0;
		}
	}

	public class OBR extends ConverterBase implements Comparable {
		public List<OBX> obxList { get; set; }
		public OBR(SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
			super(obj, fieldMap, fieldList);
			obxList = new List<OBX>();
		}
		public override String toHtml() {
			String html = '<div class="obr-section-block">';
			Lab_Observation_Result__c result = (Lab_Observation_Result__c) this.sObj;
			html += '<table class="obr-section"><tr><td>Ordered: ' + result.Ordered_Desc__c + '</td><td>Collected: ' + result.Collection_Datetime__c?.format('MM/dd/yyyy', 'America/New_York') + '</td></tr>';
			if (String.isNotBlank(result.Lab_Observation__r.query__c) && String.isNotBlank(result.Lab_Observation__r.query_answer__c)) {
				html += '<tr><td>' + result.Lab_Observation__r.query__c + '/' + result.Lab_Observation__r.query_answer__c + '</td><td></td></tr>';
			}

			html += '<tr><td></td><td></td></tr>';
			html += '</table>';
			String obx_html = '<div class="obx-section">';
			obx_html += '<table width="100%"><tr><th>Test</th><th>Flag</th><th>Result</th><th>Reference</th></tr>';
			for (OBX obx : obxList) {
				Lab_Result_Item__c item = (Lab_Result_Item__c) obx.sObj;
				obx_html += '<tr>';
				obx_html += '<td>' + (item.Observation_Desc__c != null ? item.Observation_Desc__c : '') + '</td>';
				obx_html += '<td>' + (item.Abnormal_Flags__c != null ? item.Abnormal_Flags__c : '') + '</td>';
				obx_html += '<td>' + (item.Observation_Result__c != null ? item.Observation_Result__c : '') + '</td>';
				String reference = (item.Reference_Range__c != null ? item.Reference_Range__c : '') + ' ' + (item.Units__c != null ? item.Units__c : '');
				obx_html += '<td>' + reference + '</td>';
				obx_html += '</tr>';
				if (String.isNotBlank(item.Comment__c)) {
					obx_html += '<tr><td style="padding-left:20px;" colspan="5"><table><tr><td>' + item.Comment__c + '</td></tr></table></td></tr>';
				}
			}
			obx_html += '</table>';
			obx_html += '</div>';
			html += obx_html;
			html += '</div>';
			return html;
		}
		public Integer compareTo(Object compareTo) {
			return 0;
		}
	}

	public class Patient extends ConverterBase {
		public List<OBR> obrList { get; set; }
		public Patient(SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
			super(obj, fieldMap, fieldList);
			obrList = new List<OBR>();
		}
		public override String toHtml() {
			//String html = super.toHtml();
			String html = '';
			for (OBR obr : obrList) {
				html += obr.toHtml();
			}
			return html;
		}
	}
}