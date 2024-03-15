public with sharing class NewBasicContactCtl {
	@AuraEnabled
	public static Contact saveContact(Contact con, String recordTypeName) {
		Id accRtId = [SELECT Id FROM Recordtype WHERE sobjectType = 'Account' AND Name = 'Individual' LIMIT 1].Id;
		Id conRtId = [SELECT Id FROM Recordtype WHERE sobjectType = 'Contact' AND Name = :recordTypeName LIMIT 1].Id;

		if (con.Id == null) {
			Account acc = new Account(Name = 'Individual', npe01__One2OneContact__c = con.Id, RecordTypeId = accRtId);
			insert acc;
			con.AccountId = acc.Id;
		}

		con.RecordTypeId = conRtId;
		upsert con;
		con = [SELECT Id, Name, Recordtype.Name, Account.RecordType.Name FROM Contact WHERE Id = :con.Id];
		return con;
	}

	@AuraEnabled
	public static String getCountryStateValues() {
		Schema.DescribeFieldResult c = Contact.MailingCountryCode.getDescribe();
		Schema.sObjectField country = c.getSObjectField();
		Schema.DescribeFieldResult s = Contact.MailingStateCode.getDescribe();
		Schema.sObjectField state = s.getSObjectField();

		return JSON.serialize(PicklistValues.controllingToDependentValues(country, state, true));
	}
}