import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Photo__c from '@salesforce/schema/Account.Photo__c';
import External_Patient_Id__c from '@salesforce/schema/Account.External_Patient_Id__c';

export default class DispensingPatientHeaderLwc extends LightningElement {
    @api
    recordId

    @wire(getRecord, {
        recordId: '$recordId', fields: [
            'Account.Photo__c',
            'Account.External_Patient_Id__c',
        ]
    })
    account;

    get firstColumnSize() {
        return this.photo ? 5 : 6
    }

    get hasAccount() {
        return this.account?.data ? true : false
    }

    get externalPatientId() {
        return this.account?.data ? getFieldValue(this.account?.data, External_Patient_Id__c) : '';
    }
    get photo() {
        return this.account?.data ? getFieldValue(this.account?.data, Photo__c) : '';
    }
}