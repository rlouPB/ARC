@isTest
public class PrintedCaseMedicalRecordTest {
    @TestSetup
    static void initiateData() {
        Map<String, Id> recordTypeMap = PatientFileTestDataUtil.getRecordTypeInfo();

        Contact patientContactList = new Contact(
            LastName = 'TestPatient_0',
            RecordTypeId = recordTypeMap.get('Patient'+'-'+'Contact')
        );
        insert patientContactList;

        List<Contact> patientContactAndAccount = [SELECT Id, LastName, AccountId  FROM Contact WHERE Id =: patientContactList.Id ORDER BY LastName];
        
        disco__Form_Template__c discoFormTemplateVerify = (disco__Form_Template__c) TestFactory_Patient.createSObject(
		new disco__Form_Template__c(
			Name = 'Verification_Rec_Psychiatrist_Transfer',
			disco__Status__c = 'In Use',
            DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer'
		),
		true
		);
        Admission__c admission = new Admission__c(
            Patient_Account__c = patientContactAndAccount[0].AccountId,
            Patient_Contact__c = patientContactAndAccount[0].Id,
            stage__c = 'Discharged',
            Service_Type__c = 'Residential',
            Discharge_Date__c = Date.Today().addMonths(-12),
            Admit_Date__c = Date.Today().addMonths(-15),
            Psychotherapist__c = Userinfo.getUserId()
        );
        insert admission;

        Printed_Medical_Record_Request__c request = new Printed_Medical_Record_Request__c(
            Patient_Account__c = patientContactAndAccount[0].AccountId
        );
        insert request;

        Case testCase = new Case(
            AccountId = patientContactAndAccount[0].AccountId,
            Admission__c = admission.Id,
            Status = 'Finalized'
        );
        insert testCase;

        List<SDoc_Junction__c> sDocJunctions = new List<SDoc_Junction__c>();
        List<Printed_Medical_Included_Record__c> includedObjs = new List<Printed_Medical_Included_Record__c>();
        insert new SDoc_Junction__c(Object_SF_Id__c = ''+request.Id+testCase.Id, Treatment_Plan__c = testCase.Id);

        Printed_Medical_Included_Record__c medicalIncludedRecord = new Printed_Medical_Included_Record__c(
            Printed_Medical_Record_Request__c = request.Id,
            External_Id__c = '' + request.Id + testCase.Id,
            SDoc_Junction__r = new SDoc_Junction__c(Object_SF_Id__c = '' + request.Id + testCase.Id)
        );
        insert medicalIncludedRecord;

    }

    @isTest
    private static void collectAvailableMedicalRecordsTest() {
        List<Admission__c> admiss = [SELECT Id, Name FROM Admission__c];
        Account testPatient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

        PrintedMedicalRecordBase patientRecord = new PrintedCaseMedicalRecord();
        patientRecord.admissionIdList = new List<String> { admiss[0].Id };
        patientRecord.patientId = testPatient.Id;
        patientRecord.collectAvailableMedicalRecords();
        patientRecord.getSDocJunctionLookupField();
        patientRecord.getSObjectName();
        TreeGridNode tg = new TreeGridNode();
        tg.developerName= 'Nursing_Process_Note';
        tg.sObjectName= 'Case';
        patientRecord.formatLevel2Name(tg);
    }

    @isTest
    private static void findMedicalRecordsForDocumentTypeTest() {
        List<Admission__c> admiss = [SELECT Id, Name FROM Admission__c];
        Account testPatient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

        PrintedMedicalRecordBase patientRecord = new PrintedCaseMedicalRecord();
        patientRecord.admissionIdList = new List<String> { admiss[0].Id };
        patientRecord.patientId = testPatient.Id;
        patientRecord.findMedicalRecordsForDocumentType(null);
        patientRecord.findMedicalRecordsForDocumentType('Treatment_Plan');
    }

    @isTest
    private static void collectSelectedMedicalRecordsInDateRangeTest() {
        List<Admission__c> admiss = [SELECT Id, Name FROM Admission__c];
        Account testPatient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

        PrintedMedicalRecordBase patientRecord = new PrintedCaseMedicalRecord();
        patientRecord.admissionIdList = new List<String> { admiss[0].Id };
        patientRecord.patientId = testPatient.Id;
        patientRecord.collectSelectedMedicalRecordsInDateRange();
    }

    @isTest
    private static void getMedicalRecordAsHTMLsTest() {
        List<Admission__c> admiss = [SELECT Id, Name FROM Admission__c];
        Account testPatient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

        PrintedMedicalRecordBase patientRecord = new PrintedCaseMedicalRecord();
        patientRecord.admissionIdList = new List<String> { admiss[0].Id };
        patientRecord.patientId = testPatient.Id;
        patientRecord.getMedicalRecordAsHTMLs();
    }

    @isTest
    private static void collectSelectedMedicalRecordsTest() {
        List<Admission__c> admiss = [SELECT Id, Name FROM Admission__c];
        Account testPatient = [SELECT Id, Name, Current_Admission__c FROM Account LIMIT 1];

        PrintedMedicalRecordBase patientRecord = new PrintedCaseMedicalRecord();
        patientRecord.admissionIdList = new List<String> { admiss[0].Id };
        patientRecord.patientId = testPatient.Id;
        patientRecord.collectSelectedMedicalRecords();
    }
}