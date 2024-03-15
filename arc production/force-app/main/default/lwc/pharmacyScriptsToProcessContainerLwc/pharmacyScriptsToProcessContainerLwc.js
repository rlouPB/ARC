import { LightningElement, track, api, wire} from 'lwc';
import updateRecord from '@salesforce/apex/CustomDataService.updateRecord'
import updateRecords from '@salesforce/apex/CustomDataService.updateRecords'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import getPrescription from '@salesforce/apex/DispensingService.getPrescription';
import clonePrescription from '@salesforce/apex/DispensingService.clonePrescription';

export default class PharmacyScriptsToProcessContainerLwc extends LightningElement {
    
    @track
    modeOptions = 'All;Active Pending Fill;Discontinued;Source Script'.split(';').map(x=>{return {label:x,value:x}})

    @track
    mode='All'

    @track
    fillId

    @track
    fillHeaderStr

    @track
    showSpinner=false
    selectedIds
    
    get hasFillId(){
        return this.fillId ? true : false
    }

    modeChangeHandler(e){
        debugger;
        this.mode = e.detail.value
        this.table.changeMode( e.detail.value )
    }

    onActionHandler(e){
        alert(JSON.stringify(e.detail))
    }

    async onFillClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        if ( selectedIds?.length > 1 || !selectedIds?.length ){
            this.toast('Please select one at a time to fill.','','warn')
        }else {
            let targetId = selectedIds[0]
            let prescription = await getPrescription({prescriptionId: targetId});
            if(undefined != prescription && undefined != prescription.Status__c && "Active Pending Fill" != prescription.Status__c) {
                this.toast('The status has to be "Active Pending Fill" in order to Fill.','','error')
            } else {
                this.fillHeaderStr = "Fill - " + prescription.Drug_Name__c + " - " + prescription.Drug_Format__c;
                this.fillId = selectedIds[0]
            }
        }
    }

    async onCloneClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        let targetId = selectedIds[0]
        if ( selectedIds?.length > 1 || !selectedIds?.length ){
            this.toast('Please select one at a time to clone.','','warn')
        }else {
            let prescription = await getPrescription({prescriptionId: targetId});
            if(undefined != prescription && undefined != prescription.Status__c && "Active Pending Fill" != prescription.Status__c && "Source Script" != prescription.Status__c) {
                this.toast('The status has to be "Active Pending Fill" or "Source Script" in order to Clone.','','error')
            } else if(undefined != prescription && null != prescription.Parent__c) {
                this.toast('You cannot clone a line script prescription, please clone the original prescription instead.','','error')
            } else {
                this.popup.confirm(`Are you sure you want to clone this prescription? You will no longer be able to Fill it aftewards.`).then(async (res)=>{
                    if(res){
                        this.loading = true
                        try{
                            let prescription = await clonePrescription({prescriptionId: targetId});
                            if(prescription) {
                                this.toast('Success', 'A new line script prescription has been created.','success')
                                this.refreshTable()
                            } else {
                                this.toast('Error', 'There was an error cloning the prescription.','error')
                            }
                        } catch(err) {
                            console.info('*****ERROR ON onCloneClickHandler*****', err)
                        }
                        this.loading = false
                    }
                })
            }
        }
    }

    async onDiscontinueClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        if (selectedIds?.length == 0){
            this.toast('Please select script(s) to discontinue.','','warn')
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
                if('Discontinued' != res[i].Status__c && 'Canceled' != res[i].Status__c) {
                    this.toast('You selected a script that is not Discontinued or Canceled.',"Error",'error')
                    hasError = true
                    break;
                } else {
                    res[i].Pharmacist_Discontinued__c = true
                }
            }

            if(!hasError) {
                console.log('res : ', res)
                let results = await updateRecords({
                    records : res               
                })
                console.log('results : ', results)
                if(!results){
                    this.toast("Records Discontinued",'','success')
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

    async onCancelClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        if (selectedIds?.length == 0){
            this.toast('Please select script(s) to cancel.','','warn')
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
                if('Canceled' != res[i].Status__c) {
                    this.toast('You selected a script that is not Canceled.',"Error",'error')
                    hasError = true
                    break;
                } else {
                    res[i].Pharmacist_Canceled__c = true
                }
            }

            if(!hasError) {
                console.log('res : ', res)
                let results = await updateRecords({
                    records : res               
                })
                console.log('results : ', results)
                if(!results){
                    this.toast("Records Canceled",'','success')
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

    get popup(){
        return this.template.querySelector('c-modal-popup-lwc')
    }

    get table(){
        return this.template.querySelector('c-pharmacy-scripts-to-process-table-lwc')
    }
    
    fillCmp(){
        return this.template.querySelector('c-dispensing-prescription-fill')
    }

    closeFillModal(e){
        this.fillId = null
    }
    
    async fillSaveClickHandler(e){
        console.info('fillSaveClickHandler');
        let fill = this.fillCmp()
        if ( !fill.isValid() ) {
            return
        }
        let record = await fill.getRecord() 
        record.Status__c = 'Active'
        record.IRIS_Fill_Datetime__c = new Date();
        let updateResult = await updateRecord( {record} )
        if( !updateResult ){
            this.closeFillModal()
            this.toast("Record Saved",'','success')            
            this.refreshTable()
        }else{
            this.toast(updateResult,"Error",'error')
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