@isTest
private class NewBasicContactCtlTest {

	@isTest
	static void testCtl() {
		Contact personalCon = new Contact(LastName = 'personal');
		Contact profCon = new Contact(LastName = 'professional');

		Test.startTest();
			NewBasicContactCtl.saveContact(personalCon, 'Personal');
			NewBasicContactCtl.saveContact(profCon, 'Professional');
        	NewBasicContactCtl.getCountryStateValues();
		Test.stopTest();

		List<Contact> cons = [SELECT Id, Account.Recordtype.Name, LastName, Recordtype.Name FROM Contact];
		System.assertEquals(2, cons.size());

		for (Contact con : cons) {
			System.assertEquals('Individual', con.Account.Recordtype.Name);
			if (con.LastName == 'personal') {
				System.assertEquals('Personal', con.Recordtype.Name);
			} else {
				System.assertEquals('Professional', con.Recordtype.Name);
			}
		}
	}
}