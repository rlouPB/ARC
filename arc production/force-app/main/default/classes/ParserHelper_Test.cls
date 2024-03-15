@isTest
public class ParserHelper_Test {
	@testSetup
	public static void setup() {
		Account acct = new Account(Name = 'test account');
		insert acct;

		Opportunity opty = new Opportunity(Name = 'test oppty', Amount = 20.05, AccountId = acct.id, StageName = 'New Opportunity', closedate = system.today().addDays(1));
		insert opty;
	}

	@isTest
	static void shouldReturnTheCorrectValues() {
		Account acct = [SELECT Name, CreatedBy.Email, (SELECT Name, Amount FROM Opportunities) FROM Account LIMIT 1];

		System.assertEquals(acct.Name, ParserHelper.parseSobject(acct, 'Name'));
		System.assertEquals(acct.CreatedBy.Email, ParserHelper.parseSobject(acct, 'CreatedBy.Email'));
		System.assertEquals(acct.Opportunities[0].Name, ParserHelper.parseSobject(acct, 'Opportunities[0].Name'));
		System.assertEquals('20.05', ParserHelper.toCurrency(acct, 'Opportunities[0].Amount', 2));
		System.assertEquals('', ParserHelper.toString(acct, 'Opportunities[10].Name'));
		System.assertEquals('', ParserHelper.toString(acct, 'Opportunities[10].Amount'));
		System.assertEquals(null, ParserHelper.parseSobject(acct, 'Opportunities[10].Name'));
		System.assertEquals(null, ParserHelper.parseSobject(acct, 'Opportunities[-2].Name'));
		System.assertEquals(null, ParserHelper.parseSobject(acct, 'Opportunities[].Name'));
		System.assertEquals(null, ParserHelper.parseSobject(null, 'Opportunities[].Name'));
	}
}