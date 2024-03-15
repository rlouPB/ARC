public with sharing class PrintedPhysicalMonitorMedicalRecord extends PrintedMedicalRecordBase {
	public PrintedPhysicalMonitorMedicalRecord() {
		super();
	}

	public override String getSDocJunctionLookupField() {
		return 'Physical_Monitor__c';
	}
	public override String getSObjectName() {
		return 'Physical_Monitor__c';
	}

	public override String formatLevel2Name(TreeGridNode level2) {
		//return noteDefinitionRecTypeMap.get(level2.developerName)+';'+level2.sObjectName+';'+patientId;
		return null;
	}
	public override String formatLevel3Name(SObject sObj) {
		// Physical_Monitor__c note = (Physical_Monitor__c) sObj;
		// return note.Name +';PhysicalMonitor;'+note.Id+';Physical_Monitor__c';
		return null;
	}

	public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords() {
		// Map<String, List<TreeGridNode>> treeGridMap = new Map<String, List<TreeGridNode>>();
		// List<Physical_Monitor__c> physicalMonitors = (List<Physical_Monitor__c>) Database.query(
		//                 QueryUtils.getQueryAll('Physical_Monitor__c',  new List<String>())
		//                 + ' WHERE Account__c = :patientId'
		//                 + ' AND Account__r.Current_Admission__c in :admissionIdList'
		//                 + ' AND Status = \'Finalized\''
		//                 + ' WITH SECURITY_ENFORCED'
		//                 + ' ORDER BY CreatedDate desc');

		// for(Physical_Monitor__c aPM : physicalMonitors) {
		//     if(!treeGridMap.containsKey('PhysicalMonitor')) {
		//         treeGridMap.put('PhysicalMonitor', new List<TreeGridNode>());
		//     }
		//     TreeGridNode tg = new TreeGridNode();
		//     tg.sfID = aPM.Id;
		//     tg.contactDate = aPM.CreatedDate;
		//     tg.url = '/'+aPM.Id;
		//     tg.name = formatLevel3Name(aPM);
		//     tg.nodeName = aPM.Name;
		//     tg.developerName = 'PhysicalMonitor';
		//     //tg.finalizedDatetime = aPM.Finalized_Date_Time__c;
		//     //tg.finalizedBy = aPM.Finalized_By_Professional_Name__c;
		//     List<TreeGridNode> pmItems = treeGridMap.get('PhysicalMonitor');
		//     pmItems.add(tg);
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

	public static String convertPhysicalMonitor(String pmId) {
		String htmlText = '';
		List<Physical_Monitor__c> physicalMonitors = (List<Physical_Monitor__c>) Database.query(QueryUtils.getQueryAll('Physical_Monitor__c', new List<String>()) + ' WHERE Id = :pmId');
		Id accountId = null;
		for (Physical_Monitor__c pm : physicalMonitors) {
			accountId = pm.Account__c;
		}
		Account patient = [SELECT Id, Name, Age__c, Preferred_Pronouns__c, Gender_Identifies_As__c, Sex_Assigned_at_Birth__c, Phone__c FROM Account WHERE Id = :accountId];
		for (Physical_Monitor__c pm : physicalMonitors) {
			htmlText += convertPhysicalMonitorToHtml(pm, patient);
		}
		return htmlText;
	}
	public static final Map<String, List<String>> physicalMonitorSectionFields = new Map<String, List<String>>{
		'Height/Weight' => new List<String>{ 'Weight_Patient_Refused__c', 'Height_Patient_Refused__c', 'Height_in__c', 'Height_cm__c', 'Weight_lbs__c', 'Weight_kg__c', 'BMI__c', 'BMI_Status__c' },
		'Blood Pressure' => new List<String>{ 'Pulse_per_min__c', 'BP_Arm__c', 'BP_Cuff_Size__c', 'Respiration_per_min__c', 'Oxygen_Saturation__c', 'BP_Patient_Refused__c', 'BP_Systolic_mmHg__c', 'BP_Diastolic_mmHg__c', 'Position__c' },
		'Orthostatic Blood Pressure' => new List<String>{ 'BP_Cuff_Size__c', 'Comment__c', 'BP_Arm__c' },
		'Orthostatic Blood Pressure Measurement' => new List<String>{ 'Lying_BP_Fraction__c', 'Lying_Pulse_per_min__c', 'Standing_BP_Fraction__c', 'Standing_Pulse_per_min__c', 'Sitting_BP_Fraction__c', 'Sitting_Pulse_per_min__c' },
		'Temperature Info' => new List<String>{ 'Temperature_C__c', 'Temperature_F__c' },
		'Blood Glucose Info' => new List<String>{ 'Blood_Glucose_mg_dL__c', 'Glucose_Action_Taken__c' },
		'Urinalysis' => new List<String>{ 'Urinalysis_Name__c', 'Result__c', 'Note__c', 'Urinalysis_Notes__c' }
	};
	public static String convertPhysicalMonitorToHtml(Physical_Monitor__c physicalMonitor, Account patient) {
		Map<String, Schema.SObjectField> fieldMap = Physical_Monitor__c.getSobjectType().getDescribe().fields.getMap();
		Physical_Monitor__c heightWeight = new Physical_Monitor__c();
		heightWeight.Weight_Patient_Refused__c = physicalMonitor.Weight_Patient_Refused__c;
		heightWeight.Height_Patient_Refused__c = physicalMonitor.Height_Patient_Refused__c;

		if (physicalMonitor.Weight_Patient_Refused__c) {
			physicalMonitor.Weight_lbs__c = null;
		}
		if (physicalMonitor.Height_Patient_Refused__c) {
			physicalMonitor.Height_in__c = null;
		}
		String html = '';
		// html += '<div class="patient-name">'+ patient.Name +'</div><br/>';
		// html += '<table width="100%"><tr><th>Age</th><th>Preferred Pronouns</th><th>Gender Identifies As</th><th>Sex Assigned at Birth</th><th>Phone</th></tr>';
		// html += '<tr><td>'+ patient.Age__c+'</td>';
		// html += '<td>' + (String.isNotBlank(patient.Preferred_Pronouns__c) ? patient.Preferred_Pronouns__c : '') +'</td>';
		// html += '<td>'+ (String.isNotBlank(patient.Gender_Identifies_As__c) ? patient.Gender_Identifies_As__c: '')+'</td>';
		// html += '<td>'+ (String.isNotBlank(patient.Sex_Assigned_at_Birth__c) ? patient.Sex_Assigned_at_Birth__c: '')+'</td>';
		// html += '<td>'+ (String.isNotBlank(patient.Phone__c) ? patient.Phone__c: '')+'</td></tr></table><br/>';

		// html += '<table width="100%"><tr><th>Performed Date/Time</th><th>Finalized By</th><th>Finalized Date Time</th></tr>';
		// html += '<tr><td>'+ physicalMonitor.Performed_Date_Time__c+'</td>';
		// html += '<td>' + physicalMonitor.Finalized_By__c +'</td>';
		// html += '<td>'+physicalMonitor.Finalized_Date_Time__c+'</td>';
		// html += '</tr></table><br/>';

		html += '<div class="vitals">Vitals</div><br/>';
		if (physicalMonitor.View_Height_Weight__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertHeightWeightToHtml('Height/Weight', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Height/Weight'));
		}
		if (physicalMonitor.View_Blood_Pressure_Info__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertBloodPressureToHtml('Blood Pressure', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Blood Pressure'));
		}
		if (physicalMonitor.View_Orthostatic_Blood_Pressure_Info__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertToHtml('Orthostatic Blood Pressure', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Orthostatic Blood Pressure'));
			html += PrintedPhysicalMonitorMedicalRecord.convertToHtml('Orthostatic Blood Pressure Measurement', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Orthostatic Blood Pressure Measurement'));
		}
		if (physicalMonitor.View_Temperature_Info__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertToHtml('Temperature Info', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Temperature Info'));
		}
		if (physicalMonitor.View_Blood_Glucose_Info__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertToHtml('Blood Glucose Info', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Blood Glucose Info'));
		}
		if (physicalMonitor.View_Urinalysis__c) {
			html += PrintedPhysicalMonitorMedicalRecord.convertToHtml('Urinalysis', physicalMonitor, fieldMap, physicalMonitorSectionFields.get('Urinalysis'));
		}

		return html;
	}

	public static String convertToHtml(String caption, SObject obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
		String html = '<h2>' + caption + '</h2><br/>';
		html += '<table width="60%">';
		for (String s : fieldList) {
			Schema.SObjectField field = fieldMap.get(s);
			Schema.DescribeFieldResult dfr = field.getDescribe();
			String label = dfr.getLabel();
			String value = (obj != null && obj.get(s) != null) ? String.valueOf(obj.get(s)) : '';
			if (String.isNotBlank(value)) {
				html += '<tr><td width="40%">' + label + '</td><td width="20%">' + value + '</td></tr>';
			}
		}
		html += '</table><br/>';
		return html;
	}

	public static String convertBloodPressureToHtml(String caption, Physical_Monitor__c obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
		String html = '<h2>' + caption + '</h2><br/>';
		html += '<table width="60%">';
		List<String> newList = new List<String>();

		if (!obj.BP_Patient_Refused__c) {
			newList.add('BP_Systolic_mmHg__c');
			newList.add('BP_Diastolic_mmHg__c');
		} else {
			newList.add('BP_Patient_Refused__c');
		}
		newList.add('Pulse_per_min__c');
		newList.add('Respiration_per_min__c');
		newList.add('Oxygen_Saturation__c');
		newList.add('BP_Arm__c');
		newList.add('Position__c');
		newList.add('BP_Cuff_Size__c');

		for (String s : newList) {
			Schema.SObjectField field = fieldMap.get(s);
			Schema.DescribeFieldResult dfr = field.getDescribe();
			String label = dfr.getLabel();
			String value = (obj != null && obj.get(s) != null) ? String.valueOf(obj.get(s)) : '';
			if (String.isNotBlank(value)) {
				html += '<tr><td width="40%">' + label + '</td><td width="20%">' + value + '</td></tr>';
			}
		}
		html += '</table><br/>';
		return html;
	}

	public static String convertHeightWeightToHtml(String caption, Physical_Monitor__c obj, Map<String, Schema.SObjectField> fieldMap, List<String> fieldList) {
		String html = '<h2>' + caption + '</h2><br/>';
		html += '<table width="60%">';
		List<String> newList = new List<String>();

		if (!obj.Weight_Patient_Refused__c) {
			newList.add('Weight_lbs__c');
			newList.add('Weight_kg__c');
		} else {
			newList.add('Weight_Patient_Refused__c');
		}

		if (!obj.Height_Patient_Refused__c) {
			newList.add('Height_in__c');
			newList.add('Height_cm__c');
		} else {
			newList.add('Height_Patient_Refused__c');
		}
		if (!obj.Weight_Patient_Refused__c && !obj.Height_Patient_Refused__c) {
			newList.add('BMI__c');
			newList.add('BMI_Status__c');
		}
		for (String s : newList) {
			Schema.SObjectField field = fieldMap.get(s);
			Schema.DescribeFieldResult dfr = field.getDescribe();
			String label = dfr.getLabel();
			String value = (obj != null && obj.get(s) != null) ? String.valueOf(obj.get(s)) : '';
			if (String.isNotBlank(value)) {
				html += '<tr><td width="40%">' + label + '</td><td width="20%">' + value + '</td></tr>';
			}
		}
		html += '</table><br/>';
		return html;
	}
}