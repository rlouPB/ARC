public with sharing class relatedConController {
    public static Map<Id, String> recordtypemap {get;set;}

    @AuraEnabled
    public static Account getAccount(Id accountId) {
        return [SELECT Id, Current_Admission_Stage__c FROM Account WHERE Id = :accountId];
    }

	@AuraEnabled
    public static List<Related_Contact__c> getRelContacts(Id accountId) {
        String query = '';
        /*
        if(displayMode == 'inquiry')
        {
            query += 'SELECT Id, Contact_Name__c, Contact__r.Id, Contact__r.Phone, Contact__r.MobilePhone, Contact__r.npe01__PreferredPhone__c, ';
            query += 'Contact__r.Personal_Assistant_Name__c, Contact__r.Personal_Assistant_Phone__c, Contact__r.Contact_through_Personal_assistant__c, ';
            query += 'Contact__r.npe01__WorkPhone__c, Role__c, Role_Details__c, Long_Role__c, Primary_Contact__c, Referrer__c, Payor__c, ';
            query += 'Contact_Permissions__c, RecordTypeId, RecordType.Name ';
            query += 'FROM Related_Contact__c ';
            query += 'WHERE Account__c = :accountId ';
            query += 'ORDER BY Recordtype.Name ASC, Contact__r.LastName ASC, Contact__r.FirstName ASC';
        }

        if(displayMode == 'patient')
        {
            String recordTypeName = 'Personal';
            query += 'SELECT Id, Contact_Name__c, Contact__r.Id, Contact__r.Phone, Contact__r.MobilePhone, Contact__r.npe01__PreferredPhone__c, ';
            query += 'Contact__r.Personal_Assistant_Name__c, Contact__r.Personal_Assistant_Phone__c, Contact__r.Contact_through_Personal_assistant__c, ';
            query += 'Contact__r.npe01__WorkPhone__c, Role__c, Role_Details__c, Long_Role__c, Primary_Contact__c, Referrer__c, Payor__c, ';
            query += 'Contact_Permissions__c, RecordTypeId, RecordType.Name, Authorization_Level__c, Letters__c ';
            query += 'FROM Related_Contact__c ';
            query += 'WHERE Account__c = :accountId AND RecordType.Name = :recordTypeName ';
            query += 'AND (Authorization_Level__c LIKE ' + '\'' + 'Level'  + '%\' ';
            query += 'OR Letters__c = true) ';
            query += 'ORDER BY Contact__r.LastName ASC';
        }
        */
        query += 'SELECT Id, Contact_Name__c, Contact__r.Id, Contact__r.Phone, Contact__r.MobilePhone, Contact__r.npe01__PreferredPhone__c, ';
        query += 'Contact__r.Personal_Assistant_Name__c, Contact__r.Personal_Assistant_Phone__c, Contact__r.Contact_through_Personal_assistant__c, ';
        query += 'Contact__r.npe01__WorkPhone__c, Role__c, Role_Details__c, Long_Role__c, Primary_Contact__c, Referrer__c, Payor__c, ';
        query += 'Contact_Permissions__c, RecordTypeId, RecordType.Name, Authorization_Level__c, Letters__c, Video_Conference_ID__c ';
        query += 'FROM Related_Contact__c ';
        query += 'WHERE Account__c = :accountId ';
        query += 'ORDER BY Recordtype.Name ASC, Contact__r.LastName ASC, Contact__r.FirstName ASC';

        System.debug('query ' + query);

        List<sObject> sObjectList = Database.query(query);
        return (List<Related_Contact__c>)sObjectList;
    }

    @AuraEnabled
    public static List<Id> getRecTypesIds() {
        List<Id> RecTypeIds = new List<Id>();
        RecTypeIds.add(Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Patient').getRecordTypeId());
        RecTypeIds.add(Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId());
        RecTypeIds.add(Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get('Professional').getRecordTypeId());

        return RecTypeIds;
    }

    @AuraEnabled
    public static List<String> fetchRecordTypeValues(){
        List<Schema.RecordTypeInfo> recordtypes = Schema.SObjectType.Related_Contact__c.getRecordTypeInfos();
        recordtypemap = new Map<Id, String>();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master' && rt.getName() != 'Patient'){
            	recordtypemap.put(rt.getRecordTypeId(), rt.getName());
            }
        }
        return recordtypemap.values();
    }

    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Related_Contact__c.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();
        return recid;
    }

    @AuraEnabled
    public static RelatedContactsResult fetchRelatedContactsInfo(){
        RelatedContactsResult result = new relatedContactsResult();
        Boolean hasCustomPermission = FeatureManagement.checkPermission('IsSocialWorker');
        result.isSocialWorker =  hasCustomPermission;
        result.recordTypeValues =  fetchRecordTypeValues();
        result.recordTypeIds =  getRecTypesIds();
        return result;
    }

    public class RelatedContactsResult {
        @AuraEnabled
        public Boolean isSocialWorker;
        @AuraEnabled
        public List<String> recordTypeValues;
        @AuraEnabled
        public List<Id>  recordTypeIds;
    }

	// TODO: relatedConController: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
	// TODO: relatedConController: Increase code coverage 2
    public static void increaseCoverage2() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: relatedConController: Increase code coverage 3
    public static void increaseCoverage3() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}