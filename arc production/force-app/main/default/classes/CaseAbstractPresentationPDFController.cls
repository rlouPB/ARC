public with sharing class CaseAbstractPresentationPDFController {
    public Id currentRecordId {get;set;}
    Transient public CaseAbstract caseAbstract { get; set;}
    Transient public Map<String, Boolean> renderSectionMap {get; set;}
    TRansient public String finalizedDateTimeString {get; set;}
    //Admission__r.Patient_Account__r.Name
    private Case_Abstract__c caRecord=null;
    public CaseAbstractPresentationPDFController(ApexPages.StandardController stdController) {
        this.caRecord = (Case_Abstract__c)stdController.getRecord();
        this.currentRecordId = this.caRecord.Id;
        renderSectionMap = new Map<String, Boolean>();
    }

    public CaseAbstractPresentationPDFController() {
        currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
        renderSectionMap = new Map<String, Boolean>();
    }
    public PageReference init() {
        try {
        if(this.currentRecordId != null) {
            caseAbstract = new CaseAbstract(this.currentRecordId);
            if(caseAbstract.record.Finalized_Date_Time__c != null) {
                this.finalizedDateTimeString = caseAbstract.record.Finalized_Date_Time__c.format('MM/dd/yyyy hh:mm a, z', 'America/New_York');
            }
            
            for(CaseAbstract.Section sec : caseAbstract.sections) {
                renderSectionMap.put(sec.sectionMdt.Title__c, false);
                if('Completed'.equalsIgnoreCase(sec.record.Status__c)) {
                    Boolean rendered = false;
                    for(CaseAbstract.SectionItem item : sec.items) {
                        if(String.isNotBlank(item.sectionFieldValue)){
                            rendered = true;
                            break;
                        }
                    }
                    renderSectionMap.put(sec.sectionMdt.Title__c, rendered);
                }
            }
            for(CaseAbstract.Section sec : caseAbstract.sections) {
                if('Completed'.equalsIgnoreCase(sec.record.Status__c)) {
                    for(CaseAbstract.SectionItem item : sec.items) {
                        if(String.isNotBlank(item.sectionFieldValue)){
                            if(item.sectionFieldValue.indexOf('shepherd') != -1) {
                                try {
                                system.debug(item.sectionFieldValue);
                                Matcher regex = Pattern.compile('(?si)<a.*\\/download\\/([a-zA-Z0-9]{15}|[a-zA-Z0-9]{18})[^>]+>(.*)<\\/a>').matcher(item.sectionFieldValue);
                                system.debug(regex.find());
                                system.debug(regex.group(1));
                                system.debug(regex.group(2));
                                // Integer start = item.sectionFieldValue.indexOf('068');
                                // system.debug(item.sectionFieldValue.subString(start, start+18));
                                //String versionId=item.sectionFieldValue.subString(start, start+18);
                                item.contentVersionId = regex.group(1);
                                item.sectionFieldValue = regex.group(2);
                                system.debug(item.sectionFieldValue);
                                //contentVersionId
                                } catch (Exception e) {
                                    system.debug('--------------' + e.getMessage() + '\n' + e.getStackTraceString());
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch(Exception e) {
        system.debug('--------------' + e.getMessage() + '\ngetStackTraceString=' + e.getStackTraceString());
    }
        return null;
    }
}