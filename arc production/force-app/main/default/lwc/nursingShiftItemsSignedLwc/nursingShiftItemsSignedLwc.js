import { LightningElement, track, api, wire  } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAllNursingShiftAssigments from '@salesforce/apex/NursingShiftService.getAllNursingShiftAssigments';
import getMyNursingShiftAssigments from '@salesforce/apex/NursingShiftService.getMyNursingShiftAssigments';
import { NavigationMixin } from 'lightning/navigation';

export default class NursingShiftItemsSignedLwc extends NavigationMixin(LightningElement) {
    @track
    data

    connectedCallback(){ 
        this.load()       
    }

    async load(){
        //this.data = await getAllNursingShiftAssigments()
        this.data = await getMyNursingShiftAssigments();
    }

    async reloadAll(){
        let items = this.template.querySelectorAll('c-nursing-shift-items-by-shift-lwc')
        for( let item of items){
            item.load()
        }
    }

    get nursingShifts(){
        return [...new Set( (this.data?this.data:[]).map(x=>x.Nursing_Shift__c ))]
    }

    handleRowAction(e){
        const actionName = e.detail.action.name;
        const row = e.detail.row;
        if(actionName == 'view_details'){
            let recordId = this.recordId;
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes:{
                    recordId: row.Id,
                    actionName:'view'
                }
            })
        }
    }
}