public with sharing class CancelPendingProcedureOrders {
	@AuraEnabled(cacheable=true)
	public static List<Procedure_Result__c> getPendingOrders(String orderId) {
		List<Procedure_Result__c> prs = [SELECT Id, Date__c, Due_Date__c, Procedure_Type__c FROM Procedure_Result__c WHERE Procedure_Order__c = :orderId AND Status__c = 'Pending'];
		return prs;
	}
	@AuraEnabled
	public static Integer cancelOrders(String procedureResults) {
		Integer count = 0;
		List<Procedure_Result__c> procedureResultList = (List<Procedure_Result__c>) JSON.deserialize(procedureResults, List<Procedure_Result__c>.class);
		List<Procedure_Result__c> prs = new List<Procedure_Result__c>();
		for (Procedure_Result__c pr : procedureResultList) {
			prs.add(new Procedure_Result__c(Id = pr.Id, Status__c = 'Cancelled', Cancelled_Reason__c = 'Manual Cancellation', Cancelled_By__c = userinfo.getUserId(), Cancelled_Date_Time__c = Datetime.now()));
		}
		if (prs.size() > 0) {
			update prs;
			count = prs.size();
		}

		return count;
	}
}