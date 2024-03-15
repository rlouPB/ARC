public class conPageRedirectController {
    Id patientRecTypeId {get; set;}    
    Contact contact = new Contact();
    
    public conPageRedirectController(ApexPages.StandardController stdController){
        patientRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
        if(!Test.isRunningTest()){
            List<String> fieldNames = new List<String>{'AccountId', 'RecordTypeId'};
            stdController.addFields(fieldNames);
        }
        contact = (Contact)stdController.getRecord();
    }	
    
    public PageReference redirect(){
        PageReference pageRef;
        if(contact.RecordTypeId != null){            
        	// redirect to account if the record type is 'Patient'        
            if(contact.RecordTypeId == patientRecTypeId){
                pageRef = new PageReference('/' + contact.AccountId);
                return pageRef;
            }            
        }
        pageRef = new PageReference('/' + contact.Id + '?nooverride=1');
        return pageRef;
    }
        
}