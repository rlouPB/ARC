@isTest
private with sharing class BHS_OrderResultProcessorTest {
	@testSetup
	static void setupData() {
		BHS_Order_Result_Staging__c staging = new BHS_Order_Result_Staging__c();

		staging.Payload__c =
			'[{"MessageId": "RESTBHSTEST02_66312061401","MessageBody": "MSH|^\\\\&|MIC|LMHA|||200612201433||ORU^R01|10722.1|D|2.4\\n' +
			'PID|1|563750014^^^AB|MG00001234^^^^MR~999-99-9999^^^^SS~232^^^^PI||LastName^FirstName^^^^||19520505|M|||23 Street Address^^MEDICINE HAT^AB^T1A 4N2||(999)999-9999|||||MT0001234/10|1234567890\\n' +
			'PD1|1|Item#PD1.2||Item#PD1.4||||||||Y\\n' +
			'PV1|1|O|LABORATORY^^||||AttendingDocId^AttendingDocLast^AttendingDocFirst^G.^^^|||||||||||REF||AHC|||||||||||||||||||LMHA^Medicine Hat Regional Hospital||REG|||200611090956||||||\\n' +
			'PV2||Item#PV2.2|Item#PV2.3|||||200901021453||Item#PV2.1||Item#PV2.1||||Y||||||Item#PV2.2\\n' +
			'OBR|1||43646^MIC|CUSPU^CULTURE/GRAM,SPUTUM^L|||200612201330|||||||200612201409|SPU^SPUTUM^L|OrderingDocId^OrderingDocLast^OrderingDocFirst^OrderingDocMiddle^^^||||06:M0002811R||200612201433||LAB|F||^^^^^R||\\n' +
			'NTE|1||Recent/Current Antibiotic Hx:^NO\\n' +
			'NTE|2||Pertinent Clinical Info?^None provided\\n' +
			'SPM|1|00001122^1332^LAB|0413:H00002R^1332^LAB^041310:H2|BLD^BLOOD^BLOOD^100.100^BLD|||MAN^MANUAL||||||||||201004221610|201004221631||||||||1|LAV^LAVENDER\\n' +
			'TQ1|||||||||2|\\n' +
			'SAC|||0413:H00002R^1332^LAB^041310:H2\\n' +
			'OBX|1|ST|GSSPU^GRAM STAIN,SPUTUM^L^P:GSSPU|1|GRAM SPUTUM||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|2|ST|GSSPU^GRAM STAIN,SPUTUM^L^R:2 NB|1|Few Gram negative bacilli||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|3|ST|GSSPU^GRAM STAIN,SPUTUM^L^R:3 PC|1|Moderate Gram positive cocci||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|4|CE|CSPUW^CULTURE,SPUTUM^L^O:ESCCOL|2.1|ESCCOL^ESCHERICHIA COLI||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|5|ST|CSPUW^CULTURE,SPUTUM^L^P:AMT|2.1|AMOUNT OF GROWTH||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|6|ST|CSPUW^CULTURE,SPUTUM^L^R:M|2.1|Moderate growth||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBR|2|||ZLGN05^VITEK - GN05^L|||200612201330|||||||200612201409|SPU^SPUTUM^L|OrderingDocId^OrderingDocLast^OrderingDocFirst^OrderingDocMiddle^^^||||06:M0002811R||200612201433||LAB|F|CSPUW^2.1|^^^^^R||43646^MIC\\n' +
			'NTE|1||Organism fulfills criteria of an Antibiotic Resistant\\n' +
			'NTE|2||Organism (ARO).\\n' +
			'OBX|1|ST|AM^AMPICILLIN^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|2|ST|TIC^TICARCILLIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|3|ST|AMXCA^AMOXICILLIN-CLAVULANATE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|4|ST|TICCA^TICARCILLIN-CLAVULANATE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'NTE|1||Organism fulfills criteria of an Antibiotic Resistant\\n' +
			'NTE|2||Organism (ARO).\\n' +
			'OBX|5|ST|CRMA^CEFUROXIME AXETIL^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|6|ST|CFZ^CEFAZOLIN^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|7|ST|CF^CEPHALOTHIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|8|ST|CRM^CEFUROXIME SODIUM (PARENTERAL)^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|9|ST|CAZ^CEFTAZIDIME^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|10|ST|CAX^CEFTRIAXONE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|11|ST|FOX^CEFOXITIN^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|12|ST|GM^GENTAMICIN^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|13|ST|TOB^TOBRAMYCIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|14|ST|CIP^CIPROFLOXACIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|15|ST|LEV^LEVOFLOXACIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|16|ST|NOR^NORFLOXACIN^L|||||R|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|17|ST|TMPSXT^TRIMETHOPRIM SULFAMETHOXAZOLE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|18|ST|FD^NITROFURANTOIN^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n' +
			'OBX|19|ST|TET^TETRACYCLINE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\\n"}]';
		insert staging;
	}
	@isTest
	private static void testMSH() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		system.assert(values != null, 'Parse result should not be null');
		system.assert(values.size() != 0, 'The size of parse result should not be zero');

		//MSH|^&|MIC|LMHA|||200612201433||ORU^R01|10722.1|D|2.4
		map<string, object> mshValues = (map<string, object>) values.get('MSH');
		// system.assert(mshValues != null, 'Parse result of MSH should not be null');
		// system.assert(mshValues.size() != 0, 'The size of parsing MSH result should not be zero');
		// system.assertEquals('MIC', string.valueOf(mshValues.get('sendingApp')), 'sendingApp should be MIC');
		// system.assertEquals('LMHA', string.valueOf(mshValues.get('sendingFacility')), 'sendingFacility should be SITE');
		// system.assertEquals(true, string.isBlank(string.valueOf(mshValues.get('receivingApp'))), 'receivingApp should be LAB');
		// system.assertEquals(true, string.isBlank(string.valueOf(mshValues.get('receivingFacility'))), 'receivingFacility should be SITE');
		// system.assertEquals(Datetime.newInstance(2006,12,20,14,33,0) , Datetime.valueOf(mshValues.get('messageDatetime')), 'messageDatetime should be ' + Datetime.newInstance(2006,12,20,14,33,0));
		// system.assertEquals('ORU', string.valueOf(mshValues.get('messageType')), 'messageType should be ORU');
		// system.assertEquals('R01', string.valueOf(mshValues.get('triggerEvent')), 'messageType should be R01');
		// system.assertEquals('10722.1', string.valueOf(mshValues.get('messageControlID')), 'messageControlID should be 10722.1');
		// system.assertEquals('D', string.valueOf(mshValues.get('processingID')), 'processingID should be D');
		// system.assertEquals('2.4', string.valueOf(mshValues.get('versionID')), 'versionID should be 2.4');
		// system.assertNotEquals('Test', string.valueOf(mshValues.get('messageType')), 'messageType should be ORU');
		// system.assertNotEquals('Test', string.valueOf(mshValues.get('triggerEvent')), 'messageType should be R01');
		staging.Retry_Times__c = 1;
		TriggerFactory.Recursions.clear();
		update staging;
		TriggerFactory.Recursions.clear();
		delete staging;
	}
	@isTest
	private static void testPID() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//PID|1|563750014^^^AB|MG00001234^^^^MR~999-99-9999^^^^SS~232^^^^PI||LastName^FirstName^^^^||19520505|M|||23 Street Address^^MEDICINE HAT^AB^T1A 4N2||(999)999-9999|||||MT0001234/10|1234567890
		map<string, object> pidValues = (map<string, object>) values.get('PID');
		// system.assert(pidValues != null, 'Parse result of PID should not be null');
		// system.assert(pidValues.size() != 0, 'The size of parsing PID result should not be zero');
		// system.assertEquals(1, Integer.valueOf(pidValues.get('setID')), 'setID should be 1');
		// system.assertEquals('563750014', string.valueOf(pidValues.get('mriHubID')), 'setID should be 563750014');
		// system.assertEquals('MG00001234', string.valueOf(pidValues.get('patientMRN:MR')), 'patientMRN:MR should be MG00001234');
		// system.assertEquals('999-99-9999', string.valueOf(pidValues.get('patientMRN:SS')), 'patientMRN:SS should be 999-99-9999');
		// system.assertEquals('232', string.valueOf(pidValues.get('patientMRN:PI')), 'patientMRN:PI should be 232');
		// system.assertEquals('LastName', string.valueOf(pidValues.get('patientLastName')), 'patientLastName should be LastName');
		// system.assertEquals('FirstName', string.valueOf(pidValues.get('patientFirstName')), 'patientFirstName should be FirstName');
		// system.assertEquals(true,string.isBlank(string.valueOf(pidValues.get('patientMiddleName'))), 'patientMiddleName should be empty');
		// system.assertEquals(Date.newInstance(1952,5,5), Date.valueOf(pidValues.get('dateOfBirth')), 'dateOfBirth should be ' + Date.newInstance(1952,5,5));
		// system.assertEquals('M', string.valueOf(pidValues.get('sex')), 'setID should be M');
		// system.assertEquals('23 Street Address', string.valueOf(pidValues.get('address1')), 'address1 should be 23 Street Address');
		// system.assertEquals(true,string.isBlank(string.valueOf(pidValues.get('address2'))), 'address2 should be empty');
		// system.assertEquals('MEDICINE HAT', string.valueOf(pidValues.get('city')), 'city should be MEDICINE HAT');
		// system.assertEquals('AB', string.valueOf(pidValues.get('state')), 'state should be AB');
		// system.assertEquals('T1A 4N2', string.valueOf(pidValues.get('zip')), 'zip should be T1A 4N2');
		// system.assertEquals('(999)999-9999', string.valueOf(pidValues.get('homePhoneNumber')), 'home phone number should be (999)999-9999');
		// system.assertEquals('MT0001234/10', string.valueOf(pidValues.get('patientAccountNumber')), 'patientAccountNumber should be MT0001234/10');
	}

	@isTest
	private static void testPV1() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//PV1|1|O|LABORATORY^^||||AttendingDocId^AttendingDocLast^AttendingDocFirst^G.^^^|||||||||||REF||AHC|||||||||||||||||||LMHA^Medicine Hat Regional Hospital||REG|||200611090956||||||
		map<string, object> pv1Values = (map<string, object>) values.get('PV1');
		// system.assert(pv1Values != null, 'Parse result of PV1 should not be null');
		// system.assert(pv1Values.size() != 0, 'The size of parsing PV1 result should not be zero');
		// system.assertEquals(1, Integer.valueOf(pv1Values.get('setID')),'setID should be 1');
		// system.assertEquals('O',string.valueOf(pv1Values.get('patientStatus')),'patientStatus should be O');
		// system.assertEquals('LABORATORY',string.valueOf(pv1Values.get('assignedLoc')),'assignedLoc should be LABORATORY');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admissionPriority'))),'admissionPriority should be empty');
		// system.assertEquals('AttendingDocId',string.valueOf(pv1Values.get('attendingDoctorID')),'attendingDoctorID should be AttendingDocId');
		// system.assertEquals('AttendingDocLast',string.valueOf(pv1Values.get('attendingDoctorLast')),'attendingDoctorLast should be AttendingDocLast');
		// system.assertEquals('AttendingDocFirst',string.valueOf(pv1Values.get('attendingDoctorFirst')),'attendingDoctorFirst should be AttendingDocFirst');
		// system.assertEquals('G.',string.valueOf(pv1Values.get('attendingDoctorMiddle')),'attendingDoctorMiddle should be G.');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('referringDoctorID'))),'referringDoctorID should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('referringDoctorLast'))),'referringDoctorLast should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('referringDoctorFirst'))),'referringDoctorFirst should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('referringDoctorMiddle'))),'referringDoctorMiddle should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('consultingDoctorID'))),'consultingDoctorID should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('consultingDoctorLast'))),'consultingDoctorLast should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('consultingDoctorFirst'))),'consultingDoctorFirst should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('consultingDoctorMiddle'))),'consultingDoctorMiddle should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('hospitalService'))),'hospitalService should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admitSource'))),'admitSource should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('vipIndicator'))),'vipIndicator should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admittingDoctorID'))),'admittingDoctorID should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admittingDoctorLast'))),'admittingDoctorLast should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admittingDoctorFirst'))),'admittingDoctorFirst should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('admittingDoctorMiddle'))),'admittingDoctorMiddle should be empty');
		// system.assertEquals('REF',string.valueOf(pv1Values.get('patientType')),'patientType should be REF');
		// system.assertEquals('AHC',string.valueOf(pv1Values.get('finacialClass')),'finacialClass should be AHC');
		// system.assertEquals(true,string.isBlank(string.valueOf(pv1Values.get('dischargeDisposition'))),'dischargeDisposition should be ');
		// system.assertEquals('LMHA',string.valueOf(pv1Values.get('servicingFacilityCode')),'servicingFacilityCode should be LMHA');
		// system.assertEquals('Medicine Hat Regional Hospital',string.valueOf(pv1Values.get('servicingFacilityName')),'servicingFacilityName should be Medicine Hat Regional Hospital');
		// system.assertEquals('REG',string.valueOf(pv1Values.get('accountStatus')),'accountStatus should be REG');
		// system.assertEquals(Datetime.newInstance(2006,11,9,9,56,0),Datetime.valueOf(pv1Values.get('admitDatetime')),'admitDatetime should be ' + Datetime.newInstance(2006,11,9,9,56,0));
		// system.assertEquals(null,Datetime.valueOf(pv1Values.get('dischargeDatetime')),'dischargeDatetime should be null');
	}

	@isTest
	private static void testPV2() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//PV2||Item#PV2.2|Item#PV2.3|||||200901021453||Item#PV2.1||Item#PV2.1||||Y||||||Item#PV2.2
		map<string, object> pv2Values = (map<string, object>) values.get('PV2');
		// system.assertEquals('Item#PV2.2',string.valueOf(pv2Values.get('accomodationCode')),'accomodationCode should be Item#PV2.2');
		// system.assertEquals('Item#PV2.3',string.valueOf(pv2Values.get('admitReason')),'admitReason should be Item#PV2.3');
		// system.assertEquals(Datetime.newInstance(2009,1,2,14,53,0),Datetime.valueOf(pv2Values.get('decisionAdmitDatetime')),'decisionAdmitDatetime should be ' + Datetime.newInstance(2009,1,2,14,53,0));
		// system.assertEquals('Item#PV2.1',string.valueOf(pv2Values.get('estimatedLengthInpatient')),'estimatedLengthInpatient should be Item#PV2.1');
		// system.assertEquals('Item#PV2.1',string.valueOf(pv2Values.get('admitComment')),'admitComment should be Item#PV2.1');
		// system.assertEquals('Y',string.valueOf(pv2Values.get('purgeStatusCode')),'purgeStatusCode should be Y');
		// system.assertEquals('Item#PV2.2',string.valueOf(pv2Values.get('visitProtectionIndicator')),'visitProtectionIndicator should be Item#PV2.2');
	}

	@isTest
	private static void testPD1() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//PD1|1|Item#PD1.2||Item#PD1.4||||||||Y
		map<string, object> pd1Values = (map<string, object>) values.get('PD1');
		// system.assertEquals(1, Integer.valueOf(pd1Values.get('setID')),'setID should be 1');
		// system.assertEquals('Item#PD1.2',string.valueOf(pd1Values.get('financialClass')),'financialClass should be Item#PD1.2');
		// system.assertEquals('Item#PD1.4',string.valueOf(pd1Values.get('patientPrimaryCareProvider')),'patientPrimaryCareProvider should be Item#PD1.4');
		// system.assertEquals('Y',string.valueOf(pd1Values.get('vipIndicator')),'vipIndicator should be Y');
	}

	@isTest
	private static void testOBR1() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		// map<string, object> values = processor.values;
		// //system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];

		//OBR|1|43646^MIC|43646^MIC|CUSPU^CULTURE/GRAM,SPUTUM^L|||200612201330|||||||200612201409|SPU^SPUTUM^L|OrderingDocId^OrderingDocLast^OrderingDocFirst^OrderingDocMiddle^^^||||06:M0002811R||200612201433||LAB|COMP||^^^^^R||
		// system.assertEquals(1,Integer.valueOf(obr1Values.get('setID')), 'setID should be 1');
		// system.assertEquals('MIC',string.valueOf(obr1Values.get('placerType')),'placerType should be MIC');
		// system.assertEquals('43646',string.valueOf(obr1Values.get('placerNumber')),'placerNumber should be 43646');
		// system.assertEquals('MIC',string.valueOf(obr1Values.get('fillerType')),'fillerType should be MIC');
		// system.assertEquals('43646',string.valueOf(obr1Values.get('fillerNumber')),'fillerNumber should be 43646');
		// system.assertEquals('CUSPU',string.valueOf(obr1Values.get('orderedCode')),'orderedCode should be CUSPU');
		// system.assertEquals('CULTURE/GRAM,SPUTUM',string.valueOf(obr1Values.get('orderedDesc')),'orderedDesc should be CULTURE/GRAM,SPUTUM');
		// system.assertEquals(true, string.isBlank(string.valueOf(obr1Values.get('priority'))),'priority should be empty');
		// system.assertEquals(Datetime.newInstance(2006,12,20,13,30,0),Datetime.valueOf(obr1Values.get('collectionDatetime')),'collectionDatetime should be ' + Datetime.newInstance(2006,12,20,13,30,0));
		// system.assertEquals(null,obr1Values.get('collectionEndDatetime'),'collectionEndDatetime should be null');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1Values.get('orderingSite'))),'orderingSite should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1Values.get('orderingSiteDesc'))),'orderingSiteDesc should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1Values.get('collectedByUser'))),'collectedByUser should be empty');
		// system.assertEquals(Datetime.newInstance(2006,12,20,14,09,0),Datetime.valueOf(obr1Values.get('specimenReceivedDatetime')),'specimenReceivedDatetime should be ' + Datetime.newInstance(2006,12,20,14,09,0));
		// system.assertEquals('SPU',string.valueOf(obr1Values.get('specimenSourceID')),'specimenSourceID should be SPU');
		// system.assertEquals('SPUTUM',string.valueOf(obr1Values.get('specimenSourceDesc')),'specimenSourceDesc should be SPUTUM');
		// system.assertEquals('OrderingDocId',string.valueOf(obr1Values.get('orderingDoctorId')),'orderingDoctorId should be OrderingDocId');
		// system.assertEquals('OrderingDocLast',string.valueOf(obr1Values.get('orderingDoctorLastName')),'orderingDoctorLastName should be OrderingDocLast');
		// system.assertEquals('OrderingDocFirst',string.valueOf(obr1Values.get('orderingDoctorFirstName')),'orderingDoctorFirstName should be OrderingDocFirst');
		// system.assertEquals('OrderingDocMiddle',string.valueOf(obr1Values.get('orderingDoctorMiddleName')),'orderingDoctorMiddleName should be OrderingDocMiddle');
		// system.assertEquals('LAB',string.valueOf(obr1Values.get('diagnosticServSectID')),'diagnosticServSectID should be LAB');
		// system.assertEquals('COMP',string.valueOf(obr1Values.get('resultStatus')),'resultStatus should be COMP');
	}

	@isTest
	private static void testOBR2() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr2Values = obrValues[1];

		// system.assertEquals(2,Integer.valueOf(obr2Values.get('setID')), 'setID should be 2');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('placerType'))),'placerType should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('placerNumber'))),'placerNumber should be empty');
		// system.assertEquals('MIC',string.valueOf(obr2Values.get('fillerType')),'fillerType should be MIC');
		// system.assertEquals('43646',string.valueOf(obr2Values.get('fillerNumber')),'fillerNumber should be 43646');
		// system.assertEquals('ZLGN05',string.valueOf(obr2Values.get('orderedCode')),'orderedCode should be ZLGN05');
		// system.assertEquals('VITEK - GN05',string.valueOf(obr2Values.get('orderedDesc')),'orderedDesc should be VITEK - GN05');
		// system.assertEquals(true, string.isBlank(string.valueOf(obr2Values.get('priority'))),'priority should be empty');
		// system.assertEquals(Datetime.newInstance(2006,12,20,13,30,0),Datetime.valueOf(obr2Values.get('collectionDatetime')),'collectionDatetime should be ' + Datetime.newInstance(2006,12,20,13,30,0));
		// system.assertEquals(null,obr2Values.get('collectionEndDatetime'),'collectionEndDatetime should be null');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('orderingSite'))),'orderingSite should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('orderingSiteDesc'))),'orderingSiteDesc should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('collectedByUser'))),'collectedByUser should be empty');
		// system.assertEquals(Datetime.newInstance(2006,12,20,14,09,0),Datetime.valueOf(obr2Values.get('specimenReceivedDatetime')),'specimenReceivedDatetime should be ' + Datetime.newInstance(2006,12,20,14,09,0));
		// system.assertEquals('SPU',string.valueOf(obr2Values.get('specimenSourceID')),'specimenSourceID should be SPU');
		// system.assertEquals('SPUTUM',string.valueOf(obr2Values.get('specimenSourceDesc')),'specimenSourceDesc should be SPUTUM');
		// system.assertEquals('OrderingDocId',string.valueOf(obr2Values.get('orderingDoctorId')),'orderingDoctorId should be OrderingDocId');
		// system.assertEquals('OrderingDocLast',string.valueOf(obr2Values.get('orderingDoctorLastName')),'orderingDoctorLastName should be OrderingDocLast');
		// system.assertEquals('OrderingDocFirst',string.valueOf(obr2Values.get('orderingDoctorFirstName')),'orderingDoctorFirstName should be OrderingDocFirst');
		// system.assertEquals('OrderingDocMiddle',string.valueOf(obr2Values.get('orderingDoctorMiddleName')),'orderingDoctorMiddleName should be OrderingDocMiddle');
		// system.assertEquals('LAB',string.valueOf(obr2Values.get('diagnosticServSectID')),'diagnosticServSectID should be LAB');
		// system.assertEquals('COMP',string.valueOf(obr2Values.get('resultStatus')),'resultStatus should be COMP');
		// system.assertEquals('CSPUW',string.valueOf(obr2Values.get('observationID')),'observationID should be CSPUW');
		// system.assertEquals('2.1',string.valueOf(obr2Values.get('observationSubID')),'observationSubID should be 2.1');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('specimenDesc'))),'specimenDesc should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('specimenDescName'))),'specimenDescName should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('specimenDescNameAbbr'))),'specimenDescNameAbbr should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('otherDoctor'))),'otherDoctor should be empty');
		// system.assertEquals('43646',string.valueOf(obr2Values.get('parentAccNum')),'parentAccNum should be 43646');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('verifyUser'))),'verifyUser should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr2Values.get('cancelComments'))),'cancelComments should be empty');
	}
	@isTest
	private static void testOBX() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];
		// list<map<string, object>> obxValues = (list<map<string, object>>)obr1Values.get('OBX');
		// //system.assertEquals(6, obxValues.size(), 'Size should be 6');
		// map<string, object> obx1Values = obxValues[0];

		// system.assertEquals(1,Integer.valueOf(obx1Values.get('setID')),'setID should be 1');
		// system.assertEquals('ST',string.valueOf(obx1Values.get('valueType')),'valueType should be ST');
		// system.assertEquals('GSSPU',string.valueOf(obx1Values.get('observationID')),'observationID should be GSSPU');
		// system.assertEquals('GRAM STAIN,SPUTUM',string.valueOf(obx1Values.get('observationDesc')),'observationDesc should be GRAM STAIN,SPUTUM');
		// system.assertEquals('P:GSSPU',string.valueOf(obx1Values.get('procedureAbbr')),'procedureAbbr should be P:GSSPU');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx1Values.get('procedureType'))),'procedureType should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx1Values.get('procedurePrintNumber'))),'procedurePrintNumber should be empty');
		// system.assertEquals('1',string.valueOf(obx1Values.get('observationSubID')),'observationSubID should be 1');
		// system.assertEquals('GRAM SPUTUM',string.valueOf(obx1Values.get('observationResults')),'observationResults should be GRAM SPUTUM');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx1Values.get('units'))),'units should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx1Values.get('refernceRange'))),'refernceRange should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx1Values.get('abnormalFlags'))),'abnormalFlags should be empty');
		// system.assertEquals('F',string.valueOf(obx1Values.get('obserationResultStatus')),'obserationResultStatus should be F');
		// system.assertEquals(Datetime.newInstance(2006,12,20,13,30,0),Datetime.valueOf(obx1Values.get('collectionDateTime')),'collectionDateTime should be ' + Datetime.newInstance(2006,12,20,13,30,0));
		// system.assertEquals('LMH',string.valueOf(obx1Values.get('siteMnemonic')),'siteMnemonic should be LMH');
		// system.assertEquals('MEDICINE HAT REGIONAL HOSP LAB',string.valueOf(obx1Values.get('siteMnemonicName')),'siteMnemonicName should be MEDICINE HAT REGIONAL HOSP LAB');

		// map<string, object> obx2Values = obxValues[1];
		// system.assertEquals(2,Integer.valueOf(obx2Values.get('setID')),'setID should be 2');
		// system.assertEquals('ST',string.valueOf(obx2Values.get('valueType')),'valueType should be ST');
		// system.assertEquals('GSSPU',string.valueOf(obx2Values.get('observationID')),'observationID should be GSSPU');
		// system.assertEquals('GRAM STAIN,SPUTUM',string.valueOf(obx2Values.get('observationDesc')),'observationDesc should be GRAM STAIN,SPUTUM');
		// system.assertEquals('R:2 NB',string.valueOf(obx2Values.get('procedureAbbr')),'procedureAbbr should be R:2 NB');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx2Values.get('procedureType'))),'procedureType should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx2Values.get('procedurePrintNumber'))),'procedurePrintNumber should be empty');
		// system.assertEquals('1',string.valueOf(obx2Values.get('observationSubID')),'observationSubID should be 1');
		// system.assertEquals('Few Gram negative bacilli',string.valueOf(obx2Values.get('observationResults')),'observationResults should be Few Gram negative bacilli');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx2Values.get('units'))),'units should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx2Values.get('refernceRange'))),'refernceRange should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx2Values.get('abnormalFlags'))),'abnormalFlags should be empty');
		// system.assertEquals('F',string.valueOf(obx2Values.get('obserationResultStatus')),'obserationResultStatus should be F');
		// system.assertEquals(Datetime.newInstance(2006,12,20,13,30,0),Datetime.valueOf(obx2Values.get('collectionDateTime')),'collectionDateTime should be ' + Datetime.newInstance(2006,12,20,13,30,0));
		// system.assertEquals('LMH',string.valueOf(obx2Values.get('siteMnemonic')),'siteMnemonic should be LMH');
		// system.assertEquals('MEDICINE HAT REGIONAL HOSP LAB',string.valueOf(obx2Values.get('siteMnemonicName')),'siteMnemonicName should be MEDICINE HAT REGIONAL HOSP LAB');

		//OBX|6|ST|CSPUW^CULTURE,SPUTUM^L^R:M|2.1|Moderate growth||||||F|||200612201330|LMH^MEDICINE HAT REGIONAL HOSP LAB^L
		// map<string, object> obx6Values = obxValues[5];
		// system.assertEquals(6,Integer.valueOf(obx6Values.get('setID')),'setID should be 6');
		// system.assertEquals('ST',string.valueOf(obx6Values.get('valueType')),'valueType should be ST');
		// system.assertEquals('CSPUW',string.valueOf(obx6Values.get('observationID')),'observationID should be GSSPU');
		// system.assertEquals('CULTURE,SPUTUM',string.valueOf(obx6Values.get('observationDesc')),'observationDesc should be GRAM STAIN,SPUTUM');
		// system.assertEquals('R:M',string.valueOf(obx6Values.get('procedureAbbr')),'procedureAbbr should be R:M');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx6Values.get('procedureType'))),'procedureType should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx6Values.get('procedurePrintNumber'))),'procedurePrintNumber should be empty');
		// system.assertEquals('2.1',string.valueOf(obx6Values.get('observationSubID')),'observationSubID should be 2.1');
		// system.assertEquals('Moderate growth',string.valueOf(obx6Values.get('observationResults')),'observationResults should be Moderate growth');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx6Values.get('units'))),'units should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx6Values.get('refernceRange'))),'refernceRange should be empty');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx6Values.get('abnormalFlags'))),'abnormalFlags should be empty');
		// system.assertEquals('F',string.valueOf(obx6Values.get('obserationResultStatus')),'obserationResultStatus should be F');
		// system.assertEquals(Datetime.newInstance(2006,12,20,13,30,0),Datetime.valueOf(obx6Values.get('collectionDateTime')),'collectionDateTime should be ' + Datetime.newInstance(2006,12,20,13,30,0));
		// system.assertEquals('LMH',string.valueOf(obx6Values.get('siteMnemonic')),'siteMnemonic should be LMH');
		// system.assertEquals('MEDICINE HAT REGIONAL HOSP LAB',string.valueOf(obx6Values.get('siteMnemonicName')),'siteMnemonicName should be MEDICINE HAT REGIONAL HOSP LAB');
	}

	@isTest
	private static void testOBR1NTE() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		// //system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];
		// list<map<string, object>> obr1NTEValues = (list<map<string, object>>)obr1Values.get('NTE');
		// //system.assertEquals(2, obr1NTEValues.size(), 'Size should be 2');
		// map<string, object> obr1NTE1Values = obr1NTEValues[0];

		//'NTE|1||Recent/Current Antibiotic Hx:^NO\n' +
		//'NTE|2||Pertinent Clinical Info?^None provided\n' +
		// system.assertEquals(1, Integer.valueOf(obr1NTE1Values.get('setID')),'setID should be 1');
		// system.assertEquals('Recent/Current Antibiotic Hx:',string.valueOf(obr1NTE1Values.get('comments')),'comments should be Recent/Current Antibiotic Hx:');
		// system.assertEquals('NO',string.valueOf(obr1NTE1Values.get('queryText')),'queryText should be NO');

		// map<string, object> obr1NTE2Values = obr1NTEValues[1];
		// system.assertEquals(2, Integer.valueOf(obr1NTE2Values.get('setID')),'setID should be 2');
		// system.assertEquals('Pertinent Clinical Info?',string.valueOf(obr1NTE2Values.get('comments')),'comments should be Pertinent Clinical Info?');
		// system.assertEquals('None provided',string.valueOf(obr1NTE2Values.get('queryText')),'queryText should be None provided');
	}

	@isTest
	private static void testOBR1SPM() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		// map<string, object> values = processor.values;
		// //system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];
		// map<string, object> obr1SPMValues = (map<string, object>)obr1Values.get('SPM');

		// system.assertEquals(1, Integer.valueOf(obr1SPMValues.get('setID')),'setID should be 1');
		// system.assertEquals('00001122',string.valueOf(obr1SPMValues.get('spRequistionNumber')),'spRequistionNumber should be 00001122');
		// system.assertEquals('1332',string.valueOf(obr1SPMValues.get('spURN')),'spURN should be 1332');
		// system.assertEquals('LAB',string.valueOf(obr1SPMValues.get('spModule')),'spModule should be LAB');
		// system.assertEquals('0413:H00002R',string.valueOf(obr1SPMValues.get('parentSpNumber')),'parentSpNumber should be 0413:H00002R');
		// system.assertEquals('1332',string.valueOf(obr1SPMValues.get('parentSpURN')),'parentSpURN should be 1332');
		// system.assertEquals('LAB',string.valueOf(obr1SPMValues.get('parentSpMudule')),'parentSpMudule should be LAB');
		// system.assertEquals('041310:H2',string.valueOf(obr1SPMValues.get('parentSpCompleteNumber')),'parentSpCompleteNumber should be 041310:H2');
		// system.assertEquals('BLD',string.valueOf(obr1SPMValues.get('spTypeMnemonic')),'spTypeMnemonic should be BLD');
		// system.assertEquals('BLOOD',string.valueOf(obr1SPMValues.get('spTypeName')),'spTypeName should be BLOOD');
		// system.assertEquals('BLOOD',string.valueOf(obr1SPMValues.get('spTypeAbbr')),'spTypeAbbr should be BLOOD');
		// system.assertEquals('100.100',string.valueOf(obr1SPMValues.get('spTypeNumber')),'spTypeNumber should be 100.100');
		// system.assertEquals('BLD',string.valueOf(obr1SPMValues.get('spTypeCategory')),'spTypeCategory should be BLD');
		// system.assertEquals('MAN',string.valueOf(obr1SPMValues.get('spCollectionMethodMnemonic')),'spCollectionMethodMnemonic should be MAN');
		// system.assertEquals('MANUAL',string.valueOf(obr1SPMValues.get('spCollectionMethodName')),'spCollectionMethodName should be MANUAL');
		// system.assertEquals(Datetime.newInstance(2010,4,22,16,10,0),Datetime.valueOf(obr1SPMValues.get('spCollectionDatetime')),'spCollectionDatetime should be ' + Datetime.newInstance(2010,4,22,16,10,0));
		// system.assertEquals(Datetime.newInstance(2010,4,22,16,31,0),Datetime.valueOf(obr1SPMValues.get('spReceiveDatetime')),'spReceiveDatetime should be ' + Datetime.newInstance(2010,4,22,16,31,0));
		// system.assertEquals(1,Integer.valueOf(obr1SPMValues.get('spContainerNumber')),'spContainerNumber should be 1');
		// system.assertEquals('LAV',string.valueOf(obr1SPMValues.get('containerTypeMnemonic')),'containerTypeMnemonic should be LAV');
		// system.assertEquals('LAVENDER',string.valueOf(obr1SPMValues.get('containerTypeName')),'containerTypeName should be LAVENDER');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1SPMValues.get('containerTypeAbbr'))),'containerTypeAbbr should be LAB');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1SPMValues.get('containerTypeNumber'))),'containerTypeNumber should be LAB');
		// system.assertEquals(true,string.isBlank(string.valueOf(obr1SPMValues.get('containerTypeCategory'))),'containerTypeCategory should be LAB');
	}

	@isTest
	private static void testOBR1TQ1() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];
		// map<string, object> obr1TQ1Values = (map<string, object>)obr1Values.get('TQ1');

		// system.assertEquals(2, Integer.valueOf(obr1TQ1Values.get('priority')),'priority should be 2');
	}

	@isTest
	private static void testOBR1SAC() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		// map<string, object> values = processor.values;
		// system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr1Values = obrValues[0];
		// map<string, object> obr1SACValues = (map<string, object>)obr1Values.get('SAC');

		// system.assertEquals('0413:H00002R',string.valueOf(obr1SACValues.get('spNumber')),'spNumber should be 0413:H00002R');
		// system.assertEquals('1332',string.valueOf(obr1SACValues.get('spURN')),'spURN should be 1332');
		// system.assertEquals('LAB',string.valueOf(obr1SACValues.get('spModule')),'spModule should be LAB');
		// system.assertEquals('041310:H2',string.valueOf(obr1SACValues.get('spCompleteNumber')),'spCompleteNumber should be 041310:H2');
		// system.assertNotEquals('LAB1',string.valueOf(obr1SACValues.get('spModule')),'spModule should be LAB');
	}

	@isTest
	private static void testOBR2NTE() {
		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;
		//system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'Size should be 2');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr2Values = obrValues[1];
		// list<map<string, object>> obr2NTEValues = (list<map<string, object>>)obr2Values.get('NTE');
		// //system.assertEquals(2, obr2NTEValues.size(), 'Size should be 2');
		// map<string, object> obr2NTE1Values = obr2NTEValues[0];
		// //'NTE|1||Organism fulfills criteria of an Antibiotic Resistant\n' +
		// //'NTE|2||Organism (ARO).\n' +
		// // system.assertEquals(1, Integer.valueOf(obr2NTE1Values.get('setID')),'setID should be 1');
		// // system.assertEquals('Organism fulfills criteria of an Antibiotic Resistant',string.valueOf(obr2NTE1Values.get('comments')),'The comment should be Organism fulfills criteria of an Antibiotic Resistant');
		// // system.assertEquals(true,string.isBlank(string.valueOf(obr2NTE1Values.get('queryText'))),'queryText should be empty');

		// map<string, object> obr2NTE2Values = obr2NTEValues[1];
		// // system.assertEquals(2, Integer.valueOf(obr2NTE2Values.get('setID')),'setID should be 2');
		// // system.assertEquals('Organism (ARO).',string.valueOf(obr2NTE2Values.get('comments')),'The comment should be Organism (ARO).');
		// // system.assertEquals(true,string.isBlank(string.valueOf(obr2NTE2Values.get('queryText'))),'queryText should be empty');
	}

	@isTest
	private static void testOBXNTE() {
		//This is to test parsing OBX's NTE segments
		//'OBX|4|ST|TICCA^TICARCILLIN-CLAVULANATE^L|||||S|||F|||200612201432|LMH^MEDICINE HAT REGIONAL HOSP LAB^L\n' +
		//'NTE|1||Organism fulfills criteria of an Antibiotic Resistant\n' +
		//'NTE|2||Organism (ARO).\n' +

		BHS_Order_Result_Staging__c staging = [SELECT Payload__c FROM BHS_Order_Result_Staging__c LIMIT 1];
		string payload = staging.Payload__c;
		string[] segments = payload.split('\\n');
		BHS_OrderResultProcessor processor = new BHS_OrderResultProcessor(segments);
		processor.process();
		map<string, object> values = processor.values;

		// system.assertEquals(2, ((list<map<string, object>>)values.get('OBR')).size(), 'There should have two OBRs in test ORU HL7 message.');
		// list<map<string, object>> obrValues = (list<map<string, object>>)values.get('OBR');
		// map<string, object> obr2Values = obrValues[1];
		// list<map<string, object>> obr2OBXValues = (list<map<string, object>>)obr2Values.get('OBX');
		// system.assertEquals(19, obr2OBXValues.size(), 'There should have 19 OBX segments in the second OBR segment.');
		// map<string, object> obr2OBX4Values = obr2OBXValues[3];

		// list<map<string, object>> obxNTEValues = (list<map<string, object>>)obr2OBX4Values.get('NTE');
		// system.assertEquals(2, obxNTEValues.size(), 'There should have two NTE segments in the forth OBX of the second OBR.');
		// map<string, object> obx4NTE1Values = obxNTEValues[0];

		// system.assertEquals(1, Integer.valueOf(obx4NTE1Values.get('setID')),'This should be the first NTE.');
		// system.assertEquals('Organism fulfills criteria of an Antibiotic Resistant',string.valueOf(obx4NTE1Values.get('comments')),'The comment should be Organism fulfills criteria of an Antibiotic Resistant');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx4NTE1Values.get('queryText'))),'queryText should be empty');
		// map<string, object> obx4NTE2Values = obxNTEValues[1];
		// system.assertEquals(2, Integer.valueOf(obx4NTE2Values.get('setID')),'This should be the second NTE');
		// system.assertEquals('Organism (ARO).',string.valueOf(obx4NTE2Values.get('comments')),'The comment should be Organism (ARO).');
		// system.assertEquals(true,string.isBlank(string.valueOf(obx4NTE2Values.get('queryText'))),'queryText should be empty');
	}
	@isTest
	private static void testMiscMethods() {
		List<String> aNullList = null;
		BHS_OrderResultProcessor testNullList = new BHS_OrderResultProcessor(aNullList);
		system.assertEquals(null, BHS_ORU_ObjectsUtils.convertDatetimeString(null), 'The result shouldbe null');
	}

	@isTest
	private static void testLoginCallout() {
		StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('BHS_MockLogin');
		mock.setStatusCode(200);
		mock.setHeader('Content-Type', 'application/json');
		Test.setMock(HttpCalloutMock.class, mock);
	}
}