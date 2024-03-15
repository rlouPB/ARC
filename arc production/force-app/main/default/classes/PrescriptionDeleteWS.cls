@RestResource(urlMapping='/prescription/delete')
global without sharing class PrescriptionDeleteWS {
	@HttpPost
	global static String deletePrescription() {
		try {
			RestRequest req = RestContext.request;
			Map<String, String> headers = req.headers;
			Map<String, String> params = req.params;

			Blob body = req.requestBody;
			String jsonStr = body.toString();

			String value = AdminKeyValueMetadataHelper.getValueForKey('ScriptSure_Process_Logging_Prescriptions');
			if (null != value && value.equalsIgnoreCase('true')) {
				ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil_LOGGING', 'deletePrescription - POST Body.', jsonStr.subString(0, jsonStr.length() > 131000 ? 131000 : jsonStr.length()));
			}

			List<Prescription__c> prescriptionList;
			ScriptSure_ServiceUtil.PrescriptionDetail prescriptionDetail;
			prescriptionDetail = (ScriptSure_ServiceUtil.PrescriptionDetail) JSON.deserialize(jsonStr, ScriptSure_ServiceUtil.PrescriptionDetail.class);
			Decimal externalPatientId = Decimal.valueOf(prescriptionDetail.prescriptionId);

			Prescription__c p;
			try {
				p = [SELECT Id, Status__c, External_Prescription_Id__c FROM Prescription__c WHERE External_Prescription_Id__c = :externalPatientId];
			} catch (Exception ex) {
				return 'Failure - No matching patient, probably from the wrong sandbox.';
			}
			p.Status__c = 'Canceled';
			p.Inactive_Datetime__c = DateTime.now();
			update p;

			return 'Success';
		} catch (Exception ex) {
			EventBus.publish(new CreateErrorLogEvent__e(Process_Name__c = 'ScriptSure_ServiceUtil', Stack_Trace__c = ex.getStackTraceString(), Message__c = ex.getMessage()));
		}
		return null;
	}
}