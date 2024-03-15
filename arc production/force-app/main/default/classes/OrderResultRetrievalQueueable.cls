public with sharing class OrderResultRetrievalQueueable implements Queueable, Database.AllowsCallouts {
	public OrderResultRetrievalQueueable() {
	}
	public void execute(QueueableContext context) {
		boolean hasMoreMessage = ProcedureOrderHL7Processor.retrieveOrderResult();
		if (hasMoreMessage) {
			System.enqueueJob(new OrderResultRetrievalQueueable());
		}
	}
}