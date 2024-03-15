trigger Admitted_Program_StatusTrigger on Admitted_Program_Status__c(after update, after insert) {
	private static final String ADMITTED_PAS_STATUS = 'Program Assessment Status (PAS)';

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			Admitted_ProgramStatusTriggerHandler.createNursingShiftItemsAndForms(Trigger.new);
		}
		if (Trigger.isUpdate) {
			List<Admitted_Program_Status__c> ListOfRecordsToDeleteStuff = new List<Admitted_Program_Status__c>();
			List<Admitted_Program_Status__c> ListOfRecordsToCreateStuff = new List<Admitted_Program_Status__c>();
			for (Admitted_Program_Status__c aps : Trigger.new) {
				if (String.isNotBlank(aps.Status__c) && aps.End_Date_Time__c != null && Trigger.oldMap.get(aps.Id).End_Date_Time__c != null && aps.Status__c == ADMITTED_PAS_STATUS) {
					if (aps.End_Date_Time__c.Date() < Trigger.oldMap.get(aps.Id).End_Date_Time__c.Date()) {
						ListOfRecordsToDeleteStuff.add(aps);
					} else if (aps.End_Date_Time__c.Date() > Trigger.oldMap.get(aps.Id).End_Date_Time__c.Date()) {
						ListOfRecordsToCreateStuff.add(aps);
					}
				}
			}

			if (!ListOfRecordsToDeleteStuff.isEmpty()) {
				Admitted_ProgramStatusTriggerHandler.deleteNursingShiftItemsAndForms(ListOfRecordsToDeleteStuff, Trigger.oldMap);
			}
			if (!ListOfRecordsToCreateStuff.isEmpty()) {
				Admitted_ProgramStatusTriggerHandler.createNursingShiftItemsAndForms(ListOfRecordsToCreateStuff);
			}
		}
	}
}