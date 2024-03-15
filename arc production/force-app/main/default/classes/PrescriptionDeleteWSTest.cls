@isTest
public with sharing class PrescriptionDeleteWSTest {
	@TestSetup
	static void createTestData() {
		ScriptSure_ServiceTest.createTestData();
		Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];
		patient.External_Patient_Id__c = '12345';
		update patient;
	}

	@isTest
	static void queuedPrescriptionTest() {
		RestRequest request = new RestRequest();
		request.requestUri = PrescriptionUpsertWSTest.getSiteUrl('integration') + 'services/apexrest/prescription/delete';
		request.httpMethod = 'POST';
		RestContext.request = request;
		request.addHeader('Content-Type', 'application/json');
		String jsonStr = PrescriptionDeleteWSTest.getPrescriptionJSON();
		request.requestBody = Blob.valueOf(jsonStr);

		String exceptionMsg;

		try {
			Id prescriptionId = PrescriptionDeleteWS.deletePrescription();
		} catch (Exception e) {
			exceptionMsg = e.getMessage();
			System.assertEquals(exceptionMsg, 'Invalid id: Failure - No matching patient, probably from the wrong sandbox.');
		}
	}

	@isTest
	static void queuedPrescriptionTest2() {
		Account acct = [SELECT Id, External_Patient_Id__c FROM Account WHERE External_Patient_Id__c = '12345' LIMIT 1];
		Prescription__c pres = new Prescription__c(Account__c = acct.Id, Status__c = 'Active', External_Prescription_Id__c = 131046);
		insert pres;

		RestRequest request = new RestRequest();
		request.requestUri = PrescriptionUpsertWSTest.getSiteUrl('integration') + 'services/apexrest/prescription/delete';
		request.httpMethod = 'POST';
		RestContext.request = request;
		request.addHeader('Content-Type', 'application/json');
		String jsonStr = PrescriptionDeleteWSTest.getPrescriptionJSON();
		request.requestBody = Blob.valueOf(jsonStr);

		String exceptionMsg;

		try {
			Id prescriptionId = PrescriptionDeleteWS.deletePrescription();
		} catch (Exception e) {
			exceptionMsg = e.getMessage();
			System.assertEquals(exceptionMsg, 'Invalid id: Success');
		}
	}

	public static String getPrescriptionJSON() {
		String jsonStr =
			'{' +
			'"prescriptionId": 131046,' +
			'"patientId": 12345,' +
			'            "encounterId": 30262,' +
			'            "messageId": "DEA309536C814AD59E6DDF0FCCD71E29",' +
			'            "messageType": null,' +
			'            "practiceId": 557,' +
			'            "userId": 3282,' +
			'            "userName": "Jeff Test",' +
			'            "supervisorId": null,' +
			'            "supervisorName": null,' +
			'            "doctorId": 3289,' +
			'            "doctorName": "Nicholas Test",' +
			'            "followUpPrescriberId": null,' +
			'            "followUpPrescriberName": null,' +
			'            "approveId": 3289,' +
			'            "approveName": "Nicholas Test",' +
			'            "approveDate": "2022-09-29T14:42:53.000Z",' +
			'            "refill": 11,' +
			'            "writtenDate": "2022-09-29T14:37:29.000Z",' +
			'            "fillDate": "2022-09-29T14:37:29.000Z",' +
			'            "duration": 30,' +
			'            "durationQualifier": null,' +
			'            "combinationMed": null,' +
			'            "printDuration": null,' +
			'            "compoundTitle": null,' +
			'            "compoundQuantity": null,' +
			'            "compoundQuantityQualifier": null,' +
			'            "compoundDrugDuration": null,' +
			'            "compoundDrugDurationPadded": null,' +
			'            "concurrentMed": null,' +
			'            "archive": false,' +
			'            "sendMethod": 6,' +
			'            "formularyChecked": true,' +
			'            "pharmacyId": "0068000",' +
			'            "pharmacy": "CVS 68000",' +
			'            "prescriptionType": 1,' +
			'            "prescriptionStatusTypeId": 1,' +
			'            "messageStatus": null,' +
			'            "maxDaily": 1,' +
			'            "groupId": null,' +
			'            "pharmacyNote": null,' +
			'            "internalComment": null,' +
			'            "authorizationStatus": null,' +
			'            "authorizationQualifier": null,' +
			'            "authorizationId": null,' +
			'            "ipAddress": "66.66.115.5",' +
			'            "createdAt": "2022-09-29T14:37:29.000Z",' +
			'            "updatedAt": "2022-09-29T14:42:54.000Z",' +
			'            "practiceIdExternal": null,' +
			'            "userIdExternal": null,' +
			'            "doctorIdExternal": null,' +
			'            "PrescriptionScript":' +
			'            {' +
			'                "prescriptionId": 131046,' +
			'                "drugFormat": "ER 80 mg capsule,24 hr,extended release -  30 Capsule - Take 1 capsule by mouth daily"' +
			'            },' +
			'            "PrescriptionAlerts":' +
			'            [],' +
			'            "PrescriptionDrugs":' +
			'            [' +
			'                {' +
			'                    "drugDuration": "2023-09-24",' +
			'                    "drugDurationPadded": null,' +
			'                    "prescriptionId": 131046,' +
			'                    "drugId": 127856,' +
			'                    "drugOrder": 84,' +
			'                    "ndc": "00228277911",' +
			'                    "rxnorm": "856569",' +
			'                    "rxnormQualifier": "SCD",' +
			'                    "ROUTED_MED_ID": 10404,' +
			'                    "GCN_SEQNO": 5116,' +
			'                    "drugName": "Propranolol",' +
			'                    "MED_NAME_TYPE_CD": 2,' +
			'                    "MED_REF_DEA_CD": "0",' +
			'                    "MED_REF_GEN_DRUG_NAME_CD": "1",' +
			'                    "MED_REF_FED_LEGEND_IND": "1",' +
			'                    "quantity": 30,' +
			'                    "quantityQualifier": "C48480",' +
			'                    "calculate": true,' +
			'                    "sampleLotNumber": null,' +
			'                    "sampleExpiration": null,' +
			'                    "useSubstitution": true,' +
			'                    "line1": "ER 80 mg capsule,24 hr,extended release",' +
			'                    "line2": "",' +
			'                    "reconcileDate": null,' +
			'                    "reconcileStatus": null,' +
			'                    "reconcileUserId": null,' +
			'                    "PrescriptionSigs":' +
			'                    [' +
			'                        {' +
			'                            "drugId": 127856,' +
			'                            "sigId": 120082,' +
			'                            "sigOrder": 1,' +
			'                            "line3": "Take 1 capsule by mouth daily",' +
			'                            "multipleSigModifier": null,' +
			'                            "doseDeliveryMethodCode": "419652001",' +
			'                            "doseDeliveryMethodText": "Take",' +
			'                            "doseQuantity": 1,' +
			'                            "doseFormCode": "C48480",' +
			'                            "doseFormText": "Capsule",' +
			'                            "doseRangeModifier": null,' +
			'                            "doseQuantityRange": null,' +
			'                            "doseFormCodeRange": null,' +
			'                            "doseFormTextRange": null,' +
			'                            "routeofAdministrationCode": "26643006",' +
			'                            "routeofAdministrationText": "by mouth",' +
			'                            "siteofAdministrationCode": null,' +
			'                            "siteofAdministrationText": null,' +
			'                            "administrationTimingCode": "69620002",' +
			'                            "administrationTimingText": "Daily",' +
			'                            "secondaryAdministrationTimingCode": null,' +
			'                            "secondaryAdministrationTimingText": null,' +
			'                            "secondaryAdministrationTimingModifierCode": null,' +
			'                            "secondaryAdministrationTimingModifierText": null,' +
			'                            "frequencyNumericValue": null,' +
			'                            "frequencyUnitsCode": null,' +
			'                            "frequencyUnitsText": null,' +
			'                            "intervalNumericValue": 1,' +
			'                            "intervalUnitsCode": "258703001",' +
			'                            "variableIntervalModifier": null,' +
			'                            "intervalNumericValueVariable": null,' +
			'                            "intervalUnitsText": "Day",' +
			'                            "indicationPrecursorCode": null,' +
			'                            "indicationPrecursorText": null,' +
			'                            "indicationTextCode": null,' +
			'                            "indicationText": null,' +
			'                            "indicationValueUnitofMeasureCode": null,' +
			'                            "indicationValueUnitofMeasureText": null,' +
			'                            "maximumDoseRestrictionNumericValue": null,' +
			'                            "maximumDoseRestrictionFormText": null,' +
			'                            "maximumDoseRestrictionFormQualifier": null,' +
			'                            "maximumDoseRestrictionFormCode": null,' +
			'                            "maximumDoseRestrictionDurationValue": null,' +
			'                            "maximumDoseRestrictionDurationUnitText": null,' +
			'                            "maximumDoseRestrictionDurationUnitCode": null,' +
			'                            "durationNumericValue": null,' +
			'                            "durationTextCode": "258703001",' +
			'                            "durationText": "Days",' +
			'                            "descriptor": "",' +
			'                            "dose": 30,' +
			'                            "conversionTotal": 30,' +
			'                            "calculate": true' +
			'                        }' +
			'                    ]' +
			'                }' +
			'            ],' +
			'            "PrescriptionDiagnoses":' +
			'            [],' +
			'            "PrescriptionStatuses":' +
			'            [' +
			'                {' +
			'                    "prescriptionStatusId": 41735,' +
			'                    "prescriptionStatusTypeId": 1,' +
			'                    "prescriptionId": 131046,' +
			'                    "name": "Active",' +
			'                    "encounterId": 30262,' +
			'                    "userId": null,' +
			'                    "userName": null,' +
			'                    "createdAt": "2022-09-29T14:37:29.000Z"' +
			'                }' +
			'            ],' +
			'            "PrescriptionComments":' +
			'            [' +
			'                {' +
			'                    "commentId": 4775,' +
			'                    "patientId": 81965,' +
			'                    "ROUTED_MED_ID": 10404,' +
			'                    "encounterId": 30262,' +
			'                    "prescriptionId": 131046,' +
			'                    "expirationDate": null,' +
			'                    "type": 0,' +
			'                    "archive": 0,' +
			'                    "userId": 3289,' +
			'                    "userName": "Nicholas Test",' +
			'                    "doctorId": 3289,' +
			'                    "doctorName": "Nicholas Test",' +
			'                    "comment": "Queued prescription approved by Nicholas Test",' +
			'                    "createdAt": "2022-09-29T14:42:54.000Z",' +
			'                    "updatedAt": "2022-09-29T14:42:54.000Z"' +
			'                }' +
			'            ]' +
			'        }';
		return jsonStr;
	}
}