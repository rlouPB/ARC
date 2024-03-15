public class AlertsFilter {
	/*
        Utility class to handle automatic creation of Alert-type Messages based on triggers or flows
    */

	public static List<SentAlert__e> alertsToBePublished = new List<SentAlert__e>();

	//called from time-dependent Process Builder on Credential object
	@InvocableMethod(label='Filter Alerts' description='Filters alerts for credentials')
	public static void processAlerts(List<Id> recordIds) {
		List<SentAlert__e> alertsToPublish = new List<SentAlert__e>();
		List<Credential__c> records = [SELECT Id, User__c FROM Credential__c WHERE Id IN :recordIds];

		for (Credential__c record : records) {
			execute(null, record, alertsToPublish, 'Credential__c', 'Insert');
		}

		EventBus.publish(alertsToPublish);
	}

	private static String triggerObject { get; set; }
	/**
	* @description Alert Scenario Custom Metadata on Context Object
        //query on lazy load
	*/
	public static Map<String, List<Alert_Scenario__mdt>> alertScenariosMap {
		get {
			if (alertScenariosMap == null) {
				alertScenariosMap = queryScenarios();
			}
			return alertScenariosMap;
		}
		private set {
		}
	}
	private static Map<String, List<Alert_Scenario__mdt>> queryScenarios() {
		Map<String, List<Alert_Scenario__mdt>> returnMap = new Map<String, List<Alert_Scenario__mdt>>();

		List<Alert_Scenario__mdt> scenarios = [SELECT Id, Patient_Field__c, Object__c, When__c, Alert_Subject__c, Alert_Body__c, Group__c, (SELECT Id, Field_Name__c, Field_Value__c, Operator__c, Alert_Scenario__c FROM Alert_Scenario_Details__r) FROM Alert_Scenario__mdt ORDER BY Object__c];
		for (Alert_Scenario__mdt scenario : scenarios) {
			List<Alert_Scenario__mdt> objectScenarios = returnMap.get(scenario.Object__c);
			if (objectScenarios == null)
				objectScenarios = new List<Alert_Scenario__mdt>();
			objectScenarios.add(scenario);
			returnMap.put(scenario.Object__c, objectScenarios);
		}
		return returnMap;
	}

	// public static void execute(sObject oldRecord, sObject record)
	// {
	//     String triggerObject = String.valueOf((Trigger.new != null) ? Trigger.new.getSObjectType() : Trigger.old.getSObjectType());
	//     String triggerType = '';
	//     if (System.TriggerOperation != null)
	//     {
	//         triggerType = System.TriggerOperation.name()split('_')[1].toLowerCase();
	//     }
	// }

	//called from after trigger on watched objects
	public static void execute(sObject oldRecord, sObject record, List<SentAlert__e> alertsToPublish, String triggerObject, String triggerType) {
		AlertsFilter.triggerObject = triggerObject;

		if (alertScenariosMap.size() == 0)
			return;

		if (alertScenariosMap.get(triggerObject) == null)
			return;

		List<Alert_Scenario__mdt> scenarios = alertScenariosMap.get(triggerObject);

		for (Alert_Scenario__mdt scenario : scenarios) {
			//skip scenario if should not run in this trigger context
			//if((scenario.When__c != triggerType && !scenario.When__c.contains(triggerType))) continue;
			if (!scenario.When__c.contains(triggerType))
				continue;

			Boolean addAlert = true;

			for (Alert_Scenario_Detail__mdt detail : scenario.Alert_Scenario_Details__r) {
				Object recordValue = record.get(detail.Field_Name__c);

				if (oldRecord != null) {
					Object oldValue = oldRecord.get(detail.Field_Name__c);
					if (oldValue == recordValue)
						return;
				}

				String operator = detail.Operator__c;
				Object detailCompareValue = detail.Field_Value__c;

				if (!valuesMatch(recordValue, operator, detailCompareValue)) {
					addAlert = false;
				}
			}

			if (addAlert) {
				SentAlert__e sentAlert = new SentAlert__e(AlertScenarioId__c = scenario.Id, RecordId__c = record.Id);

				if (scenario.Patient_Field__c != null) {
					sentAlert.Contact__c = (String) record.get(scenario.Patient_Field__c);
				}

				alertsToPublish.add(sentAlert);
			}
		}
	}

	public static Boolean valuesMatch(Object recordValue, String operator, Object compareValue) {
		String equals = '==';
		String notEqual = '<>';
		String greaterThan = '>';
		String greaterThanEqual = '>=';
		String lessThan = '<';
		String lessThanEqual = '<=';
		String isBlank = 'ISBLANK';
		// String isTrue = 'ISTRUE';
		// String isFalse = 'ISFALSE';

		if (operator == equals) {
			return compareValue == recordValue;
		}
		if (operator == notEqual) {
			return compareValue != recordValue;
		}
		if (operator == greaterThan) {
			return (Decimal) compareValue > (Decimal) recordValue;
		}
		if (operator == greaterThanEqual) {
			return (Decimal) compareValue >= (Decimal) recordValue;
		}
		if (operator == lessThan) {
			return (Decimal) compareValue < (Decimal) recordValue;
		}
		if (operator == lessThanEqual) {
			return (Decimal) compareValue < (Decimal) recordValue;
		}
		if (operator == isBlank) {
			return recordValue == null || recordValue == '';
		}
		//TODO uncomment if we get scenarios like this
		// if(operator == isTrue) {
		//     return recordValue == null || recordValue == '';
		// }
		// if(operator == isFalse) {
		//     return recordValue == null || recordValue == '';
		// }

		return false;
	}
}