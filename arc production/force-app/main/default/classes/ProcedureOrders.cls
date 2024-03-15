public class ProcedureOrders {
	/*
        Utility class to support all types of Procedure Orders with related processes

        Notes:
                Procedure Results and other objects are build in the method buildProcResults()
    */

	//Ids passed to class constructor
	public Set<Id> procOrderIds;

	//queried filtered list of object records with Active and !Executed
	public List<Procedure_Order__c> procOrdersToExecute;
	public Map<Id, ProcOrderWrapper> procOrderWrapperMap = new Map<Id, ProcOrderWrapper>();

	//running lists of related Objects to upsert based on Procedure Orders
	Map<String, List<sObject>> sObjectTypeToUpsertListMap = new Map<String, List<sObject>>{ 'Procedure_Result__c' => new List<sObject>(), 'Nursing_Shift_Item__c' => new List<sObject>(), 'Physical_Monitor__c' => new List<sObject>(), 'disco__Form__c' => new List<sObject>() };

	//Protect against recursion
	public static Boolean isExecutingProcedureOrders = false;

	//lazy populated from queryAvailableNursingShifts()
	static List<Nursing_Shift__c> availableNursingShifts = new List<Nursing_Shift__c>();
	static Map<String, Nursing_Shift__c> shiftIndexToNursingShift {
		get {
			if (shiftIndexToNursingShift == null) {
				shiftIndexToNursingShift = queryAvailableNursingShifts();
			}
			return shiftIndexToNursingShift;
		}
		private set;
	}

	List<String> extraProcOrderFieldsToQuery = new List<String>{ 'Admission__r.Patient_Account__c', 'Recordtype.Name', 'Admission__r.Patient_Contact__c' };

	//Nursing Procedure Settings

	static Integer defaultNursingDueDateInterval = 7; //If not repeating, use this interval for due date
	//static String defaultNursingShiftNumber = '1st';
	static List<String> shiftNumbersByPriority = new List<String>{ '2nd', '3rd' }; //try for each date in order

	@testVisible //used when building Physical Monitors based on Nursing Procedure Order
	static Map<String, String> physicalMonitorViewFieldMap = new Map<String, String>{ 'Blood Glucose' => 'View_Blood_Glucose_Info__c', 'Blood Pressure' => 'View_Blood_Pressure_Info__c', 'Orthostatic Vital Signs' => 'View_Orthostatic_Blood_Pressure_Info__c', 'Height/Weight' => 'View_Height_Weight__c', 'Temperature' => 'View_Temperature_Info__c' };

	//Constructor
	public ProcedureOrders(Set<Id> procOrderIds) {
		this.procOrderIds = procOrderIds;

		//Find any of these procedure orders that need executed
		queryProcedureOrders();
	}

	//query for any Procedure Orders in the Ids that need to be executed
	public void queryProcedureOrders() {
		//Use FOR UPDATE to avoid race condition and possible double-creation of records
		String queryString = QueryUtils.getQueryAll('Procedure_Order__c', extraProcOrderFieldsToQuery);
		queryString += ' WHERE Active__c = TRUE' + ' AND Executed__c = FALSE' + ' AND Id IN :procOrderIds' + ' FOR UPDATE';

		procOrdersToExecute = database.query(queryString);
		for (Procedure_Order__c procOrder : procOrdersToExecute) {
			ProcOrderWrapper wrapper = new ProcOrderWrapper(procOrder);
			wrapper.buildProcResults(); //Build Result and related records
			procOrderWrapperMap.put(procOrder.Id, wrapper);
		}
	}

	static Map<String, Nursing_Shift__c> queryAvailableNursingShifts() {
		String queryString = QueryUtils.getQueryAll('Nursing_Shift__c', new List<String>());
		queryString += ' WHERE Status__c != \'Closed\'' + ' ORDER BY Date__c ASC';

		availableNursingShifts = (List<Nursing_Shift__c>) Database.query(queryString);

		Map<String, Nursing_Shift__c> returnMap = new Map<String, Nursing_Shift__c>();
		for (Nursing_Shift__c shift : availableNursingShifts) {
			returnMap.put(shift.Shift__c, shift);
		}
		return returnMap;
	}

	//perform DML on Procedure Order and all result-related records
	public void commitRecords() {
		if (!procOrdersToExecute.isEmpty()) {
			//Procedure Order Executed Checkbox

			update procOrdersToExecute;

			//related records
			for (ProcOrderWrapper wrapper : procOrderWrapperMap.values()) {
				sObjectTypeToUpsertListMap.get('Procedure_Result__c').addAll(wrapper.procResults);
				sObjectTypeToUpsertListMap.get('Nursing_Shift_Item__c').addAll(wrapper.shiftItems);
				sObjectTypeToUpsertListMap.get('Physical_Monitor__c').addAll(wrapper.physMonitors);
				sObjectTypeToUpsertListMap.get('disco__Form__c').addAll(wrapper.forms);
			}

			for (String key : sObjectTypeToUpsertListMap.keySet()) {
				//modified by roy lou -- prevent exception if sObjectTypeToUpsertListMap.get(key) is null
				//BTW, the DML should not be inside any loop
				List<sObject> upsertList = new List<sObject>();
				for (sObject obj : sObjectTypeToUpsertListMap.get(key)) {
					if (obj != null) {
						upsertList.add(obj);
					}
				}

				upsert upsertList;
			}

			//connect related records to each other
			for (ProcOrderWrapper wrapper : procOrderWrapperMap.values()) {
				for (ResultInstance instance : wrapper.resultInstances) {
					instance.connectRecords();
				}
			}
			for (String key : sObjectTypeToUpsertListMap.keySet()) {
				//modified by roy lou -- prevent exception if sObjectTypeToUpsertListMap.get(key) is null
				List<sObject> upsertList = new List<sObject>();
				for (sObject obj : sObjectTypeToUpsertListMap.get(key)) {
					if (obj != null) {
						upsertList.add(obj);
					}
				}
				upsert upsertList;
			}
			update procOrdersToExecute;

			List<String> orderIds = new List<String>();
			Map<String, Lab_Observation__c> updateLabObservations = new Map<String, Lab_Observation__c>();
			for (Procedure_Order__c order : procOrdersToExecute) {
				if (order.Recordtype.Name == 'Lab Order') {
					orderIds.add(order.Id);
				}
			}

			List<Procedure_Order__c> orders = [SELECT Id, (SELECT Id FROM Lab_Observations__r), (SELECT Id FROM Procedure_Results__r) FROM Procedure_Order__c WHERE Id IN :orderIds];
			for (Procedure_Order__c order : orders) {
				for (Procedure_Result__c pr : order.Procedure_Results__r) {
					for (Lab_Observation__c lab : order.Lab_Observations__r) {
						updateLabObservations.put(lab.Id, new Lab_Observation__c(Id = lab.Id, Procedure_Result__c = pr.Id));
					}
				}
			}
			if (updateLabObservations.values().size() > 0) {
				update updateLabObservations.values();
			}
		}
	}

	//STATIC METHODS

	//called by trigger in BEFORE UPDATE: populate completed and finalized names
	public static void populateProcedureOrderBeforeData(Map<Id, sObject> newMap, Map<Id, sObject> oldMap) {
		//Collect changes to Completed by or Finalized By lookup fields
		Set<Id> posNeedCompletedBy = new Set<Id>();
		Set<Id> posNeedFinalizedBy = new Set<Id>();
		Set<Id> neededUserIds = new Set<Id>();

		for (sObject so : newMap.values()) {
			//default message control Id
			if (so.get('BHS_Message_Control_Id__c') == null) {
				so.put('BHS_Message_Control_Id__c', so.Id);
			}

			//clear out repeating detail fields if checkbox is cleared
			if ((Boolean) so.get('Repeating__c') == false) {
				so.put('Repeating_Frequency__c', null);
				so.put('End_Date__c', null);
			}

			//clear out Physical Monitor Section field if it's not in Related Records
			String relatedRecords = String.valueOf(so.get('Related_Records__c'));
			if (String.isBlank(relatedRecords) || !relatedRecords.contains('Physical Monitor')) {
				so.put('Physical_Monitor_Sections__c', null);
			}

			//Compare old and new field values
			sObject oldSo = oldMap.get(so.Id);
			if (oldSo.get('Completed_By__c') != so.get('Completed_By__c')) {
				so.put('Completed_By_Name__c', null);
				posNeedCompletedBy.add(so.Id);
				neededUserIds.add((Id) so.get('Completed_By__c'));
			}
			if (oldSo.get('Finalized_By_User__c') != so.get('Finalized_By_User__c')) {
				so.put('Finalized_By__c', null);

				posNeedFinalizedBy.add(so.Id);
				neededUserIds.add((Id) so.get('Finalized_By_User__c'));
			}
		}

		//get Users needed to populate text Name field on PO
		String userQueryString = QueryUtils.getQueryAll('User', new List<String>()) + ' WHERE Id IN :neededUserIds';
		Map<Id, User> queriedUsersMap = new Map<Id, User>((List<User>) Database.query(userQueryString));

		//populate text fields with Professional Name from queried users
		for (Id poId : posNeedCompletedBy) {
			sObject so = newMap.get(poId);
			if (so.get('Completed_By__c') == null)
				continue;

			User theUser = queriedUsersMap.get((Id) so.get('Completed_By__c'));
			so.put('Completed_By_Name__c', theUser.Professional_Name__c);
		}
		for (Id poId : posNeedFinalizedBy) {
			sObject so = newMap.get(poId);
			if (so.get('Finalized_By_User__c') == null)
				continue;

			User theUser = queriedUsersMap.get((Id) so.get('Finalized_By_User__c'));
			so.put('Finalized_By__c', theUser.Professional_Name__c);
		}
	}

	//Called by trigger on Procedure_Order__c, filters Idssends to future or now methods
	public static void executeProcedureOrders(List<sObject> triggerNew) {
		if (ProcedureOrders.isExecutingProcedureOrders)
			return;

		Set<Id> procOrderIdsToExecute = new Set<Id>();
		for (sObject so : triggerNew) {
			if ((Boolean) so.get('Active__c') && !(Boolean) so.get('Executed__c')) {
				procOrderIdsToExecute.add(so.Id);
			}
		}

		if (System.isFuture() || System.isBatch()) {
			executeProcedureOrdersNow(procOrderIdsToExecute);
		} else {
			if (!procOrderIdsToExecute.isEmpty())
				executeProcedureOrdersFuture(procOrderIdsToExecute);
		}
	}
	@future
	@testVisible
	static void executeProcedureOrdersFuture(Set<Id> procOrderIds) {
		executeProcedureOrdersNow(procOrderIds);
	}
	@testVisible
	static void executeProcedureOrdersNow(Set<Id> procOrderIds) {
		ProcedureOrders.isExecutingProcedureOrders = true;
		Savepoint sp = Database.setSavepoint();
		try {
			ProcedureOrders procOrders = new ProcedureOrders(procOrderIds);
			procOrders.commitRecords();
		} catch (Exception ex) {
			Database.rollBack(sp);
			ProcessLogging.quickProcessLog('executeProcedureOrders', ex.getStackTraceString(), ex.getMessage());
		}
		ProcedureOrders.isExecutingProcedureOrders = false;
	}

	public static String buildShiftIndex(Date dt, String shiftNumber) {
		String shiftIndex = String.valueOf(dt.month()) + '/' + String.valueOf(dt.day()) + '/' + String.valueOf(dt.year()) + ' - ' + shiftNumber;
		return shiftIndex;
	}

	//wrapper for 1 Procedure Order that will be executed
	public class ProcOrderWrapper {
		public Procedure_Order__c procOrder;

		//1 or more Procedure Result records and related sObject records for this Procedure Order
		public List<ResultInstance> resultInstances = new List<ResultInstance>();

		//collected lists of new records to upsert bulkified
		public List<Procedure_Result__c> procResults = new List<Procedure_Result__c>();
		public List<Nursing_Shift_Item__c> shiftItems = new List<Nursing_Shift_Item__c>();
		public List<Physical_Monitor__c> physMonitors = new List<Physical_Monitor__c>();
		public List<disco__Form__c> forms = new List<disco__Form__c>();
		// Physical_Monitor__c defaultPhysMonitorTemplate;

		public ProcOrderWrapper(Procedure_Order__c po) {
			this.procOrder = po;
		}

		//Build Procedure Result record(s) along with other object records related to result instances
		public void buildProcResults() {
			procOrder.Executed__c = true;

			if (procOrder.Repeating__c == false) {
				addResultInstance(procOrder.Activation_Date__c, procOrder.Activation_Date__c.addDays(defaultNursingDueDateInterval));
			} else {
				Integer repeatingMultiple = 1;
				String repeatingPeriod = 'day';
				if (procOrder.Repeating_Frequency__c.contains('Week')) {
					repeatingPeriod = 'week';
					if (procOrder.Repeating_Frequency__c.contains('Per Two Weeks')) {
						repeatingMultiple = 2;
					}
				} else if (procOrder.Repeating_Frequency__c.contains('Month')) {
					repeatingPeriod = 'month';
					if (
						procOrder.Repeating_Frequency__c.startsWith('Every') //e.g. 'Every 3 Months'
					) {
						List<String> parts = procOrder.Repeating_Frequency__c.split(' ');
						repeatingMultiple = Integer.valueOf(parts[1]);
					}
				}
				//default to end date on proc order, may be different depending on actual frequency
				Date lastResultDate = procOrder.End_Date__c;

				if (repeatingPeriod == 'day') {
					Date resultDate = procOrder.Activation_Date__c;

					while (resultDate <= lastResultDate) {
						addResultInstance(resultDate, resultDate.addDays(1));
						resultDate = resultDate.addDays(1 * repeatingMultiple);
					}
				} else if (repeatingPeriod == 'week') {
					//1 Time per Week: Shift Item for Monday, Due Date Friday
					//2 Times per Week: Monday Due Wednesday, Thursday Due Saturday
					//3 Times per Week: Monday Due Tuesday, Wednesday Due Thursday, Friday Due Saturday
					//1 Time per Two Weeks: Monday first week Due Monday second week
					//First resultDate is the Monday of the week following Activation Date, unless Activation Date is a Monday
					//Last Result Date is the Monday of the week that End Date falls in; actual last result date will be <= to this

					Date startActivationPeriod = procOrder.Activation_Date__c.toStartOfWeek().addDays(1);
					Date resultDate = startActivationPeriod.addDays(7);
					if (startActivationPeriod == procOrder.Activation_Date__c) {
						resultDate = startActivationPeriod;
					}

					Date startLastPeriod = procOrder.End_Date__c.toStartOfWeek();
					lastResultDate = startLastPeriod;

					while (resultDate <= lastResultDate) {
						if (procOrder.Repeating_Frequency__c == '1 Time Per Week') {
							addResultInstance(resultDate, resultDate.addDays(4));
						} else if (procOrder.Repeating_Frequency__c == '2 Times Per Week') {
							addResultInstance(resultDate, resultDate.addDays(2));
							addResultInstance(resultDate.addDays(3), resultDate.addDays(5));
						} else if (procOrder.Repeating_Frequency__c == '3 Times Per Week') {
							addResultInstance(resultDate, resultDate.addDays(1));
							addResultInstance(resultDate.addDays(2), resultDate.addDays(3));
							addResultInstance(resultDate.addDays(4), resultDate.addDays(5));
						} else if (procOrder.Repeating_Frequency__c == '1 Time Per Two Weeks') {
							addResultInstance(resultDate, resultDate.addDays(7));
						}
						resultDate = resultDate.addDays(7 * repeatingMultiple);
					}
				} else if (repeatingPeriod == 'month') {
					//1 Time Per Month: First of month due 15th
					//Every 3 Months: First of first month due 15th of second month
					//Every 4 Months: First of first month due 1st of third month
					//Every 6 Months: First of first month due 1st of 4th month
					//Starts on the 1st of the month following Activation Date, unless Activation Date is the 1st
					//Last resultDate is the 1st of the month that End Date falls in; actual last result Date will be <= to this

					Date startActivationPeriod = procOrder.Activation_Date__c.toStartOfMonth();
					Date resultDate = startActivationPeriod.addMonths(1);
					if (startActivationPeriod == procOrder.Activation_Date__c) {
						resultDate = startActivationPeriod;
					}

					Date startLastPeriod = procOrder.End_Date__c.toStartOfMonth();
					lastResultDate = startLastPeriod;
					while (resultDate <= lastResultDate) {
						if (procOrder.Repeating_Frequency__c == '1 Time Per Month') {
							addResultInstance(resultDate, resultDate.addDays(14));
						} else if (procOrder.Repeating_Frequency__c == 'Every 3 Months') {
							addResultInstance(resultDate, resultDate.addMonths(1).addDays(14));
						} else if (procOrder.Repeating_Frequency__c == 'Every 4 Months') {
							addResultInstance(resultDate, resultDate.addMonths(2));
						} else if (procOrder.Repeating_Frequency__c == 'Every 6 Months') {
							addResultInstance(resultDate, resultDate.addMonths(3));
						}
						resultDate = resultDate.addMonths(repeatingMultiple);
					}
				}
			}
		} //end buildProcResults

		//add resultinstance and all new records to appropriate lists
		//void addResultInstance(Date resultDate, Date dueDate, String nursingShiftNumber)
		void addResultInstance(Date resultDate, Date dueDate) {
			//ResultInstance resultWrapper = new ResultInstance(procOrder, resultDate, dueDate, nursingShiftNumber);
			ResultInstance resultWrapper = new ResultInstance(procOrder, resultDate, dueDate);
			resultInstances.add(resultWrapper);

			procResults.add(resultWrapper.procResult);
			shiftItems.add(resultWrapper.shiftItem);
			if (resultWrapper.physMonitor != null) {
				physMonitors.add(resultWrapper.physMonitor);
			} else if (resultWrapper.form != null) {
				forms.add(resultWrapper.form);
			}
		}
	}

	//Contains everything involved with a single Procedure Result along with related records and information
	class ResultInstance {
		Procedure_Order__c procOrder;

		Date resultDate;
		Date dueDate;
		// String nursingShiftNumber;

		public Procedure_Result__c procResult;
		public Nursing_Shift_Item__c shiftItem;
		public Physical_Monitor__c physMonitor;
		public disco__Form__c form;

		//public ResultInstance(Procedure_Order__c po, Date resultDate, Date dueDate, String nursingShiftNumber)
		public ResultInstance(Procedure_Order__c po, Date resultDate, Date dueDate) {
			this.procOrder = po;
			this.resultDate = resultDate;
			this.dueDate = dueDate;
			// this.nursingShiftNumber = nursingShiftNumber;

			buildRecords();
		}

		public void buildRecords() {
			//Procedure Result
			procResult = new Procedure_Result__c(Status__c = 'Pending', Procedure_Order__c = procOrder.Id, Date__c = resultDate);

			if (procOrder.Recordtype.Name == 'Nursing Procedure') {
				//Shift Item
				shiftItem = new Nursing_Shift_Item__c(
					Procedure_Order__c = procOrder.Id,
					Patient__c = procOrder.Admission__r.Patient_Account__c,
					Shift_Date__c = resultDate,
					Due_Date__c = dueDate,
					//Shift_Number__c = nursingShiftNumber, //JN removed 220809: shift number will be determined later
					Status__c = 'Open',
					//Item_Name_from_Patient__c =  'Med Office Order',
					Item_Name__c = 'Med Office Order',
					Subject__c = procOrder.Procedure__c,
					Additional_Information__c = procOrder.MD_Comments__c
				);

				if (procOrder.Related_Records__c != null) {
					//Physical Monitor
					if (procOrder.Related_Records__c.contains('Physical Monitor')) {
						physMonitor = new Physical_Monitor__c(Account__c = procOrder.Admission__r.Patient_Account__c, RecordTypeId = RecordTypeHelper.getIdByName('Physical_Monitor__c', 'Draft'), Procedure_Order__c = procOrder.Id);
						//TODO: Carry Cuff Size and some other fields over from previous Phys Mons by querying?
						physMonitor.BP_Cuff_Size__c = 'Regular';

						//gatekeeper checkbox fields on phys mon
						if (procOrder.Physical_Monitor_Sections__c != null) {
							List<String> selectedPhysMonSections = procOrder.Physical_Monitor_Sections__c.split(';');
							for (String pmSection : selectedPhysMonSections) {
								String fieldName = ProcedureOrders.physicalMonitorViewFieldMap.get(pmSection);
								physMonitor.put(fieldName, true);
							}
						}

						//Form
					} else if (procOrder.Related_Records__c.contains('Assessment') && procOrder.Form_Template__c != null) {
						form = new disco__Form__c(disco__Form_Account__c = procOrder.Admission__r.Patient_Account__c, disco__Form_Template__c = procOrder.Form_Template__c, Admission__c = procOrder.Admission__c, disco__Form_Contact__c = procOrder.Admission__r.Patient_Contact__c);
					}
				}
			}
		}

		//Populate lookup fields. (run this after the records have been inserted)
		void connectRecords() {
			if (procOrder.Recordtype.Name == 'Nursing Procedure') {
				procResult.Nursing_Shift_Item__c = shiftItem.Id;
				shiftItem.Procedure_Result__c = procResult.Id;
				shiftItem.Shift_Number__c = shiftNumbersByPriority[0];
				for (String shiftNumber : shiftNumbersByPriority) {
					String shiftIndex = ProcedureOrders.buildShiftIndex(shiftItem.Shift_Date__c, shiftNumber);
					if (ProcedureOrders.shiftIndexToNursingShift.containsKey(shiftIndex)) {
						shiftItem.Shift_Number__c = shiftNumber;
						shiftItem.Nursing_Shift__c = ProcedureOrders.shiftIndexToNursingShift.get(shiftIndex).Id;
						break;
					}
				}

				if (form != null) {
					shiftItem.Form__c = form.Id;
					procOrder.Form__c = form.Id;
					procResult.Form__c = form.Id;
				}

				if (physMonitor != null && procOrder.Physical_Monitor_Sections__c != null) {
					shiftItem.Physical_Monitor__c = physMonitor.Id;
					procResult.Physical_Monitor__c = physMonitor.Id;
					physMonitor.Nursing_Shift_Item__c = shiftItem.Id;
				}
			}
		}
	}
}