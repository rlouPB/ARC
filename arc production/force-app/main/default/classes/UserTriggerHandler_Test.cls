@isTest
public class UserTriggerHandler_Test {
	@testSetup
	static void setup() {
	}

	@isTest
	static void testbulkBefore() {
		UserTriggerHandler.bulkBefore();
	}

	@isTest
	static void testbulkAfter() {
		UserTriggerHandler.bulkAfter();
	}

	@isTest
	static void testbeforeInsert() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.beforeInsert(so);
	}

	@isTest
	static void testbeforeUpdate() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.beforeUpdate(so, so);
	}

	@isTest
	static void testbeforeDelete() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.beforeDelete(so);
	}

	@isTest
	static void testafterInsert() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.afterInsert(so);
	}

	@IsTest
	static void testafterUpdate() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.afterUpdate(so, so);
	}

	@isTest
	static void testafterDelete() {
		Account a = new Account(Name = 'test');
		sObject so = (sObject) a;
		UserTriggerHandler.afterDelete(so);
	}

	@isTest
	static void testandFinally() {
		UserTriggerHandler.andFinally();
	}
}