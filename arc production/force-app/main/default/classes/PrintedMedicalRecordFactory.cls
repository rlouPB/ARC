public with sharing class PrintedMedicalRecordFactory {
	static Map<String, String> printedMedicalRecordHandlerMap = new Map<String, String>{ 'Patient_Note__c' => 'PatientNote', 'disco__Form__c' => 'YourekaForm', 'EGO__c' => 'EGO', 'Case' => 'Case', 'Procedure_Order__c' => 'ProcedureOrder' };
	/*******************************************************************************************************
	 * @description Naming convention of a Printed Medical Record Handler
	 */
	static final string HANDLER_NAMING_FORMATTER = 'Printed{0}MedicalRecord';

	/*******************************************************************************************************
	 * @description Dynamically creates a PrintedMedicalRecord handler based on the Medical Record Type passed in as a parameter.
	 *   The handler to be created dynamically should have the following naming convention 'Printed'+Type+'MedicalRecord'
	 *   such as BHS_MSHParser.
	 *
	 * @param medicalRecordType:string a segment name
	 * @return an instance of PrintedMedicalRecordBase derived class
	 */
	public static PrintedMedicalRecordBase createHandler(String sObjectName, String patientId, String requestId, String admissionId) {
		PrintedMedicalRecordBase instance = null;
		String medicalRecordType = printedMedicalRecordHandlerMap.get(sObjectName);
		String className = String.format(HANDLER_NAMING_FORMATTER, new List<string>{ medicalRecordType });
		Type dynamicApexType = Type.forName(className);
		instance = (PrintedMedicalRecordBase) dynamicApexType.newInstance();
		instance.initialize(patientId, requestId, admissionId);

		return instance;
	}
}