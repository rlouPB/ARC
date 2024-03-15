import { LightningElement, api, track, wire } from 'lwc';
import Prescription_Object from '@salesforce/schema/Prescription__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class DispensingHistory extends LightningElement {
    @api recordId

    @track
    selectedId

    @wire(getObjectInfo, {objectApiName: Prescription_Object})
    prescriptionInfo

    get keyPrefix(){
        return this.prescriptionInfo?.data?.keyPrefix
    }

    get isPatient(){
        return `${this.recordId}`.startsWith('001')
    }

    get isPrescription(){
        return this.recordId && this.keyPrefix && `${this.recordId}`.startsWith( this.keyPrefix )
    }

    get patientFilter(){
        return `AND Patient__c='${this.recordId}' AND Status__c = 'Finalized'`
    }

    get prescriptionFilter(){
        return `AND Prescription__c='${this.recordId}' AND Status__c = 'Finalized'`
    }
    
    eventClickHandler(e){
        this.selectedId = e.detail.event.id
    }

    closeDialog(e){
        this.selectedId = undefined
    }

    openPrintedLastDispensedMeds() {
        var pdfUrl = "/apex/PrintedLastDispensedMedsPDF?accountId="+this.recordId
        window.open(pdfUrl);
    }
}