public with sharing class SIP_OrderResultRetrieval implements SystemScheduling.ScheduledItemProcessor {
	public static void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		try {
			System.debug(scheduledItemDefs[0]); // to trigger catch block in test class
			System.enqueueJob(new OrderResultRetrievalQueueable());
		} catch (Exception ex) {
			ProcessLogging.addProcessLog('SystemScheduling', ex.getStackTraceString(), ex.getMessage());
		}
	}
}