/**
 * Description: This class will manage sensitive Contact Informarion and populate SSN in case is empty.
 * Created By: Fernando Ortiz
 */

public without sharing class ContactSensitiveFormDataCtl {
	public class PatientWrapper {
		public PatientWrapper(Contact patient) {
			this.PatientId = patient.Id;
			this.Name = patient.Name;
			this.FirstName = patient.FirstName;
			this.LastName = patient.LastName;
			this.Birthdate = patient.Birthdate;
			this.SSN = maskSSN(patient.Social_Security_Number__c, 4);
			this.MobilePhone = patient.MobilePhone;
			this.HomePhone = patient.Phone;
			this.WorkPhone = patient.npe01__WorkPhone__c;
			this.PreferredPhone = patient.npe01__PreferredPhone__c;
			this.Email = patient.Email;
		}

		@AuraEnabled
		public Id PatientId { get; set; }
		@AuraEnabled
		public String Name { get; set; }
		@AuraEnabled
		public String FirstName { get; set; }
		@AuraEnabled
		public String LastName { get; set; }
		@AuraEnabled
		public Date Birthdate { get; set; }
		@AuraEnabled
		public String SSN { get; set; }
		@AuraEnabled
		public String MobilePhone { get; set; }
		@AuraEnabled
		public String HomePhone { get; set; }
		@AuraEnabled
		public String WorkPhone { get; set; }
		@AuraEnabled
		public String PreferredPhone { get; set; }
		@AuraEnabled
		public String Email { get; set; }
	}

	@TestVisible
	private static Contact getContactRecord() {
		//Get logged user
		Id userId = System.UserInfo.getUserId();

		User us = [SELECT Id, ContactId FROM User WHERE Id = :userId][0];

		if (us.ContactId == null) {
			return null;
		}

		List<Contact> contactList = [
			SELECT
				Id,
				Name,
				FirstName,
				LastName,
				Birthdate,
				Social_Security_Number__c,
				Phone,
				MobilePhone,
				npe01__WorkPhone__c,
				npe01__PreferredPhone__c,
				Email
			FROM Contact
			WHERE Id = :us.ContactId
		];

		// List<Contact> contactList = [SELECT Id, Name, Birthdate, Social_Security_Number__c, Phone, MobilePhone, npe01__WorkPhone__c, npe01__PreferredPhone__c, Email
		// FROM Contact WHERE Id =: '003L000001KIZ3PIAX'];

		return contactList[0];
	}

	@AuraEnabled
	public static Boolean saveSSN(string ssn) {
		if (ssn == null || ssn == '' || ssn.length() < 9) {
			return false;
		}

		Contact ctc = getContactRecord();

		if (ctc == null || ctc.Social_Security_Number__c != null) {
			return false;
		}

		ctc.Social_Security_Number__c = ssn;

		update ctc;
		return true;
	}

	@AuraEnabled
	public static PatientWrapper getPatientInformation() {
		Contact ctc = getContactRecord();

		if (ctc == null) {
			return null;
		}

		PatientWrapper patient = new PatientWrapper(ctc);
		return patient;
	}

	private static String maskSSN(string ssn, Integer length) {
		if (ssn == null || String.isEmpty(ssn)) {
			return null;
		}

		String strMask = '***-**-';
		return strMask + ssn.right(length);
	}
}