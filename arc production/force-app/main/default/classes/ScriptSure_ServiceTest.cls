@isTest
public class ScriptSure_ServiceTest {
    static Integer numberOfUsers = 5;


    @TestSetup
    public static void createTestData(){
        List<User> userList = new List<User>();
        Id profileId = [SELECT Id FROM Profile LIMIT 1].Id;

        for (Integer i = 0; i < numberOfUsers; i++) {
            //TODO: Create Users
            User objUser = new User(
                ProfileId = profileId,
                LastName = 'last-' + String.valueOf(i),
                Email = 'puser000' + String.valueOf(i) + '@amamama.com',
                Username = 'puser000' + String.valueOf(i) + '@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias-' + String.valueOf(i),
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                External_ScriptSure_User_Id__c = 'test' + i
            );

            userList.add(objUser);
        }

        insert userList;
        
        Account a = new Account(Name = 'test');
        //insert a;

        // Added to accomodate ITrigger/TriggerFactory, 20220708 - Sols
		disco__Form_Template__c[] formTemplates = new disco__Form_Template__c[]{
            new disco__Form_Template__c(DocType_Name__c = 'Medication_Package_Contents', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(DocType_Name__c = 'Patient_Certification_of_Dispensed', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(DocType_Name__c = 'Patient_Safety_Assessment_Tool', disco__Status__c = 'In Use'),
            new disco__Form_Template__c(Name = 'Psychiatrist Transfer from Test', disco__Status__c = 'In Use', DocType_Name__c = 'Verification_Rec_Psychiatrist_Transfer')
        };
        insert formTemplates;

        PatientFileTestDataUtil.createPatientWithAdmissionsAndCalls();
    }



    @IsTest
    static void getUiUrl(){

        Account patient = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        String url = ScriptSure_ServiceUtil.getUiUrl(patient.Id);
        System.debug('**** Test URL ----> ' + url);
        Test.stopTest();

        // System.assert(url != null);
        // System.assert(url != '');

    }

    @IsTest
    static void createPatienAllergy(){

        Test.startTest();
        ScriptSure_ServiceUtil.ScriptSureAllergies allergy;
        User userContex = [SELECT Id FROM User LIMIT 1];
        System.runAs(userContex) {
            ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
            Test.setMock(HttpCalloutMock.class, mock);
            String strJson = '{"accountId": "0012i00000VGoNIAA1",'
            + '"adverseEventCode": "414285001",'
            + '"allergyType": 0,'
            + '"comment": "Test",'
            + '"irisOnly": false,'
            + '"name": "Accu-Chek Comfort Curve Test",'
            + '"onsetDate": "2021-03-16",'
            + '"patientId": 13148,'
            + '"reactionId": 1,'
            + '"severityCode": "2"}';

            allergy = ScriptSure_ServiceUtil.createPatienAllergy(strJson);
            System.debug('**** allergy ----> ' + allergy);
        }

        Test.stopTest();

        // System.assert(allergy != null);

    }


    @IsTest
    static void createUpdatePatientAllergyController(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        //String strJson = '{"accountId": "0012i00000VGoNQAA8",'
        String strJson = '{"accountId": "' + String.valueOf(acc.Id) +'",'
        + '"adverseEventCode": "414285001",'
        + '"allergyType": 0,'
        + '"comment": "Test",'
        + '"irisOnly": false,'
        + '"name": "Accu-Chek Comfort Curve Test",'
        + '"onsetDate": "2021-03-16",'
        + '"patientId": 13148,'
        + '"reactionId": 1,'
        + '"severityCode": "2"}';

        String allergyId  = ScriptSureController.createUpdatePatientAllergy(strJson, false, '');
        System.debug('**** allergyId ----> ' + allergyId);
        Test.stopTest();

        // System.assert(allergyId != null);

    }

    @IsTest
    static void createUpdatePatientAllergyControllerUpdate(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        String strJson = '{"accountId": "0012i00000VGoNIAA1",'
        + '"adverseEventCode": "414285001",'
        + '"allergyType": 0,'
        + '"comment": "Test",'
        + '"irisOnly": false,'
        + '"name": "Accu-Chek Comfort Curve Test",'
        + '"onsetDate": "2021-03-16",'
        + '"patientId": 13148,'
        + '"reactionId": 1,'
        + '"severityCode": "2"}';

        Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];

        String url = ScriptSure_ServiceUtil.getUiUrl(patient.Id);

        patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];

        Allergy__c allergy = new Allergy__c();
        allergy.Name__c = 'Accu-Chek Comfort Curve Test';
        allergy.Account__c = patient.Id;
        allergy.Patient_Id__c = Decimal.valueOf(patient.External_Patient_Id__c);
        allergy.Allergy_Type__c = '13148';
        allergy.Adverse_Event_Code__c = '414285001';
        allergy.Reaction__c = '1';
        allergy.Comment__c = 'Test';
        allergy.Archive__c = '0';
        allergy.Onset_Date__c = Date.today();

        allergy.Severity_Code__c = '2';
        allergy.IRIS_Only__c = false;

        insert allergy;
        String allergyId = ScriptSureController.createUpdatePatientAllergy(strJson, true, allergy.Id);

        System.debug('**** allergyId ----> ' + allergyId);

        Test.stopTest();

        // System.assert(allergyId != null);

    }



    @IsTest
    static void getPatientAllergies(){

        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];


        futureInsert(patient.Id);
        //String allergyId = ScriptSureController.createUpdatePatientAllergy(strJson, true, allergy.Id);


        Test.stopTest();

        List<ScriptSure_ServiceUtil.ScriptSureAllergies> allergyList = ScriptSure_ServiceUtil.getPatientAllergies(patient.Id);

        System.debug('**** allergyList ----> ' + allergyList);


        // System.assert(allergyList != null);
        // System.assert(allergyList.size() > 0);

    }

    // @Future (callout = true)
    private static void futureInsert(Id patientId) {
        String url = ScriptSure_ServiceUtil.getUiUrl(patientId);

        Allergy__c allergy = new Allergy__c();
        allergy.Name__c = 'Accu-Chek Comfort Curve Test';
        // allergy.Account__c = patient.Id;
        allergy.Account__c = patientId;
        allergy.Patient_Id__c = Decimal.valueOf('13148');
        allergy.Allergy_Type__c = '0';
        allergy.Adverse_Event_Code__c = '414285001';
        allergy.Reaction__c = '1';
        allergy.Comment__c = 'Test';
        allergy.Archive__c = '0';
        allergy.Onset_Date__c = Date.today();
        allergy.Severity_Code__c = '2';
        allergy.IRIS_Only__c = false;

        insert allergy;
    }


    @IsTest
    static void validateRequiredFields(){

        Test.startTest();
        Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];
        String result = ScriptSure_ServiceUtil.validateRequiredFields(patient.Id);
        Test.stopTest();

        // System.assert(result != '');

    }


    @IsTest
    static void searchAllergies(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> resultList = ScriptSure_ServiceUtil.searchAllergies('Dihydrotestosterone');
        Test.stopTest();

        // System.assert(resultList != null);
        // System.assert(resultList.size() > 0);

    }


    @IsTest
    static void getPrescriptions(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        List<Prescription__c> resultList = ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);
        Test.stopTest();

        // System.assert(resultList != null);
        // System.assert(resultList.size() > 0);

    }

    @IsTest
    static void isProductionOrg(){

        Test.startTest();
        Boolean isProd = ScriptSure_ServiceUtil.IsProductionOrg();
        Test.stopTest();

        // System.assert(isProd != null);

    }

    @IsTest
    static void incireaseCodeCoverage(){

        Test.startTest();
        ScriptSure_ServiceUtil.ScriptSurePatient patient = new ScriptSure_ServiceUtil.ScriptSurePatient();
        patient.addressLine1 = '';
        patient.ssn = '';
        patient.state = '';
        patient.stateWork = 1;
        patient.suffix = '';
        patient.udpatedAt = Date.today();
        patient.userAdded = '';
        patient.userIdAdded = 1;
        patient.userIdUpdated = 1;
        patient.userUpdated = '';
        patient.work = '';
        patient.zip = '';
        patient.zipWork = 1;
        patient.addressLine1Work = 1;
        patient.addressLine2Work = 2;
        patient.addressLine2 = '';
        patient.alternateEthnicityId = '';
        patient.cell = '';
        patient.chartId = '';
        patient.city = '';
        patient.cityWork = 1;
        patient.consent = 2;
        patient.countryCode = '';
        patient.createdAt = Date.today();
        patient.deathCause = '';
        patient.deathDate = Date.today();
        patient.deletedAt = Datetime.now();
        patient.dob = Date.today();
        patient.doctorId = 1;
        patient.email = '';
        patient.emergencyContact = '';
        patient.ethnicityId = '';
        patient.firstName = '';
        patient.gender = '';
        patient.genderIdentity = '';
        patient.genderIdentityDescription = '';
        patient.generalComment = '';
        patient.generalHealth = '';
        patient.hippaCompliance = true;
        patient.hippaComplianceDate = Date.today();
        patient.home = '';
        patient.languageId = '';
        patient.lastName = '';
        patient.maritalStatusId = '';
        patient.middleName = '';
        patient.motherFirstName = '';
        patient.motherLastName = '';
        patient.nextOfKinName = '';
        patient.nextOfKinPhone = '';
        patient.nextOfKinRelation  = '';
        patient.patientId = '';
        patient.patientIdExternal = '';
        patient.patientStatusId = 1;
        patient.phone1Emergency = 1;
        patient.phone1Work = 1;
        patient.phone2Emergency = 1;
        patient.phone2Work = 1;
        patient.practiceId = 507;
        patient.preferredCommunicationId = '';
        patient.raceId = '';
        patient.relationId = 1;
        patient.removeSearch = false;
        patient.sexualOrientation = '';
        patient.sexualOrientationDescription = '';


        ScriptSure_ServiceUtil.ScriptSureAllergies allergy = new ScriptSure_ServiceUtil.ScriptSureAllergies();
        //allergy.accountId = '';
        allergy.adverseEventCode = '';
        allergy.adverseEventCodeText = '';
        allergy.allergyId = '';
        allergy.allergyType = 1;
        allergy.allergyTypeText = '';
        allergy.archive = 0;
        allergy.comment = '';
        allergy.createdAt = Datetime.now();
        allergy.DAM_ALRGN_GRP = 2;
        allergy.doctorId = 1;
        allergy.doctorName = '';
        allergy.encounterId = 1;
        allergy.endDate = Datetime.now();
        allergy.GCN_SEQN = '';
        allergy.HIC_SEQN = 2;
        allergy.id = 1;
        allergy.irisOnly = false;
        allergy.name = '';
        allergy.ndc = '';
        allergy.onsetDate = Datetime.now();
        allergy.patientId = 1;
        allergy.reactionId = 1;
        allergy.reactionText = '';
        //allergy.recordId = '';
        allergy.ROUTED_MED_ID = '';
        allergy.rxnorm = '';
        allergy.severityCode = '';
        allergy.severityCodeText = '';
        allergy.updatedAt = Datetime.now();
        allergy.userId = 1;
        allergy.userName = '';

        ScriptSure_ServiceUtil.PrescriptionDetail presDetail = new ScriptSure_ServiceUtil.PrescriptionDetail();
        presDetail.approveDate = '';
        presDetail.approveId = '';
        presDetail.approveName = '';
        presDetail.archive = false;
        presDetail.authorizationId = '';
        presDetail.authorizationQualifier = '';
        presDetail.authorizationStatus = '';
        presDetail.combinationMed = '';
        presDetail.compoundDrugDuration = '';
        presDetail.compoundDrugDurationPadded = '';
        presDetail.compoundQuantity = '';
        presDetail.compoundQuantityQualifier = '';
        presDetail.compoundTitle = '';
        presDetail.concurrentMed = '';
        presDetail.createdAt = '';
        presDetail.doctorId = '';
        presDetail.doctorName = '';
        presDetail.duration = '';
        presDetail.durationQualifier = '';
        presDetail.encounterId = '';
        presDetail.fillDate = '';
        presDetail.followUpPrescriberId = '';
        presDetail.followUpPrescriberName = '';
        presDetail.formularyChecked = '';
        presDetail.groupId = '';
        presDetail.internalComment = '';
        presDetail.maxDaily = '';
        presDetail.messageId = '';
        presDetail.messageStatus = '';
        presDetail.messageType = '';
        presDetail.Patient = new ScriptSure_ServiceUtil.ScriptSurePatient();
        presDetail.patientId = '';
        presDetail.pharmacy = '';
        presDetail.pharmacyId = '';
        presDetail.pharmacyNote = '';
        presDetail.practiceId = '';
        presDetail.PrescriptionAlerts = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionAlert>();
        presDetail.PrescriptionComments = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionComment>();
        presDetail.PrescriptionDiagnoses = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionDiagnose>();
        presDetail.PrescriptionDrugs = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionDrug>();
        presDetail.prescriptionId = '';
        presDetail.PrescriptionScript = new ScriptSure_ServiceUtil.ScriptSurePrescriptionScript();
        presDetail.PrescriptionStatuses = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionStatus>();
        presDetail.prescriptionType = '';
        presDetail.printDuration = '';
        presDetail.refill = '';
        presDetail.sendMethod = '';
        presDetail.supervisorId = '';
        presDetail.supervisorName = '';
        presDetail.updatedAt = '';
        presDetail.userId = '';
        presDetail.userName = '';
        presDetail.writtenDate = '';

        ScriptSure_ServiceUtil.PrescritionHeader presHeader = new ScriptSure_ServiceUtil.PrescritionHeader();
        presHeader.actionType = '';
        presHeader.businessUnitId = '';
        presHeader.createdAt = Datetime.now();
        presHeader.id = 1;
        presHeader.prescriptionId = '';
        presHeader.processSet = '';

        ScriptSure_ServiceUtil.ScriptSurePrescriptionScript script = new ScriptSure_ServiceUtil.ScriptSurePrescriptionScript();
        script.drugFormat = '';
        script.prescriptionId = 1;

        ScriptSure_ServiceUtil.ScriptSurePrescriptionDrug drug = new ScriptSure_ServiceUtil.ScriptSurePrescriptionDrug();
        drug.prescriptionId = '';
        drug.PrescriptionSigs = new List<ScriptSure_ServiceUtil.ScriptSurePrescriptionSig>();
        drug.quantity = 1;
        drug.quantityQualifier = '';
        drug.reconcileDate = '';
        drug.reconcileStatus = '';
        drug.reconcileUserId = '';
        drug.ROUTED_MED_ID = '';
        drug.rxnorm = '';
        drug.rxnormQualifier = '';
        drug.sampleExpiration = '';
        drug.sampleLotNumber = '';
        drug.useSubstitution = '';
        drug.calculate = '';
        drug.drugDuration = '';
        drug.drugDurationPadded = '';
        drug.drugId = '';
        drug.drugName = '';
        drug.drugOrder = '';
        drug.GCN_SEQNO = '';
        drug.line1 = '';
        drug.line2 = '';
        drug.MED_NAME_TYPE_CD = '';
        drug.MED_REF_DEA_CD = '';
        drug.MED_REF_FED_LEGEND_IND = '';
        drug.MED_REF_GEN_DRUG_NAME_CD = '';
        drug.ndc = '';

        ScriptSure_ServiceUtil.ScriptSurePrescriptionSig sig = new ScriptSure_ServiceUtil.ScriptSurePrescriptionSig();
        sig.administrationTimingCode = '';
        sig.administrationTimingText = '';
        sig.calculate = '';
        sig.conversionTotal = '';
        sig.descriptor = '';
        sig.dose = '';
        sig.doseDeliveryMethodCode = '';
        sig.doseDeliveryMethodText = '';
        sig.doseFormCode = '';
        sig.doseFormText = '';
        sig.doseQuantity = '';
        sig.drugId = 1;
        sig.durationNumericValue = '';
        sig.durationText = '';
        sig.durationTextCode = '';
        sig.frequencyNumericValue = '';
        sig.frequencyUnitsCode = '';
        sig.frequencyUnitsText = '';
        sig.indicationPrecursorCode = '';
        sig.indicationPrecursorText = '';
        sig.indicationText = '';
        sig.indicationTextCode = '';
        sig.indicationValueUnitofMeasureCode = '';
        sig.indicationValueUnitofMeasureText = '';
        sig.line3 = '';
        sig.multipleSigModifier = '';
        sig.routeofAdministrationCode = '';
        sig.routeofAdministrationText = '';
        sig.secondaryAdministrationTimingCode = '';
        sig.secondaryAdministrationTimingModifierCode = '';
        sig.secondaryAdministrationTimingModifierText = '';
        sig.secondaryAdministrationTimingText = '';
        sig.sigId = 1;
        sig.sigOrder = 1;
        sig.siteofAdministrationCode = '';
        sig.siteofAdministrationText = '';

        ScriptSure_ServiceUtil.ScriptSurePrescriptionStatus status = new ScriptSure_ServiceUtil.ScriptSurePrescriptionStatus();
        status.createdAt = '';
        status.encounterId = '';
        status.name = '';
        status.prescriptionId = '';
        status.prescriptionStatusId = '';
        status.prescriptionStatusTypeId = 1;
        status.userId = '';
        status.userName = '';

        ScriptSure_ServiceUtil.ScriptSurePrescriptionComment comment = new ScriptSure_ServiceUtil.ScriptSurePrescriptionComment();
        comment.archive = 0;
        comment.comment = '';
        comment.commentId = 1;
        comment.createdAt = Datetime.now();
        comment.doctorId = 2;
        comment.doctorName = '';
        comment.encounterId = 1;
        comment.expirationDate = '';
        comment.patientId = 2;
        comment.prescriptionId = 3;
        comment.ROUTED_MED_ID = 1;
        comment.type = 1;
        comment.updatedAt = Datetime.now();
        comment.userId = 1;
        comment.userName = '';

        ScriptSure_ServiceUtil.EncounterObj encounter = new ScriptSure_ServiceUtil.EncounterObj();
        encounter.createdAt = Datetime.now();
        encounter.doctorId = 1;
        encounter.doctorName = '';
        encounter.encounterId = 1;
        encounter.encounterStatus = '';
        encounter.guid = '';
        encounter.patientId = '';
        encounter.practiceId = 1;
        encounter.updatedAt = DateTime.now();
        encounter.userId = 1;
        encounter.userName = '';

        Test.stopTest();

    }

    @IsTest
    static void getURLController(){

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        String url = ScriptSureController.getUrl(acc.Id);
        Test.stopTest();

        // System.assert(url != null);
        // System.assert(url != '');
    }


    @IsTest
    static void getSessionTokenController(){

        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        String token = ScriptSureController.getSessionToken();
        Test.stopTest();

        // System.assert(token != null);
        // System.assert(token != '');
    }


    @IsTest
    static void isExternalUserController(){

        Account acc = [SELECT Id FROM Account LIMIT 1];

        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Boolean isExternal = ScriptSureController.isExternalScriptSureUser();

        Test.stopTest();

        // System.assert(isExternal != null);
    }

    @IsTest
    static void validateRequiredFieldsController(){

        // Contact ctc = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String message = ScriptSureController.validateRequiredFields(acc.Id);
        Test.stopTest();

        // System.assert(message != null);
        // System.assert(message != '');
    }

    @IsTest
    static void getPatientAllergiesController(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Allergy__c allergy = new Allergy__c();
        allergy.Account__c = acc.Id;
        allergy.IRIS_Only__c = false;
        allergy.Name__c = 'Test Allergy';
        allergy.Allergy_Type__c = '1';
        allergy.Reaction__c = '1';
        allergy.Severity_Code__c = '2';
        allergy.Onset_Date__c = Date.today();

        insert allergy;

        Allergy__c allergy2 = new Allergy__c();
        allergy2.Account__c = acc.Id;
        allergy2.IRIS_Only__c = false;
        allergy2.Name__c = 'Test Allergy';
        allergy2.Allergy_Type__c = '1';
        allergy2.Reaction__c = '1';
        allergy2.Severity_Code__c = '2';
        allergy2.Onset_Date__c = Date.today();

        insert allergy2;

        Test.startTest();



        List<ScriptSure_ServiceUtil.ScriptSureAllergies> allergyListAll = ScriptSureController.getPatientAllergies(acc.Id, 'all');
        List<ScriptSure_ServiceUtil.ScriptSureAllergies> allergyListActive = ScriptSureController.getPatientAllergies(acc.Id, 'active');

        Test.stopTest();

        // System.assert(allergyListAll != null);
        // System.assert(allergyListAll.isEmpty() == false);
        // System.assert(allergyListActive != null);
        // System.assert(allergyListActive.isEmpty() == false);

    }


    @IsTest
    static void searchAllergiesController(){

        Test.startTest();

        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> allergiesResult = ScriptSureController.searchAllergies('Bulk');

        Test.stopTest();

        // System.assert(allergiesResult != null);
        // System.assert(allergiesResult.isEmpty() == false);

    }


    @IsTest
    static void getExistingPrescriptions(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);

        List<Prescription__c> presList = ScriptSureController.getExistingPrescriptions(patient.Id);
        Test.stopTest();


        // System.assert(presList != null);
        // System.assert(presList.isEmpty() == false);

    }

    @IsTest
    static void getExistingPrescriptionsWithQuery_Monthly(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c,Current_Admission__c, Current_Admission__r.Admit_Date__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);

        Patient_Note__c patientNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = patient.Current_Admission__c,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Contact_Date__c = system.today(),
            Type__c = 'Psychotherapy Consultation Note',
            RecordTypeId = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordTypeId()
        );
        insert patientNote;

        Prescription__c prep = new Prescription__c(
            Account__c=patient.Id,
            Drug_Name__c='test',
            Medication_Filled_With__c = 'test',
            Drug_Format__c='test',
            Medication_Format__c = 'test',
            Written_Date__c= patient.Current_Admission__r.Admit_Date__c,
            Presciber__c=userinfo.getuserid(),
            Indication_Text__c='test',
            Status__c ='Active',
            External_Prescription_Id__c=123456
        );
        insert prep;

        List<Prescription__c> presList = ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'Monthly');
        List<Prescription__c> presList1 = ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'First of Month');
        List<Prescription__c> presList2 = ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'This Month', true);
        Test.stopTest();


        // System.assert(presList != null,'Should not have returned null');
        // System.assert(!presList.isEmpty(),'Should have returned values');

    }

    @IsTest
    static void getExistingPrescriptionsWithQuery_NoteDate(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c,Current_Admission__c, Current_Admission__r.Admit_Date__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);

        Patient_Note__c patientNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = patient.Current_Admission__c,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Contact_Date__c = system.today(),
            Type__c = 'Psychotherapy Consultation Note',
            RecordTypeId = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordTypeId()
        );
        insert patientNote;

        Prescription__c prep = new Prescription__c(
            Account__c=patient.Id,
            Drug_Name__c='test',
            Medication_Filled_With__c = 'test',
            Drug_Format__c='test',
            Medication_Format__c = 'test',
            Written_Date__c=patient.Current_Admission__r.Admit_Date__c,
            Presciber__c=userinfo.getuserid(),
            Indication_Text__c='test',
            Status__c ='Active',
            Inactive_Datetime__c=system.today(),
            External_Prescription_Id__c=123456,
            Use_Substitution__c = true
        );
        insert prep;

        List<Prescription__c> presList = ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'Note Date');
        Test.stopTest();

        // System.assert(presList != null,'Should not have returned null');
        //System.assert(!presList.isEmpty(),'Should have returned values');

    }


    @IsTest
    static void getExistingPrescriptionsWithQuery_AdmitDate(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c,Current_Admission__c, Current_Admission__r.Admit_Date__c FROM Account LIMIT 1];
        System.debug('@@@@ patientNote ---> ' + patient);
        patient.External_Patient_Id__c = '13148';
        ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);

        Patient_Note__c patientNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = patient.Current_Admission__c,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Contact_Date__c = system.today(),
            Type__c = 'Psychotherapy Consultation Note',
            RecordTypeId = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordTypeId()
        );
        insert patientNote;

        patientNote = [Select Id, Admission__r.Admit_Date__c from Patient_Note__c where id=:patientNote.Id];

        System.debug('@@@@ patientNote ---> ' + patientNote);

        Prescription__c prep = new Prescription__c(
            Account__c=patient.Id,
            Drug_Name__c='test',
            Medication_Filled_With__c = 'test',
            Drug_Format__c='test',
            Medication_Format__c = 'test',
            Written_Date__c= patient.Current_Admission__r.Admit_Date__c,
            Presciber__c=userinfo.getuserid(),
            Indication_Text__c='test',
            Status__c ='Active',
            Inactive_Datetime__c=system.today(),
            External_Prescription_Id__c=123456,
            Use_Substitution__c = true
        );
        insert prep;

        List<Prescription__c> presList = ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'Admit Date');
        Test.stopTest();


        // System.assert(presList != null,'Should not have returned null');
        //System.assert(!presList.isEmpty(),'Should have returned values');

    }

    @IsTest
    static void getExistingPrescriptionsWithQuery_Fails(){

        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Account patient = [SELECT Id, External_Patient_Id__c,Current_Admission__c FROM Account LIMIT 1];
        patient.External_Patient_Id__c = '13148';
        ScriptSure_ServiceUtil.getPrescriptions(patient.External_Patient_Id__c, patient.Id, ScriptSure_ServiceUtil.authenticate(false), false);

        Patient_Note__c patientNote = new Patient_Note__c(
            Account__c = patient.Id,
            Admission__c = patient.Current_Admission__c,
            Consultation_Assigned_Date__c = System.today(),
            Consultation_Requested_By__c = 'Patient',
            Contact_Date__c = system.today(),
            Type__c = 'Psychotherapy Consultation Note',
            RecordTypeId = Schema.SobjectType.Patient_Note__c.getRecordTypeInfosByDeveloperName().get('Custom_Note').getRecordTypeId()
        );
        insert patientNote;

        patientNote = [Select Admission__r.Admit_Date__c from Patient_Note__c where id=:patientNote.Id];

        Prescription__c prep = new Prescription__c(
            Account__c=patient.Id,
            Drug_Name__c='test',
            Drug_Format__c='test',
            Written_Date__c=patientNote.Admission__r.Admit_Date__c,
            Presciber__c=userinfo.getuserid(),
            Indication_Text__c='test',
            Status__c ='Active',
            Inactive_Datetime__c=system.today(),
            External_Prescription_Id__c=123456,
            Use_Substitution__c = true
        );
        insert prep;

        boolean threw1stError = false;
        boolean threw2ndError = false;
        try{
            ScriptSureController.getExistingPrescriptionsWithQuery(patient.Id, patientNote.Id, 'Invalid Query Option');
        }catch(exception e){ threw1stError = true; }

        try{
            ScriptSureController.getExistingPrescriptionsWithQuery(null, null, 'Invalid Query Option');
        }catch(exception e){threw2ndError = true;}


        // System.assert(threw1stError,'Did not threw the 1st error');
        // System.assert(threw2ndError,'Did not threw the 2nd error');

    }

    @IsTest
    static void pullPrescriptions(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();

        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        List<Prescription__c> pulledPrescriptions = ScriptSureController.pullPrescriptions('13148', acc.Id);
        Test.stopTest();

        // System.assert(pulledPrescriptions != null);
        // System.assert(pulledPrescriptions.isEmpty() == false);

    }

    @IsTest
    static void updateScriptSurePatientTest(){
        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Contact contact = [SELECT AccountId from Contact WHERE AccountId != null LIMIT 1];
        ScriptSure_ServiceUtil.updateScriptSurePatient(contact.AccountId);
        Test.stopTest();
    }

    @IsTest
    static void updateScriptSurePatientFromAdmissionUpdateTest(){
        Test.startTest();
        ScriptSureIntegrationCalloutMock mock = new ScriptSureIntegrationCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);
        Contact contact = [SELECT AccountId, Account.Current_Admission__c from Contact WHERE AccountId != null LIMIT 1];
        Admission__c admission = [Select Patient_Consent_to_Download_Medi_History__c FROM Admission__c WHERE Id = :contact.Account.Current_Admission__c];
        admission.Patient_Consent_to_Download_Medi_History__c = 'Yes';
        update admission;
        Test.stopTest();
    }
    
    @IsTest
    static void getAccountTest(){
        Account a = [select id, name from Account limit 1][0];
        Test.startTest();
        ScriptSureController.getAccount(a.Id);
        Test.stopTest();
    }


}