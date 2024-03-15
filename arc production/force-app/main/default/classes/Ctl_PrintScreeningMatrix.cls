public with sharing class Ctl_PrintScreeningMatrix {
  /*

*/

  public List<Related_Contact__c> relatedContacts { get; set; }
  public List<AdmissionScreeningController.QuestionWrapper> allQuestions {
    get;
    set;
  }
  public String serviceType { get; set; }

  public Ctl_PrintScreeningMatrix(ApexPages.standardController stdcon) {
    AdmissionScreeningController.QuestionSetWrapper wrapper;
    sObject obj = stdcon.getRecord();
    if (obj instanceof Account) {
      wrapper = AdmissionScreeningController.getQuestionsForAccount(
        stdcon.getId()
      );
    } else if (obj instanceof Admission__c) {
      wrapper = AdmissionScreeningController.getQuestions(
        (String) obj.get('Patient_Account__c'),
        (String) obj.Id,
        serviceType
      );
    }
    relatedContacts = wrapper.relatedContacts;
    allQuestions = wrapper.allQuestions;
    serviceType = wrapper.serviceType;
  }
}