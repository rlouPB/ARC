global class AdminControlCenterCtl {
	public String resultString { get; set; }
	public String buttonName { get; set; }
	public static String everyHourCRONString = '0 20 * * * ?'; //20 minutes past the hour

	public AdminControlCenterCtl() {
	}

	public void handleButtonPress() {
		try {
			resultString = '';
			switch on buttonName {
				when 'systemSchedulingBatchRunBatch' {
					resultString = SystemSchedulingBatch.runBatch();
				}
				when 'systemSchedulingBatchSchedule' {
					resultString = SystemSchedulingBatch.scheduleBatch();
				}
				when 'runDailyNursingProcess' {
					SIP_DailyNursingShifts.processLogic();
					resultString = 'Nursing Shift Batch has been started. Check back in 10 minutes to see the new shifts.';
				}
				when 'runLabTestResultRetrievalProcess' {
					ProcedureOrderHL7Processor.retrieveOrderResult();
				}
				when 'runLabOrderRequestBatch' {
					LabOrderRequestBatch ssBatch = new LabOrderRequestBatch();
					resultString = Database.executeBatch(ssBatch, 1);
				}
				when 'systemSchedulingLabOrderBatchSchedule' {
					LabOrderBatchScheduler m = new LabOrderBatchScheduler();
					resultString = system.schedule('Lab Order Job', everyHourCRONString, m);
				}
				when 'RecurringMeetingsBatchRun' {
					resultString = RecurringMeetingsBatch.runBatch();
				}
				when 'RecurringMeetingsBatchSchedule' {
					resultString = RecurringMeetingsBatchScheduler.scheduleWeekly();
				}
				when 'ProgramGroupMembershipsRun' {
					resultString = ProgramGroupMemberships.syncAdmittedProgramsToGroup();
				}
				when 'AutoGroupMembershipsRun' {
					AutoGroupMemberships.syncToGroupMemberships();
				}
				when 'DataRetentionBatchRun' {
					resultString = Batch_DataRetention.startBatch();
				}
				when 'DataRetentionBatchSchedule' {
					resultString = Batch_DataRetention.scheduleDaily();
				}
				when 'AdmittedProgramDaysBatchRun' {
					resultString = AdmittedProgramDaysBatch.runBatch();
				}
				when 'AdmittedProgramDaysBatchSchedule' {
					resultString = AdmittedProgramDaysBatch.scheduleDaily();
				}
				when else {
					throw new CustomException('No action found for buttonName "' + buttonName + '"');
				}
			}
			if (!resultString.contains('Nursing Shift Batch has been started')) {
				resultString = 'Action ' + buttonName + ' completed successfully. ' + resultString;
			}
		} catch (Exception e) {
			resultString = 'Exception on click ' + buttonName + '\r\nMessage: ' + e.getMessage() + '\n\nStack Trace: ' + e.getStackTraceString();
		}
		buttonName = null;
	}

	// public void runDailyNursingProcess(){
	//     try{
	//         SIP_DailyNursingShifts.processLogic();
	//         resultString = 'SIP_DailyNursingShifts completed.';
	//     }catch(Exception ex){
	//         resultString = 'Exception: ' + ex.getMessage() + ' - ' + ex.getStackTraceString();
	//     }
	// }

	// public String systemSchedulingBatchRunBatch() {
	//     resultString = SystemSchedulingBatch.runBatch();
	//     return null;
	// }
	// public String systemSchedulingBatchScheduleBatch() {
	//     resultString = SystemSchedulingBatch.scheduleBatch();
	//     return null;
	// }

	@RemoteAction
	global static String getNowDateTime(String context) {
		String nowString = context + '-' + String.valueOf(System.now());
		return nowString;
	}
}