public without sharing class ChangeAdmittedProgramController {
	private static final String ADMITTED_PROGRAM_PERMISSION = 'Change_Admitted_Program';
	public class ChangeAdmittedException extends Exception {
	}

	@AuraEnabled
	public static PatientAccount getAccountInfo(String accountId) {
		return new PatientAccount(accountId);
	}

	public class SaveParams {
		@AuraEnabled
		public string accountId; //Patient Account Id
		@AuraEnabled
		public string chosenFunction; //action to take (Change Program, New Status, Update Status)

		@AuraEnabled
		public datetime startDate; //new Current Admitted Program
		@AuraEnabled
		public datetime startDateTime; //new Admitted Program Status
		@AuraEnabled
		public datetime endDateTime; //update Admitted Program Status
		@AuraEnabled
		public string programId; //record Id of Program record that new Admitted Program looks up to
		@AuraEnabled
		public string programManagerId;

		@AuraEnabled
		public Admitted_Program__c newAdmittedProgram; //admittedProgram record being created
		@AuraEnabled
		public Admitted_Program_Status__c admittedProgramStatusRecord; //for create or update

		@AuraEnabled
		public string statusId; //record Id of Admitted Program Status to update
		@AuraEnabled
		public string status; //Status used to create new Admitted Program Status record
	}

	public static Account getAccount(id accId) {
		return [
			SELECT
				Id,
				Name,
				Current_Admission__c,
				Current_Admission__r.Current_Admitted_Program__c,
				Current_Admission__r.Current_Admitted_Program__r.Start_Date__c,
				Current_Admission__r.Current_Admitted_Program__r.End_Date__c,
				Current_Admission__r.Current_Admitted_Program__r.Program__c,
				Current_Admission__r.Current_Admitted_Program__r.Program__r.Name,
				Current_Admission__r.Current_Admitted_Program__r.Program__r.Short_Name__c,
				Current_Admission__r.Current_Admitted_Program__r.Program__r.Product_Code__c,
				Current_Admission__r.Current_Admitted_Program__r.Program_Manager__c,
				Current_Admission__r.Current_Admitted_Program__r.Days__c,
				Current_Admitted_Program_Name__c
			FROM Account
			WHERE Id = :accId
			LIMIT 1
		];
	}

	// Update End Date on current admitted Program to start of new program
	// Insert new Admitted_Program__c record with speced Start Date
	// Update account.Current_Admitted_Program__c lookup
	public static void changeProgram(Account acc, SaveParams params) {
		// if( string.isBlank(params?.programId) )
		// {
		// 	throw new ChangeAdmittedException('Please select a Program.');
		// }

		if (acc.Current_admission__c == null) {
			throw new ChangeAdmittedException('Current Admission does not exist. Please contact help desk.');
		}

		// String programManagerId = (!String.isBlank(params.programManagerId))
		// 				? params.programManagerId
		// 				: null;
		// Date startDate = Date.valueOf(params.startDate);

		// Admitted_Program__c ap = new Admitted_Program__c(
		// 	Admission__c = acc.Current_Admission__c,
		// 	Program__c = params.programId,
		// 	Start_date__c = startDate,
		// 	Program_Manager__c = programManagerId
		// );
		// insert ap;

		//new Admitted Program, populated in JS
		Admitted_Program__c ap = params.newAdmittedProgram;

		Program__c program = [SELECT Id, Product_Code__c FROM Program__c WHERE Id = :ap.Program__c];
		ap.Name = program.Product_Code__c;
		ap.Admission__c = acc.Current_Admission__c;
		ap.Account__c = acc.Id; //JN added 220721
		insert ap;

		//put End Date on previous Current Admitted Program
		if (acc.Current_Admission__r?.Current_Admitted_Program__c != null) {
			update new Admitted_Program__c(Id = acc.Current_Admission__r.Current_Admitted_Program__c, End_Date__c = params.newAdmittedProgram.Start_Date__c);
		}

		// if(ap == null || ap.Id == null){
		// 	throw new ChangeAdmittedException('Admitted Program not inserted currectly: ' + JSON.serialize(ap));
		// }

		Admission__c admission = new Admission__c(Id = acc.Current_admission__c, Current_Admitted_Program__c = ap.Id);
		update admission;

		// if(admission.Current_Admitted_Program__c == null){
		// 	throw new ChangeAdmittedException('Current Admitted Program not updated');
		// }
	}

	//Insert new Admitted Program status
	public static void newStatus(Account acc, SaveParams params) {
		//if( string.isBlank(params?.status) ){
		if (String.isBlank(params.admittedProgramStatusRecord.Status__c)) {
			throw new ChangeAdmittedException('There is no Status selected');
		}

		//if(acc?.Current_Admission__r?.Current_Admitted_Program__c == null ){
		if (String.isBlank(params?.admittedProgramStatusRecord.Admitted_Program__c)) {
			throw new ChangeAdmittedException('There is no admitted program specified.');
		}

		// Admitted_Program_Status__c aps = new Admitted_Program_Status__c(
		// 	Admitted_Program__c = acc.Current_Admission__r.Current_Admitted_Program__c,
		// 	Start_Date_Time__c = params.,
		// 	Status__c = params.status
		// );
		// Map<String, String> admittedProgramStatusMap = (Map<String, String>)params.admittedProgramStatusRecord;
		// Admitted_Program_Status__c admittedProgramStatusRecord = (Admitted_Program_Status__c)params.admittedProgramStatusRecord;
		// Admitted_Program_Status__c aps = new Admitted_Program_Status__c(
		// 	Admitted_Program__c = acc.Current_Admission__r.Current_Admitted_Program__c,
		// 	Start_Date_Time__c = params.,
		// 	Status__c = params.status
		// );
		// insert aps;
		Admitted_Program_Status__c newAps = params.admittedProgramStatusRecord;
		newAps.Account__c = acc.Id;
		newAps.Admission__c = acc.Current_Admission__c;
		insert newAps;
	}

	//update existing Admitted Program Status
	public static void updateStatus(Account acc, SaveParams params) {
		//if( string.isBlank(params?.statusId) ){
		if (string.isBlank(params.admittedProgramStatusRecord.Id)) {
			throw new ChangeAdmittedException('No Status selected for update');
		}
		if (params.admittedProgramStatusRecord.End_Date_Time__c == null) {
			throw new ChangeAdmittedException('No End Date Time selected');
		}

		// update new Admitted_Program_Status__c(
		// 	Id= params?.statusId,
		// 	end_date_time__c = params?.endDateTime
		// );
		update params.admittedProgramStatusRecord;
	}

	public static void updateCurrentAdmittedProgramCurrentStatus(id accountId) {
		PatientAccount info = getAccountInfo(accountId);
		if (info.currentAdmittedProgram != null) {
			string[] statusList = new List<string>{};
			if (info.currentAdmittedProgramStatuses != null) {
				for (Admitted_Program_Status__c aps : info.currentAdmittedProgramStatuses) {
					if (String.isNotBlank(aps.Status__c)) {
						statusList.add(aps.Status__c);
					}
				}
			}
			string statusListString = string.join(statusList, ', ');
			// Admitted_Program__c currentAdmittedProgram = [Select Current_Status__c from Admitted_Program__c where id=:info.currentAdmittedProgram.Id ];
			//Modified by Roy Lou - 12/06/2021 - commented out the if(info.currentAdmittedProgram.Current_Status__c != statusListString)
			//the info.currentAdmittedProgram.Current_Status__c has been set in getAccountInfo() call the same as statusListString
			//if(info.currentAdmittedProgram.Current_Status__c != statusListString){
			update new Admitted_Program__c(Id = info.currentAdmittedProgram.Id, Current_Status__c = statusListString);
			Admitted_Program__c ap = [SELECT Id, Current_Status__c FROM Admitted_Program__c WHERE id = :info.currentAdmittedProgram.Id];
			//}
		}
	}

	public class Response {
		@AuraEnabled
		public string errorMessage;
		@AuraEnabled
		public string staticString;
	}

	@AuraEnabled
	public static Response saveRecord(string paramsJson) {
		Response resp = new Response();
		Savepoint sp = Database.setSavepoint();
		try {
			SaveParams params = (SaveParams) JSON.deserialize(paramsJson, SaveParams.class);
			Account acc = getAccount(params?.accountId);
			switch on params?.chosenFunction {
				when 'Change Program' {
					changeProgram(acc, params);
				}
				when 'New Status' {
					newStatus(acc, params);
				}
				when 'Update Status' {
					updateStatus(acc, params);
				}
				when else {
					throw new ChangeAdmittedException('invalid function');
				}
			}
			updateCurrentAdmittedProgramCurrentStatus(acc.Id);
		} catch (ChangeAdmittedException e) {
			handleException(e, resp, sp);
		} catch (Exception e) {
			handleException(e, resp, sp);
			ProcessLogging.quickProcessLog('ChangeAdmittedProgramController.saveRecord', e.getStackTraceString(), e.getMessage());
		}
		return resp;
	}

	public static void handleException(Exception e, Response resp, Savepoint sp) {
		resp.errorMessage = e.getMessage();
		resp.StaticString = e.getStackTraceString();
		Database.rollback(sp);
	}

	public class option {
		@AuraEnabled
		public string value;

		@AuraEnabled
		public string label;

		public option(string value, string label) {
			this.value = value;
			this.label = label;
		}
	}

	public class PatientAccount {
		@AuraEnabled
		public Id accountId;
		@AuraEnabled
		public Account account;
		@AuraEnabled
		public Admitted_Program__c currentAdmittedProgram;
		@AuraEnabled
		public List<Admitted_Program_Status__c> currentAdmittedProgramStatuses; //statuses valid by date/time compared to Now
		@AuraEnabled
		public String currentStatus; //concatenated list of Status strings from current apStatuses

		@AuraEnabled
		public Admitted_Program_Status__c admittedProgramStatus; //apStatus record being created or updated

		@AuraEnabled
		public option[] statusOptions = new List<option>{};
		@AuraEnabled
		public Boolean hasAdmittedProgramPermission;

		//reference
		@AuraEnabled
		public Map<Id, User> programId2ProgramManagerMap = new Map<Id, User>();

		public PatientAccount(Id accountId) {
			this.accountId = accountId;
			queryAccount();
			queryCurrentAdmittedProgram();
			queryActivePrograms();
			this.hasAdmittedProgramPermission = FeatureManagement.checkPermission(ADMITTED_PROGRAM_PERMISSION);
			// newAdmittedProgram = new Admitted_Program__c(
			// 	Admission__c = account.Current_Admission__c,
			// 	Start_Date__c = system.today()
			// );
			// admittedProgramStatus = new Admitted_Program_Status__c(
			// 	Admitted_Program__c = currentAdmittedProgram.Id,
			// 	Start_Date_Time__c = system.now()
			// );

			this.statusOptions.add(new option('', '-- None Selected --'));
			for (Schema.PicklistEntry pk : Schema.SObjectType.Admitted_Program_Status__c.fields.Status__c.getPicklistValues()) {
				this.statusOptions.add(new option(pk.getValue(), pk.getLabel()));
			}
		}

		void queryAccount() {
			this.account = getAccount(accountId);
		}

		public void queryCurrentAdmittedProgram() {
			for (Admitted_Program__c cap : [
				SELECT Id, Name, Start_Date__c, End_Date__c, Current_Status__c, Program__c, Program__r.Name, Program__r.Short_Name__c, Program__r.Product_Code__c, Days__c, Program_Manager__c, Program_Manager__r.Id, Program_Manager__r.Name, Program_Manager__r.Professional_Name__c, (SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c, Status__c FROM Admitted_Program_Statuses__r WHERE Start_Date_Time__c <= :system.now() AND (End_Date_Time__c >= :system.now() OR End_Date_Time__c = NULL) ORDER BY Name ASC)
				FROM Admitted_Program__c
				WHERE Id = :account.Current_Admission__r.Current_Admitted_Program__c
			]) {
				this.currentAdmittedProgram = cap;
			}

			string[] statusList = new List<string>{};

			this.currentAdmittedProgramStatuses = new List<Admitted_Program_Status__c>();
			if (this.currentAdmittedProgram?.Admitted_Program_Statuses__r != null) {
				for (Admitted_Program_Status__c st : this.currentAdmittedProgram?.Admitted_Program_Statuses__r) {
					this.currentAdmittedProgramStatuses.add(st);
					statusList.add(st.Status__c);
				}
			}
			this.currentStatus = String.join(statusList, ', ');
			if (this.currentAdmittedProgram != null) {
				this.currentAdmittedProgram.Current_Status__c = this.currentStatus;
			}
		}

		void queryActivePrograms() {
			for (Program__c prog : [SELECT Id, Name, Short_Name__c, Product_Code__c, Program_Manager__c, Program_Manager__r.Id, Program_Manager__r.Professional_Name__c FROM Program__c WHERE Active__c = TRUE AND Is_Parent_Program__c = FALSE]) {
				programId2ProgramManagerMap.put(prog.Id, prog.Program_Manager__r);
			}
		}
	}
}