@isTest
public class CallSearchTest {
	@testSetup
	static void setup() {
		PatientFileTestDataUtil.createPatientWithNote();
	}

	@isTest
	private static void getPatientNotesTest() {
		List<Contact> c = [SELECT Id, AccountId, LastName FROM Contact WHERE LastName LIKE 'TestPatient_1'];

		String searchOptions = '{"name":"TestPatient_1","searchFor":"patient","startDate":"';

		searchOptions = searchOptions + System.today() + '","endDate":"' + System.today() + '","isIncludeNonStarterCalls":false,"ARCUser":\"';

		searchOptions = searchOptions + userInfo.getUserId() + '\"' + ',"gender":"Male","city":"test","state":"test","phone":"1234567890"}';

		Map<String, String> searchOptionsMap = (Map<String, String>) JSON.deserialize(searchOptions, Map<String, String>.class);

		String csw = CallSearch.getPatientNotes(searchOptionsMap, c[0].AccountId);
		Test.startTest();
		List<CallSearch.SearchByCallWrapper> searchByCallWrapper = (List<CallSearch.SearchByCallWrapper>) JSON.deserialize(csw, List<CallSearch.SearchByCallWrapper>.class);

		system.assertEquals(2, searchByCallWrapper.size());
		Test.stopTest();
	}

	@isTest
	private static void searchByCallTest() {
		String searchOptions = '{"name":"TestPatient_1","searchFor":"patient","startDate":"';
		searchOptions = searchOptions + System.today() + '","endDate":"' + System.today() + '","isIncludeNonStarterCalls":true,"ARCUser":\"';
		searchOptions = searchOptions + userInfo.getUserId() + '\"' + ',"gender":"Male","city":"test","state":"AL","phone":"1234567"}';

		//searchFor with patient
		String csw = CallSearch.searchByCall(searchOptions, null);
		List<CallSearch.SearchByCallWrapper> searchByCallWrapper = (List<CallSearch.SearchByCallWrapper>) JSON.deserialize(csw, List<CallSearch.SearchByCallWrapper>.class);
		system.assertEquals(2, searchByCallWrapper.size());

		//searchFor with caller
		String searchOptionsWithCaller = '{"name":"test_callerName","searchFor":"caller","startDate":"","endDate":"","isIncludeNonStarterCalls":false,"ARCUser":\"';
		searchOptionsWithCaller = searchOptionsWithCaller + userInfo.getUserId() + '\"' + ',"gender":"Male","city":"test","state":"AL","phone":"1234567"}';
		String cswWithCaller = CallSearch.searchByCall(searchOptionsWithCaller, null);
		List<CallSearch.SearchByCallWrapper> searchByCallWrapperWithCaller = (List<CallSearch.SearchByCallWrapper>) JSON.deserialize(cswWithCaller, List<CallSearch.SearchByCallWrapper>.class);
		system.assertEquals(2, searchByCallWrapper.size());
	}
}