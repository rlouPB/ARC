import { api, track, LightningElement } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateRecord from '@salesforce/apex/CustomDataService.updateRecord'
import getPrescription from '@salesforce/apex/DispensingService.getPrescription';

export default class DispensingPrescriptionFillModal extends LightningElement {
    @api
    recordId

    @track
    fillHeaderStr

    async renderedCallback() {
        let prescription = await getPrescription({prescriptionId: this.recordId});
        this.fillHeaderStr = "Fill - " + prescription.Drug_Name__c + " - " + prescription.Drug_Format__c;
    }
    
    closePanel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async saveRecord(){
        let fill = this.template.querySelector('c-dispensing-prescription-fill')
        let record = await fill.getRecord()
        record.Status__c = 'Active'
        let updateResult = await updateRecord( {record} )
        if( !updateResult ){
            this.closePanel()
            this.toast("Record Saved",'','success')
            eval("$A.get('e.force:refreshView').fire();")
        }else{
            this.toast(updateResult,"Error",'error')
        }
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