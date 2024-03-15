({
	toggleSpinner : function(component, duration) {
		component.set('v.enableButtons', !component.get('v.enableButtons'));
        window.setTimeout($A.getCallback(function() {
            if (component.find("spinner")) {
                var spinnerCls = component.find("spinner").get("v.class");
                if (spinnerCls) {
                    if (spinnerCls === 'slds-show') {
                        component.find("spinner").set("v.class", "slds-hide");    
                    } else {
                        component.find("spinner").set("v.class", "slds-show");    
                    }
                } else{
                    component.find("spinner").set("v.class", "slds-hide");    
                }
            }
          }), duration);	   
	},
	hideSpinner : function(component, helper, duration) {
		component.set('v.enableButtons', true);
        window.setTimeout($A.getCallback(function() {
            if (component.find("spinner")) {
                component.find("spinner").set("v.class", "slds-hide");   
            }
        }), duration);	
	},
	showSpinner : function(component, helper, duration) {
		component.set('v.enableButtons', false);
        window.setTimeout($A.getCallback(function() {
            if (component.find("spinner")) {
                component.find("spinner").set("v.class", "slds-show");   
            }
        }), duration);	
	},
    validateIsRequired : function(component,fields, obj) {
      let errorMessage = component.get("v.errorMessage");
      return Object.keys(fields).reduce(function (validSoFar, field) {
          if(!obj[field]) {
              if(errorMessage === '' ) {
                 errorMessage = fields[field];
              } else {
                 errorMessage = errorMessage + ', ' + fields[field];  
              }
          }
          component.set('v.errorMessage',errorMessage)
          return validSoFar && obj[field];
      }, true);
    },
    showErrorMessage : function(component) {
        this.showCustomToast(component,{'type':'error','title':'Please review the errors in the page.','message':'Required fields missing: '+ component.get('v.errorMessage')});
    },
    setValueBasedOnFieldType : function(obj,apiName,event){
        if(apiName === 'Contact' && event.getSource().get("v.fieldName") === 'Name') {
            obj['FirstName'] = event.getParams().firstName;
            obj['LastName'] = event.getParams().lastName;
            obj['Salutation'] = event.getParams().salutation;
        }
        
        if(event.getParams().hasOwnProperty('checked')){
            obj[event.getSource().get("v.fieldName")] = event.getParam('checked');
        } else {
            obj[event.getSource().get("v.fieldName")] = event.getParam('value');
        }
        
        return obj;
    },
    saveContact : function(component,contact,helper){
        var self = this;
        helper.callApexMethod(
            component,
            "saveContact",
            {'con':contact,'recordTypeName':component.get('v.contactRecordTypeName')},
            function (result) {
                console.log(JSON.stringify(result));
                self.handleSaveSuccess(component,result);
            },
            function(error){
                self.toggleSpinner(component, 0);
                helper.showCustomToast(component,{'type':'error','title':'Error while saving a record','message':error});
            }
        );

    },
    handleSaveSuccess : function(component,result) {    
		let evt = component.getEvent("closeModalView");
        
        this.toggleSpinner(component, 0);
        console.log('back from contact save result ' + JSON.stringify(result));
        var data = {
            "label" : result.Name,
            "value" : result.Id,
            "isRecord" : true
        };
        evt.setParams({
            "data" : data
        })
        evt.fire();
	},
    
    populateDefaultFieldValues : function (component, event, helper)
    {
        let contact = component.get('v.contact');
        let contactRecordTypeName = component.get('v.contactRecordTypeName');
        let defaultPreferredPhone = '';
        if (contactRecordTypeName == 'Patient')
        {
            defaultPreferredPhone = 'Mobile';
        } else if (contactRecordTypeName == 'Personal')
        {
            defaultPreferredPhone = 'Home';
        } else if (contactRecordTypeName == 'Professional')
        {
            defaultPreferredPhone = 'Work';
        }
        contact.npe01__PreferredPhone__c = defaultPreferredPhone;
        component.set('v.contact', contact);
    },

    populateStateCountryOptions : function(component, event, helper)
    {
        helper.callApexMethod(
            component,
            "getCountryStateValues",
            {},
            function (result) {
                let countryChoices = JSON.parse(result);
                let defaultValue = '';
                console.log(countryChoices);
                let countryOptions = [];
                countryChoices.forEach( function(item) 
                {
                    countryOptions.push({'label': item.label, 'value': item.value});
                });

                component.set('v.countryDependencies', countryChoices);
                component.set('v.countryOptions', countryOptions);

                // let defaultCountryCode = component.get('v.defaultCountryCode');
                let defaultCountry = component.get('v.defaultCountry');
                let contact = component.get('v.contact');
                //if (!contact.MailingCountry) contact.MailingCountry = defaultCountry;
                if (!contact.MailingCountry) contact.MailingCountry = defaultCountry;
                if (!contact.OtherCountry) contact.OtherCountry = defaultCountry;
                
                component.set('v.contact', contact);

                helper.populateStateOptions(component, event, helper);

            },
            function(error){
                self.toggleSpinner(component, 0);
                helper.showCustomToast(component,{'type':'error','title':'Error while saving a record','message':error});
            }
        );
    },
    populateStateOptions : function(component, event, helper)
    {
        let contact = component.get('v.contact');
        let countryDependencies = component.get('v.countryDependencies');
        let mailingProvinceOptions, otherProvinceOptions;

        if (contact.MailingCountry)
        {
            let oldMailingOptions = mailingProvinceOptions;
            countryDependencies.forEach(function (item) 
            {
                if (item.label == contact.MailingCountry) mailingProvinceOptions = item.dependentFieldChoices;
            });
            if (mailingProvinceOptions && oldMailingOptions != mailingProvinceOptions)
            {
                console.log('changed mailingcountry to ' + contact.MailingCountry);
                component.set('v.mailingProvinceOptions', mailingProvinceOptions);
            }
        }
        if (contact.OtherCountry)
        {
            countryDependencies.forEach(function (item) 
            {
                if (item.label == contact.OtherCountry) otherProvinceOptions = item.dependentFieldChoices;
            });
            if (otherProvinceOptions) 
            {
                component.set('v.otherProvinceOptions', otherProvinceOptions);   
            }
        }
        
        
    }
})