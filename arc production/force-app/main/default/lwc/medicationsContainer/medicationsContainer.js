import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isExternalScriptSureUser from '@salesforce/apex/ScriptSureController.isExternalScriptSureUser';
import validateRequiredFields from "@salesforce/apex/ScriptSureController.validateRequiredFields";
import pullPrescriptions from "@salesforce/apex/ScriptSureController.pullPrescriptions";
import getAccount from "@salesforce/apex/ScriptSureController.getAccount";

export default class MedicationsContainer extends LightningElement {
    @track showModal = false;
    @api externalpatientid = '';
    @api recordId = '';
    @track displayScriptSureButton = false;

    @track
    modeOptions = 'Show All;Show Active'.split(';').map(x=>{return {label:x,value:x}})

    @track
    mode='Show Active'

    modeChangeHandler(e){
        this.mode = e.detail.value
        this.table.changeMode( e.detail.value )
    }

    get table(){
        return this.template.querySelector('c-clinical-prescriptions-table')
    }

    connectedCallback() {

        isExternalScriptSureUser()
        .then(result => {
            this.displayScriptSureButton = result;
            console.log('**** IsExternalUser ---> ', result);
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while getting user information', 'error');
            console.error('Form Data Error: ', error);
        });
    }



    modalclosed() {
        this.showModal = false;
        // this.pullPrescriptions();
    }


    pullPrescriptions() {
        // this.externalpatientid = this.account.data ? getFieldValue(this.account.data, EXTERNAL_PATIENT_ID_FROM_ACCOUNT) : '';
        
        if(null == this.externalpatientid || '' == this.externalpatientid) {
            getAccount({accountId: this.recordId}).then(account => {
                this.externalpatientid = account.External_Patient_Id__c
                console.log('##### externalPatientId #2 ---> ', this.externalpatientid);
                this.pullPrescriptions()
            });
        } else {
            console.log('##### externalPatientId ---> ', this.externalpatientid);
            console.log('##### accountId ---> ', this.recordId);
            console.log('##### AQ Testing---> ');
            pullPrescriptions({externalPatientId: this.externalpatientid, accountId: this.recordId})
            .then(prescriptions => {
                console.log('##### prescriptions ---> ', prescriptions);
                if (prescriptions) {
                    this.template.querySelector('c-clinical-prescriptions-table').load();
                }
            })
            .catch(error => {
                this.toast('Form data Error', error.body.message, 'error');
                console.error('Form Data Error: ', error);
            });
        }
    }

    // openModal() {
    //     this.showModal = true;
    // }
    openScriptSureModal() {

        if (this.externalpatientid && this.externalpatientid !== '') {
            this.showModal = true;
            return;
        }
       

        validateRequiredFields({patientContactId: this.recordId})
        .then(missingFields => {
            if (missingFields != null && missingFields != undefined && missingFields == "") {
                this.showModal = true;
            } else {
                this.notifyUser('Form data Error', 'These required fields are missing: ' + missingFields, 'error');
            }
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while validating Patient required information', 'error');
            console.error('Form Data Error: ', error);
        });
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
}