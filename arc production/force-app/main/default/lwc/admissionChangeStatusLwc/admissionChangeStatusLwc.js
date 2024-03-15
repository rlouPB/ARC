import { api, LightningElement, track, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import PRESCRIPTION_OBJECT from '@salesforce/schema/Prescription__c';
import ADMISSION_ID_FROM_ACCOUNT from '@salesforce/schema/Account.Current_Admission__c';
import ADMISSION_ID_FROM_PRESCRIPTION from '@salesforce/schema/Prescription__c.Account__r.Current_Admission__c';

export default class AdmissionChangeStatusLwc extends LightningElement {
    @api
    recordId

    @wire(getRecord, { recordId: '$recordId', fields: [ADMISSION_ID_FROM_ACCOUNT] })
    account;

    @wire(getRecord, { recordId: '$recordId', fields: [ADMISSION_ID_FROM_PRESCRIPTION] })
    prescription;

    @track
    showPopup

    fields='Dispensing_Status__c,MSA_Schedule__c,MSA_Pickup_Location__c'.split(',')

    get admissionId(){
        return this.admissionIdFromAccount || this.admissionIdFromPrescription
    }

    get admissionIdFromAccount() {
        return this.account.data ? getFieldValue(this.account.data, ADMISSION_ID_FROM_ACCOUNT) : '';
    }

    get admissionIdFromPrescription() {
        return this.prescription.data ? getFieldValue(this.prescription.data, ADMISSION_ID_FROM_PRESCRIPTION) : '';
    }

    onChangeStatusClick(e){
        this.showPopup=true
    }
    onCancelHandler(e){
        this.dispatchEvent(new CustomEvent('cancel') )
        this.showPopup = false
    }
    onSuccessHandler(e){
        this.dispatchEvent(new CustomEvent('success') )
        this.showPopup = false
    }
    onErrorHandler(e){
        this.dispatchEvent(new CustomEvent('error',{detail: e.detail}) )
    }
}