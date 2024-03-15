import { LightningElement, api } from 'lwc';

export default class DispensingHistoryPatientLwc extends LightningElement {
    @api patientId

    get filter(){
        return ` AND Patient__c='${this.patientId}'`
    }
}