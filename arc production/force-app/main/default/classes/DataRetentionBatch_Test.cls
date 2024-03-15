@isTest
private class DataRetentionBatch_Test {
	@testSetup
	static void createTestData() {
		Datetime moreThan180 = Datetime.now().addDays(-181);
		Datetime lessThan180 = Datetime.now().addDays(-179);
		Datetime moreThan60 = Datetime.now().addDays(-61);
		Datetime moreThan7 = Datetime.now().addDays(-8);

		Field_History__c f = (Field_History__c) TestFactory_Patient.createSObject(new Field_History__c(Long_Text_Value__c = 'Test_Patient'), true);
		Test.setCreatedDate(f.Id, moreThan180);

		Field_History__c f1 = (Field_History__c) TestFactory_Patient.createSObject(new Field_History__c(Long_Text_Value__c = 'Test1_Patient'), true);
		Test.setCreatedDate(f1.Id, moreThan180);

		Field_History__c f2 = (Field_History__c) TestFactory_Patient.createSObject(new Field_History__c(Long_Text_Value__c = 'Test2_Patient'), true);
		Test.setCreatedDate(f2.Id, lessThan180);

		Account a = (Account) TestFactory_Patient.createSObject(new Account(Name = 'accTest'), true);
		Contact c = (Contact) TestFactory_Patient.createSObject(new Contact(accountId = a.Id, LastName = 'Mik'), true);
		Test.setCreatedDate(c.Id, moreThan180);

		Contact c1 = (Contact) TestFactory_Patient.createSObject(new Contact(accountId = a.Id, LastName = 'Nik'), true);
		Test.setCreatedDate(c1.Id, lessThan180);

		Message__c msg = (Message__c) TestFactory_Patient.createSObject(new Message__c(Contact__c = c1.Id, Name = 'test message', Type__c = 'Clinical Alert', Subject__c = 'sub'), true);
		Test.setCreatedDate(msg.Id, moreThan60);

		Access_Log__c al = (Access_Log__c) TestFactory_Patient.createSObject(new Access_Log__c(Name = 'Test_AL', RecordId__c = 'testB000002AufCQAS', Context__c = 'voluntary'), true);
		Test.setCreatedDate(al.Id, moreThan7);
	}

	@isTest
	public static void dataRetentionScheduleTest() {
		List<Retention_Setting__mdt> mdtRecords = [SELECT ID, Object__c, Date_Field__c, Allowed_Age__c, Additional_Filter__c FROM Retention_Setting__mdt];

		String CRON_EXP = '0 0 3 * * ? *';

		test.startTest();
		List<Field_History__c> fh = [SELECT Id, createdDate FROM Field_History__c];
		//List<Contact> Con = [SELECT Id, createdDate FROM Contact];

		Batch_DataRetention bdr = new Batch_DataRetention();
		String jobId = System.schedule('ScheduleApexClassTest', CRON_EXP, new Batch_DataRetention());

		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

		test.stopTest();
		// System.assertEquals(CRON_EXP, ct.CronExpression);
		List<Field_History__c> fh1 = [SELECT Id FROM Field_History__c];
		//List<Contact> c = [SELECT Id FROM Contact];
		// System.assertEquals(3, fh1.size());
		//System.assertEquals(2, c.size());
	}

	@isTest
	public static void dataRetentionTest() {
		List<Retention_Setting__mdt> mdtRecords = [SELECT ID, Object__c, Date_Field__c, Allowed_Age__c, Additional_Filter__c FROM Retention_Setting__mdt];

		test.startTest();

		List<Field_History__c> fh = [SELECT Id, createdDate FROM Field_History__c];
		List<Message__c> msg = [SELECT Id, createdDate FROM Message__c];
		List<Access_Log__c> alog = [SELECT Id, createdDate FROM Access_Log__c];
		Batch_DataRetention bdr = new Batch_DataRetention(mdtRecords);
		Database.executeBatch(bdr);

		test.stopTest();

		List<Field_History__c> fh1 = [SELECT Id FROM Field_History__c];
		List<Message__c> m = [SELECT Id FROM Message__c];
		List<Access_Log__c> a = [SELECT Id FROM Access_Log__c];
		//System.assertEquals(1, fh1.size());
		// System.assertEquals(0, m.size());
		// System.assertEquals(0, a.size());
	}
}