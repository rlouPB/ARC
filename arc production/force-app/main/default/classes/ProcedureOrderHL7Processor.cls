/**
* @author Synaptic Advisors
* @date 2022
*
* @group BHS
* @group-content ../../ApexDocContent/BHS.htm
*
* @description A helper class to send/retrieve lab tests to/from LifePoint
*  
*/
public with sharing class ProcedureOrderHL7Processor {
    public static String LIFEPOINT_SETTING = 'Default';
    public static final String ACK_HEADER = 'status';
    public static final String PROCESS_NAME = 'Send Lab Order Request';
    public static final String PROCESS_METHOD = 'ProcedureOrderHL7Processor.sendOrder';
    public static final String PROCESS_MESSAGE = 'Retry attempts exhausted';
    @future(Callout=True)
    public static void sendHL7OrderFuture(String orderId, String procedureResultId) {
        system.debug('sendHL7OrderFuture----');
        sendOrder(orderId, procedureResultId);
    }

	static void addSentIsuranceInfo(Id procedureResultId, String insuranceInfo) {
        Procedure_Result__c po = new Procedure_Result__c(Id = procedureResultId, Insurance_Sent__c=insuranceInfo);
        update po;
    }

    /*******************************************************************************************************
    * @description Send a lab test order in hl7 format to LifePoint
    * Error handling:
    * This method handles both exception thrown by Apex, and communication errors such as 401 and 404 returned from LifePoint endpoint.
    * @param orderId:string procedure order sf Id
    * @param procedureResultId:string procedure result sf Id
    * @return an instance of BHS_ORM_Staging__c 
    */
    @AuraEnabled 
    public static BHS_ORM_Staging__c sendOrder(String orderId, String procedureResultId) {
        Procedure_Order__c po1 = [SELECT Admission__c, Admission__r.Patient_Contact__r.Birthdate,Admission__r.Patient_Contact__r.FirstName,
                        Admission__r.Patient_Contact__r.LastName,Admission__r.Patient_Contact__r.MiddleName, Admission__r.Patient_Contact__c,
                        Admission__r.Patient_Contact__r.MailingState,Admission__r.Patient_Contact__r.MailingStreet,
                        Admission__r.Patient_Contact__r.MailingCity,Admission__r.Patient_Contact__r.MailingCountry,
                        Admission__r.Patient_Contact__r.MailingCountryCode,Admission__r.Patient_Contact__r.MailingPostalCode,
                        Admission__r.Patient_Contact__r.MailingStateCode,Admission__r.Patient_Contact__r.Phone,Admission__r.Patient_Contact__r.Race__c,
                        Admission__r.Patient_Contact__r.Gender__c,Patient_Account__r.Age__c,Patient_Account__r.Email__c,Patient_Account__r.Gender__c,Patient_Account__r.Name,
                        Admission__r.Admit_Date__c, BHS_Message_Control_Id__c, Patient_Account__r.Medical_Record_Number__c, Patient_Account__r.External_Patient_Id__c,
                        Patient_Account__r.BHS_Patient_Id__c, Admission__r.Patient_Contact__r.BHS_Patient_Name__c, Admission__r.Patient_Contact__r.BHS_Gender_Code__c,
                        Admission__r.Patient_Contact__r.BHS_Patient_Address__c, Name, 
                        BHS_Ordering_Provider__c, Date_of_Order__c, Finalized_Date_Time__c, Indication__c, MD_Comments__c,
                        (SELECT Id,Name,Order_Id__c,Order_Date__c,Collection_Date__c,BHS_Ordering_Provider__c,Lab_Test_Type__c,Stat_Flag__c,BHS_Ordered_Procedure__c,
                         Query__c, Query_Answer__c FROM Lab_Observations__r)
                        FROM Procedure_Order__c WHERE Id = :orderId WITH SECURITY_ENFORCED limit 1];

        List<Insurance_Policy__c> insurances = [SELECT Id, Group_Number__c, Policy_Number__c, Subscriber_Name__c, Insurance_Provider_Name__c,Subscriber_Date_of_Birth__c
                                                FROM Insurance_Policy__c 
                                                WHERE Admission__c = :po1.Admission__c 
                                                AND Insurance_Billing_Status__c <> 'Billing only Medications'
                                                AND (Policy_Start_Date__c = NULL OR Policy_Start_Date__c < TODAY)
                                                AND (Policy_End_Date__c = NULL OR Policy_End_Date__c > TODAY)];
        String orderHL7Msg = '';
        orderHL7Msg += BHS_HL7_WriterUtils.transformASegment('MSH', po1, null);
        
        orderHL7Msg += BHS_HL7_WriterUtils.transformASegment('PID', po1, 1);

        String comment ='';
        if(String.isNotBlank(po1.Indication__c)) {
            comment += 'Indication: ' + po1.Indication__c + ';';
        }
        if(String.isNotBlank(po1.MD_Comments__c)) {
            comment += 'Physician Comment: ' + po1.MD_Comments__c ;
        }
        if(String.isNotBlank(comment)) {
            po1.Procedure_Order_Comment__c = comment;
            orderHL7Msg += BHS_HL7_WriterUtils.transformASegment('NTE', po1, 1);
        }
        String insuranceInfo='';
        for(Integer idx=0; idx < insurances.size(); idx++) {
            orderHL7Msg += BHS_HL7_WriterUtils.transformASegment('IN1', insurances[idx], idx+1);
            insuranceInfo += insurances[idx].Insurance_Provider_Name__c+ ',';
            insuranceInfo += insurances[idx].Group_Number__c + ',';
            insuranceInfo += insurances[idx].Policy_Number__c + ',';
            insuranceInfo += insurances[idx].Subscriber_Name__c + ',';
            insuranceInfo += String.valueOf(insurances[idx].Subscriber_Date_of_Birth__c);
            
        }
        //ARC-2471 change ORC.2 from procedure order Id to Procedure Result Id
        //Id poId = po1.Id;
        //po1.Id = procedureResultId;
        String orcHl7 = BHS_HL7_WriterUtils.transformASegment('ORC', po1, null);
        orcHl7 = orcHl7.replace(orderId, procedureResultId);
        orderHL7Msg += orcHl7;
        
        //ARC-2471 restore the procedure order id
        //po1.Id = poId;
        for(Integer idx=0; idx < po1.Lab_Observations__r.size(); idx++) {
            orderHL7Msg += BHS_HL7_WriterUtils.transformASegment('OBR', po1.Lab_Observations__r[idx], idx+1);
        }
        System.debug('checkpoint orderHL7Msg =' + orderHL7Msg);
        
        String result = 'Send HL7 Message to LifePoint is disabled!';
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(LIFEPOINT_SETTING);
        System.debug('checkpoint lp.Disable_Send__c =' + lp.Disable_Send__c);
        if(!lp.Disable_Send__c) {
            try {
                result = sendHL7(orderHL7Msg);
            } catch (Exception e) {
                result = e.getMessage();
                ProcessLogging.quickProcessLog(PROCESS_NAME, e.getStackTraceString(), result);
            }
        }
        System.debug('checkpoint result =' + result);
        BHS_ORM_Staging__c staging = new BHS_ORM_Staging__c(Payload__c = orderHL7Msg, Procedure_Result__c = procedureResultId, External_Id__c=procedureResultId);
        Map<String, Object> ack = null;
        Procedure_Result__c pr = new Procedure_Result__c(Id = procedureResultId);
        if(result.indexOf(ACK_HEADER) != -1 || lp.Disable_Send__c) {
            staging.ACK_Message__c = result;
            staging.status__c = 'In Progress';
            staging.Error_Message__c = null;
            upsert staging External_Id__c;
            ProcedureOrderHL7Processor.addSentIsuranceInfo(procedureResultId, insuranceInfo);
            pr.Sent_Date_Time__c = DateTime.now();
        } else {
            //retrieve current number of retry times stored in BHS_ORM_Staging__c
            List<BHS_ORM_Staging__c> stgObjs = [SELECT Id, Retry_Times__c FROM BHS_ORM_Staging__c where External_Id__c = :procedureResultId];
            staging.Retry_Times__c = 1;
            if(stgObjs.size() > 0) {
                //increase the number of retry times
                Decimal retryTimes = stgObjs[0].Retry_Times__c == null ? 0 : stgObjs[0].Retry_Times__c;
                staging.Retry_Times__c = ++retryTimes;
            }
            //when error occurs, set Error_Meeage__c returned from LifePoint
            //  set Sent_Date_Time__c to null, therefore batch process can retry it
            staging.Error_Message__c = result;
            pr.Sent_Date_Time__c = null;
            staging.ACK_Message__c = null;
            
            if(staging.Retry_Times__c <= lp.Max_Retries__c) {
                staging.status__c = 'Resent';
            } else {
                pr.Exhaust_Max_Retries__c = true;
                staging.status__c = 'Error';
                ProcessLogging.quickProcessLog(PROCESS_NAME, PROCESS_METHOD, PROCESS_MESSAGE);
            }
            upsert staging External_Id__c;
        }
        update pr;
        return staging;
    }
    
    public static String sendHL7(String hl7Msg) {
        Map<String, Object> strAccessToken = (Map<String, Object>) JSON.deserializeUntyped(getAccessToken());
        String accessToken = (String) strAccessToken.get('jwt');
        System.debug(accessToken);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(LIFEPOINT_SETTING);
        req.setEndpoint(lp.Order_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Content-Type','application/json');
        //String payload = '{"HL7": "MSH|^~\\\\&|LIFEPOINT|AUSTENRIGGS|XYZ|XYZ|202203160842||OML^O21|20140000000944|T|2.5.1|20140000000943||||||\rPID|1||2||||19500102|M|||123 Test Street^^Test Town^NJ^07452||1111111111|2222222222ext2334|||||111-11-1111\rPV1|||||||12345 ^House^Gregory||||||||||||||||||||||||||||||||12345 ^House^Gregory|||||||||||\rORC|XO|21|21-24341_0||R||^^^^^R^N||201403241350|||12345 ^House^Gregory|0^||||||\rOBR|1|21|21-24341_0|24341_0^Gas & carbon monoxide panel in arterial blood|R|201402281350|201403241350|201403241350|||||||^^^|12345 ^House^Gregory|||||||LAB|||||^ ~^ ~^ |||||\rDG1|1||428|HEART FAILURE1\r"}';
        Map<String, String> payloadMap = new Map<String, String> {
            'HL7'=>hl7Msg
        };
        
        String payload = JSON.serialize(payloadMap);
        payload = payload.replace('\\\\r','\\r');
        System.debug('payload=' + payload);
        req.setBody(payload);
        String hl7Result=null;
        //if(!Test.isRunningTest()) {
            HttpResponse res = h.send(req);
            hl7Result = res.getBody();
        //} 
        return hl7Result;
    }
    public class UserCredentials {
        public UserCredentials(String userName, String password) {
            this.username = userName;
            this.password = password;
        }
        public String username;
        public String password;
    }
    public static String getAccessToken() {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','application/json');
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(LIFEPOINT_SETTING);
        req.setEndpoint(lp.Login_Endpoint__c);
        req.setMethod('GET');
        UserCredentials credentials = new UserCredentials(lp.User_Name__c, lp.Password__c);
        String payload = JSON.serialize(credentials);
        req.setBody(payload);
        // Send the request, and return a response
        String token = '{"jwt":"96Fe0F3YmiPk0t41kdj6CYFC7muZl2BrAgkv4iaZSUwI"}';
        if(!Test.isRunningTest()) {
            HttpResponse res = h.send(req);
            token = res.getBody();
        } 
        return token;
    }

    public class OrderResult {
        public String MessageId;
        public String MessageBody;
    }

    @AuraEnabled 
    public static boolean retrieveOrderResult() {
        boolean bResult = false;
        LifePoint_Setting__mdt lp = LifePoint_Setting__mdt.getInstance(LIFEPOINT_SETTING);
        BHS_Order_Result_Staging__c errorOrderResultStaging = null;
        try {
            Map<String, Object> strAccessToken = (Map<String, Object>) JSON.deserializeUntyped(getAccessToken());
            String accessToken = (String) strAccessToken.get('jwt');
            System.debug(accessToken);
            Http h = new Http();
            HttpRequest req = new HttpRequest();
           
            req.setEndpoint(lp.Result_Endpoint__c);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setHeader('Content-Type','application/json');
            BHS_Order_Result_Staging__c r = null;
            HttpResponse res = h.send(req);
            String orderResult = res.getBody();
            if(String.isNotBlank(orderResult)) {
                //if the queue is empty, break out the loop
                List<OrderResult> results = (List<OrderResult>) JSON.deserialize(orderResult, List<OrderResult>.class);
                
                if(results.size() > 0 && String.isNotBlank(results[0].MessageId)) {
                    r = new BHS_Order_Result_Staging__c(Payload__c = orderResult, Status__c = 'Not Started');
                    insert r;
                    bResult = true;
                }  else {
                    system.debug(LoggingLevel.INFO, JSON.serialize(results));
                }
            }
        } catch (Exception e) {
            errorOrderResultStaging = new BHS_Order_Result_Staging__c(Error_Message__c = e.getMessage() + '\n' + e.getStackTraceString(), Status__c = 'Error');
        } finally {
            if(errorOrderResultStaging != null) {
                insert errorOrderResultStaging;
                String errorMsg = lp.Lab_Result_Retrieval_Error_Message__c;
                if(String.isBlank(errorMsg)) {
                    errorMsg = 'An error has occurred in processing a lab result from BHS.  Please review and resolve error in “BHS Order Result Staging”';
                }
                ProcessLogging.quickProcessLog('retrieveOrderResult', 'BHS_Order_Result_Staging__c Id = ' + errorOrderResultStaging.Id, errorMsg);
            }
        }
        return bResult;
    }

}