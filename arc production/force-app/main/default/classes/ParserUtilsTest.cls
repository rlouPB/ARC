@isTest
public class ParserUtilsTest {
	@isTest
	static void test() {
		Account a = new Account(Name = 'Test Acc');
		ParserUtils.getValue((sObject) a, '\\.salesforce');
	}
}