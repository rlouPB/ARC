public without sharing class NursingSignInOutService {
	@AuraEnabled
	public static Nursing_Shift__c getNursingShiftSingle(string recordId) {
		for (Nursing_Shift__c ns : [SELECT Id, Name, Shift_Number__c, Status__c, Date__c, Med_Nurse__c, Charge_Nurse__c, Backup_Med_Nurse__c, Type_of_Day__c FROM Nursing_Shift__c WHERE Id = :recordId]) {
			return ns;
		}
		return null;
	}

	@AuraEnabled
	public static Nursing_Shift_Assignment__c[] getMyNursingShiftAssigments() {
		Id userId = UserInfo.getUserId();
		return [SELECT Id, Nursing_Shift__c, Nursing_Shift__r.Shift__c, Nursing_Shift__r.Date__c, Nursing_Shift__r.Shift_Number__c FROM Nursing_Shift_Assignment__c WHERE Owner__c = :userId AND Sign_Out_Date_Time__c = NULL AND Nursing_Shift__c != NULL];
	}

	@AuraEnabled
	public static string signIntoShift(Id shiftId) {
		try {
			insert new Nursing_Shift_Assignment__c(Nursing_Shift__C = shiftId, Owner__c = userinfo.getuserid(), Sign_In_Date_Time__c = System.now(), Status__c = 'Open');
			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static string signOutFromShift(Id nursingShiftAssignmentId) {
		try {
			//Validating
			if ([SELECT COUNT() FROM Nursing_Shift_Item__c WHERE Nursing_Shift_Assignment__c = :nursingShiftAssignmentId AND (NOT Status__c IN ('Closed', 'Cancelled'))] > 0) {
				return 'Assignment still have open items';
			}

			update new Nursing_Shift_Assignment__c(Id = nursingShiftAssignmentId, Sign_Out_Date_Time__c = System.now(), Status__c = 'Closed');
			return null;
		} catch (Exception ex) {
			return ex.getMessage() + ' - ' + ex.getStackTraceString();
		}
	}

	@AuraEnabled
	public static Object[] getSignInOutData() {
		/*  List<Nursing_Shift__c> nursingShifts = new List<Nursing_Shift__c>();
        nursingShifts = [
            SELECT
                Id,
                Date__c,
                Shift__c,
                Shift_Number__c,
                Status__c,
                Charge_Nurse__c,
                Shift_Open_Date_Time__c,
                Scheduled_Closed_Date_Time__c
            FROM Nursing_Shift__c
            WHERE
                Status__c in ('Open','New')
            ORDER BY Date__c ASC, Shift_Number__c ASC
        ];
        list<nursingShiftWrapper> nslist = new list<nursingShiftWrapper>();
        for(Nursing_Shift__c ns : nursingShifts){
            nslist.add(new nursingShiftWrapper(ns));
        }
        return nslist;*/
		return [SELECT Id, Date__c, Shift__c, Shift_Number__c, Status__c, Charge_Nurse__c, Shift_Open_Date_Time__c, Scheduled_Closed_Date_Time__c FROM Nursing_Shift__c WHERE Status__c IN ('Open', 'New') ORDER BY Date__c ASC, Shift_Number__c ASC];
	}

	public class nursingShiftWrapper {
		@AuraEnabled
		public Nursing_Shift__c nursingShift { get; set; }
		@AuraEnabled
		public string shiftOpenDateTimeFormatted { get; set; }
		public nursingShiftWrapper(Nursing_Shift__c ns) {
			this.nursingShift = ns;
			this.shiftOpenDateTimeFormatted = ns.Shift_Open_Date_Time__c.format('MM/dd/yyyy HH:mm:ss');
		}
	}
}