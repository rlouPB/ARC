@isTest
global class ScriptSureIntegrationCalloutMock implements HttpCalloutMock {
	global HTTPResponse respond(HTTPRequest request) {
		HttpResponse response = new HttpResponse();

		response.setHeader('Content-Type', 'application/json');
		response.setStatusCode(200);

		//Authenticate
		if (request.getEndpoint().contains('login')) {
			response.setBody('{"sessionToken": "VbLXMJAgD4V1XRGKs1dMsjxtTWHkxlIw"}');
			return response;
		}

		//Prescriber
		if (request.getEndpoint().contains('user/practice/prescriber')) {
			response.setBody('{ "practiceId": 1, "prescriberId": 212 }');
			return response;
		}

		//Create Patient
		if (request.getEndpoint().contains('v1.0/encounter/current/')) {
			response.setBody('{"successMsg": "New Encounter Created",' + '"savedEncounterObj": {' + '  "encounterId": 18839,' + '  "userId": 1255,' + '  "guid": "5c2c7554-67c9-41bf-a0f4-f05a490ae5c7",' + '  "patientId": "12944",' + '  "practiceId": 557,' + '  "userName": "Alexcia Adams",' + '  "doctorId": 1255,' + '  "doctorName": "Alexcia Adams",' + '  "encounterStatus": "A",' + '  "updatedAt": "2021-03-23T01:57:49.000Z",' + '  "createdAt": "2021-03-23T01:57:49.000Z"' + '}}');
			return response;
		}

		//Create Patient
		if (request.getEndpoint().contains('/v1.0/patient')) {
			response.setBody(
				'{"sucessMsg": "Ok", "savedPatientObj": { ' +
				'"dob": "2004-02-11",' +
				'"patientId": 12944,' +
				'"patientIdExternal": null,' +
				'"patientSource": null,' +
				'"practiceId": 557,' +
				'"doctorId": 1285,' +
				'"chartId": null,' +
				'"ssn": null,' +
				'"firstName": "Patient",' +
				'"middleName": null,' +
				'"lastName": "Demo 18",' +
				'"suffix": null,' +
				'"gender": "M",' +
				'"sexualOrientation": null,' +
				'"sexualOrientationDescription": null,' +
				'"genderIdentity": null,' +
				'"genderIdentityDescription": null,' +
				'"ethnicityId": null,' +
				'"alternateEthnicityId": null,' +
				'"raceId": null,' +
				'"alternateRaceId": null,' +
				'"languageId": null,' +
				'"maritalStatusId": null,' +
				'"addressLine1": "Address Line 1",' +
				'"addressLine2": null,' +
				'"city": "NY",' +
				'"zip": "10016",' +
				'"state": "NY",' +
				'"countryCode": "US",' +
				'"home": null,' +
				'"work": null,' +
				'"cell": "4628973145",' +
				'"email": null,' +
				'"preferredCommunicationId": "P",' +
				'"emergencyContact": null,' +
				'"relationId": null,' +
				'"phone1Emergency": null,' +
				'"phone2Emergency": null,' +
				'"addressLine1Work": null,' +
				'"addressLine2Work": null,' +
				'"cityWork": null,' +
				'"stateWork": null,' +
				'"zipWork": null,' +
				'"phone1Work": null,' +
				'"phone2Work": null,' +
				'"hippaCompliance": null,' +
				'"hippaComplianceDate": null,' +
				'"consent": true,' +
				'"patientStatusId": 0,' +
				'"nextOfKinPatientId": null,' +
				'"nextOfKinName": null,' +
				'"nextOfKinPhone": null,' +
				'"nextOfKinRelation": null,' +
				'"motherFirstName": null,' +
				'"motherLastName": null,' +
				'"generalHealth": null,' +
				'"generalComment": null,' +
				'"removeSearch": null,' +
				'"deathDate": null,' +
				'"deathCause": null,' +
				'"userIdAdded": 1255,' +
				'"userAdded": "alexcia.adams@austenriggs.net",' +
				'"userIdUpdated": 1255,' +
				'"userUpdated": "alexcia.adams@austenriggs.net",' +
				'"deletedAt": null,' +
				'"createdAt": "2021-02-08T19:10:46.000Z",' +
				'"updatedAt": "2021-02-08T19:10:46.000Z"}}'
			);
			return response;
		}

		//Search Allergies
		if (request.getEndpoint().contains('/v1.0/allergy/search')) {
			response.setBody('[{' + '"allergyType": "1",' + '"allergyId": "53320",' + '"ROUTED_MED_ID": 77946,' + '"Descr": "4-Dihydrotestosterone (Bulk)"}]');
			return response;
		}

		//Get Patient Allergies
		if (request.getEndpoint().contains('v1.0/allergy/patient/')) {
			response.setBody(
				'[  {' +
				'"id": 4957,' +
				'"patientId": 13148,' +
				'"encounterId": 18688,' +
				'"HIC_SEQN": null,' +
				'"DAM_ALRGN_GRP": 0,' +
				'"GCN_SEQN": "",' +
				'"rxnorm": null,' +
				'"ndc": null,' +
				'"allergyType": "0",' +
				'"reactionId": 1,' +
				'"severityCode": "2",' +
				'"adverseEventCode": "414285001",' +
				'"name": "Acetaminophen Non Aspirin oral",' +
				'"comment": "comments in here",' +
				'"onsetDate": "2021-03-09T00:00:00.000Z",' +
				'"endDate": null,' +
				'"archive": 0,' +
				'"userId": 2758,' +
				'"userName": "David Avery",' +
				'"doctorId": 2758,' +
				'"doctorName": "David Avery",' +
				'"createdAt": "2021-03-05T13:52:54.000Z",' +
				'"updatedAt": "2021-03-05T13:52:54.000Z"' +
				'    },' +
				'    {' +
				'"id": 5067,' +
				'"patientId": 13148,' +
				'"encounterId": 18790,' +
				'"HIC_SEQN": null,' +
				'"DAM_ALRGN_GRP": 0,' +
				'"GCN_SEQN": "",' +
				'"rxnorm": null,' +
				'"ndc": null,' +
				'"allergyType": "0",' +
				'"reactionId": 0,' +
				'"severityCode": "2",' +
				'"adverseEventCode": "414285001",' +
				'"name": "4-Dihydrotestosterone (Bulk)",' +
				'"comment": "123",' +
				'"onsetDate": "2021-03-09T00:00:00.000Z",' +
				'"endDate": null,' +
				'"archive": 0,' +
				'"userId": 2758,' +
				'"userName": "David Avery",' +
				'"doctorId": 2758,' +
				'"doctorName": "David Avery",' +
				'"createdAt": "2021-03-17T17:29:21.000Z",' +
				'"updatedAt": "2021-03-17T17:29:21.000Z"' +
				'    },' +
				'    {' +
				'"id": 5086,' +
				'"patientId": 13148,' +
				'"encounterId": 18804,' +
				'"HIC_SEQN": null,' +
				'"DAM_ALRGN_GRP": 0,' +
				'"GCN_SEQN": "",' +
				'"rxnorm": null,' +
				'"ndc": null,' +
				'"allergyType": "0",' +
				'"reactionId": 2,' +
				'"severityCode": "5",' +
				'"adverseEventCode": "419199007",' +
				'"name": "Hay Fever Formula oral",' +
				'"comment": null,' +
				'"onsetDate": "2000-02-29T00:00:00.000Z",' +
				'"endDate": null,' +
				'"archive": 0,' +
				'"userId": 2758,' +
				'"userName": "David Avery",' +
				'"doctorId": 2758,' +
				'"doctorName": "David Avery",' +
				'"createdAt": "2021-03-18T17:45:35.000Z",' +
				'"updatedAt": "2021-03-18T17:46:03.000Z"' +
				'    },' +
				'    {' +
				'"id": 5087,' +
				'"patientId": 13148,' +
				'"encounterId": 18804,' +
				'"HIC_SEQN": null,' +
				'"DAM_ALRGN_GRP": 0,' +
				'"GCN_SEQN": "",' +
				'"rxnorm": null,' +
				'"ndc": null,' +
				'"allergyType": "0",' +
				'"reactionId": 1,' +
				'"severityCode": "6",' +
				'"adverseEventCode": "419199007",' +
				'"name": "CAT/FELINE PRODUCTS",' +
				'"comment": null,' +
				'"onsetDate": "2000-02-29T00:00:00.000Z",' +
				'"endDate": "2021-03-01T00:00:00.000Z",' +
				'"archive": 0,' +
				'"userId": 2758,' +
				'"userName": "David Avery",' +
				'"doctorId": 2758,' +
				'"doctorName": "David Avery",' +
				'"createdAt": "2021-03-18T18:20:43.000Z",' +
				'"updatedAt": "2021-03-19T13:57:56.000Z"' +
				'    },' +
				'    {' +
				'"id": 5126,' +
				'"patientId": 13148,' +
				'"encounterId": 18841,' +
				'"HIC_SEQN": null,' +
				'"DAM_ALRGN_GRP": 0,' +
				'"GCN_SEQN": "",' +
				'"rxnorm": null,' +
				'"ndc": null,' +
				'"allergyType": "0",' +
				'"reactionId": 1,' +
				'"severityCode": "2",' +
				'"adverseEventCode": "414285001",' +
				'"name": "Accu-Chek Comfort Curve Test",' +
				'"comment": "Test",' +
				'"onsetDate": "2021-03-15T00:00:00.000Z",' +
				'"endDate": null,' +
				'"archive": 0,' +
				'"userId": 2758,' +
				'"userName": "David Avery",' +
				'"doctorId": 2758,' +
				'"doctorName": "David Avery",' +
				'"createdAt": "2021-03-23T03:02:36.000Z",' +
				'"updatedAt": "2021-03-23T03:02:36.000Z"' +
				'    }]'
			);

			return response;
		}

		//Create Allergy
		if (request.getEndpoint().contains('v1.0/allergy')) {
			response.setBody('{"id":4889,"reactionId":2,"patientId":13148,' + '"onsetDate":"2021-02-07T00:00:00.000Z","name":"Abbott-Hbe Eia 100-Test Kit 3",' + '"comment":"5","archive":0,"allergyType":0,"adverseEventCode":"418038007",' + '"encounterId":18546,"userId":1255,"userName":"Alexcia Adams","doctorId":1255,"doctorName":"Alexcia Adams",' + '"DAM_ALRGN_GRP":0,"GCN_SEQN":"","updatedAt":"2021-02-15T01:41:41.000Z","createdAt":"2021-02-15T01:41:41.000Z"}');
			return response;
		}

		//Get Prescriptions
		if (request.getEndpoint().contains('/v1.0/mailbox/prescription')) {
			String body =
				'{"processSet":"1430d24657af424588b280d9f7d8ff8d","prescriptions":[{"id":20497,"prescriptionId":112377,"businessUnitId":523,' +
				'"actionType":"U","processSet":"3cdcd82b184e4c31be6a310b4929f07c","createdAt":"2021-02-08T19:15:21.000Z","Prescription":{"prescriptionId":112377,' +
				'"patientId":13148,"encounterId":18487,"messageId":"3203adbf91d742e6b85833dd3df47bb9","practiceId":557,"userId":1255,"userName":"Alexcia Adams",' +
				'"supervisorId":null,"supervisorName":null,"doctorId":1255,"doctorName":"Alexcia Adams","followUpPrescriberId":null,"followUpPrescriberName":null,' +
				'"approveId":null,"approveName":null,"approveDate":null,"refill":15,"writtenDate":"2021-02-08T19:15:11.000Z","fillDate":"2021-02-08T19:15:11.000Z",' +
				'"duration":30,"durationQualifier":null,"combinationMed":null,"printDuration":null,"compoundTitle":null,"compoundQuantity":null,"compoundQuantityQualifier":null,' +
				'"compoundDrugDuration":null,"compoundDrugDurationPadded":null,"concurrentMed":null,"archive":false,"sendMethod":5,"formularyChecked":true,"pharmacyId":null,' +
				'"pharmacy":null,"prescriptionType":1,"prescriptionStatusTypeId":1,"messageStatus":null,"maxDaily":3,"groupId":null,"pharmacyNote":null,"internalComment":null,' +
				'"authorizationStatus":null,"authorizationQualifier":null,"authorizationId":null,"createdAt":"2021-02-08T19:15:21.000Z","updatedAt":"2021-02-08T19:15:21.000Z",' +
				'"Patient":{"dob":"2021-02-15","patientIdExternal":null},"PrescriptionScript":{"prescriptionId":112377,' +
				'"drugFormat":"200 mg capsule -  90 Capsule - Take 1 capsule by mouth three times daily"},"PrescriptionAlerts":[],' +
				'"PrescriptionDrugs":[{"drugDuration":"2022-06-03","drugDurationPadded":null,"prescriptionId":112377,"drugId":111102,"drugOrder":6,"ndc":"00093894001",' +
				'"rxnorm":"197310","rxnormQualifier":"SCD","ROUTED_MED_ID":941,"GCN_SEQNO":9630,"drugName":"Acyclovir","MED_NAME_TYPE_CD":2,"MED_REF_DEA_CD":"0",' +
				'"MED_REF_GEN_DRUG_NAME_CD":"1","MED_REF_FED_LEGEND_IND":"1","quantity":90,"quantityQualifier":"C48480","calculate":true,"sampleLotNumber":null,' +
				'"sampleExpiration":null,"useSubstitution":true,"line1":"200 mg capsule","line2":"","reconcileDate":null,"reconcileStatus":null,"reconcileUserId":null,' +
				'"PrescriptionSigs":[{"drugId":111102,"sigId":106202,"sigOrder":1,"line3":"Take 1 capsule by mouth three times daily","multipleSigModifier":null,' +
				'"doseDeliveryMethodCode":"419652001","doseDeliveryMethodText":"Take","doseQuantity":1,"doseFormCode":"C48480","doseFormText":"Capsule",' +
				'"routeofAdministrationCode":"26643006","routeofAdministrationText":"by mouth","siteofAdministrationCode":null,"siteofAdministrationText":null,' +
				'"administrationTimingCode":"229798009","administrationTimingText":"Three times daily","secondaryAdministrationTimingCode":null,' +
				'"secondaryAdministrationTimingText":null,"secondaryAdministrationTimingModifierCode":null,"secondaryAdministrationTimingModifierText":null,' +
				'"frequencyNumericValue":3,"frequencyUnitsCode":"258703001","frequencyUnitsText":"Day","indicationPrecursorCode":null,"indicationPrecursorText":null,' +
				'"indicationTextCode":null,"indicationText":null,"indicationValueUnitofMeasureCode":null,"indicationValueUnitofMeasureText":null,"durationNumericValue":null,' +
				'"durationTextCode":"258703001","durationText":"Days","descriptor":"","dose":90,"conversionTotal":1,"calculate":true}]}],"PrescriptionDiagnoses":[],' +
				'"PrescriptionStatuses":[{"prescriptionStatusId":20028,"prescriptionStatusTypeId":1,"prescriptionId":112377,"name":"Active","encounterId":18487,' +
				'"userId":1255,"userName":"Alexcia Adams","createdAt":"2021-02-08T19:15:21.000Z"}],"PrescriptionComments":[]}}]}';

			response.setBody(body);
			return response;
		}

		return response;
	}
}