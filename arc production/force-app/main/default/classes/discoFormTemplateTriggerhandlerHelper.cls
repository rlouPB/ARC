global without sharing class discoFormTemplateTriggerhandlerHelper {
    global static final string DUPLICATE_DOCTYPE_ERROR_BASE = 'There cannot be more than one DocType Name active at the same time';
    global static final string[] activeStatus = 'In Use;Active'.split(';');

    global static void validateDocTypeName(disco__Form_Template__c[] forms){
        if(forms != null && forms.size() > 0){
            validateDocTypeOnList(forms);
            validateDocTypeAgainstOthers(forms);
        }
    }

    static void validateDocTypeOnList(disco__Form_Template__c[] forms){
        set<string> timesFound = new set<string>();
        for(disco__Form_Template__c form : forms){
            if(form.DocType_Name__c != null && activeStatus.contains(form.disco__Status__c)){
                if(!timesFound.contains(form.DocType_Name__c)){
                    timesFound.add(form.DocType_Name__c);
                }else{
                    form.addError(DUPLICATE_DOCTYPE_ERROR_BASE +': ' + form.DocType_Name__c);
                }
            }
        }
    }

    static void validateDocTypeAgainstOthers(disco__Form_Template__c[] forms){
        if(forms != null){
            set<string> timesFound = new set<string>();
            disco__Form_Template__c[] formsInSystemList = [select Id, DocType_Name__c,disco__Status__c from disco__Form_Template__c where disco__Status__c in :activeStatus];
            for(disco__Form_Template__c form : forms){            
                if(form.DocType_Name__c != null && activeStatus.contains(form.disco__Status__c)){
                    for(disco__Form_Template__c formInSystem : formsInSystemList){
                        if( form.Id != formInSystem.Id && activeStatus.contains(form.disco__Status__c) && formInSystem.DocType_Name__c == form.DocType_Name__c ){
                            form.addError(DUPLICATE_DOCTYPE_ERROR_BASE + ': ' + form.DocType_Name__c);
                        }
                    }
                }
            }
        }
    }
}