import { api, LightningElement } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import cancelPackages from '@salesforce/apex/DispensingService.cancelPackages'

export default class DispensingCancelPackageModalLwc extends LightningElement {
    @api
    recordId

    closePanel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async cancelRecord(){
        let packageIds = [this.recordId];
        console.log('packageIds : ', packageIds)
        let cancelResult = await cancelPackages({
            packageIds : packageIds       
        })
        console.log('cancelResult : ', cancelResult)
        if(cancelResult) {
            this.toast( cancelResult ,'Error','error')
        } else {
            this.closePanel()
            this.toast("Packages successfully canceled.",'','success')
            eval("$A.get('e.force:refreshView').fire();")
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