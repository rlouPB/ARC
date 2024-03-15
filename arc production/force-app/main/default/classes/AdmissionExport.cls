public with sharing class AdmissionExport {
	/*
		Purpose: 	Create CSV based on Patient and Current Admission to be used to import to Lotus Notes AdmissionsContact.
					Only intended for use while Lotus Notes is still in place

		History:	Created		JN 	180713
					Hotfix		JN	201104	Support for Basic Note
											Remove Ref and CN contacts
*/
	public String csvFileName { get; set; }

	public String csv = '';
	public String getCsv() {
		return csv;
	}

	private final Integer MAX_LOG_SIZE = 32000; //Lotus Notes limitation

	Id patientAccountId;
	Account patientAccount;
	List<Related_Contact__c> relatedContacts;
	Map<String, Related_Contact__c> prefix2relatedContactMap = new Map<String, Related_Contact__c>();

	//calculated patient values for CSV
	Map<String, String> calculatedValuesMap = new Map<String, String>{ 'ConsultDate' => '', 'InqDate1' => '', 'InqDate2' => '', 'PriorArc' => 'No', 'PriorArcDate' => '', 'CompleteLog' => '', 'Sex' => '' };
	Set<String> additionalAccountFields = new Set<String>{ 'Current_Admission__r.CreatedDate', 'Current_Admission__r.Consultation_Date__c', 'Current_Admission__r.Consultation_Only_Date__c', 'Patient_Contact__r.Sex_Assigned_at_Birth__c' };

	List<String> personalPrefixesInOrder = new List<String>{ 'Ct1', 'Ct2', 'Fm1', 'Fm2', 'Fm3', 'Fm4', 'Fm5' };

	// removed 201104 JN
	// List<String> professionalPrefixesInOrder = new List<String>
	// {
	// 	'Ref1',
	// 	'Ref2',
	// 	'CN1',
	// 	'CN2',
	// 	'CN3',
	// 	'CN4'
	// };

	List<List<String>> patientFieldMaps = new List<List<String>>{
		new List<String>{ 'Medical_Record_Number__c', 'MedNum' },
		new List<String>{ 'Current_Admission__r.AdmissionId__c', 'AdmissionId' },
		new List<String>{ 'Patient_Contact__r.LastName', 'PtNameLast' },
		new List<String>{ 'Patient_Contact__r.FirstName', 'PtNameFirst' },
		new List<String>{ 'Patient_Contact__r.Middle_w_Readmit__c', 'PtNameMid' },
		new List<String>{ null, 'PriorArc' },
		new List<String>{ null, 'PriorArcDate' },
		new List<String>{ 'Patient_Contact__r.MailingStreet', 'PtAddStreet' },
		new List<String>{ 'Patient_Contact__r.MailingCity', 'PtAddCity' },
		new List<String>{ 'Patient_Contact__r.MailingStateCode', 'PtAddState' },
		new List<String>{ 'Patient_Contact__r.MailingPostalCode', 'PtAddZip' },
		new List<String>{ 'Patient_Contact__r.MailingCountryCode', 'PtAddCountry' },
		new List<String>{ 'Patient_Contact__r.Email', 'PtEmail' },
		new List<String>{ 'Patient_Contact__r.Combined_Phone__c', 'PtTel ' },
		new List<String>{ null, 'Sex' },
		new List<String>{ 'Age__c', 'Age' },
		new List<String>{ 'Patient_Contact__r.Birthdate', 'DOB' },
		new List<String>{ 'Current_Admission__r.Pharmacy__c', 'PresPharm_1' },
		//new List<String> { 'Current_Admission__r.Initial_Therapist__c', 'InitialTherapist' },
		new List<String>{ 'Current_Admission__r.Admitting_Officer__c', 'AdmitOfficer' },
		new List<String>{ null, 'ConsultDate' },
		new List<String>{ 'Current_Admission__r.Is_Consultation_Only__c', 'ConsultOnly' },
		new List<String>{ null, 'InqDate1' },
		new List<String>{ null, 'InqDate2' },
		new List<String>{ null, 'CompleteLog' }
	};

	Map<String, List<String>> contactPrefix2FieldsMap = new Map<String, List<String>>{
		'SF' => new List<String>{ null, 'Contact__r.Salutation', 'Contact__r.LastName', 'Contact__r.FirstName', 'Contact__r.MiddleName', 'Contact__r.MailingStreet', 'Contact__r.MailingCity', 'Contact__r.MailingState', 'Contact__r.MailingPostalCode', 'Contact__r.MailingCountry', 'Contact__r.Combined_Phone__c', 'Contact__r.MobilePhone', 'Contact__r.Email', 'Contact__r.Fax', 'Contact__r.Suffix_Credentials__c', 'Role__c', 'Contact__r.Works_at_Institution__r.Name', null },
		'Ct1' => new List<String>{ 'Ct1Id', 'Ct1Salutation', 'Ct1NameLast', 'Ct1NameFirst', 'Ct1NameMid', 'Ct1AddStreet', 'Ct1AddCity', 'Ct1AddState', 'Ct1AddZip', 'Ct1AddCountry', 'Ct1Tel', 'na', 'Ct1Email', 'na', 'Ct1ProfDisc', 'Ct1Relation', 'na', 'na' },
		'Ct2' => new List<String>{ 'Ct2Id', 'Ct2Salutation', 'Ct2NameLast', 'Ct2NameFirst', 'Ct2NameMid', 'Ct2AddStreet', 'Ct2AddCity', 'Ct2AddState', 'Ct2AddZip', 'Ct2AddCountry', 'Ct2Tel', 'na', 'Ct2Email', 'na', 'Ct2ProfDisc', 'Ct2Relation', 'na', 'na' },
		'Fm1' => new List<String>{ 'Fm1Id', 'Fm1Salutation', 'Fm1NameLast', 'Fm1NameFirst', 'Fm1NameMid', 'Fm1AddStreet', 'Fm1AddCity', 'Fm1AddState', 'Fm1AddZip', 'Fm1AddCountry', 'Fm1Tel', 'Fm1CellPhone', 'Fm1Email', 'na', 'Fm1ProfDisc', 'Fm1Relation', 'na', 'na' },
		'Fm2' => new List<String>{ 'Fm2id', 'Fm2Salutation', 'Fm2NameLast', 'Fm2NameFirst', 'Fm2NameMid', 'Fm2AddStreet', 'Fm2AddCity', 'Fm2AddState', 'Fm2AddZip', 'Fm2AddCountry', 'Fm2Tel', 'Fm2CellPhone', 'Fm2Email', 'na', 'Fm2ProfDisc', 'Fm2Relation', 'na', 'na' },
		'Fm3' => new List<String>{ 'Fm3Id', 'Fm3Salutation', 'Fm3NameLast', 'Fm3NameFirst', 'Fm3NameMid', 'Fm3AddStreet', 'Fm3AddCity', 'Fm3AddState', 'Fm3AddZip', 'Fm3AddCountry', 'Fm3Tel', 'Fm3CellPhone', 'Fm3Email', 'na', 'Fm3ProfDisc', 'Fm3Relation', 'na', 'na' },
		'Fm4' => new List<String>{ 'Fm4Id', 'Fm4Salutation', 'Fm4NameLast', 'Fm4NameFirst', 'Fm4NameMid', 'Fm4AddStreet', 'Fm4AddCity', 'Fm4AddState', 'Fm4AddZip', 'Fm4AddCountry', 'Fm4Tel', 'Fm4CellPhone', 'Fm4Email', 'na', 'Fm4ProfDisc', 'Fm4Relation', 'na', 'na' },
		'Fm5' => new List<String>{ 'Fm5Id', 'Fm5Salutation', 'Fm5NameLast', 'Fm5NameFirst', 'Fm5NameMid', 'Fm5AddStreet', 'Fm5AddCity', 'Fm5AddState', 'Fm5AddZip', 'Fm5AddCountry', 'Fm5Tel', 'Fm5CellPhone', 'Fm5Email', 'na', 'Fm5ProfDisc', 'Fm5Relation', 'na', 'na' }
		// 		,
		// 'Ref1' => new List<String> { 'Ref1Id', 'Ref1Salutation', 'Ref1NameLast', 'Ref1NameFirst', 'Ref1NameMid', 'Ref1AddStreet', 'Ref1AddCity',
		// 		'Ref1AddState', 'Ref1AddZip', 'Ref1AddCountry', 'Ref1Tel', 'Ref1TelCell', 'Ref1EmailAddress', 'Ref1Fax', 'Ref1ProfDisc',
		// 		'Ref1Relation',	'na', 'Ref1NewDate' },
		// 'Ref2' => new List<String> { 'Ref2Id', 'Ref2Salutation', 'Ref2NameLast', 'Ref2NameFirst', 'Ref2NameMid', 'Ref2AddStreet', 'Ref2AddCity',
		// 		'Ref2AddState', 'Ref2AddZip', 'Ref2AddCountry', 'Ref2Tel', 'Ref2TelCell', 'Ref2EmailAddress', 'Ref2Fax', 'Ref2ProfDisc',
		// 		'Ref2Relation',	'na', 'Ref2NewDate'  },
		// 'CN1' => new List<String> { 'CN1Id', 'CN1Salutation', 'CN1NameLast', 'CN1NameFirst', 'CN1NameMid', 'CN1AddStreet', 'CN1AddCity',
		// 		'CN1AddState', 'CN1AddZip', 'CN1AddCountry', 'CN1Tel', 'CN1TelCell', 'CN1EmailAddress', 'CN1Fax', 'Cn1ProfDisc',
		// 		'Cn1Relation', 'CN1Institution', 'CN1NewDate'  },
		// 'CN2' => new List<String> { 'CN2Id', 'CN2Salutation', 'CN2NameLast', 'CN2NameFirst', 'CN2NameMid', 'CN2AddStreet', 'CN2AddCity',
		// 		'CN2AddState', 'CN2AddZip', 'CN2AddCountry', 'CN2Tel', 'CN2TelCell', 'CN2EmailAddress', 'CN2Fax', 'CN2ProfDisc',
		// 		'CN2Relation', 'CN2Institution', 'CN2NewDate'  },
		// 'CN3' => new List<String> { 'CN3Id', 'CN3Salutation', 'CN3NameLast', 'CN3NameFirst', 'CN3NameMid', 'CN3AddStreet', 'CN3AddCity',
		// 		'CN3AddState', 'CN3AddZip', 'CN3AddCountry', 'CN3Tel', 'CN3TelCell', 'CN3EmailAddress', 'CN3Fax', 'CN3ProfDisc',
		// 		'CN3Relation', 'CN3Institution', 'CN3NewDate'  },
		// 'CN4' => new List<String> { 'CN4Id', 'CN4Salutation', 'CN4NameLast', 'CN4NameFirst', 'CN4NameMid', 'CN4AddStreet', 'CN4AddCity',
		// 		'CN4AddState', 'CN4AddZip', 'CN4AddCountry', 'CN4Tel', 'CN4TelCell', 'CN4EmailAddress', 'CN4Fax', 'CN4ProfDisc',
		// 		'CN4Relation', 'CN4Institution', 'CN4NewDate'  }
	};

	Set<String> dateFieldNames = new Set<String>{ 'Birthdate' };

	public AdmissionExport(ApexPages.standardController stdCon) {
		patientAccountId = stdCon.getId();

		queryPatient();

		queryRelatedContacts();

		//determine which contact prefixes(Ct1, Ct2, Fm1, Ref1, etc) will be used and for which related contacts
		assignRelatedContactPrefixes();

		populateCsvHeaders();

		calculatePatientValues();

		populateCsvValues();
	}

	void queryPatient() {
		Set<String> fieldsToQuery = new Set<String>();

		for (List<String> mappingList : patientFieldMaps) {
			if (mappingList[0] != null)
				fieldsToQuery.add(mappingList[0]);
		}

		for (String field : additionalAccountFields) {
			fieldsToQuery.add(field);
		}

		String queryString = 'SELECT ';
		Boolean firstField = true;
		for (String fieldName : fieldsToQuery) {
			if (firstField)
				firstField = false;
			else
				queryString += ',';
			queryString += fieldName;
		}

		queryString += ' FROM Account' + ' WHERE Id = \'' + patientAccountId + '\'';

		List<Account> accs = (List<Account>) Database.query(queryString);
		if (!accs.isEmpty()) {
			patientAccount = accs[0];
			csvFileName = patientAccount.Patient_Contact__r.LastName + ' export';
		}
	}

	void queryRelatedContacts() {
		Set<String> fieldsToQuery = new Set<String>();

		for (String fieldName : contactPrefix2FieldsMap.get('SF')) {
			fieldsToQuery.add(fieldName);
		}
		fieldsToQuery.add('RecordType.Name');
		fieldsToQuery.add('Contact_Name__c');
		fieldsToQuery.remove(null);

		String queryString = 'SELECT ';
		Boolean firstField = true;
		for (String fieldName : fieldsToQuery) {
			if (firstField)
				firstField = false;
			else
				queryString += ',';
			queryString += fieldName;
		}

		queryString += ' FROM Related_Contact__c' + ' WHERE Account__c = \'' + patientAccountId + '\' AND Recordtype.Name != \'Professional\'';

		relatedContacts = (List<Related_Contact__c>) Database.query(queryString);
	}

	void assignRelatedContactPrefixes() {
		String prefix;

		for (Related_Contact__c rc : relatedContacts) {
			// if (rc.Recordtype.Name == 'Professional')
			// {
			// 	for (String proPrefix : professionalPrefixesInOrder)
			// 	{
			// 		if (!prefix2relatedContactMap.containsKey(proPrefix))
			// 		{
			// 			prefix = proPrefix;
			// 			break;
			// 		}
			// 	}
			// } else
			if (rc.Recordtype.Name == 'Personal') {
				for (String rcPrefix : personalPrefixesInOrder) {
					if (!prefix2relatedContactMap.containsKey(rcPrefix)) {
						prefix = rcPrefix;
						break;
					}
				}
			}
			//drop RC if no prefixes left
			if (prefix != null)
				prefix2relatedContactMap.put(prefix, rc);
		}
	}

	void populateCsvHeaders() {
		Boolean firstField = true;
		for (List<String> mappingList : patientFieldMaps) {
			if (firstField)
				firstField = false;
			else
				csv += ',';
			csv += mappingList[1];
		}

		List<String> allPrefixesInOrder = new List<String>();
		allPrefixesInOrder.addAll(personalPrefixesInOrder);
		//allPrefixesInOrder.addAll(professionalPrefixesInOrder);
		for (String prefix : allPrefixesInOrder) {
			if (prefix2relatedContactMap.containsKey(prefix)) {
				List<String> rcFieldNames = contactPrefix2FieldsMap.get(prefix);
				for (String fieldName : rcFieldNames) {
					if (fieldName != 'na')
						csv += ',' + fieldName;
				}
			}
		}
		csv += '\r\n';
	}

	//get values for CSV that are not just field mappings
	void calculatePatientValues() {
		//ConsultDate
		if (patientAccount.Current_Admission__r.Consultation_Date__c != null) {
			calculatedValuesMap.put('ConsultDate', String.valueOf(patientAccount.Current_Admission__r.Consultation_Date__c));
		} else {
			if (patientAccount.Current_Admission__r.Consultation_Only_Date__c != null) {
				calculatedValuesMap.put('ConsultDate', String.valueOf(patientAccount.Current_Admission__r.Consultation_Only_Date__c));
			}
		}

		//InqDate1
		calculatedValuesMap.put('InqDate1', patientAccount.Current_Admission__r.CreatedDate.format('M/d/yyyy'));

		//InqDate2
		calculatedValuesMap.put('InqDate2', patientAccount.Current_Admission__r.CreatedDate.format('M/d/yyyy'));

		//PriorArc
		//PriorArcDate
		List<Admission__c> priorAdmissions = [SELECT Id, Admit_Date__c FROM Admission__c WHERE Id != :patientAccount.Current_Admission__c AND Patient_Account__c = :patientAccountId AND Admit_Date__c != NULL ORDER BY Admit_Date__c DESC LIMIT 1];
		if (!priorAdmissions.isEmpty()) {
			calculatedValuesMap.put('PriorArc', 'Yes');
			calculatedValuesMap.put('PriorArcDate', String.valueOf(priorAdmissions[0].Admit_Date__c));
		}

		//CompleteLog
		// List<Task> calls = [SELECT Id, Call_Date_Time__c, Owner.Name, Patient_Note__r.Caller_Affect_and_Presentation__c,
		// 						Caller_Name__c, Patient_Note__r.Rich_Text_Notes__c
		// 					FROM Task
		// 					WHERE WhatId = :patientAccountId
		// 					ORDER BY Call_Date_Time__c DESC];

		List<Basic_Note__c> calls = [
			SELECT
				Id,
				Call_Date_Time__c,
				Caller_Affect_and_Presentation__c,
				Caller_Name__c,
				Rich_Text_Notes__c,
				TYPEOF Owner
					WHEN User THEN Name
				END
			FROM Basic_Note__c
			WHERE Account__c = :patientAccountId
			ORDER BY Call_Date_Time__c DESC
		];
		String log = '';

		for (Basic_Note__c bn : calls) {
			String cleanNotes = '';

			if (bn.Rich_Text_Notes__c != null) {
				cleanNotes = bn.Rich_Text_Notes__c;
				cleanNotes = cleanNotes.replaceAll('<br>', '\n');
				cleanNotes = cleanNotes.replaceAll('</p>', '</p>\n');
				cleanNotes = cleanNotes.replaceAll('<li>', '\n<li>');
				cleanNotes = cleanNotes.replaceAll('<[^>]+>', ' ');
				cleanNotes = cleanNotes.unescapeHtml4();
				cleanNotes = cleanNotes.replaceAll('"', '""');
				cleanNotes = cleanNotes.replaceAll(',', '\\,');
			}

			if (bn.Call_Date_Time__c != null)
				log += bn.Call_Date_Time__c.format() + '  ';
			log += bn.Owner.Name;
			log += '\n';

			if (bn.Caller_Name__c != null) {
				log += 'Person Spoken To: ' + bn.Caller_Name__c + '\n';
			}
			if (bn.Caller_Affect_and_Presentation__c != null) {
				log += 'Caller Affect and Presentation: ' + bn.Caller_Affect_and_Presentation__c + '\n';
			}

			if (cleanNotes != '') {
				log += cleanNotes + '\n';
			}

			if (log.length() >= MAX_LOG_SIZE) {
				log = log.abbreviate(MAX_LOG_SIZE);
				break;
			}
		}
		calculatedValuesMap.put('CompleteLog', log);

		//Sex
		String sex = patientAccount.Patient_Contact__r.Sex_Assigned_At_Birth__c;
		if (sex != 'Male' && sex != 'Female') {
			sex = '';
		}
		calculatedValuesMap.put('Sex', sex);
	}

	void populateCsvValues() {
		Boolean firstField = true;
		for (List<String> mappingList : patientFieldMaps) {
			if (firstField)
				firstField = false;
			else
				csv += ',';
			String fieldValue = '';
			if (mappingList[0] != null) {
				fieldValue = String.valueOf(getFieldValue(patientAccount, mappingList[0]));
			} else if (calculatedValuesMap.containsKey(mappingList[1])) {
				fieldValue = calculatedValuesMap.get(mappingList[1]);
			}
			if (fieldValue != '') {
				fieldValue = fieldValue.replaceAll('"', '""');
			}
			csv += '"' + fieldValue + '"';
		}

		List<String> allPrefixesInOrder = new List<String>();
		allPrefixesInOrder.addAll(personalPrefixesInOrder);
		//allPrefixesInOrder.addAll(professionalPrefixesInOrder);

		for (String prefix : allPrefixesInOrder) {
			if (prefix2relatedContactMap.containsKey(prefix)) {
				Related_Contact__c rc = prefix2relatedContactMap.get(prefix);
				Integer totalFields = contactPrefix2FieldsMap.get(prefix).size();

				List<String> lotusFieldNames = contactPrefix2FieldsMap.get(prefix);
				List<String> sfFieldNames = contactPrefix2FieldsMap.get('SF');
				for (Integer i = 0; i < totalFields; i++) {
					String sfFieldName = sfFieldNames[i];
					String lotusFieldName = lotusFieldNames[i];
					//skip na columns
					if (lotusFieldName == 'na')
						continue;

					String fieldValue = '';
					if (sfFieldName != null) {
						fieldValue = (String) getFieldValue(rc, sfFieldName);
					} else if (lotusFieldName.containsIgnoreCase('Id')) {
						fieldValue = patientAccount.Current_Admission__r.AdmissionId__c + prefix;
					} else if (lotusFieldName.containsIgnoreCase('NewDate')) {
						fieldValue = calculatedValuesMap.get('InqDate1');
					}
					if (fieldValue != '') {
						fieldValue = fieldValue.replaceAll('"', '""');
					}
					csv += ',"' + fieldValue + '"';
				}
			}
		}
		csv += '\r\n';
	}

	Object getFieldValue(sObject record, String fieldName) {
		if (fieldName.contains('.')) {
			String objectName = fieldName.substringBefore('.');
			String newFieldName = fieldName.substringAfter('.');
			record = (sObject) record.getSobject(objectName);
			if (record == null)
				return '';

			return getFieldValue(record, newFieldName);
		}
		Object result = record.get(fieldName);

		if (dateFieldNames.contains(fieldName)) {
			result = String.valueOf((Date) record.get(fieldName));
		}
		if (result == null)
			result = '';

		return result;
	}

	//used for troubleshooting
	//public void emailCsv()
	//{
	//	List<Messaging.EmailFileAttachment> fileAttachmentList = new List<Messaging.EmailFileAttachment>();
	//	Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
	//	csvAttc.setFileName('lotusExport.csv');
	//	csvAttc.setBody(Blob.valueOf(csv));
	//	fileAttachmentList.add(csvAttc);

	//	List<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();
	//	Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
	//	String[] toAddresses = new list<string> {Userinfo.getUserEmail()};
	//	singleEmail.setSubject('Lotus export CSV');
	//	singleEmail.setToAddresses( toAddresses );
	//	singleEmail.setPlainTextBody(csv);
	//	singleEmail.setFileAttachments(fileAttachmentList);
	//	singleEmailList.add(singleEmail);

	//	Messaging.sendEmail(singleEmailList);
	//}
}