@isTest
public class Group_NoteTriggerHandlerTest {
	@isTest
	static void test1() {
		sobject so = null;
		Group_Note__c gn = new Group_Note__c();
		insert gn;
		update gn;

		Group_NoteTriggerHandler h = new Group_NoteTriggerHandler();
		h.afterDelete(so);
		h.afterInsert(so);
		//h.afterUpdate(so, so);
		h.beforeDelete(so);
		h.beforeInsert(so);
		h.beforeUpdate(So, so);
		//  h.bulkAfter();
		h.bulkBefore();
	}
}