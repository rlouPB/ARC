@isTest
public class test_conPageRedirectController{
    public static final Id patientRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
    public static final Id personalRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
    public static final Id professionalRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Professional').getRecordTypeId();
    
    // tests page redirect if the record type is Patient
    @isTest
	public static void isPatientRecordType() {
        
        test.startTest();        
        
        Account accnt = (Account)TestFactory_Patient.createSObject(new Account(), 'TestFactory_Patient.PatientAccountDefaults', true);
        Contact con = (Contact)TestFactory_Patient.createSObject(new Contact(AccountID = accnt.Id, 
                                                                            RecordTypeId = patientRecTypeId), 
                                                                'TestFactory_Patient.RelatedContactDefaults', 
                                                                true);
        
        PageReference pageRef = Page.contactPageRedirect;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', con.id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        conPageRedirectController cntrller = new conPageRedirectController(sc);
        System.assertEquals(false, cntrller.redirect().getUrl().containsIgnoreCase('nooverride'), 'Page reference returned is not equal to false');    
        
        test.stopTest();
	}

    // tests page redirect does not occur if the record type is Personal
    @isTest
    public static void isPersonalRecordType() {
        
        test.startTest();        
        
        Account accnt = (Account)TestFactory_Patient.createSObject(new Account(), 'TestFactory_Patient.PatientAccountDefaults', true);
        Contact con = (Contact)TestFactory_Patient.createSObject(new Contact(AccountID = accnt.Id, 
                                                                            RecordTypeId = personalRecTypeId), 
                                                                'TestFactory_Patient.RelatedContactDefaults', 
                                                                true);
        
        PageReference pageRef = Page.contactPageRedirect;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', con.id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        conPageRedirectController cntrller = new conPageRedirectController(sc);
        System.assertEquals(true, cntrller.redirect().getUrl().containsIgnoreCase('nooverride'), 'Page reference returned is not equal to true');    
        
        test.stopTest();
    }

    // tests page redirect does not occur if the record type is Professional
    @isTest
    public static void isProfessionalRecordType() {
        
        test.startTest();        
        
        Account accnt = (Account)TestFactory_Patient.createSObject(new Account(), 'TestFactory_Patient.PatientAccountDefaults', true);
        Contact con = (Contact)TestFactory_Patient.createSObject(new Contact(AccountID = accnt.Id, 
                                                                            RecordTypeId = professionalRecTypeId), 
                                                                'TestFactory_Patient.RelatedContactDefaults', 
                                                                true);
        
        PageReference pageRef = Page.contactPageRedirect;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', con.id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(con);
        conPageRedirectController cntrller = new conPageRedirectController(sc);
        System.assertEquals(true, cntrller.redirect().getUrl().containsIgnoreCase('nooverride'), 'Page reference returned is not equal to true');    
        
        test.stopTest();
    }   

}