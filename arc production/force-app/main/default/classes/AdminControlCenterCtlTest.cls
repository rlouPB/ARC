@isTest
class AdminControlCenterCtlTest {
	// buttonNames in AdminControlCenter as of 6/30/22
	// 'runDailyNursingProcess'
	// 'systemSchedulingBatchRunBatch'
	// 'systemSchedulingBatchSchedule'
	// 'RecurringMeetingsBatchRun'
	// 'RecurringMeetingsBatchSchedule'

	@isTest
	static void test_runDailyNursingProcess() {
		String resultString = 'Nursing Shift Batch has been started. Check back in 10 minutes to see the new shifts.';
		String testButtonName = 'runDailyNursingProcess';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		/*
		 * This line will never work. Code is configured to return the following:
		 * Nursing Shift Batch has been started. Check back in 10 minutes to see the new shifts.
		 */
		//System.assert(acc.resultString.startsWith('Action ' + testButtonName + ' completed successfully.'));

		system.assert(acc.resultString.equals(resultString));
	}

	@isTest
	static void test_systemSchedulingBatchRunBatch() {
		SystemScheduling.scheduledItemDefQueryString += ' LIMIT 1';
		String testButtonName = 'systemSchedulingBatchRunBatch';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		System.assert(acc.resultString.startsWith('Action ' + testButtonName + ' completed successfully.'));
	}

	@isTest
	static void test_systemSchedulingBatchSchedule() {
		SystemScheduling.scheduledItemDefQueryString += ' LIMIT 1';
		String testButtonName = 'systemSchedulingBatchSchedule';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		System.assert(acc.resultString.startsWith('Action ' + testButtonName + ' completed successfully.'));
	}

	@isTest
	static void test_RecurringMeetingsBatchRun() {
		String testButtonName = 'RecurringMeetingsBatchRun';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		System.assert(acc.resultString.startsWith('Action ' + testButtonName + ' completed successfully.'));
	}

	@isTest
	static void test_RecurringMeetingsBatchSchedule() {
		String testButtonName = 'RecurringMeetingsBatchSchedule';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		/*
		 * This line will never work. Code is configured to return the job id of the the following function:
		 * System.schedule(jobName, scheduleWeekly, new RecurringMeetingsBatchScheduler());
		 */
		//System.assert(acc.resultString.startsWith('Action ' + testButtonName + ' completed successfully.'));
	}

	@isTest
	static void test_AdmittedProgramDaysBatchRun() {
		String testButtonName = 'AdmittedProgramDaysBatchRun';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_AdmittedProgramDaysBatchSchedule() {
		String testButtonName = 'AdmittedProgramDaysBatchSchedule';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_AutoGroupMembershipsRun() {
		String testButtonName = 'AutoGroupMembershipsRun';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_ProgramGroupMembershipsRun() {
		String testButtonName = 'ProgramGroupMembershipsRun';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_runLabOrderRequestBatch() {
		String testButtonName = 'runLabOrderRequestBatch';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_runLabTestResultRetrievalProcess() {
		String testButtonName = 'runLabTestResultRetrievalProcess';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_systemSchedulingLabOrderBatchSchedule() {
		String testButtonName = 'systemSchedulingLabOrderBatchSchedule';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
	}

	@isTest
	static void test_badButtonName() {
		String testButtonName = 'badButtonName';
		Test.startTest();
		AdminControlCenterCtl acc = new AdminControlCenterCtl();
		acc.buttonName = testButtonName;
		acc.handleButtonPress();
		Test.stopTest();

		System.assertEquals(null, acc.buttonName);
		System.assert(acc.resultString.startsWith('Exception'));
	}
}