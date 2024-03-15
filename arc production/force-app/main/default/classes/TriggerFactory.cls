/*
 * @author ben.efigenio@synapticap.com
 * @date 08/19/2019
 *
 * @group TriggerFactory
 *
 * @description Used to instantiate and execute Trigger Handlers associated with sObjects.
 */
public class TriggerFactory {
	/*******************************************************************************************************
	 * @description List of soTypes to prevent running Handlers during Testing
	 */
	public static Set<Schema.sObjectType> Exclusions = new Set<Schema.sObjectType>();

	/*******************************************************************************************************
	 * @description Map to make sure each trigger handler only runs once
	 */
	@TestVisible
	public static Map<Schema.sObjectType, Integer> Recursions = new Map<Schema.sObjectType, Integer>();

	/*******************************************************************************************************
	 * @description Map of soTypes against their triggerHandler to prevent exception from the getHandler() becuase of longer names
	 */
	public static Map<Schema.sObjectType, ITrigger> LongNameSObject = new Map<Schema.sObjectType, ITrigger>{
		Nursing_Shift_Patient_Assignment__c.sObjectType => (ITrigger) Type.forName('N_S_Patient_AssignmentTriggerHandler').newInstance(),
		Medication_Administration_Record__c.sObjectType => (ITrigger) Type.forName('Medication_Admin_RecordTriggerHandler').newInstance(),
		Medication_Administration_Line__c.sObjectType => (ITrigger) Type.forName('Medication_Admin_LineTriggerHandler').newInstance(),
		Printed_Medical_Included_Record__c.sObjectType => (ITrigger) Type.forName('PrintedMedicalIncludedTriggerHandler').newInstance()
		// Patient_Note__c.sObjectType => (ITrigger) Type.forName('Patient_NoteTriggerHandler').newInstance()
	};

	/*******************************************************************************************************
	 * @description Create and execute a trigger handler
	 * @param soType SObject Type
	 * @example
	 * TriggerFactory.createHandler(soType);
	 */
	public static void createHandler(Schema.sObjectType soType) {
		ITrigger handler = getHandler(soType);

		// Allow exlcusion of Triggers from running during Unit Tests
		if (Test.isRunningTest() && Exclusions.contains(soType)) {
			// System.debug('[TF - ' + soType + '] - : Not Executing (Excluded)...');
		} else if (isFirstRun(soTYpe)) {
			execute(handler, soType);
		} else {
			// System.debug('[TF - ' + soType + '] - : Not Executing (Recursive call)...');
		}
	}

	/*******************************************************************************************************
	 * @description Control the execution of the handler
	 * @param handler A Trigger Handler to execute
	 * @param soType Object type to process
	 * @example
	 * TriggerFactory.execute(handler, soType);
	 */
	private static void execute(ITrigger handler, Schema.sObjectType soType) {
		// Before Trigger
		if (Trigger.isBefore) {
			// Call the bulk before to handle any caching of data and enable bulkification
			handler.bulkBefore();

			// Iterate through the records to be deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject so : Trigger.old) {
					handler.beforeDelete(so);
				}
			} else if (Trigger.isInsert) {
				// Iterate through the records to be inserted passing them to the handler.
				for (SObject so : Trigger.new) {
					handler.beforeInsert(so);
				}
			} else if (Trigger.isUpdate) {
				// Iterate through the records to be updated passing them to the handler.
				for (SObject so : Trigger.old) {
					handler.beforeUpdate(so, Trigger.newMap.get(so.Id));
				}
			}
		} else {
			// Call the bulk after to handle any caching of data and enable bulkification
			handler.bulkAfter();

			// Iterate through the records deleted passing them to the handler.
			if (Trigger.isDelete) {
				for (SObject so : Trigger.old) {
					handler.afterDelete(so);
				}
			} else if (Trigger.isInsert) {
				// Iterate through the records inserted passing them to the handler.
				for (SObject so : Trigger.new) {
					handler.afterInsert(so);
				}
			} else if (Trigger.isUpdate) {
				// Iterate through the records updated passing them to the handler.
				for (SObject so : Trigger.old) {
					handler.afterUpdate(so, Trigger.newMap.get(so.Id));
				}
			}
		}

		// Perform any post processing
		handler.andFinally();
	}

	/*******************************************************************************************************
	 * @description Get the appropriate handler for the object type.
	 * @param soType Object type to process
	 * @example
	 * TriggerFactory.getHandler(soType);
	 */
	private static ITrigger getHandler(Schema.sObjectType soType) {
		String objectName;
		String className;
		try {
			if (LongNameSObject.containsKey(soType)) {
				ITrigger handler = LongNameSObject.get(soType);
				return handler;
			}

			objectName = soType.getDescribe().getName();
			className = objectName.replaceAll('__c|__', '') + 'TriggerHandler';
			ITrigger itrig = (ITrigger) Type.forName(className).newInstance();
			return itrig;
		} catch (Exception e) {
			ProcessLogging.quickProcessLog('TriggerFactory', e.getStackTraceString(), 'No Trigger Handler registered for Object Type: ' + objectName + ' (' + className + ')');
			throw new TriggerException('No Trigger Handler registered for Object Type: ' + objectName + ' (' + className + ')');
		}
	}

	/*******************************************************************************************************
	 * @description Calculate whether the Trigger Handler for the soType has ran once before and after
	 * @param soType Object type to process
	 * @example
	 * TriggerFactory.isFirstRun(soType);
	 */
	private static Boolean isFirstRun(Schema.sObjectType soType) {
		Integer recCount = Recursions.containsKey(soType) ? Recursions.get(soType) : 0;

		recCount = recCount + 1;

		if (!'EGO__c'.equals(soType.getDescribe().getName())) {
			Recursions.put(soType, recCount);
		}

		return recCount < 3 ? true : false;
	}

	public class TriggerException extends Exception {
	}
}