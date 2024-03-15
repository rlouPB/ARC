/**
 * @author Synaptic Advisors
 * @date 2021
 *
 * @group BHS
 * @group-content ../../ApexDocContent/BHS.htm
 *
 * @description
 *   BHS Order Result Processor. It is responsible for parsing the HL7 ORU message and upserting the parsed <p>
 *   information to Salesforce object Prosedure Order. <p>
 *   The expected payload has following structure.
 *   MSH - Required
 *       PID - Required, one per message
 *       NK1 - Optional, multiple per message
 *       PV1 - Required, one per message
 *       PV2 - Required, one per message
 *       PD1 - Required, one per message
 *       OBR - Required, may be multiple
 *           TQ1 - Required for 2.5+, one per OBR
 *           NTE - Optional, may be mulitiple per OBR
 *           SPM - Required for 2.5+, one per OBR
 *           SAC - Required for 2.5+, one per OBR
 *           OBX - Required, may be multiple per OBR
 *               NTE - Optional, may be multiple per OBX
 *
 */
public with sharing class BHS_OrderResultProcessor {
	/*******************************************************************************************************
	 * @description Stores the segments to be processed
	 */
	public List<String> segments { get; set; }

	/*******************************************************************************************************
	 * @description Stores the parsed information
	 */
	public map<string, object> values = new Map<string, object>();

	/*******************************************************************************************************
	 * @description Stores current index of segment to be processed
	 */
	public integer index = 0;

	public Id procedureOrderId;
	/*******************************************************************************************************
	 * @description Constructor
	 * @param segments:List<String> Segments to be processed
	 */
	public BHS_OrderResultProcessor(List<String> segments) {
		this.segments = segments;
		if (this.segments == null) {
			this.segments = new List<String>();
		}
	}

	public BHS_OrderResultProcessor(List<String> segments, String poId) {
		this.procedureOrderId = poId;
		this.segments = segments;
		if (this.segments == null) {
			this.segments = new List<String>();
		}
	}

	/*******************************************************************************************************
	 * @description Adds processed segment to the final object
	 * @param segments:List<String> Segments to be processed
	 */
	private void addSegment(string segmentName, map<string, object> childValues) {
		if (segmentName == 'OBR') {
			if (!this.values.containsKey(segmentName)) {
				this.values.put(segmentName, new List<map<string, object>>());
			}
			list<map<string, object>> objList = (list<map<string, object>>) this.values.get(segmentName);
			objList.add(childValues);
		} else {
			this.values.put(segmentName, childValues);
		}
	}

	public static String getUUID() {
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		String guid = h.SubString(0, 8) + '-' + h.SubString(8, 12) + '-' + h.SubString(12, 16) + '-' + h.SubString(16, 20) + '-' + h.substring(20);
		return guid;
	}

	/*******************************************************************************************************
	 * @description Entry point to process the HL7 ORU message
	 *
	 */
	public void process() {
		while (index < segments.size()) {
			String segment = segments[index];
			string segName = BHS_HL7_ParserBase.getMessageName(segment);
			BHS_HL7_ParserBase parser = BHS_HL7_ParserFactory.createParser(segName);
			index = parser.parse(segments, index);
			index++;
			addSegment(segName, parser.values);
		}

		Id labObservationId = null;
		List<Lab_Observation_Result__c> obrList = new List<Lab_Observation_Result__c>();
		List<Lab_Result_Item__c> obxUpsertList = new List<Lab_Result_Item__c>();
		List<BHS_Comment__c> comments = new List<BHS_Comment__c>();
		for (String key : this.values.keyset()) {
			if (key == 'OBR') {
				list<map<string, object>> obrs = (list<map<string, object>>) this.values.get(key);
				for (map<string, object> obr : obrs) {
					Integer obrSequence = Integer.valueOf(obr.get('setID'));
					String placerNumber = (String) obr.get('placerNumber');
					String fillerNumber = (String) obr.get('fillerNumber');
					String orderedCode = (String) obr.get('orderedCode');
					String orderedDesc = (String) obr.get('orderedDesc');
					DateTime collectionDatetime = DateTime.valueOf(obr.get('collectionDatetime'));
					DateTime collectionEndDatetime = DateTime.valueOf(obr.get('collectionEndDatetime'));
					DateTime specimenReceivedDatetime = DateTime.valueOf(obr.get('specimenReceivedDatetime'));
					String orderingDoctorId = (String) obr.get('orderingDoctorId');
					String orderingDoctorLastName = (String) obr.get('orderingDoctorLastName');
					String orderingDoctorFirstName = (String) obr.get('orderingDoctorFirstName');
					String resultStatus = (String) obr.get('resultStatus');
					//String externalId = fillerNumber + '_' + BHS_OrderResultProcessor.getUUID() + '_'+obr.get('setID');
					String externalId = fillerNumber + '_' + orderedCode + '_' + obr.get('setID');

					Lab_Observation_Result__c result = new Lab_Observation_Result__c(
						Sequence__c = obrSequence,
						Placer_Number__c = placerNumber,
						Filler_Number__c = fillerNumber,
						Ordered_Code__c = orderedCode,
						Ordered_Desc__c = orderedDesc,
						Collection_Datetime__c = collectionDatetime,
						Collection_End_Datetime__c = collectionEndDatetime,
						Specimen_Received_Datetime__c = specimenReceivedDatetime,
						Ordering_Doctor_Id__c = orderingDoctorId,
						Ordering_Doctor_Last_Name__c = orderingDoctorLastName,
						Ordering_Doctor_First_Name__c = orderingDoctorFirstName,
						Result_Status__c = resultStatus,
						External_Id__c = externalId
					);
					if (String.isNotBlank(placerNumber)) {
						result.Lab_Observation__c = Test.isRunningTest() ? null : placerNumber;
						labObservationId = Test.isRunningTest() ? null : placerNumber;
					}
					obrList.add(result);

					if (obr.containsKey('OBX')) {
						List<map<string, object>> obxList = (List<map<string, object>>) obr.get('OBX');
						for (map<string, object> obx : obxList) {
							String obxExternalId = externalId + '_' + obx.get('setID');
							Lab_Result_Item__c resultItem = new Lab_Result_Item__c();
							resultItem.External_Id__c = obxExternalId;
							resultItem.Sequence__c = Integer.valueOf(obx.get('setID'));
							resultItem.Value_Type__c = (String) obx.get('valueType');
							resultItem.Observation_Id__c = (String) obx.get('observationID');
							resultItem.Observation_Desc__c = (String) obx.get('observationDesc');
							resultItem.Observation_Sub_Id__c = (String) obx.get('observationSubID');
							resultItem.Observation_Result__c = (String) obx.get('observationResults');
							resultItem.Units__c = (String) obx.get('units');
							resultItem.Reference_Range__c = (String) obx.get('refernceRange');
							resultItem.Observation_Result_Status__c = (String) obx.get('obserationResultStatus');
							resultItem.Collection_DateTime__c = DateTime.valueOf(obx.get('collectionDateTime')); //2022-06-24 10:18:00
							resultItem.Site_Mnemonic__c = (String) obx.get('siteMnemonic');
							resultItem.Abnormal_Flags__c = (String) obx.get('abnormalFlags');
							resultItem.Lab_Observation__c = null;
							resultItem.Procedure_Order__c = null;
							resultItem.Procedure_Result__c = null;
							resultItem.Lab_Observation_Result__r = new Lab_Observation_Result__c(External_Id__c = externalId);

							obxUpsertList.add(resultItem);
							List<map<string, object>> nteList = (List<map<string, object>>) obx.get('NTE');
							String comment = '';
							if (nteList != null) {
								for (map<string, object> nte : nteList) {
									String c = (String) nte.get('comments');
									if (String.isBlank(c)) {
										c = '<br/>';
									} else if (c.endsWith('.')) {
										c += '<br/>';
									}
									comment += c;
								}
							}
							resultItem.Comment__c = comment;
						}
					}
				}
			} else {
				system.debug('BHS_OrderResultProcessor process-------------key=' + key + ' val =' + this.values.get(key));
			}
		}

		upsert obrList External_Id__c;
		upsert obxUpsertList External_Id__c;
		//insert comments;
		List<String> itemIds = new List<String>();
		for (Lab_Result_Item__c item : obxUpsertList) {
			itemIds.add(item.Id);
		}
		Set<String> procedureResultIds = new Set<String>();
		List<Lab_Result_Item__c> updateItems = new List<Lab_Result_Item__c>();
		List<Lab_Result_Item__c> items = [SELECT Id, Lab_Observation_Result__r.Lab_Observation__r.Id, Lab_Observation_Result__r.Lab_Observation__r.Procedure_Result__r.Id, Lab_Observation_Result__r.Lab_Observation__r.Procedure_Result__r.Procedure_Order__r.Id FROM Lab_Result_Item__c WHERE Id IN :itemIds];
		String procedureResultId = '';
		String procedureOrderId = '';
		try {
			Lab_Observation__c lo = [SELECT Id, Procedure_Order__c FROM Lab_Observation__c WHERE Id = :labObservationId];
			procedureOrderId = lo.Procedure_Order__c;
			Procedure_Result__c pr = [SELECT Id FROM Procedure_Result__c WHERE Procedure_Order__c = :lo.Procedure_Order__c LIMIT 1];
			procedureResultId = pr.Id;
		} catch (Exception e) {
			ProcessLogging.quickProcessLog('Lob Order Result Processing', e.getStackTraceString(), e.getMessage());
		}

		for (Lab_Result_Item__c item : items) {
			String c_procedureResultId = item.Lab_Observation_Result__r?.Lab_Observation__r?.Procedure_Result__r?.Id;
			String c_procedureOrderId = item.Lab_Observation_Result__r?.Lab_Observation__r?.Procedure_Result__r?.Procedure_Order__r?.Id;
			if (String.isNotBlank(c_procedureResultId)) {
				procedureResultId = c_procedureResultId;
			}
			if (String.isNotBlank(c_procedureOrderId)) {
				procedureOrderId = c_procedureOrderId;
			}
			String observationId = item.Lab_Observation_Result__r?.Lab_Observation__r?.Id;
			Lab_Result_Item__c ri = new Lab_Result_Item__c(Id = item.Id);
			if (String.isNotBlank(procedureResultId)) {
				procedureResultIds.add(procedureResultId);
				ri.Procedure_Result__c = procedureResultId;
			}
			if (String.isNotBlank(procedureOrderId)) {
				ri.Procedure_Order__c = procedureOrderId;
			}
			if (String.isNotBlank(observationId)) {
				ri.Lab_Observation__c = observationId;
			}
			updateItems.add(ri);
		}
		update updateItems;
		List<Procedure_Result__c> updateProcedureResults = new List<Procedure_Result__c>();
		for (Procedure_Result__c pr : [SELECT Id FROM Procedure_Result__c WHERE Id IN :procedureResultIds]) {
			updateProcedureResults.add(new Procedure_Result__c(Id = pr.Id, Status__c = 'Received'));
		}
		if (updateProcedureResults.size() > 0) {
			update updateProcedureResults;
		}
	}
}

/*
 *   ORU HL7 mapping
 *
 *   MSH|^~\\&|LAB|SITE|LAB|SITE|200612051358||ORU^R01|7453.1|D|2.4
 *   MSH.3 Sending Application
 *   MSH.4 Sending Facility
 *   MSH.5 Receiving Application
 *   MSH.6 Receiving Facility
 *   MSH.7 Message Datetime
 *   MSH.9 Message Type
 *   MSH.10 Message control ID
 *   MSH.11 Processing ID
 *   MSH.12 Version ID
 *
 *   PID|1|563750014^^^AB|MG00001234^^^^MR~999-99-9999^^^^SS~232^^^^PI||LastName^FirstName^^^^||19520505|M|||23 Street Address^^MEDICINE HAT^AB^T1A 4N2||(999)999-9999|||||MT0001234/10|1234567890|
 *	PID.1 setID
 *	PID.2 mriHubID
 *	PID.3 patientMRN
 *	PID.5 patientName
 *	PID.7 dateOfBirth
 *	PID.8 sex
 *	PID.11 patientAddress
 *	PID.13 homePhoneNumber
 *	PID.18 patientAccountNumber
 *	PID.19 patientSSN
 *
 *   PD1|1|Item#PD1.2||Item#PD1.4||||||||Y
 *	PD1.1 setID
 *	PD1.2 financialClass
 *	PD1.4 patientPrimaryCareProvider
 *	PD1.12 vipIndicator
 *
 *   PV1|1|O|CLRH 3F LAB^^||||AttendingDocId^AttendingDocLast^AttendingDocFirst^^^^|||||||||||REF||AHC|||||||||||||||||||MEDH^MediTech General Hospital||REG|||200607111417||||||
 *	PV1.1 setID integer
 *	PV1.2 patient status
 *	PV1.3 assignLocation
 *	PV1.4 AdmissionPriority
 *	PV1.7 AttendingDoctor
 *	PV1.8 ReferringDoctor
 *	PV1.9 ConsultingDoctor
 *	PV1.10 Hostipal Service
 *	PV1.14 Admit Source
 *	PV1.16 VIP Indicator
 *	PV1.17 Admitting Doctor
 *	PV1.18 Patient Type
 *	PV1.20 Financial Class
 *	PV1.36 Discharge Disposition
 *	PV1.39 Servicing Facility
 *	PV1.41 Account Status
 *	PV1.44 AdmitDatetime
 *	PV1.45 DischargeDatetime
 *
 *   PV2||Item#PV2.2|Item#PV2.3|||||200901021453||Item#PV2.1||Item#PV2.1||||Y||||||Item#PV2.2
 *	PV2.2 accomodationCode
 *	PV2.3 admitReason
 *	PV2.8 decisionAdmitDatetime
 *	PV2.10 estimatedLengthInpatient
 *	PV2.12 admitComment
 *	PV2.16 purgeStatusCode
 *	PV2.22 visitProtectionIndicator
 *
 *   OBR|1|43646^MIC|43646^MIC|CUSPU^CULTURE/GRAM,SPUTUM^L|||200612201330|||||||200612201409|SPU^SPUTUM^L|OrderingDocId^OrderingDocLast^OrderingDocFirst^OrderingDocMiddle^^^||||06:M0002811R||200612201433||LAB|COMP||^^^^^R||
 *	OBR.1 setID
 *	OBR.2 placers order #
 *	OBR.3 fillers order #
 *	OBR.4 order procedure code
 *	OBR.5 priority
 *	OBR.7 collection datetime
 *	OBR.8 collection end datetime
 *	OBR.9 ordering site
 *	OBR.10 collected by user
 *	OBR.14 specimen received datetime
 *	OBR.15 specimen source - microbiology only
 *	OBR.16 ordering doctor
 *	OBR.24 diagnostic serc sect ID
 *	OBR.25 specimen status
 *	OBR.26 linked results - microbiology only
 *	OBR.27 mic specimen description - microbiology only
 *	OBR.28 other doctor
 *	OBR.29 patient accession # - microbiology only
 *	OBR.32 verify user
 *	OBR.39 cancel comments
 *
 *   OBX|1|ST|NA^SODIUM^L^NA^T^1110.001|Item#00769|142|cc/ml|120-140|H|||F|||199703091405|ML^MAIN LAB^L
 *	OBX.1 setID
 *	OBX.2 Value Type
 *	OBX.3 Observation Identifier
 *	OBX.4 Observation Sub-ID
 *	OBX.5 Observation Results
 *	OBX.6 Units
 *	OBX.7 Reference Range
 *	OBX.8 Abnormal Flags
 *	OBX.11 Observation Result Status
 *	OBX.14 Requested Datetime
 *	OBX.15 Producers ID
 *
 *   NTE|1||Recent/Current Antibiotic Hx:^NO
 *	NTE.1 setID
 *	NTE.3 comments
 *
 *   SPM|1|00001122^1332^LAB|0413:H00002R^1332^LAB^041310:H2|BLD^BLOOD^BLOOD^100.100^BLD|||MAN^MANUAL||||||||||201004221610|201004221631||||||||1|LAV^LAVENDER
 *	SPM.1 setID
 *	SPM.2 specimenID (spRequistionNumber, spURN, spModule)
 *	SPM.3 specimenParentIds (parentSpNumber, parentSpURN, parentSpMudule, parentSpCompleteNumber)
 *	SPM.4 specimenType (spTypeMnemonic, spTypeName, spTypeAbbr, spTypeNumber, spTypeCategory)
 *	SPM.7 collectionMethod (spCollectionMethodMnemonic, spCollectionMethodName)
 *	SPM.17 spCollectionDatetime
 *	SPM.18 spReceiveDatetime
 *	SPM.26 spContainerNumber
 *	SPM.27 containerType (containerTypeMnemonic, containerTypeName, containerTypeAbbr, containerTypeNumber, containerTypeCategory)
 *
 *   TQ1|||||||||2|
 *	TQ1.9 priority
 *
 *   SAC|||0413:H00002R^1332^LAB^041310:H2
 *	SAC.3 containerId (spNumber, spURN, spModule, spCompleteNumber)
 */