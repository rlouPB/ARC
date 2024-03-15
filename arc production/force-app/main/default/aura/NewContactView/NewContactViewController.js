({
    handleOnError: function(component, event, helper) {
        //RecordEditform error 
        var params = event.getParams();
        helper.toggleSpinner(component, 0);
        console.log(params);
    },
    onFieldChange: function(component, event, helper) {
         console.log('onFieldChange');
        let contact = component.get("v.contact"),
            selectedRecordType =  component.get("v.selectedRecordType"),
            objectApiName = '';
        
        if(selectedRecordType.label === 'Professional') {
           objectApiName = component.find("newProfessionalContactForm").get("v.objectApiName");
        } else {
           objectApiName =  component.find("newContactForm").get("v.objectApiName");
        }
        
        
        if(objectApiName === 'Contact') {
            component.set("v.contact",helper.setValueBasedOnFieldType(contact,objectApiName,event));
        } 
        
        
    },
    onFieldChangeRelated: function(component, event, helper) {
        let relatedContact = component.get("v.relatedContact"),
             selectedRecordType =  component.get("v.selectedRecordType"),
        	 relatedObjectApiName = '';
       
        if(selectedRecordType.label === 'Professional') {
            relatedObjectApiName = component.find("relatedContactFormProfessional").get("v.objectApiName");
        } else {
            relatedObjectApiName = component.find("relatedContactFormPersonal").get("v.objectApiName"); 
        } 
        
        if(relatedObjectApiName === 'Related_Contact__c') {
            component.set("v.relatedContact",helper.setValueBasedOnFieldType(relatedContact,relatedObjectApiName,event));
        }
     },
	save : function(component, event, helper) {
        
        let selectedRecordType =  component.get("v.selectedRecordType"),
            contact = component.get("v.contact"),
            relatedContact = component.get("v.relatedContact"),
            accountId = component.get("v.recordId");

        //empty error message every time save clicked    
        component.set("v.errorMessage",'');
        contact.RecordTypeId = selectedRecordType.value;
        relatedContact.RecordTypeId = selectedRecordType.relatedValue;
        relatedContact.Account__c = accountId;
		console.log(JSON.stringify(contact));
        if(selectedRecordType.label === 'Professional') {
            //both fields error message show   
            const isContactFieldsValid = helper.validateIsRequired(component,{'FirstName' : 'First Name','LastName':'Last Name'},contact),
                isRelatedContactFieldsValid= helper.validateIsRequired(component,{'Role__c':'Role'},relatedContact);
            
            if(isContactFieldsValid && isRelatedContactFieldsValid){
                helper.hideCustomToast(component);
                helper.toggleSpinner(component, 0);
                helper.saveContactform(component,contact,relatedContact,helper);
                //component.find('newProfessionalContactForm').submit(contact)
            } else{
                helper.showErrorMessage(component);
            } 
        } else {
            //both fields error message show  
            const isContactFieldsValid = helper.validateIsRequired(component,{'LastName':'Last Name'},contact),
                isRelatedContactFieldsValid= helper.validateIsRequired(component,{'Role__c':'Role'},relatedContact);
            
            if(isContactFieldsValid && isRelatedContactFieldsValid){
                helper.toggleSpinner(component, 0);
                helper.saveContactform(component,contact,relatedContact,helper);
                //component.find("newContactForm").submit(contact);
            } else {
               helper.showErrorMessage(component); 
            } 
            
         }
		
	},
    cancel : function(component, event, helper) {
        var evt = component.getEvent("closeModalView");
        evt.fire();
    },
    onrecordTypeChange: function(component, event, helper) {
        //reInitialize when Recordtype change
        component.set("v.contact",{'sobjectType':'Contact'});
        component.set("v.relatedContact",{'sobjectType':'Related_Contact__c'});
        
        const contactRecordTypeList = component.get("v.contactRecordTypeList"),
              relatedContactRecordTypeList = component.get("v.relatedContactRecordTypeList");
        
        const contactRecordTypeRecord = contactRecordTypeList.find(record => record.value === event.getParam('value'));
        const relatedContactRecordTypeRecord = relatedContactRecordTypeList.find(record => record.label === contactRecordTypeRecord.label);
        
        let selectedRecordType =  component.get("v.selectedRecordType");
        selectedRecordType.label = contactRecordTypeRecord.label;
        selectedRecordType.value = contactRecordTypeRecord.value;
        selectedRecordType.relatedValue = relatedContactRecordTypeRecord.value;
        
        component.set("v.selectedRecordType",selectedRecordType);
        helper.toggleSpinner(component, 0);
    },
    load : function(component, event, helper) {
        helper.toggleSpinner(component, 0);
    }, 
    handleError : function(component, event, helper) {
    	var params = event.getParams();
        helper.toggleSpinner(component, 0);
    },  
    doInit : function(component, event, helper) {
        helper.callApexMethod(
            component,
            "getContactRecordTypeDetails",
             null,
            function (result) {
               
                let contactRecordTypes = (collection) => {
                    return collection.filter((record) => record.Name != 'Patient').map((record) => {
                 		let recordMap = {'label':record.Name,'value':record.Id};
                		console.log('recordMap ist: ' + recordMap);
                		return  recordMap;
                	});
                }
                
               
                const contactRecordTypeList = contactRecordTypes(result.contactRecordTypes);
     			const relatedContactRecordTypeList = contactRecordTypes(result.relatedContactRecordTypes);
              	
    			component.set("v.contactRecordTypeList",contactRecordTypeList);
    			component.set("v.relatedContactRecordTypeList",relatedContactRecordTypeList);
    
     			helper.toggleSpinner(component, 0);
            },
             function(error){
                helper.showCustomToast({'type':'error','title':error});
                helper.toggleSpinner(component, 0);
            }
        );
    },
})