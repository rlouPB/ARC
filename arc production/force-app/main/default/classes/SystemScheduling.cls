public class SystemScheduling {
	public static String scheduledItemDefQueryString = 'SELECT sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ' + 'ScheduledItemProcessor_Parameters__c, MasterLabel ' + 'FROM Scheduled_Item_Definition__mdt';
	public static String scheduledItemRunQueryString = 'SELECT Next_Run_Datetime__c, Retry_Count__c, Retry_Detail__c, ' + 'Scheduled_Item_Def__c, Scheduled_Item_Def_Status__c ' + 'FROM Scheduled_Item_Run__c';

	public SystemScheduling() {
	}

	public static List<Scheduled_Item_Run__c> queryScheduledItemRuns() {
		Set<Id> badSet = null; //null set will include all defs
		return queryScheduledItemRuns(badSet);
	}
	public static List<Scheduled_Item_Run__c> queryScheduledItemRuns(Set<Id> scheduledDefIds) {
		String filteredQueryString = scheduledItemRunQueryString;
		if (scheduledDefIds != null) {
			List<String> quotedStringList = new List<String>();
			for (String s : scheduledDefIds) {
				quotedStringList.add('\'' + s.trim() + '\'');
			}
			String scheduledDefIdsString = '(' + String.join(quotedStringList, ', ') + ')';
			filteredQueryString += ' WHERE Scheduled_Item_Def__c IN ' + scheduledDefIdsString;
		}
		List<Scheduled_Item_Run__c> results = Database.query(scheduledItemRunQueryString);

		return results;
	}

	public static List<Scheduled_Item_Definition__mdt> queryScheduledItemDefs() {
		List<Scheduled_Item_Definition__mdt> results = Database.query(scheduledItemDefQueryString);
		return results;
	}

	public static void runScheduledItemDefs(List<Scheduled_Item_Definition__mdt> scheduledItemDefs) {
		//separate scheduledItemDefsinto lists based on which SystemScheduling.ScheduledItemProcessor to use
		Map<String, List<Scheduled_Item_Definition__mdt>> scheduledDefsByProcesseor = new Map<String, List<Scheduled_Item_Definition__mdt>>();
		for (Scheduled_Item_Definition__mdt currentDef : scheduledItemDefs) {
			List<Scheduled_Item_Definition__mdt> thisProcessorDefs = scheduledDefsByProcesseor.get(currentDef.ScheduledItemProcessor_to_Use__c);
			if (thisProcessorDefs == null) {
				thisProcessorDefs = new List<Scheduled_Item_Definition__mdt>();
			}
			thisProcessorDefs.add(currentDef);
			scheduledDefsByProcesseor.put(currentDef.ScheduledItemProcessor_to_Use__c, thisProcessorDefs);
		}

		for (String processorToUse : scheduledDefsByProcesseor.keySet()) {
			String SIPName = processorToUse;

			Type sip = Type.forName('SIP_' + SIPName);

			if (sip == null) {
				ProcessLogging.addProcessLog('SystemScheduling', 'sip', 'SIP instance class does not exist for ProcessorToUse: ' + SIPName);
			} else {
				if (sip.newInstance() instanceof SystemScheduling.ScheduledItemProcessor) {
					SystemScheduling.ScheduledItemProcessor thisSIP = (SystemScheduling.ScheduledItemProcessor) sip.newInstance();
					thisSIP.process(scheduledDefsByProcesseor.get(processorToUse));
				}
			}
		}

		ProcessLogging.commitProcessLogs();
	}

	public interface ScheduledItemProcessor {
		void process(List<Scheduled_Item_Definition__mdt> scheduledItemDefs);
	}
}