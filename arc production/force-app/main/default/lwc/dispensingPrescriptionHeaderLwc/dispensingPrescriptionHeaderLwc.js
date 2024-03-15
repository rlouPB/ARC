import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { api, LightningElement, wire } from 'lwc';
import ACCOUNT_FIELD from '@salesforce/schema/Prescription__c.Account__c';

export default class DispensingPrescriptionHeaderLwc extends LightningElement {
    @api
    recordId

    @wire( getRecord, { recordId:'$recordId', fields:[ACCOUNT_FIELD]} )
    prescription

    get accountId(){
        return getFieldValue(this.prescription.data,ACCOUNT_FIELD)
    }
}