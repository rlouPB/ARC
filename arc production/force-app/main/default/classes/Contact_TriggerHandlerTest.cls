@isTest
private class Contact_TriggerHandlerTest {
	//cover trigger methods with no code in them
	@isTest
	static void touchAllMethods() {
		Id conPatientRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordtypeId();
		Id conStaffRtId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('ARC Staff').getRecordtypeId();
		ITrigger handler = (ITrigger) Type.forName('ContactTriggerHandler').newInstance();

		Test.startTest();
			//gets tested by other classes
			// handler.bulkAfter()

			handler.bulkBefore();
			handler.beforeInsert(new Contact(RecordtypeId = conStaffRtId));
			handler.beforeUpdate(new Contact(), new Contact());
			handler.beforeDelete(new Contact());
			handler.afterInsert(new Contact(Staff_User__c = Userinfo.getUserId()));
			handler.afterUpdate(new Contact(), new Contact(Staff_User__c = Userinfo.getUserId()));
			handler.afterDelete(new Contact());
			handler.andFinally();
		Test.stopTest();
	}
}