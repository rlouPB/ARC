public without sharing class TrackFieldHistory {

    //trackFields
	public static void trackFields(List<sObject> triggerNew, Map<Id, sObject> triggerOldMap){
		Boolean isInsert = triggerOldMap == null;

		String objectName = triggerNew[0].Id.getSObjectType().getDescribe().getName();

		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

		List<Field_History__c> fieldHistoriesToInsert = new List<Field_History__c>();

		for (Schema.SObjectField rawField: fieldMap.values())
		{
            Schema.DescribeFieldResult currentField = rawField.getDescribe();
            String fieldName = currentField.getName();
			if (currentField.getType() == Schema.DisplayType.TEXTAREA && string.isNotEmpty(fieldName)){
				for (sObject currentRecord: triggerNew)
				{
                    sObject oldRecord = (isInsert != true)?  triggerOldMap.get(currentRecord.Id) : null;
					if ( isInsert == true && currentRecord.get(fieldName) != null && currentRecord.get(fieldName) != ''){
                        fieldHistoriesToInsert.add( addFieldTrackingRecord(objectName,fieldName,currentRecord,null) );
					} else if (
                        isInsert != true &&
                        currentRecord.get(fieldName) != oldRecord.get(fieldName)
                    ){
                        fieldHistoriesToInsert.add( addFieldTrackingRecord(objectName,fieldName,currentRecord,oldRecord) );
					}
				}
			}
		}
        if( fieldHistoriesToInsert.size() > 0 ){
            insert fieldHistoriesToInsert;
        }
    }

    public static Field_History__c addFieldTrackingRecord(string sobjectName,string fieldName, sobject newObject, sobject oldRecord){
        Field_History__c fh =  new Field_History__c(
            Field_Name__c = fieldName,
            Long_Text_Value__c = String.valueOf(newObject.get(fieldName)),
            Old_Long_Text_Value__c = (oldRecord != null)? string.valueof(oldRecord.get(fieldName)) : null
        );
        fh.put(sobjectName,newObject.get('Id'));
        return fh;
    }
}