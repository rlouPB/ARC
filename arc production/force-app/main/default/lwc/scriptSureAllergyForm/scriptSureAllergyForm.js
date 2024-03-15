import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import createPatientAllergy from "@salesforce/apex/ScriptSureController.createPatientAllergy";
import createUpdatePatientAllergy from "@salesforce/apex/ScriptSureController.createUpdatePatientAllergy";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ALLERGY_OBJECT from '@salesforce/schema/Allergy__c';
import ALLERGY_TYPE_FIELD from '@salesforce/schema/Allergy__c.Allergy_Type__c';
import ADVERSE_EVENT_FIELD from '@salesforce/schema/Allergy__c.Adverse_Event_Code__c';
import REACTION_FIELD from '@salesforce/schema/Allergy__c.Reaction__c';
import SEVERITY_FIELD from '@salesforce/schema/Allergy__c.Severity_Code__c';

export default class ScriptSureAllergyForm extends LightningElement {
    
    @wire(getObjectInfo, { objectApiName: ALLERGY_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ALLERGY_TYPE_FIELD})
    allergyTypeOptions;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: ADVERSE_EVENT_FIELD})
    adverseCodeOptions;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: REACTION_FIELD})
    reactionOptions;
    
    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: SEVERITY_FIELD})
    severityOptions;


    @api allergyname = '';
    @api patientid = '';
    @api accountid = '';
    @api recordid;
    @api allergytoedit;
    @api irisonly = false;


    @track name = '';
    @track onsetDate;
    @track endDate;
    @track selectedAllergyType;
    @track selectedAdverseCode;
    @track selectedReaction;
    @track selectedSeverity;
    @track description;
    @track allergyRecordId;
    //@track isIrisOnly = false;

    @track isSaveNew = false;
    @track showSpinner = false;

    @track originalName;
    @track originalOnsetDate;
    @track originalEndDate;
    @track originalSelectedAllergyType;
    @track originalSelectedReaction;
    @track originalSelectedSeverity;
    @track originalDescription;

    connectedCallback() 
    {
        console.log("**** allergyTypeOptions ----> ", this.allergyTypeOptions);

        // Focus on input field (once rendering done)
        window.setTimeout(() => 
        {
            const onsetDateInput = this.template.querySelector('.onsetDateInput');
            if (onsetDateInput) onsetDateInput.focus();
        }, 50);

        if (this.allergyname) {
            this.name = this.allergyname;
            this.allergyRecordId = this.recordid;
        }
        

        if (this.allergytoedit != null) {
            console.log('@@@@@ allergy edit ---> ', JSON.parse(JSON.stringify(this.allergytoedit)));
            this.loadExistingAllergy();
        }

        this.cloneFormValues();

    }

    // @track allergyTypeOptions = [
    //     {label: 'Food Intolerance', value: '0'},
    //     {label: 'Food Allergy', value: '1'},
    //     {label: 'Drug Allergy', value: '2'},
    // ];
    // @track reactionOptions = [
    //     {label: 'Skin Rash', value: '0'},
    //     {label: 'Hives', value: '1'},
    //     {label: 'Respiratory Distress', value: '2'},
    // ];
    // @track severityOptions = [
    //     {label: 'Fatal', value: '0'},
    //     {label: 'Severe', value: '1'},
    //     {label: 'Moderate', value: '2'},
    // ];

    validateOnDirtyData () {
        let canContinue = true;
        if(
            this.name != this.originalName ||
            this.onsetDate != this.originalOnsetDate ||
            this.endDate != this.originalEndDate ||
            this.selectedAllergyType != this.originalSelectedAllergyType ||
            this.selectedReaction != this.originalSelectedReaction ||
            this.selectedSeverity != this.originalSelectedSeverity ||
            this.description != this.originalDescription
        ) {
            canContinue = confirm('Some changes were detected, Do you want to proceed without saving?');
        }

        return canContinue;
    }

    cloneFormValues() {
        if (!this.allergyname) {
            this.originalName = this.name;
        }        
        this.originalOnsetDate = this.onsetDate;
        this.originalEndDate = this.endDate;
        this.originalSelectedAllergyType = this.selectedAllergyType;
        this.originalSelectedReaction = this.selectedReaction;
        this.originalSelectedSeverity = this.selectedSeverity;
        this.originalDescription = this.description;
    }

    closeModal() {
        let valid = this.validateOnDirtyData();
        console.log('****** closeModal Allergy form ---> ', valid);
        if (!valid) {
            return;
        }

        this.clearValues();
        this.dispatchEvent(new CustomEvent('closeallergyformmodal'));
    }

    loadExistingAllergy() {
        this.allergyRecordId = this.allergytoedit.recordId;
        this.name = this.allergytoedit.name;
        this.onsetDate = this.allergytoedit.onsetDate;
        this.endDate = this.allergytoedit.endDate;
        // this.selectedAllergyType = this.allergytoedit.allergyType.toString();
        if (this.allergytoedit.adverseEventCode) {
            // this.selectedAllergyType = this.allergytoedit.adverseEventCode.toString();
            this.selectedAdverseCode = this.allergytoedit.adverseEventCode.toString();
        }
        if (this.allergytoedit.reactionId) {
            this.selectedReaction = this.allergytoedit.reactionId.toString();            
        }
        if (this.allergytoedit.severityCode) {
            this.selectedSeverity = this.allergytoedit.severityCode;
        }
        this.description = this.allergytoedit.comment;
    }


    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts){
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }

    onAllergyNameChange(event) {
        this.name = event.target.value;
        console.log('**** name ---> ', this.name);
    }
    onSetDateChange(event) {
        this.onsetDate = event.target.value;
        console.log('**** onsetDate ---> ', this.onsetDate);
    }
    onEndDateChange(event) {
        this.endDate = event.target.value;
        console.log('**** endDate ---> ', this.endDate);
    }
    onDescriptionChange(event) {
        this.description = event.target.value;
        console.log('**** description ---> ', this.description);
    }
    onAllergyTypeChange(event) {
        this.selectedAllergyType = event.target.value;
        console.log('**** selectedAllergyType ---> ', this.selectedAllergyType);
    }
    onAdverseCodeChange(event) {
        this.selectedAdverseCode = event.target.value;
        console.log('**** selectedAdverseCode ---> ', this.selectedAdverseCode);
    }
    onReactionsChange(event) {
        this.selectedReaction = event.target.value;
        console.log('**** selectedReaction ---> ', this.selectedReaction);
    }
    onSeverityChange(event) {
        this.selectedSeverity = event.target.value;
        console.log('**** selectedSeverity ---> ', this.selectedSeverity);
    }

    validateRequiredAllergies() {
        
    }

    saveAllergy() 
    {
        this.showSpinner = true;
        let allergy = {
            name: this.name,
            onsetDate: this.onsetDate,
            endDate: this.endDate,
            allergyType: parseInt(this.selectedAllergyType),
            adverseEventCode: this.selectedAdverseCode,
            reactionId: parseInt(this.selectedReaction),
            severityCode: this.selectedSeverity,
            comment: this.description,
            accountId: this.accountid,
            patientId: parseInt(this.patientid),
            //irisOnly: this.isIrisOnly
            irisOnly: this.irisonly
        };

        console.log('**** allergy ---> ', allergy);

        let strAllergyJson = JSON.stringify(allergy);

        createUpdatePatientAllergy({jsonAllergy: strAllergyJson, isUpdate: this.allergyRecordId != null, recordId: this.allergyRecordId})
        .then(savedId => {
            if (savedId) {
                this.allergyRecordId = savedId;
                this.notifyUser('Success!', 'Allergy was saved successfully.', 'success');
                if (this.isSaveNew) {
                    this.clearValues();
                    this.dispatchEvent(new CustomEvent('closeformopensearch'));
                } else {
                    this.dispatchEvent(new CustomEvent('closeallergyformmodal'));
                }
            } else {
                this.notifyUser('Error', 'Something went wrong while saving the Allergy. Please contact your Administrator', 'error');
            }
            
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while saving the Allergy.', 'error');
            this.showSpinner = false;
            console.error('**** Form Data Error: ', error);
        });
    }

    save() {
        this.saveAllergy();
    }

    saveAndNew() {
        this.isSaveNew = true;
        this.saveAllergy();
    }

    clearValues() {
        this.name = null;
        this.allergytoedit = null;
        this.onsetDate = null;
        this.endDate = null;
        this.selectedAllergyType = null;
        this.selectedReaction = null;
        this.selectedSeverity = null;
        this.description = null;
    }
}