@isTest
public class LightningDatatableControllerTest {
    private static final String CONTACT_OBJECT_NAME = 'Contact';
    private static final String ID_FIELD_NAME = 'Id';

    @TestSetup
    static void initiateData(){
        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 1'
        );
        insert testContact1;
    }

    @isTest
    private static void getTotalCountTest() {
        List<Contact> contactList = [SELECT Id, Name FROM Contact LIMIT 1];
        List<SOQL_Objects.SOQL_Criterion> filter = new List<SOQL_Objects.SOQL_Criterion> { new SOQL_Objects.SOQL_Criterion(ID_FIELD_NAME, '=', (String) contactList[0].get(ID_FIELD_NAME)) };

        Test.startTest();
        Integer noOfRecords = LightningDatatableController.getTotalCount(CONTACT_OBJECT_NAME, JSON.serialize(filter));
        Test.stopTest();

        System.assertEquals(contactList.size(), noOfRecords);
    }

    @isTest
    private static void getDatatableResponseTest() {
        List<Contact> contactList = [SELECT Id, Name FROM Contact LIMIT 1];
        List<SOQL_Objects.SOQL_Criterion> filter = new List<SOQL_Objects.SOQL_Criterion> { new SOQL_Objects.SOQL_Criterion(ID_FIELD_NAME, '=', (String) contactList[0].get(ID_FIELD_NAME)) };

        Test.startTest();
        LightningDatatableController.DatatableResponse dataTableResponse = LightningDatatableController.getDatatableResponse(CONTACT_OBJECT_NAME, new List<String> { 'Name' }, JSON.serialize(filter), 1, 0);
        Test.stopTest();

        System.assertEquals(contactList[0].get(ID_FIELD_NAME), dataTableResponse.dataList[0].get(ID_FIELD_NAME));
    }
}