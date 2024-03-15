import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class RecordLink extends NavigationMixin(LightningElement) {
    @api
    recordId

    @api
    recordName

    @api
    target = '_blank';
    
    get hrefUrl(){
        return `/${this.recordId}`
    }

    handleClick(e){
        e.preventDefault();
        let recordId = this.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes:{
                recordId: recordId,
                actionName:'view'
            }
        })
    }
}