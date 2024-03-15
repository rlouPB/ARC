import { api, track, LightningElement } from 'lwc';
import getFieldDefinitions from '@salesforce/apex/DispensingService.getFieldDefinitions'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class DispensingPrescriptionPackage extends LightningElement {

    @api
    showSpinner

    @track
    metadataLoaded

    @track
    fieldsMetadata=[]

    get inputFields(){
        return Array.from( this.template.querySelectorAll('lightning-input-field') )
    }

    @api
    async getRecord(patientId) {
        let me = this
        return new Promise((resolve) => {            
            let record = this.inputFields
            .filter( (input) => input.value != undefined)
            .reduce( (acc,cur) => ({...acc, [cur.fieldName]: cur.value}), {sobjectType:'Package__c',Patient__c:patientId})

            console.info("package record ===> ", JSON.parse(JSON.stringify(record)))

            resolve( record )
        })
    }

    @api
    isValid(){
        // this.template.querySelector('lightning-record-edit-form').submit()  
        let formIsValid = true   
        this.inputFields.forEach(element => {
            console.log('Field is==> ' + element.fieldName);
            console.log('Field is==> ' + element.value);
            if('Start_Date__c' == element.fieldName) {
                if(null == element.value) {
                    this.toast("Start Date is required.","Error","error");
                    formIsValid = false;
                } else {
                    var startDateInput = Date.parse(element.value);
                    if(new Date().setUTCHours(0,0,0,0) > startDateInput) {
                        this.toast("Enter a Start Date in the future.","Error","error");
                        formIsValid = false;
                    }
                }
            }
        });
        return formIsValid;
    }

    @api
    getStartDate() {
        let retVal = ''
        this.inputFields.forEach(element => {
            if('Start_Date__c' == element.fieldName) {
                retVal = element.value;
            }
        });
        return retVal
    }

    @api
    getEndDate() {
        let retVal = ''
        this.inputFields.forEach(element => {
            if('End_Date__c' == element.fieldName) {
                retVal = element.value;
            }
        });
        return retVal
    }

    @api
    getPackageDeliveryETA() {
        let retVal = ''
        this.inputFields.forEach(element => {
            if('Package_Delivery_ETA__c' == element.fieldName) {
                retVal = element.value;
            }
        });
        return retVal
    }

    onSubmitHandler(e) {
        e.preventDefault();
    }

    async onloadHandler(e){
        if( this.metadataLoaded ) {
            return
        }
        this.metadataLoaded = true
        let fieldNames = this.inputFields.map(x=>x.fieldName)
        this.fieldsMetadata = await getFieldDefinitions({ sobjectType:'Package__c', fieldNames })
    }

    toast(message,title='alert',variant='info') {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}