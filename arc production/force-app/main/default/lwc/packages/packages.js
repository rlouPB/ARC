import { LightningElement, track, api, wire } from 'lwc';
import updateRecord from '@salesforce/apex/CustomDataService.updateRecord'
import updateRecords from '@salesforce/apex/CustomDataService.updateRecords'
import dispensePackages from '@salesforce/apex/DispensingService.dispensePackages'
import finalizePackages from '@salesforce/apex/DispensingService.finalizePackages'
import printPackages from '@salesforce/apex/DispensingService.printPackages'
import cancelPackages from '@salesforce/apex/DispensingService.cancelPackages'
import clearDispensedPackages from '@salesforce/apex/DispensingService.clearDispensedPackages'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { publish, MessageContext } from 'lightning/messageService';
import medicationDispensed from '@salesforce/messageChannel/medicationDispensed__c';
import checkPerms from '@salesforce/apex/PermissionUtils.checkPerms';
import getPackage from '@salesforce/apex/DispensingService.getPackage';

export default class Packages extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @api
    recordId
    
    @track
    modeOptions = 'Show All;Show New'.split(';').map(x=>{return {label:x,value:x}})

    @track
    mode='Show New'

    selectedIds

    @track
    showSpinner=false
    @track
    hasPackageAndPrintButtons
    
    get table(){
        return this.template.querySelector('c-dispensing-packages-table')
    }

    async connectedCallback() {
        this.hasPackageAndPrintButtons = await checkPerms({perms: 'DispensingShowPackagePrintBtns'})
    }

    modeChangeHandler(e){
        debugger;
        this.mode = e.detail.value
        this.table.changeMode( e.detail.value )
    }

    onActionHandler(e){
        alert(JSON.stringify(e.detail))
    }

    async dispenseClickHandler(e){
        this.showSpinner=true
        let selectedIds = this.table.selectedRowIds
        if( selectedIds.length == 0 ){
            this.toast('You need to select a package to dispense.','','warn')
        } else if (selectedIds?.length > 1 || !selectedIds?.length) {
            this.toast('Please dispense one package at a time.','','warn')
        } else{
            let targetId = selectedIds[0];
            let myPackage = await getPackage({packageId: targetId});
            if(undefined != myPackage) {
                if("New" != myPackage.Status__c) {
                    this.selectedIds = this.table.selectedRowIds.filter(x=>x != targetId)
                    this.toast('', 'You can only dispense new packages.', 'error');
                } else {
                    let results = await dispensePackages({
                        packageIds : selectedIds,
                        patientId: this.recordId                
                    })
                    console.log('results : ', results)
                    console.log('results.length : ', results.length)
                    if(results.length == 0 || results.length == 15 || results.length == 18){
                        this.toast("Records Dispensed",'','success')
                        this.refreshTable()
                        this.showSpinner=false
                        if(results.length == 15 || results.length == 18) {
                            // window.open('/lightning/r/disco__Form__c/' + results + '/edit');
                            window.open('/apex/disco__CompleteForm?Id=' + results + '&edit=true', "_blank", "height=1000");
                        }
                        setTimeout(() => {
                            this.finalizeClickHandler(e)
                        },1000)
                    } else{
                        this.toast(results,"Error",'error')
                        this.showSpinner=false
                    }
                }
            }
        }
        
        this.showSpinner=false
    }

    async clearDispensedClickHandler(e){
        this.showSpinner=true
        await clearDispensedPackages({accountId: this.recordId})
        this.refreshTable()
        // const payload = { message: 'reload dispensing history' };
        // publish(this.messageContext, medicationDispensed, payload);
        this.showSpinner=false
    }

    get popup(){
        return this.template.querySelector('c-modal-popup-lwc')
    }

    get table(){
        return this.template.querySelector('c-dispensing-packages-table')
    }
    
    async finalizeClickHandler(e) {
        this.showSpinner=true
        let me = this
        let dispensedList = this.table.getRecords().filter(x=>x.Dispensed__c).map(x=>x.Package_Name_Fml__c || x.Name)
        if(dispensedList.length == 0){
            me.toast('Please Dispense first and then Finalize.','','error')
            this.showSpinner=false
            return
        }
        let ul = dispensedList.map(x=>`<li>${x}</li>`).join('')
        let result = await this.popup.confirm(
            `Are you sure you want to finalize the following dispensed packages?  <br/> <ul>${ul}</ul>`
        )
        if ( result ) {
            let finalizeResult = await finalizePackages({
                packageIds : me.table.dispensedIds,
                patientId: me.recordId                
            })
            console.log('finalizeResult : ', finalizeResult)
            if(finalizeResult) {
                me.toast( finalizeResult ,'Error','error')
                this.showSpinner=false
            } else {
                me.toast("Dispensed Records Finalized",'','success')
                me.refreshTable()
                const payload = { message: 'reload dispensing history' };
                publish(this.messageContext, medicationDispensed, payload);
                this.showSpinner=false
            }
        }
        this.showSpinner=false
    }

    async printClickHandler(e) {
        this.showSpinner=true
        let selectedIds = this.table.selectedRowIds
        if( selectedIds.length == 0 ){
            this.toast('You need to select a package to print.','','warn')
        } else{
            let results = await printPackages({
                packageIds : selectedIds              
            })
            console.log('results : ', results)
            console.log('results.length : ', results.length)
            if(results.length == 15 || results.length == 18){
                this.showSpinner=false
                if(results.length == 15 || results.length == 18) {
                    // window.open('/apex/SDOC__SDCreate1?id=' + results + '&Object=SDocCallableParent__c&doclist=PackagesPrintingTemplate&autoopen=0');
                    var pdfUrl = "/apex/PrintedDispensingPackagesPDF?Ids="+results;
                    window.open(pdfUrl);
                }
            } else{
                this.toast(results,"Error",'error')
                this.showSpinner=false
            }
        }
        this.showSpinner=false
    }

    async cancelClickHandler(e) {
        this.showSpinner=true
        let selectedIds = this.table.selectedRowIds
        let me = this
        let selectedList = this.table.getRecords().filter(x=>selectedIds.includes(x.Id)).map(x=>x.Package_Name_Fml__c || x.Name)
        if(selectedList.length == 0){
            return
        }
        let ul = selectedList.map(x=>`<li>${x}</li>`).join('')
        let result = await this.popup.confirm(
            `Are you sure you want to cancel the following packages?  <br/> <ul>${ul}</ul>`
        )
        if ( result ) {
            let targetId = selectedIds[0];
            let myPackage = await getPackage({packageId: targetId});
            if(undefined != myPackage) {
                if("New" != myPackage.Status__c) {
                    this.selectedIds = this.table.selectedRowIds.filter(x=>x != targetId)
                    this.toast('', 'You can only cancel new packages.', 'error');
                } else {
                    let cancelResult = await cancelPackages({
                        packageIds : selectedIds         
                    })
                    console.log('cancelResult : ', cancelResult)
                    if(cancelResult) {
                        me.toast( cancelResult ,'Error','error')
                        this.showSpinner=false
                    } else {
                        me.toast("Packages successfully canceled.",'','success')
                        me.refreshTable()
                        this.showSpinner=false
                    }
                }
            }            
        }
        this.showSpinner=false
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

    enableDispensingButton() {
        const dispensePackageBtn = this.template.querySelector('[data-id="dispensePackageBtn"]');
        dispensePackageBtn.disabled = false;
    }

    disableDispensingButton() {
        const dispensePackageBtn = this.template.querySelector('[data-id="dispensePackageBtn"]');
        dispensePackageBtn.disabled = true;
    }
}