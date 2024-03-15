import { LightningElement, track, api, wire} from 'lwc';
import updateRecord from '@salesforce/apex/CustomDataService.updateRecord'
import updateRecords from '@salesforce/apex/CustomDataService.updateRecords'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class PharmacyOrdersToProcessContainerLwc extends LightningElement {
    
    @track
    showSpinner=false
    selectedIds
    
    get table(){
        return this.template.querySelector('c-pharmacy-orders-to-process-table-lwc')
    }

    onActionHandler(e){
        alert(JSON.stringify(e.detail))
    }

    async onMarkAsCompleteClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        if (selectedIds?.length == 0){
            this.toast('Please select script(s) to mark as complete.','','warn')
        }else {
            let allRecords = this.table.getRecords()
            console.log('allRecords : ', allRecords)
            console.log('selectedIds : ', selectedIds)
            let res = allRecords.filter(
                function(e) {
                    return this.indexOf(e.Id) >= 0;
                  },
                  selectedIds
            );
            console.log(res);
            let hasError = false;
            for (var i = 0; i < res.length; i++) {
                res[i].Pharmacy_Complete__c = true
            }

            if(!hasError) {
                console.log('res : ', res)
                let results = await updateRecords({
                    records : res               
                })
                console.log('results : ', results)
                if(!results){
                    this.toast("Records Completed",'','success')
                    this.refreshTable()
                    this.showSpinner=false
                } else{
                    this.toast(results,"Error",'error')
                    this.showSpinner=false
                }
                this.table.clearSelected()
            }
        }
    }
    
    refreshTable(){
        this.table.load()
        this.table.clearSelected()
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