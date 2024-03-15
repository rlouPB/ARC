/*
 * Description: This class will provide general and common functions for the Scripture Integration solution.
 * Created By: Fernando Ortiz
 */

public class ScriptSure_ServiceUtil implements Database.AllowsCallouts{

    public static String authenticate(Boolean useAdminAccountIfNeeded) {

        String sessionToken;

        //try {

            SObject scriptSureSettings = getSettings();

            System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);

            if (scriptSureSettings != null) {

                User loggedUser = getLoggedUser();

                if(null == loggedUser.External_ScriptSure_User_Id__c && useAdminAccountIfNeeded) {
                    loggedUser = getScriptSureAdminUser();
                }

                String hashedKey = getHashedKey();

                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(String.valueOf(scriptSureSettings.get('Login_Url__c')) + 'v1.0/login/byapp');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('apikey', String.valueOf(scriptSureSettings.get('Api_Key__c')));
                request.setBody('{"apikey": "'+hashedKey+'", "email": "'+loggedUser.Email+'"}');

                HttpResponse response = http.send(request);

                // If the request is successful, parse the JSON response.
                if (response.getStatusCode() == 200) {

                    //Deserialize the JSON string into collections of primitive data types.
                    Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    sessionToken = (String)results.get('sessionToken');

                    System.debug('***** Sessiont Token ---> ' + sessionToken);
                }
            } else {
                //Throw some type of exception
            }

            return sessionToken;

        // } catch (Exception ex) {
        //     ProcessLogging.quickProcessLogFuture('ScriptSure_ServiceUtil', 'authenticate', ex.getMessage());
        //     throw new AuraHandledException(ex.getMessage());
        // }


    }

    private static String getHashedKey() {

        try {
            SObject scriptSureSettings = getSettings();
            System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);

            long mills = Datetime.now().getTime();
            String messageBuilder = '';
            String apiKey = String.valueOf(scriptSureSettings.get('Api_Key__c'));
            String secret = String.valueOf(scriptSureSettings.get('Secret__c'));
            messageBuilder += apiKey+'_'+secret+'_'+mills;
            Blob apiKeyBlob = Blob.valueOf(apiKey);
            Blob secretBlob = Blob.valueOf(secret);
            Blob messageBlob = Blob.valueOf(messageBuilder);
            Blob data = Crypto.generateMac('hmacSHA1', messageBlob, secretBlob);
            String dataStr = EncodingUtil.convertToHex(data);
            String apiKeyValue = apiKey+'~'+dataStr+'~'+mills;
            System.debug('apiKeyValue : ' + apiKeyValue);

            return apiKeyValue;

        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'getHashedKey', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }

    public static String getUiUrl(String patientAccounttid) {

        // try {
            System.debug('*** patientAccounttid --> ' + patientAccounttid);

            if (patientAccounttid == null || patientAccounttid == '') {
                return null;
            }

            String sessionToken = authenticate(false);

            ScriptSure_ServiceUtil.ScriptSurePatient savedPatient;

            Contact patient = [SELECT Id, Account.External_Patient_Id__c, AccountId FROM Contact WHERE AccountId =: patientAccounttid LIMIT 1];
            String externalId;

            if (patient.Account.External_Patient_Id__c == null || patient.Account.External_Patient_Id__c == '') {
                savedPatient = createScriptSurePatient(new List<Id>{patient.Id});
                externalId = String.valueOf(savedPatient.patientId);
            } else {
                externalId = patient.Account.External_Patient_Id__c;
            }

            String url;

            //Get API Custom Settings
            SObject scriptSureSettings = getSettings();
            System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);

            if (scriptSureSettings != null) {
                url = String.valueOf(scriptSureSettings.get('Base_Url__c')) + '?sessiontoken=' + sessionToken + '#/chart/'+ externalId + '/dashboard';
            }

            return url;
        // } catch (Exception ex) {
        //     ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'getUiUrl', ex.getMessage());
        //     throw new AuraHandledException(ex.getMessage());
        // }


    }


    /******* Private Methods *******/

    private static User getLoggedUser() {
        //TODO: Get logged user and validate it contains an external User Id.
        Id userId = System.UserInfo.getUserId();

        User loggedUser = [SELECT Id, Email, External_ScriptSure_User_Id__c FROM User WHERE Id =: userId];

        return loggedUser;
    }

    private static User getScriptSureAdminUser() {
        SObject scriptSureSettings = getSettings();
        System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);
        if (scriptSureSettings != null) {
            Id userId = String.valueOf(scriptSureSettings.get('ScriptSure_SF_Admin_User_ID__c'));
            User adminUser;

            if (!Test.isRunningTest()) {
                adminUser = [SELECT Id, Email, External_ScriptSure_User_Id__c FROM User WHERE Id =: userId];
            } else {
                adminUser = new User();
                adminUser.External_ScriptSure_User_Id__c = '123456';
            }

            return adminUser;
        } else {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'getScriptSureAdminUser', 'ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
            throw new AuraHandledException('ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
        }
    }

    public static ScriptSurePatient createScriptSurePatient(List<Id> patientIDs) {

        // try {
            // ScriptSure_ServiceUtil.ScriptSurePatientWrapper patientWrapper;
            ScriptSurePatient savedPatient;

            if (patientIDs != null) {

                List<Contact> patientList = [SELECT Id, FirstName, MiddleName, LastName, Gender__c, AccountId, Account.External_Patient_Id__c,
                                 Birthdate, MailingAddress, Phone, MobilePhone, npe01__WorkPhone__c, Sex_Assigned_at_Birth__c,
                                 MailingCity, MailingState, MailingCountry, MailingPostalCode, MailingStateCode, MailingStreet
                                FROM Contact WHERE Id IN :patientIDs];


                // Fetching consents from the admission object
                List<Admission__c> patientAdmissions = [Select Patient_Contact__c , Patient_Consent_to_Download_Medi_History__c from Admission__c WHERE Patient_Account__c IN: patientIDs AND Stage__c = 'Admitted'];
                Map<id, Boolean> patientConsent = new Map<id, Boolean>();
                for (Admission__c ad : patientAdmissions) {
                    patientConsent.put(ad.Patient_Contact__c , 'Yes'.equals(ad.Patient_Consent_to_Download_Medi_History__c));
                }

                System.debug('**** patientList2 ----> ' + patientList);

                //Get API Custom Settings
                SObject scriptSureSettings = getSettings();
                System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);

                List<Account> patientAccountListToUpdate;

                Id userId = System.UserInfo.getUserId();

                User currentUser = [SELECT Id, External_ScriptSure_User_Id__c FROM User WHERE Id =: userId LIMIT 1];

                if (scriptSureSettings != null) {

                    patientAccountListToUpdate = new List<Account>();
                    String sessionToken = authenticate(false);

                    for (Contact patient : patientList) {

                        ScriptSurePatient externalPatient = new ScriptSurePatient(patient, String.valueOf(scriptSureSettings.get('Practice_Id__c')), currentUser.External_ScriptSure_User_Id__c, String.valueOf(scriptSureSettings.get('Phone_Number__c')) , patientConsent.get(patient.Id));
                        String strJsonPatient = JSON.serialize(externalPatient, true);

                        String url = scriptSureSettings.get('Base_Url__c') + 'v1.0/patient?sessiontoken=' + sessionToken;

                        HttpResponse response = sendCallOut(url, 'POST', strJsonPatient);
                        System.debug('**** Create Patient Response Test ---> ' + response.getBody());

                        // If the request is successful, parse the JSON response.
                        if (response.getStatusCode() == 200) {

                            // patientWrapper = (ScriptSurePatientWrapper)JSON.deserialize(response.getBody(), ScriptSure_ServiceUtil.ScriptSurePatientWrapper.class);
                            
                            // {
                            //     "successMsg": "Patient Saved",
                            //     "savedPatientObj":
                            //     {
                            //         "dob": "1980-01-01",
                            //         "patientId": 80334,
                            //         "zip": "55555",
                            //         "work": "4139315320",
                            //         "state": "LA",
                            //         "preferredCommunicationId": "P",
                            //         "practiceId": 557,
                            //         "patientStatusId": 0,
                            //         "lastName": "Austin",
                            //         "gender": "M",
                            //         "firstName": "Steve",
                            //         "doctorId": 2758,
                            //         "consent": false,
                            //         "city": "Anywhere",
                            //         "addressLine1": "123 Main Street",
                            //         "userIdAdded": 2758,
                            //         "userIdUpdated": 2758,
                            //         "userAdded": "david.avery@synapticap.com",
                            //         "userUpdated": "david.avery@synapticap.com",
                            //         "updatedAt": "2022-08-23T13:37:34.000Z",
                            //         "createdAt": "2022-08-23T13:37:34.000Z"
                            //     }
                            // }

                            Map<String, Object> m = 
                                (Map<String, Object>)
                                    JSON.deserializeUntyped(response.getBody());

                            Map<String, Object> pObj = 
                                (Map<String, Object>)m.get('savedPatientObj');
                            System.debug('pObj.get(patientId) : ' + pObj.get('patientId'));
                            Integer pId = (Integer)pObj.get('patientId');
                            System.debug('pId : ' + pId);
                            String pIdStr = String.valueOf(pId);
                            System.debug('pIdStr : ' + pIdStr);

                            savedPatient = new ScriptSurePatient(pIdStr);
                            // savedPatient.patientId = pObj.get('patientId').toString();
                            
                            // System.debug('patientWrapper : ' + patientWrapper);
                            // ScriptSurePatient savedPatient = patientWrapper.savedPatientObj;
                            System.debug('savedPatient : ' + savedPatient);
                            Account acc = new Account(id = patient.AccountId, External_Patient_Id__c = savedPatient.patientId);
                            System.debug('acc : ' + acc);
                            patientAccountListToUpdate.add(acc);

                            //Sync Allergies
                            syncPatientAllergies(patient.AccountId, savedPatient.patientId);

                        } else if (response.getStatusCode() >= 400) {
                            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                            String errorMessage = (String)results.get('error');
                            throw new AuraHandledException(errorMessage);
                        }
                    }

                    if (patientAccountListToUpdate.size() > 0) {
                        update patientAccountListToUpdate;
                    }

                } else {
                    ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'createScriptSurePatient', 'ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
                    throw new AuraHandledException('ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
                }

            }

            return savedPatient;
        // } catch (Exception ex) {
        //     System.debug('caught exception creating patient. - ex :' + ex);
        //     ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'createScriptSurePatient', ex.getMessage());
        //     throw new AuraHandledException(ex.getMessage());
        // }
    }

    @Future (callout = true)
    public static void updateScriptSurePatient(Id patientId) {
        try {
            ScriptSure_ServiceUtil.ScriptSurePatientWrapper patientWrapper;

            System.Debug('patientId : ' + patientId);

            if (null != patientId) {

                Contact patient = [SELECT Id, FirstName, MiddleName, LastName, Gender__c, AccountId, Account.External_Patient_Id__c,
                                 Birthdate, MailingAddress, Phone, MobilePhone, npe01__WorkPhone__c, Sex_Assigned_at_Birth__c,
                                 MailingCity, MailingState, MailingCountry, MailingPostalCode, MailingStateCode, MailingStreet
                                FROM Contact WHERE AccountId = :patientId];

                // Fetching consents from the admission object
                List<Admission__c> patientAdmissions = [Select Patient_Contact__c, Patient_Consent_to_Download_Medi_History__c from Admission__c WHERE Patient_Account__c = :patientId AND Stage__c = 'Admitted'];
                Map<id, Boolean> patientConsent = new Map<id, Boolean>();
                for (Admission__c ad : patientAdmissions) {
                    patientConsent.put(ad.Patient_Contact__c , 'Yes'.equals(ad.Patient_Consent_to_Download_Medi_History__c));
                }

                //Get API Custom Settings
                SObject scriptSureSettings = getSettings();

                List<Account> patientAccountListToUpdate;

                if (scriptSureSettings != null) {

                    patientAccountListToUpdate = new List<Account>();
                    String sessionToken = authenticate(true);

                    System.Debug('patientConsent.get(patient.Id) : ' + patientConsent.get(patient.Id));
                    ScriptSurePatient externalPatient = new ScriptSurePatient(patient, String.valueOf(scriptSureSettings.get('Practice_Id__c')), getScriptSureAdminUser().External_ScriptSure_User_Id__c, String.valueOf(scriptSureSettings.get('Phone_Number__c')) , patientConsent.get(patient.Id));
                    String strJsonPatient = JSON.serialize(externalPatient, true);
                    System.Debug('strJsonPatient : ' + strJsonPatient);

                    String url = scriptSureSettings.get('Base_Url__c') + 'v1.0/patient?sessiontoken=' + sessionToken;

                    HttpResponse response = sendCallOut(url, 'PUT', strJsonPatient);
                    System.debug('**** Create Patient Response Test ---> ' + response.getBody());

                    // If the request is successful, parse the JSON response.
                    if (response.getStatusCode() == 200) {
                        System.Debug('ScriptSure Patient Update Successful.');
                    } else if (response.getStatusCode() >= 400) {
                        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                        String errorMessage = (String)results.get('error');
                        throw new CustomException(errorMessage);
                    }
                } else {
                    ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'updateScriptSurePatient', 'ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
                    throw new CustomException('ScriptSure Settings not found, please verify the Custom Settings for ScriptSure are defined');
                }
            }
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'updateScriptSurePatient', ex.getMessage());
            throw new CustomException(ex.getMessage());
        }
    }

    public static ScriptSure_ServiceUtil.ScriptSureAllergies createPatienAllergy(String jsonAllergy) {
        try {
            ScriptSure_ServiceUtil.ScriptSureAllergies allergy;
            ScriptSure_ServiceUtil.ScriptSureAllergies receivedAllergy = (ScriptSure_ServiceUtil.ScriptSureAllergies)JSON.deserialize(jsonAllergy, ScriptSure_ServiceUtil.ScriptSureAllergies.class);

            if (receivedAllergy != null) {

                SObject scriptSureSettings = getSettings();
                System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);

                String sessionToken = authenticate(true);

                String allergyUrl = String.valueOf(scriptSureSettings.get('Base_Url__c')) + '/v1.0/allergy?sessiontoken=' + sessionToken;



                HttpResponse response = sendCallOut(allergyUrl, 'POST', jsonAllergy);

                if (response.getStatusCode() == 200) {
                    allergy = (ScriptSure_ServiceUtil.ScriptSureAllergies)JSON.deserialize(response.getBody(), ScriptSure_ServiceUtil.ScriptSureAllergies.class);
                } else {
                    throw new AuraHandledException(response.getStatusCode() + ' ----> ' + response.getBody());
                }
            }

            return allergy;
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'createPatienAllergy', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }

    }

    @Future (callout = true)
    public static void createScriptSurePatienAllergy(String allergyJSON) {

        Allergy__c allergy = (Allergy__c)JSON.deserialize(allergyJSON, Allergy__c.class);
        createScriptSurePatienAllergy(allergy);
    }


    public static ScriptSure_ServiceUtil.ScriptSureAllergies createScriptSurePatienAllergy(Allergy__c allergy) {
        System.debug('***** createScriptSurePatienAllergy JSON ---> 1');
        System.debug('***** Allergy__c allergy JSON ---> ' + allergy);
        try {
            if (allergy == null) {
                return null;
            }

            //Prevent the creation of the Patient Allergy if it is IRIS Only
            if (allergy.IRIS_Only__c) {
                return null;
            }

            System.debug('***** createScriptSurePatienAllergy JSON ---> 2');


            ScriptSure_ServiceUtil.ScriptSureAllergies scriptureAllergy = new ScriptSure_ServiceUtil.ScriptSureAllergies(allergy);

            System.debug('***** createScriptSurePatienAllergy JSON ---> 3');


            SObject scriptSureSettings = getSettings();
            System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);
            System.debug('***** createScriptSurePatienAllergy JSON ---> 4');

            String sessionToken = authenticate(false);

            System.debug('***** createScriptSurePatienAllergy JSON ---> 5');


            String allergyUrl = scriptSureSettings.get('Base_Url__c') + 'v1.0/allergy?sessiontoken=' + sessionToken;

            System.debug('***** createScriptSurePatienAllergy JSON ---> 6');


            String strJsonAllergy = JSON.serialize(scriptureAllergy, true);

            System.debug('***** createScriptSurePatienAllergy JSON ---> 7');


            HttpResponse response = sendCallOut(allergyUrl, 'POST', strJsonAllergy);
            System.debug('***** createScriptSurePatienAllergy JSON ---> ' + response.getBody());


            ScriptSure_ServiceUtil.ScriptSureAllergies savedScriptSureAllergy;



            if (response.getStatusCode() == 200) {
                savedScriptSureAllergy = (ScriptSure_ServiceUtil.ScriptSureAllergies)JSON.deserialize(response.getBody(), ScriptSure_ServiceUtil.ScriptSureAllergies.class);


                //TODO: Update the External Id
                Allergy__c newAllergy = new Allergy__c(Id = allergy.Id, Id__c = savedScriptSureAllergy.id);
                AllergyTrigger_Handler.runUpdate = false;
                update newAllergy;

            } else {
                throw new AuraHandledException(response.getStatusCode() + ' ----> ' + response.getBody());
            }


            return savedScriptSureAllergy;
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'createScriptSurePatienAllergy', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }


    @Future (callout = true)
    public static void updateScriptSurePatienAllergy(String allergyJSON) {

        Allergy__c allergy = (Allergy__c)JSON.deserialize(allergyJSON, Allergy__c.class);

        syncPatientAllergies(allergy);
    }

    public static ScriptSure_ServiceUtil.ScriptSureAllergies syncPatientAllergies(Allergy__c allergy) {

        try {
                if (allergy == null) {
                    return null;
                }

                //Prevent the creation of the Patient Allergy if it is IRIS Only
                if (allergy.IRIS_Only__c) {
                    return null;
                }

                ScriptSure_ServiceUtil.ScriptSureAllergies scriptureAllergy = new ScriptSure_ServiceUtil.ScriptSureAllergies(allergy);

                SObject scriptSureSettings = getSettings();
                System.debug('**** scriptSureSettings ---> ' + scriptSureSettings);
                String sessionToken = authenticate(true);

                String allergyUrl = String.valueOf(scriptSureSettings.get('Base_Url__c')) + 'v1.0/allergy?sessiontoken=' + sessionToken;

                String strJsonAllergy = JSON.serialize(scriptureAllergy, true);

                HttpResponse response = sendCallOut(allergyUrl, 'PUT', strJsonAllergy);

                System.debug('**** response Test Allergy ----> ' + response.getBody());

                ScriptSure_ServiceUtil.ScriptSureAllergies savedScriptSureAllergy;

                if (response.getStatusCode() == 200) {
                    savedScriptSureAllergy = (ScriptSure_ServiceUtil.ScriptSureAllergies)JSON.deserialize(response.getBody(), ScriptSure_ServiceUtil.ScriptSureAllergies.class);
                } else {
                    throw new AuraHandledException(response.getStatusCode() + ' ----> ' + response.getBody());
                }

                return savedScriptSureAllergy;
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'syncPatientAllergies', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }

    private static SObject getSettings() {

        if (Test.isRunningTest()) {
            ScriptSure_API_Test_Settings__c settingsTest = new ScriptSure_API_Test_Settings__c();
            settingsTest.Base_Url__c = 'https://stage.scriptsure.com/';
            settingsTest.Practice_Id__c = '557';
            settingsTest.Phone_Number__c = '(413) 931-5320';
            settingsTest.Api_Key__c = '69d60ece-acc5-4aca-a72a-f46745fe0770';
            settingsTest.Login_Url__c = 'https://stage-platform.scriptsure.com/';
            settingsTest.Secret__c = '$2a$10$njfyVa97ZQMPBcdkPmwn1uOrEu.nKkZlZaliRoSb2JAbJymt0tMKm';
            return settingsTest;
        }

        if (IsProductionOrg()) {
            return ScriptSure_API_Prod_Settings__c.getOrgDefaults();
        } else {
            return ScriptSure_API_Test_Settings__c.getOrgDefaults();
        }
    }

    private static HttpResponse sendCallOut(String url, String method, String body) {
        return sendCallOut(url, method, body, false);
    }

    private static HttpResponse sendCallOut(String url, String method, String body, Boolean isFromBatch) {
        try {

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            System.debug('##### url ---> ' + url);
            request.setEndpoint(url);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json');
            if (method != 'GET') {
                request.setBody(body);
            }

            HttpResponse response = http.send(request);

            return response;
        } catch (Exception ex) {
            System.Debug('error is sendCallOut - ex : ' + ex);
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', ex.getStackTraceString(), ex.getMessage());
            if(isFromBatch) {
                throw ex;
            } else {
                throw new AuraHandledException(ex.getMessage());
            }
        }


    }


    public static List<ScriptSure_ServiceUtil.ScriptSureAllergies> getPatientAllergies(String externalPatientId) {

        try {
            SObject scriptSureSettings = getSettings();
            String sessionToken = authenticate(true);
            List<ScriptSure_ServiceUtil.ScriptSureAllergies> allergiesList;

            String url = scriptSureSettings.get('Base_Url__c') + 'v1.0/allergy/patient/'+externalPatientId+'?sessiontoken=' + sessionToken;

            HttpResponse response = sendCallOut(url, 'GET', '');

            System.debug('***** Patient Allergies JSON ---> ' + response.getBody());

            if (response.getStatusCode() == 200) {
                allergiesList = (List<ScriptSure_ServiceUtil.ScriptSureAllergies>)JSON.deserialize(response.getBody(), List<ScriptSure_ServiceUtil.ScriptSureAllergies>.class);
            }

            return allergiesList;
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'getPatientAllergies', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }

    @Future(callout = true)
    public static void syncPatientAllergies(Id accountId, String externalPatientId) {

        try {

            List<Allergy__c> allergyList = [SELECT Id, HIC_SEQN__c, Id__c, Name__c, Ndc__c, Onset_Date__c, Patient_Id__c, Account__r.Encounter_Id__c,
            Reaction__c, Reaction_Text__c, ROUTED_MED_ID__c, Rxnorm__c, Severity_Code__c, Severity_Code_Text__c, Updated_At__c, User_Id__c, User_Name__c, Allergy_Type__c, Archive__c,
            Comment__c, Created_At__c, DAM_ALRGN_GRP__c, Doctor_Name__c, End_Date__c, Adverse_Event_Code__c, Adverse_Event_Code_Text__c,
            GCN_SEQN__c, Account__c, IRIS_Only__c, Allergy_Type_Text__c, Allergy_Id__c FROM Allergy__c WHERE Account__c =: accountId AND Id__c = null AND IRIS_Only__c = false];

            List<Allergy__c> allergyListToUpdate = new List<Allergy__c>();

            for (Allergy__c allergy : allergyList) {
                allergy.Patient_Id__c = Decimal.valueOf(externalPatientId);

                ScriptSure_ServiceUtil.ScriptSureAllergies savedAllergy = createScriptSurePatienAllergy(allergy);
                if (savedAllergy != null) {
                    allergy.Id__c = savedAllergy.id;
                    allergyListToUpdate.add(new Allergy__c(Id = allergy.Id, Id__c = allergy.Id__c));
                }
            }

            system.debug('allergyListToUpdate : ' + allergyListToUpdate);

            if (!allergyListToUpdate.isEmpty()) {
                AllergyTrigger_Handler.runUpdate = false;
                update allergyListToUpdate;
            }
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'syncPatientAllergies', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }


    public static string validateRequiredFields(Id patientContactId) {

        try {
            String missingFields = '';

            String Query='SELECT ';
            List<Schema.FieldSetMember> fieldList=SObjectType.Contact.FieldSets.ScriptSure_Patient_Required_Fields.getFields();

            for(Schema.FieldSetMember f : fieldList) {
                Query = Query+f.getFieldPath() +',';
            }

            Query += 'Id FROM Contact WHERE AccountId=: patientContactId';
            Contact conRec=Database.query(Query);

            sobject sobj = conRec;
            for(Schema.FieldSetMember f : fieldList) {
                object field = sobj.get(f.getFieldPath());

                if (field == null) {
                    missingFields += f.getLabel() + ', ';
                }
            }

            return missingFields;
        } catch (Exception ex) {
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'validateRequiredFields', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }


    }

    public static List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> searchAllergies(String allergyName) {

        String sessionToken = authenticate(true);
        SObject scriptSureSettings = getSettings();
        String url = scriptSureSettings.get('Base_Url__c') + 'v1.0/allergy/search?sessiontoken=' + sessionToken;
        String body = '{ "query": { "name": "' + allergyName + '" } }';

        List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy> allergiesList;

        try {
            HttpResponse response = sendCallOut(url, 'POST', body);

            if (response.getStatusCode() == 200) {
                allergiesList = (List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy>)JSON.deserialize(response.getBody(), List<ScriptSure_ServiceUtil.ScriptSureSearchAllergy>.class);
            }

        } catch (Exception ex) {
            ProcessLogging.quickProcessLogFuture('ScriptSure_ServiceUtil', 'searchAllergies', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }

        return allergiesList;

    }

    @future(callout = true)
    private static void deleteScriptSureProcessSet(string processSet, String sessionToken){
        // Delete mailbox call to clear out these prescription so we don't keep fetching them again and again.
        SObject settings = getSettings();
        String url2 = settings.get('Base_Url__c') + 'v1.0/mailbox/prescription/' + processSet + '?sessiontoken='+sessionToken;
        HttpResponse response2 = sendCallOut(url2, 'DELETE', '');
        System.debug('delete processSet response2.getBody() : ' + response2.getBody());
    }

    public static void deleteScriptSureProcessSetFromBatch(string processSet, String sessionToken){
        // Delete mailbox call to clear out these prescription so we don't keep fetching them again and again.
        SObject settings = getSettings();
        String url2 = settings.get('Base_Url__c') + 'v1.0/mailbox/prescription/' + processSet + '?sessiontoken='+sessionToken;
        HttpResponse response2 = sendCallOut(url2, 'DELETE', '');
        System.debug('delete processSet from batch response2.getBody() : ' + response2.getBody());
    }

    public static List<Prescription__c> getPrescriptions(String externalPatientId, String accountId, String sessionToken, Boolean isFromBatch) {

        try {
            if (externalPatientId == null || externalPatientId == '') {
                return null;
            }

            List<Prescription__c> prescriptionList;

            ScriptSure_ServiceUtil.PrescriptionWrapper prescriptionWrap;

            SObject settings = getSettings();

            String url = settings.get('Base_Url__c') + 'v1.0/mailbox/prescription/' + externalPatientId + '?sessiontoken='+sessionToken;

            HttpResponse response = sendCallOut(url, 'GET', '', isFromBatch);

            System.debug('***** response.getStatusCode() --> ' + response.getStatusCode());
            System.debug('***** response.getBody() --> ' + response.getBody());

            String value = AdminKeyValueMetadataHelper.getValueForKey('ScriptSure_Process_Logging_Prescriptions');
            if(null != value && value.equalsIgnoreCase('true')) {
                ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil_LOGGING', 'getPrescriptions - API Response.', response.getBody().subString(0, response.getBody().length() > 131000 ? 131000 : response.getBody().length()));
            }

            if (response.getStatusCode() == 200) {
                prescriptionWrap = (ScriptSure_ServiceUtil.PrescriptionWrapper)JSON.deserialize(response.getBody(), ScriptSure_ServiceUtil.PrescriptionWrapper.class);
                prescriptionList = createUpdatePrescriptions(prescriptionWrap, accountId);
                if(isFromBatch) {
                    // persist processSet Id - this will be processed in following batch
                    ScriptSure_Process_Sets__c ssps = new ScriptSure_Process_Sets__c(
                        Name = prescriptionWrap.processSet,
                        Process_Set_ID__c = prescriptionWrap.processSet
                    );
                    insert ssps;
                }
                if(!isFromBatch && !Test.isRunningTest()) {
                    System.debug('Calling deleteScriptSureProcessSet - isFromBatch : ' + isFromBatch + ', Test.isRunningTest() : ' + Test.isRunningTest());
                    deleteScriptSureProcessSet(prescriptionWrap.processSet, sessionToken);
                }
            } else {
                System.Debug('ScriptSure_ServiceUtit error in getPrescriptions - response.getBody() : ' + response.getBody());
                ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'getPrescriptions', response.getBody());
                throw new CustomException(response.getBody());
            }
            // return prescriptionWrap;
            return prescriptionList;
        } catch (Exception ex) {
            EventBus.publish(new CreateErrorLogEvent__e(Process_Name__c ='ScriptSure_ServiceUtil', Stack_Trace__c=ex.getStackTraceString(), Message__c= ex.getMessage() ));
            if(isFromBatch) {
                throw ex;
            } else {
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }

    public static List<Prescription__c> createUpdatePrescriptions(ScriptSure_ServiceUtil.PrescriptionWrapper prescriptionWrap, String accountId) {

        try {
            if (prescriptionWrap == null) {
                return null;
            }

            if (prescriptionWrap.prescriptions == null || prescriptionWrap.prescriptions.size() == 0) {
                return null;
            }

            Map<String, User> usersByExternalScriptSureId = new Map<String, User>();
            for(User u : [SELECT External_ScriptSure_User_Id__c, Id FROM User WHERE External_ScriptSure_User_Id__c != null]){
                usersByExternalScriptSureId.put(u.External_ScriptSure_User_Id__c, u);
            }

            Set<Decimal> prescriptionExternalIDs = new Set<Decimal>();
            Map<Decimal, ScriptSure_ServiceUtil.PrescritionHeader> mapPrescriptions = new Map<Decimal, ScriptSure_ServiceUtil.PrescritionHeader>();

            for (ScriptSure_ServiceUtil.PrescritionHeader header : prescriptionWrap.prescriptions) {
                prescriptionExternalIDs.add(Decimal.valueOf(String.valueOf(header.prescriptionId)));
                mapPrescriptions.put(Decimal.valueOf(String.valueOf(header.prescriptionId)), header);
            }

            List<Prescription__c> prescriptionListToInsert = new List<Prescription__c>();
            List<Prescription__c> prescriptionListToUpdate = new List<Prescription__c>();

            //TODO: Get SF Records within the external IDs and create a Map with the External ID as key
            //List<Prescription__c> prescriptionList = [SELECT Id, External_Prescription_Id__c, Drug_Name__c, Drug_Format__c, Written_Date__c, Presciber__c,Status__c FROM Prescription__c WHERE External_Prescription_Id__c IN : mapPrescriptions.keySet()];
            List<Prescription__c> prescriptionList = (Prescription__c[])database.query(
                QueryUtils.getQueryAll('Prescription__c', new string[]{}) + ' WHERE External_Prescription_Id__c in :prescriptionExternalIDs'
            );

            System.debug('***** prescriptionList ---> ' + prescriptionList);
            System.debug('***** prescriptionList Size ---> ' + prescriptionList.size());


            Map<Decimal, Prescription__c> mapIrisPrescriptions = new Map<Decimal, Prescription__c>();

            for (Prescription__c pres : prescriptionList) {
                mapIrisPrescriptions.put(pres.External_Prescription_Id__c, pres);
            }

            //Get the Prescriptions To Insert
            Id currentUserId = System.UserInfo.getUserId();
            for (ScriptSure_ServiceUtil.PrescritionHeader header : mapPrescriptions.values()) {

                if (mapIrisPrescriptions.get(Decimal.valueOf(header.prescriptionId)) == null) {

                    Prescription__c prescrip = new Prescription__c();
                    prescrip.Account__c = accountId;

                    Account account = [SELECT Current_Admission__c from Account where Id = :accountId];
                    if(null != account)
                        prescrip.Admission__c = account.Current_Admission__c;

                    prescrip.External_Prescription_Id__c = Integer.valueOf(header.prescriptionId);

                    if(null == header.Prescription) {
                        continue;
                    }
                    if(null != header.Prescription.PrescriptionScript) {
                        prescrip.Drug_Format__c = header.Prescription.PrescriptionScript.drugFormat;
                    }
                    prescrip.Drug_Name__c = header.Prescription.PrescriptionDrugs[0].drugName;
                    prescrip.Quantity__c = header.Prescription.PrescriptionDrugs[0].quantity;
                    prescrip.NDC__c = header.Prescription.PrescriptionDrugs[0].ndc;
                    prescrip.Med_Ref_DEA_CD__c = header.Prescription.PrescriptionDrugs[0].MED_REF_DEA_CD;
                    prescrip.Pharmacy_Note__c = header.Prescription.pharmacyNote;

                    if (header.Prescription.PrescriptionDrugs.size() > 1) {
                        prescrip.Drug_Name_2__c = header.Prescription.PrescriptionDrugs[1].drugName;
                        prescrip.Quantity_2__c = header.Prescription.PrescriptionDrugs[1].quantity;
                        prescrip.NDC_2__c = header.Prescription.PrescriptionDrugs[1].ndc;
                        prescrip.Med_Ref_DEA_CD_2__c = header.Prescription.PrescriptionDrugs[1].MED_REF_DEA_CD;
                    }

                    if (header.Prescription.PrescriptionDrugs.size() > 2) {
                        prescrip.Drug_Name_3__c = header.Prescription.PrescriptionDrugs[2].drugName;
                        prescrip.Quantity_3__c = header.Prescription.PrescriptionDrugs[2].quantity;
                        prescrip.NDC_3__c = header.Prescription.PrescriptionDrugs[2].ndc;
                        prescrip.Med_Ref_DEA_CD_3__c = header.Prescription.PrescriptionDrugs[2].MED_REF_DEA_CD;

                    }

                    prescrip.Written_Date__c = (DateTime)JSON.deserialize('"' + header.prescription.writtenDate + '"', DateTime.class);
                    prescrip.Presciber__c = null != usersByExternalScriptSureId.get(header.Prescription.doctorId) ? usersByExternalScriptSureId.get(header.Prescription.doctorId).Id : currentUserId;
                    prescrip.Use_Substitution__c = 'true'.equalsIgnoreCase(header.Prescription.PrescriptionDrugs[0].useSubstitution);

                    String status = header.prescription.archive ? 'Inactive' : 'Pending Approval';
                    object last1 = getLast(header.prescription.PrescriptionStatuses);
                    if(last1 != null){
                        ScriptSurePrescriptionStatus lastStatus = (ScriptSurePrescriptionStatus)last1;
                        if('Discontinued'.equals(lastStatus.name)) {
                            status = 'Discontinued';
                            object last = getLast(header.prescription.PrescriptionComments);
                            if(last != null){
                                ScriptSurePrescriptionComment lastComment = (ScriptSurePrescriptionComment)last;
                                System.debug('This is before exception ' + lastComment);
                                System.debug('"' + lastComment.expirationDate + '"');
                                if(String.isNotBlank(lastComment.expirationDate))
                                    prescrip.Inactive_Datetime__c = (DateTime)JSON.deserialize('"' + lastComment.expirationDate + '"', DateTime.class);
                            }
                        } else if('Cancel Prescription'.equals(lastStatus.name)) {
                            status = 'Canceled';
                            // I don't have expiration date in api response for cancelled scripts.
                            prescrip.Inactive_Datetime__c = DateTime.now();
                        } else if('New Prescription'.equals(lastStatus.name) || 'Active'.equals(lastStatus.name)){
                            if(header.Prescription.userName.equals(header.Prescription.doctorName) || '2' == header.Prescription.sendMethod) {
                                if(null != header.Prescription.pharmacyId) {
                                    status = 'Active Pending Fill';
                                } else {
                                    status = 'Pending Approval';
                                }
                            } else if(null != header.Prescription.approveId) {
                                status = 'Active Pending Fill';
                            } else {
                                status = 'Pending Approval';
                            }
                        } 
                    }

                    System.debug('***** status ---> ' + status);
                    System.debug('***** header.prescription.prescriptionStatusTypeId ---> ' + header.prescription.prescriptionStatusTypeId);
                    System.debug('***** header.prescription.archive ---> ' + header.prescription.archive);
                    prescrip.Status__c = status;
                    if(null != header.Prescription.PrescriptionDrugs[0].PrescriptionSigs && header.Prescription.PrescriptionDrugs[0].PrescriptionSigs.size() > 0) {
                        prescrip.Indication_Text__c = header.Prescription.PrescriptionDrugs[0].PrescriptionSigs[0].indicationText;
                    }
                    
                    // Get the old perscription from mapIrisPrescriptions if status in now Inactive and it wasn't,
                    // set inactiveDateTime = (DateTime)JSON.deserialize('"' + header.prescription.updatedAt + '"', DateTime.class);
                    if(status == 'Inactive' ){
                        object last = getLast(header.prescription.PrescriptionComments);
                        if(last != null){
                            ScriptSurePrescriptionComment lastComment = (ScriptSurePrescriptionComment)last;
                            if(String.isNotBlank(lastComment.expirationDate))
                            prescrip.Inactive_Datetime__c = (DateTime)JSON.deserialize('"' + lastComment.expirationDate + '"', DateTime.class);
                        }
                    }

                    system.debug('-----------------------------------------------0--------------------------------------------');
                    System.debug('***** status ---> ' + status);
                    system.debug('-----------------------------------------------/0--------------------------------------------');

                    prescriptionListToInsert.add(prescrip);
                } else {
                    Prescription__c prescrip = mapIrisPrescriptions.get(Decimal.valueOf(header.prescriptionId));

                    if(null == header.Prescription) {
                        continue;
                    }

                    if(null != header.Prescription.PrescriptionScript) {
                        prescrip.Drug_Format__c = header.Prescription.PrescriptionScript.drugFormat;
                    }
                    prescrip.Drug_Name__c = header.Prescription.PrescriptionDrugs[0].drugName;
                    prescrip.Quantity__c = header.Prescription.PrescriptionDrugs[0].quantity;
                    prescrip.NDC__c = header.Prescription.PrescriptionDrugs[0].ndc;
                    prescrip.Med_Ref_DEA_CD__c = header.Prescription.PrescriptionDrugs[0].MED_REF_DEA_CD;
                    prescrip.Pharmacy_Note__c = header.Prescription.pharmacyNote;

                    if (header.Prescription.PrescriptionDrugs.size() > 1) {
                        prescrip.Drug_Name_2__c = header.Prescription.PrescriptionDrugs[1].drugName;
                        prescrip.Quantity_2__c = header.Prescription.PrescriptionDrugs[1].quantity;
                        prescrip.NDC_2__c = header.Prescription.PrescriptionDrugs[1].ndc;
                        prescrip.Med_Ref_DEA_CD_2__c = header.Prescription.PrescriptionDrugs[1].MED_REF_DEA_CD;
                    }

                    if (header.Prescription.PrescriptionDrugs.size() > 2) {
                        prescrip.Drug_Name_3__c = header.Prescription.PrescriptionDrugs[2].drugName;
                        prescrip.Quantity_3__c = header.Prescription.PrescriptionDrugs[2].quantity;
                        prescrip.NDC_3__c = header.Prescription.PrescriptionDrugs[2].ndc;
                        prescrip.Med_Ref_DEA_CD_3__c = header.Prescription.PrescriptionDrugs[2].MED_REF_DEA_CD;

                    }

                    prescrip.Written_Date__c = (DateTime)JSON.deserialize('"' + header.prescription.writtenDate + '"', DateTime.class);
                    prescrip.Presciber__c = null != usersByExternalScriptSureId.get(header.Prescription.doctorId) ? usersByExternalScriptSureId.get(header.Prescription.doctorId).Id : currentUserId;
                    prescrip.Use_Substitution__c = 'true'.equalsIgnoreCase(header.Prescription.PrescriptionDrugs[0].useSubstitution);

                    String status = header.prescription.archive ? 'Inactive' : 'Pending Approval';
                    object last1 = getLast(header.prescription.PrescriptionStatuses);
                    if(last1 != null){
                        ScriptSurePrescriptionStatus lastStatus = (ScriptSurePrescriptionStatus)last1;
                        if('Discontinued'.equals(lastStatus.name)) {
                            status = 'Discontinued';
                            object last = getLast(header.prescription.PrescriptionComments);
                            if(last != null){
                                ScriptSurePrescriptionComment lastComment = (ScriptSurePrescriptionComment)last;
                                System.debug('This is before exception ' + lastComment);
                                System.debug('"' + lastComment.expirationDate + '"');
                                if(String.isNotBlank(lastComment.expirationDate))
                                    prescrip.Inactive_Datetime__c = (DateTime)JSON.deserialize('"' + lastComment.expirationDate + '"', DateTime.class);
                            }
                        } else if('Archived'.equals(lastStatus.name)) {
                            status = 'Archived';
                        } else if('Cancel Prescription'.equals(lastStatus.name)) {
                            status = 'Canceled';
                            // I don't have expiration date in api response for cancelled scripts.
                            prescrip.Inactive_Datetime__c = DateTime.now();
                        } else if('New Prescription'.equals(lastStatus.name) || 'Active'.equals(lastStatus.name)){
                            if('Active'.equals(prescrip.Status__c)) {
                                status = 'Active';
                            } else {
                                if(header.Prescription.userName.equals(header.Prescription.doctorName) || '2' == header.Prescription.sendMethod) {
                                    if(null != header.Prescription.pharmacyId) {
                                        status = 'Active Pending Fill';
                                    } else {
                                        status = 'Pending Approval';
                                    }
                                } else if(null != header.Prescription.approveId) {
                                    status = 'Active Pending Fill';
                                } else {
                                    status = 'Pending Approval';
                                }
                            }
                        } 
                    }

                    system.debug('-----------------------------------------------1--------------------------------------------');
                    System.debug('***** mapIrisPrescriptions.get(header.prescriptionId) != null --- ');
                    System.debug('***** status ---> ' + status);
                    System.debug('***** header.prescription.prescriptionStatusTypeId ---> ' + header.prescription.prescriptionStatusTypeId);
                    System.debug('***** header.prescription.archive ---> ' + header.prescription.archive);

                    boolean statusChangedToInactive = status == 'Inactive' && prescrip.Status__c != status;
                    prescrip.Status__c = status;

                    // Get the old perscription from mapIrisPrescriptions if status in now Inactive and it wasn't,
                    // set inactiveDateTime = (DateTime)JSON.deserialize('"' + header.prescription.updatedAt + '"', DateTime.class);
                    if( statusChangedToInactive ){
                        object last = getLast(header.prescription.PrescriptionComments);
                        if(last != null){
                            ScriptSurePrescriptionComment lastComment = (ScriptSurePrescriptionComment)last;
                            System.debug('This is before exception ' + lastComment);
                            System.debug('"' + lastComment.expirationDate + '"');
                            if(String.isNotBlank(lastComment.expirationDate))
                            prescrip.Inactive_Datetime__c = (DateTime)JSON.deserialize('"' + lastComment.expirationDate + '"', DateTime.class);
                        }
                    }

                    System.debug('***** prescrip.Inactive_Datetime__c ---> ' + prescrip.Inactive_Datetime__c);
                    system.debug('-----------------------------------------------/1--------------------------------------------');


                    prescriptionListToUpdate.add(prescrip);
                }
            }

            if (prescriptionListToInsert.size() > 0) {
                insert prescriptionListToInsert;
            }

            if (prescriptionListToUpdate.size() > 0) {
                update prescriptionListToUpdate;
            }

            List<Prescription__c> prescList = new List<Prescription__c>();
            prescList.addAll(prescriptionListToInsert);
            prescList.addAll(prescriptionListToUpdate);

            return prescList;
        } catch (Exception ex) {
            System.Debug('error creating patient prescriptions - ex : ' + ex);
            System.Debug('Stack Trace: ' + ex.getStackTraceString());
            ProcessLogging.quickProcessLog('ScriptSure_ServiceUtil', 'createUpdatePrescriptions', ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static object getLast(object[] arr){
        return (arr != null && arr.size() > 0)? arr[ arr.size() - 1 ] : null;
    }

    public static Boolean IsProductionOrg() { // Method to check of environement is Production ORG or not

        Organization org = [SELECT IsSandbox FROM Organization WHERE Id =:UserInfo.getOrganizationId()];
        return !org.IsSandbox;
    }


    /************ WRAPPER CLASSES ************/

    public class ScriptSurePatient {

        public ScriptSurePatient () {

        }

        public ScriptSurePatient (String patientId) {
            System.debug('In constructor - patientId : ' + patientId);
            this.patientId = patientId;
        }

        public ScriptSurePatient(Contact patient, String practiceId, String externalUserId, String workPhoneNumber , Boolean patientConsentToDownloadMediHistory) {
            //Map Data
            if (patient == null) {
                return;
            }

            this.patientId = patient.Account.External_Patient_Id__c;
            this.dob = patient.Birthdate;
            this.patientStatusId = 0;
            if (practiceId != null) {
                this.practiceId = Integer.valueOf(practiceId);
            }
            if (externalUserId != null) {
                this.doctorId = Integer.valueOf(externalUserId);
            }


            this.firstName = patient.FirstName;
            if(null != this.firstName && this.firstName.length() > 35) {
                this.firstName = this.firstName.left(35);
            }

            this.middleName = patient.MiddleName;
            if(null != this.middleName && this.middleName.length() > 35) {
                this.middleName = this.middleName.left(35);
            }

            this.lastName = patient.LastName;
            if(null != this.lastName && this.lastName.length() > 35) {
                this.lastName = this.lastName.left(35);
            }
            this.preferredCommunicationId = 'P';
            System.debug('patientConsentToDownloadMediHistory : ' + patientConsentToDownloadMediHistory);
            this.consent = null != patientConsentToDownloadMediHistory && patientConsentToDownloadMediHistory ? 1 : 0;  
            this.gender = patient.Sex_Assigned_at_Birth__c == 'Male' ? 'M' : patient.Sex_Assigned_at_Birth__c == 'Female' ? 'F' : 'O' ;
            this.addressLine1 = patient.MailingStreet;
            System.debug('this.addressLine1 : ' + this.addressLine1);
            if(null != this.addressLine1 && this.addressLine1.length() > 35) {
                this.addressLine1 = this.addressLine1.left(35);
            }
            System.debug('this.addressLine1B : ' + this.addressLine1);
            this.city = patient.MailingCity;
            if(null != this.city && this.city.length() > 35) {
                this.city = this.city.left(35);
            }
            this.state = patient.MailingStateCode;
            if(null != this.state && this.state.length() > 2) {
                this.state = this.state.left(2);
            }
            this.zip = patient.MailingPostalCode;
            if(null != this.zip && this.zip.length() > 9) {
                this.zip = this.zip.left(9);
            }
            // this.cell = patient.MobilePhone;
            // this.home = patient.Phone;
            this.work = workPhoneNumber;
        }


        @AuraEnabled
        public String patientId {get; set;}
        @AuraEnabled
        public String patientIdExternal {get; set;}
        @AuraEnabled
        public Integer practiceId {get; set;}
        @AuraEnabled
        public Integer doctorId {get; set;}
        @AuraEnabled
        public String chartId {get; set;}
        @AuraEnabled
        public String ssn {get; set;}
        @AuraEnabled
        public String firstName {get; set;}
        @AuraEnabled
        public String middleName {get; set;}
        @AuraEnabled
        public String lastName {get; set;}
        @AuraEnabled
        public String suffix {get; set;}
        @AuraEnabled
        public Datetime dob {get; set;}
        @AuraEnabled
        public String gender {get; set;}
        @AuraEnabled
        public String sexualOrientation {get; set;}
        @AuraEnabled
        public String sexualOrientationDescription {get; set;}
        @AuraEnabled
        public String genderIdentity {get; set;}
        @AuraEnabled
        public String genderIdentityDescription {get; set;}
        @AuraEnabled
        public String ethnicityId {get; set;}
        @AuraEnabled
        public String alternateEthnicityId {get; set;}
        @AuraEnabled
        public String raceId {get; set;}
        @AuraEnabled
        public String languageId {get; set;}
        @AuraEnabled
        public String maritalStatusId {get; set;}
        @AuraEnabled
        public String addressLine1 {get; set;}
        @AuraEnabled
        public String addressLine2 {get; set;}
        @AuraEnabled
        public String city {get; set;}
        @AuraEnabled
        public String zip {get; set;}
        @AuraEnabled
        public String state {get; set;}
        @AuraEnabled
        public String countryCode {get; set;}
        @AuraEnabled
        public String home {get; set;}
        @AuraEnabled
        public String work {get; set;}
        @AuraEnabled
        public String cell {get; set;}
        @AuraEnabled
        public String email {get; set;}
        @AuraEnabled
        public String preferredCommunicationId {get; set;}
        @AuraEnabled
        public String emergencyContact {get; set;}
        @AuraEnabled
        public Integer relationId {get; set;}
        @AuraEnabled
        public Integer phone1Emergency {get; set;}
        @AuraEnabled
        public Integer phone2Emergency {get; set;}
        @AuraEnabled
        public Integer addressLine1Work {get; set;}
        @AuraEnabled
        public Integer addressLine2Work {get; set;}
        @AuraEnabled
        public Integer cityWork {get; set;}
        @AuraEnabled
        public Integer stateWork {get; set;}
        @AuraEnabled
        public Integer zipWork {get; set;}
        @AuraEnabled
        public Integer phone1Work {get; set;}
        @AuraEnabled
        public Integer phone2Work {get; set;}
        @AuraEnabled
        public Boolean hippaCompliance {get; set;}
        @AuraEnabled
        public Datetime hippaComplianceDate {get; set;}
        @AuraEnabled
        public Integer consent {get; set;}
        @AuraEnabled
        public Integer patientStatusId {get; set;}
        @AuraEnabled
        public String nextOfKinName {get; set;}
        @AuraEnabled
        public String nextOfKinPhone {get; set;}
        @AuraEnabled
        public String nextOfKinRelation {get; set;}
        @AuraEnabled
        public String motherFirstName {get; set;}
        @AuraEnabled
        public String motherLastName {get; set;}
        @AuraEnabled
        public String generalHealth {get; set;}
        @AuraEnabled
        public String generalComment {get; set;}
        @AuraEnabled
        public Boolean removeSearch {get; set;}
        @AuraEnabled
        public Datetime deathDate {get; set;}
        @AuraEnabled
        public String deathCause {get; set;}
        @AuraEnabled
        public Integer userIdAdded {get; set;}
        @AuraEnabled
        public String userAdded {get; set;}
        @AuraEnabled
        public Integer userIdUpdated {get; set;}
        @AuraEnabled
        public String userUpdated {get; set;}
        @AuraEnabled
        public Datetime createdAt {get; set;}
        @AuraEnabled
        public Datetime udpatedAt {get; set;}
        @AuraEnabled
        public Datetime deletedAt {get; set;}
    }


    public class ScriptSureAllergies {

        public ScriptSureAllergies() {

        }

        public ScriptSureAllergies(Allergy__c allergy) {

            if (allergy.Id__c != null) {
                Id = Integer.valueOf(String.valueOf(allergy.Id__c));
            }
            if (allergy.Patient_Id__c != null) {
                patientId = Integer.valueOf(String.valueOf(allergy.Patient_Id__c));
            }

            if (allergy.Account__r.Encounter_Id__c != null)
            encounterId = Integer.valueOf(String.valueOf(allergy.Account__r.Encounter_Id__c));
            allergyId = String.valueOf(allergy.Allergy_Id__c);
            rxnorm = String.valueOf(allergy.Rxnorm__c);
            ndc = String.valueOf(allergy.Ndc__c);
            allergyType = 0;
            allergyTypeText = allergy.Allergy_Type_Text__c;
            if(allergy.Reaction__c != null)
            reactionId = Integer.valueOf(String.valueOf(allergy.Reaction__c));
            reactionText = allergy.Reaction_Text__c;
            severityCode = allergy.Severity_Code__c;
            severityCodeText = allergy.Severity_Code_Text__c;
            adverseEventCode = allergy.Adverse_Event_Code__c;
            adverseEventCodeText = allergy.Adverse_Event_Code_Text__c;
            name = allergy.IRIS_Only__c ?  allergy.Name__c + ' (IRIS Only)' : allergy.Name__c;
            comment = allergy.Comment__c;
            onsetDate = allergy.Onset_Date__c;
            endDate = allergy.End_Date__c;
            if (allergy.Archive__c != null)
            archive = Integer.valueOf(allergy.Archive__c);
            if (allergy.Id__c != null)
            id = Integer.valueOf(String.valueOf(allergy.Id__c));
            if (allergy.HIC_SEQN__c != null)
            HIC_SEQN = Integer.valueOf(String.valueOf(allergy.HIC_SEQN__c));
            if (allergy.DAM_ALRGN_GRP__c != null)
            DAM_ALRGN_GRP = Integer.valueOf(String.valueOf(allergy.DAM_ALRGN_GRP__c));
            GCN_SEQN = String.valueOf(allergy.GCN_SEQN__c);
            if (allergy.User_Id__c != null)
            userId = Integer.valueOf(String.valueOf(allergy.User_Id__c));
            userName = allergy.User_Name__c;
            doctorName = allergy.Doctor_Name__c;
            updatedAt = allergy.Updated_At__c;
            createdAt = allergy.Created_At__c;
            ROUTED_MED_ID = allergy.ROUTED_MED_ID__c;
            accountId = allergy.Account__c;
            recordId = allergy.Id;
            irisOnly = allergy.IRIS_Only__c;

        }


        @AuraEnabled
        public Integer patientId {get; set;}
        @AuraEnabled
        public Integer encounterId {get; set;}
        @AuraEnabled
        public String allergyId {get; set;}
        @AuraEnabled
        public String rxnorm {get; set;}
        @AuraEnabled
        public String ndc {get; set;}
        @AuraEnabled
        public Integer allergyType {get; set;}
        @AuraEnabled
        public String allergyTypeText {get; set;}
        @AuraEnabled
        public Integer reactionId {get; set;}
        @AuraEnabled
        public String reactionText {get; set;}
        @AuraEnabled
        public String severityCode {get; set;}
        @AuraEnabled
        public String severityCodeText {get; set;}
        @AuraEnabled
        public String adverseEventCode {get; set;}
        @AuraEnabled
        public String adverseEventCodeText {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String comment {get; set;}
        @AuraEnabled
        public Datetime onsetDate {get; set;}
        @AuraEnabled
        public Datetime endDate {get; set;}
        @AuraEnabled
        public Integer archive {get; set;}
        @AuraEnabled
        public Integer id {get; set;}
        @AuraEnabled
        public Integer HIC_SEQN {get; set;}
        @AuraEnabled
        public Integer DAM_ALRGN_GRP {get; set;}
        @AuraEnabled
        public String GCN_SEQN {get; set;}
        @AuraEnabled
        public Integer userId {get; set;}
        @AuraEnabled
        public String userName {get; set;}
        @AuraEnabled
        public Integer doctorId {get; set;}
        @AuraEnabled
        public String doctorName {get; set;}
        @AuraEnabled
        public Datetime updatedAt {get; set;}
        @AuraEnabled
        public Datetime createdAt {get; set;}
        @AuraEnabled
        public String ROUTED_MED_ID {get; set;}
        @AuraEnabled
        public Id accountId {get; set;}
        @AuraEnabled
        public Id recordId {get; set;}
        @AuraEnabled
        public Boolean irisOnly {get; set;}

    }

    public class ScriptSureSearchAllergy {
        @AuraEnabled
        public String allergyId {get; set;}
        @AuraEnabled
        public String allergyType {get; set;}
        @AuraEnabled
        public Integer ROUTED_MED_ID {get; set;}
        @AuraEnabled
        public String Descr {get; set;}
    }

    public class ScriptSurePatientWrapper {
        public String successMsg {get; set;}
        public ScriptSurePatient savedPatientObj {get; set;}
    }

    public class PrescriptionDetail {

        public String prescriptionId {get; set;}
        public String patientId {get; set;}
        public String encounterId {get; set;}
        public String messageId {get; set;}
        public String messageType {get; set;}
        public String practiceId {get; set;}
        public String userId {get; set;}
        public String userName {get; set;}
        public String supervisorId {get; set;}
        public String supervisorName {get; set;}
        public String doctorId {get; set;}
        public String doctorName {get; set;}
        public String followUpPrescriberId {get; set;}
        public String followUpPrescriberName {get; set;}
        public String approveId {get; set;}
        public String approveName {get; set;}
        public String approveDate {get; set;}
        public String refill {get; set;}
        public String writtenDate {get; set;}
        public String fillDate {get; set;}
        public String duration {get; set;}
        public String durationQualifier {get; set;}
        public String combinationMed {get; set;}
        public String printDuration {get; set;}
        public String compoundTitle {get; set;}
        public String compoundQuantity {get; set;}
        public String compoundQuantityQualifier {get; set;}
        public String compoundDrugDuration {get; set;}
        public String compoundDrugDurationPadded {get; set;}
        public String concurrentMed {get; set;}
        public Boolean archive {get; set;}
        public String sendMethod {get; set;}
        public String formularyChecked {get; set;}
        public String pharmacyId {get; set;}
        public String pharmacy {get; set;}
        public String prescriptionType {get; set;}
        public Integer prescriptionStatusTypeId {get; set;}
        public String messageStatus {get; set;}
        public String maxDaily {get; set;}
        public String groupId {get; set;}
        public String pharmacyNote {get; set;}
        public String internalComment {get; set;}
        public String authorizationStatus {get; set;}
        public String authorizationQualifier {get; set;}
        public String authorizationId {get; set;}
        public String createdAt {get; set;}
        public String updatedAt {get; set;}
        public ScriptSurePatient Patient {get; set;}
        public ScriptSurePrescriptionScript PrescriptionScript {get; set;}
        public List<ScriptSurePrescriptionAlert> PrescriptionAlerts {get; set;}
        public List<ScriptSurePrescriptionDrug> PrescriptionDrugs {get; set;}
        public List<ScriptSurePrescriptionDiagnose> PrescriptionDiagnoses {get; set;}
        public List<ScriptSurePrescriptionStatus> PrescriptionStatuses {get; set;}
        public List<ScriptSurePrescriptionComment> PrescriptionComments {get; set;}
    }

    public class PrescritionHeader {
        public Integer id {get; set;}
        public String prescriptionId {get; set;}
        public String businessUnitId {get; set;}
        public String actionType {get; set;}
        public String processSet {get; set;}
        public Datetime createdAt {get; set;}
        public PrescriptionDetail Prescription {get; set;}
        public PrescriptionDetail PrescriptionDelete {get; set;}
    }

    public class ScriptSurePrescriptionScript {
        public Integer prescriptionId {get; set;}
        public String drugFormat {get; set;}
    }

    public class ScriptSurePrescriptionAlert {

    }

    public class ScriptSurePrescriptionDrug {
        public String drugDuration {get; set;}
        public String drugDurationPadded {get; set;}
        public String prescriptionId {get; set;}
        public String drugId {get; set;}
        public String drugOrder {get; set;}
        public String ndc {get; set;}
        public String rxnorm {get; set;}
        public String rxnormQualifier {get; set;}
        public String ROUTED_MED_ID {get; set;}
        public String GCN_SEQNO {get; set;}
        public String drugName {get; set;}
        public String MED_NAME_TYPE_CD {get; set;}
        public String MED_REF_DEA_CD {get; set;}
        public String MED_REF_GEN_DRUG_NAME_CD {get; set;}
        public String MED_REF_FED_LEGEND_IND {get; set;}
        public Decimal quantity {get; set;}
        public String quantityQualifier {get; set;}
        public String calculate {get; set;}
        public String sampleLotNumber {get; set;}
        public String sampleExpiration {get; set;}
        public String useSubstitution {get; set;}
        public String line1 {get; set;}
        public String line2 {get; set;}
        public String reconcileDate {get; set;}
        public String reconcileStatus {get; set;}
        public String reconcileUserId {get; set;}
        public List<ScriptSurePrescriptionSig> PrescriptionSigs {get; set;}
    }

    public class ScriptSurePrescriptionSig {
        public ScriptSurePrescriptionSig() {

        }
        public Integer drugId {get; set;}
        public Integer sigId {get; set;}
        public Integer sigOrder {get; set;}
        public String line3 {get; set;}
        public String multipleSigModifier {get; set;}
        public String doseDeliveryMethodCode {get; set;}
        public String doseDeliveryMethodText {get; set;}
        public String doseQuantity {get; set;}
        public String doseFormCode {get; set;}
        public String doseFormText {get; set;}
        public String routeofAdministrationCode {get; set;}
        public String routeofAdministrationText {get; set;}
        public String siteofAdministrationCode {get; set;}
        public String siteofAdministrationText {get; set;}
        public String administrationTimingCode {get; set;}
        public String administrationTimingText {get; set;}
        public String secondaryAdministrationTimingCode {get; set;}
        public String secondaryAdministrationTimingText {get; set;}
        public String secondaryAdministrationTimingModifierCode {get; set;}
        public String secondaryAdministrationTimingModifierText {get; set;}
        public String frequencyNumericValue {get; set;}
        public String frequencyUnitsCode {get; set;}
        public String frequencyUnitsText {get; set;}
        public String indicationPrecursorCode {get; set;}
        public String indicationPrecursorText {get; set;}
        public String indicationTextCode {get; set;}
        public String indicationText {get; set;}
        public String indicationValueUnitofMeasureCode {get; set;}
        public String indicationValueUnitofMeasureText {get; set;}
        public String durationNumericValue {get; set;}
        public String durationTextCode {get; set;}
        public String durationText {get; set;}
        public String descriptor {get; set;}
        public String dose {get; set;}
        public String conversionTotal {get; set;}
        public String calculate {get; set;}
    }

    public class ScriptSurePrescriptionDiagnose {

    }

    public class ScriptSurePrescriptionStatus implements Comparable {
        public String prescriptionStatusId {get; set;}
        public Integer prescriptionStatusTypeId {get; set;}
        public String prescriptionId {get; set;}
        public String name {get; set;}
        public String encounterId {get; set;}
        public String userId {get; set;}
        public String userName {get; set;}
        public String createdAt {get; set;}
        public Datetime createdAtDate;

        public Datetime getCreatedAtDate() {
            return Datetime.parse(this.createdAt);
        }

        public Integer compareTo(Object compareTo) {
            ScriptSurePrescriptionStatus scriptSurePrescriptionStatus = (ScriptSurePrescriptionStatus)compareTo;

            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (this.getCreatedAtDate().getTime() > scriptSurePrescriptionStatus.getCreatedAtDate().getTime()) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (this.getCreatedAtDate().getTime() < scriptSurePrescriptionStatus.getCreatedAtDate().getTime()) {
                // Set return value to a negative value.
                returnValue = -1;
            }

            return returnValue;
        }
    }

    public class ScriptSurePrescriptionComment {
        public Integer commentId {get; set;}
        public Integer patientId {get; set;}
        public Integer ROUTED_MED_ID {get; set;}
        public Integer encounterId {get; set;}
        public Integer prescriptionId {get; set;}
        public String expirationDate {get; set;}
        public Integer type {get; set;}
        public Integer archive {get; set;}
        public Integer userId {get; set;}
        public String userName {get; set;}
        public Integer doctorId {get; set;}
        public String doctorName {get; set;}
        public String comment {get; set;}
        public DateTime createdAt {get; set;}
        public DateTime updatedAt {get; set;}
    }


    public class PrescriptionWrapper {
        public String processSet {get; set;}
        public List<PrescritionHeader> prescriptions {get; set;}
    }

    public class EncounterObj {
        public Integer encounterId {get; set;}
        public Integer userId {get; set;}
        public String guid {get; set;}
        public String patientId {get; set;}
        public Integer practiceId {get; set;}
        public String userName {get; set;}
        public Integer doctorId {get; set;}
        public String doctorName {get; set;}
        public String encounterStatus {get; set;}
        public Datetime updatedAt {get; set;}
        public Datetime  createdAt{get; set;}
    }

    public class EncounterWrapper {
        public String successMsg {get; set;}
        public EncounterObj savedEncounterObj {get; set;}
    }
}