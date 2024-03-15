@isTest
public class N_S_Patient_AssignmentTriggerHandlerTest {
	@isTest
	static void test1() {
		Sobject so = null;
		N_S_Patient_AssignmentTriggerHandler h = new N_S_Patient_AssignmentTriggerHandler();
		h.afterDelete(so);
		h.afterInsert(so);
		h.afterUpdate(so, so);
		h.beforeDelete(so);
		h.beforeInsert(so);
		h.beforeUpdate(So, so);
		h.bulkBefore();
		h.andFinally();
		try {
			h.bulkAfter();
		} catch (Exception ex) {
		}
	}
}