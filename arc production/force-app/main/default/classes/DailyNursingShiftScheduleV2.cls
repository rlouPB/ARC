global with sharing class DailyNursingShiftScheduleV2 implements Schedulable {
    global void execute(SchedulableContext sc) {
        DailyNursingShiftBatch batch = new DailyNursingShiftBatch() ;
        Id batchProcessId = Database.executeBatch(batch, 1);
    }
}