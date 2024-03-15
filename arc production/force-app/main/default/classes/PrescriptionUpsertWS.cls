@RestResource(urlMapping='/prescription/upsert')
global without sharing class PrescriptionUpsertWS {
	@HttpPost
	global static ID upsertPrescription() {
		try {
			RestRequest req = RestContext.request;
			Map<String, String> headers = req.headers;
			Map<String, String> params = req.params;

			Blob body = req.requestBody;
			String jsonStr = body.toString();

			String value = AdminKeyValueMetadataHelper.getValueForKey('ScriptSure_Process_Logging_Prescriptions');
			if (null != value && value.equalsIgnoreCase('true')) {
				ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil_LOGGING', 'upsertPrescription - POST Body.', jsonStr.subString(0, jsonStr.length() > 131000 ? 131000 : jsonStr.length()));
			}

			List<Prescription__c> prescriptionList;
			ScriptSure_ServiceUtil.PrescriptionDetail prescriptionDetail;
			prescriptionDetail = (ScriptSure_ServiceUtil.PrescriptionDetail) JSON.deserialize(jsonStr, ScriptSure_ServiceUtil.PrescriptionDetail.class);

			String accountId = '';
			try {
				accountId = [SELECT Id FROM Account WHERE External_Patient_Id__c = :prescriptionDetail.patientId LIMIT 1].Id;
			} catch (Exception ex) {
				return 'Failure - No matching patient, probably from the wrong sandbox.';
			}

			ScriptSure_ServiceUtil.PrescritionHeader prescriptionHeader = new ScriptSure_ServiceUtil.PrescritionHeader();
			prescriptionHeader.Prescription = prescriptionDetail;
			prescriptionHeader.prescriptionId = prescriptionDetail.prescriptionId;
			ScriptSure_ServiceUtil.PrescriptionWrapper prescriptionWrapper = new ScriptSure_ServiceUtil.PrescriptionWrapper();
			List<ScriptSure_ServiceUtil.PrescritionHeader> prescriptionHeaders = new List<ScriptSure_ServiceUtil.PrescritionHeader>();
			prescriptionHeaders.add(prescriptionHeader);
			prescriptionWrapper.Prescriptions = prescriptionHeaders;
			prescriptionList = ScriptSure_ServiceUtil.createUpdatePrescriptions(prescriptionWrapper, accountId);
			return prescriptionList.get(0).Id;
		} catch (Exception ex) {
			EventBus.publish(new CreateErrorLogEvent__e(Process_Name__c = 'ScriptSure_ServiceUtil', Stack_Trace__c = ex.getStackTraceString(), Message__c = ex.getMessage()));
		}
		return null;
	}

	// @HttpPost
	// @RestResource(urlMapping='/prescription/delete')
	// global static String deletePrescription() {
	//     try {
	//         return 'Success';

	//     } catch (Exception ex) {
	//         EventBus.publish(new CreateErrorLogEvent__e(Process_Name__c ='ScriptSure_ServiceUtil', Stack_Trace__c=ex.getStackTraceString(), Message__c= ex.getMessage() ));
	//     }
	//     return null;
	// }

	// @HttpPost
	// @RestResource(urlMapping='/prescription/queued')
	// global static String queuedPrescription() {
	//     try {
	//         return 'Success';

	//     } catch (Exception ex) {
	//         EventBus.publish(new CreateErrorLogEvent__e(Process_Name__c ='ScriptSure_ServiceUtil', Stack_Trace__c=ex.getStackTraceString(), Message__c= ex.getMessage() ));
	//     }
	//     return null;
	// }
}