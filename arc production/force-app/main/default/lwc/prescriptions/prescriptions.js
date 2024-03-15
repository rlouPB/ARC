import { LightningElement, track, api, wire} from 'lwc';
import updateRecord from '@salesforce/apex/CustomDataService.updateRecord'
import insertPackage from '@salesforce/apex/DispensingService.insertPackage'
import updateRecords from '@salesforce/apex/CustomDataService.updateRecords'
import finalizePrescriptions from '@salesforce/apex/DispensingService.finalizePrescriptions'
import dispensePrescriptions from '@salesforce/apex/DispensingService.dispensePrescriptions'
import cleardDispensedPrescriptions from '@salesforce/apex/DispensingService.cleardDispensedPrescriptions'
import clearDispensedPrescriptionsForPrescriptions from '@salesforce/apex/DispensingService.clearDispensedPrescriptionsForPrescriptions'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import isExternalScriptSureUser from '@salesforce/apex/ScriptSureController.isExternalScriptSureUser';
import validateRequiredFields from "@salesforce/apex/ScriptSureController.validateRequiredFields";
import pullPrescriptions from "@salesforce/apex/ScriptSureController.pullPrescriptions";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import EXTERNAL_PATIENT_ID_FROM_ACCOUNT from '@salesforce/schema/Account.External_Patient_Id__c';
import { publish, MessageContext } from 'lightning/messageService';
import medicationDispensed from '@salesforce/messageChannel/medicationDispensed__c';
import checkPerms from '@salesforce/apex/PermissionUtils.checkPerms';
import getPrescription from '@salesforce/apex/DispensingService.getPrescription';
import getAccount from "@salesforce/apex/ScriptSureController.getAccount";

export default class Prescriptions extends LightningElement {
    @wire(MessageContext)
    messageContext;

    @api
    recordId

    @wire(getRecord, { recordId: '$recordId', fields: [EXTERNAL_PATIENT_ID_FROM_ACCOUNT] })
    account;
    
    @track
    modeOptions = 'Show All;Show Active'.split(';').map(x=>{return {label:x,value:x}})

    @track
    mode='Show Active'

    @track
    fillId

    @track
    fillHeaderStr

    @track
    openPackage

    selectedIds
    @track showScriptSureModal = false;
    @api externalpatientid = '';
    @track displayScriptSureButton = false;
    @track
    showSpinner=false
    @track
    hasPackageAndPrintButtons

    get hasFillId(){
        return this.fillId ? true : false
    }

    get table(){
        return this.template.querySelector('c-dispensing-prescriptions-table')
    }

    async connectedCallback() {

        isExternalScriptSureUser()
        .then(result => {
            this.displayScriptSureButton = result;
            console.log('**** IsExternalUser ---> ', result);
        })
        .catch(error => {
            this.toast('Form data Error', 'An error occured while getting user information', 'error');
            console.error('Form Data Error: ', error);
        });
        this.hasPackageAndPrintButtons = await checkPerms({perms: 'DispensingShowPackagePrintBtns'})
    }

    modalclosed() {
        this.showScriptSureModal = false;
        // this.pullPrescriptions();
    }


    pullPrescriptions() {
        // this.externalpatientid = this.account.data ? getFieldValue(this.account.data, EXTERNAL_PATIENT_ID_FROM_ACCOUNT) : '';
        
        if(null == this.externalpatientid || '' == this.externalpatientid) {
            getAccount({accountId: this.recordId}).then(account => {
                this.externalpatientid = account.External_Patient_Id__c
                console.log('##### externalPatientId #2 ---> ', this.externalpatientid);
                this.pullPrescriptions()
            });
        } else {
            console.log('##### externalPatientId ---> ', this.externalpatientid);
            console.log('##### accountId ---> ', this.recordId);
            console.log('##### AQ Testing---> ');
            pullPrescriptions({externalPatientId: this.externalpatientid, accountId: this.recordId})
            .then(prescriptions => {
                console.log('##### prescriptions ---> ', prescriptions);
                if (prescriptions) {
                    this.template.querySelector('c-dispensing-prescriptions-table').load();
                }
            })
            .catch(error => {
                this.toast('Form data Error', error.body.message, 'error');
                console.error('Form Data Error: ', error);
            });
        }
    }

    openScriptSureModal() {

        if (this.externalpatientid && this.externalpatientid !== '') {
            this.showScriptSureModal = true;
            return;
        }
       
        validateRequiredFields({patientContactId: this.recordId})
        .then(missingFields => {
            if (missingFields != null && missingFields != undefined && missingFields == "") {
                this.showScriptSureModal = true;
            } else {
                this.toast('Form data Error', 'These required fields are missing: ' + missingFields, 'error');
            }
        })
        .catch(error => {
            this.toast('Form data Error', 'An error occured while validating Patient required information', 'error');
            console.error('Form Data Error: ', error);
        });
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

    onPackageClickHandler(e){        
        let selectedIds = this.table.selectedRowIds
        if (!selectedIds?.length ){
            this.toast('Please select one or more prescriptions to package.','','warn')
        }else {
            this.openPackage = true
            this.selectedIds = selectedIds;
        }
    }

    async dispenseClickHandler(e){
        this.showSpinner=true
        let selectedIds = this.table.selectedRowIds
        if( selectedIds.length == 0 ) {
            this.toast('You need to select at least one medication to dispense.','','error')
        } else {
            let nonActivePrescriptions = this.table.getRecords().filter(x=>x.Status__c != "Active")
            const result = nonActivePrescriptions.filter(function(value) {
                if(selectedIds.includes(value.Id)) {
                    return value;
                }
            })
            if(result.length > 0){
                this.toast('You can only dispense active medications.','','error')
            } else {

                let results = await dispensePrescriptions({
                    prescriptionIds: selectedIds,
                    patientId: this.recordId
                })

                console.log('results : ', results)
                console.log('results.length : ', results.length)
                if(results.length == 0 || results.length == 15 || results.length == 18){
                    this.toast("Records Dispensed",'','success')
                    this.refreshTable()
                    // const payload = { message: 'reload dispensing history' };
                    // publish(this.messageContext, medicationDispensed, payload);
                    this.showSpinner=false
                    if(results.length == 15 || results.length == 18) {
                        window.open('/lightning/r/disco__Form__c/' + results + '/edit');
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
        this.showSpinner=false
    }

    async clearDispensedClickHandler(e){
        this.showSpinner=true
        let selectedIds = this.table.selectedRowIds
        if( selectedIds.length > 0 ){
            let prescriptions = selectedIds.map(x=>{
                return { Id:x }
            })
            console.log('prescriptions : ', prescriptions)
            await clearDispensedPrescriptionsForPrescriptions({prescriptionIdsArr:prescriptions})
        } else {
            await cleardDispensedPrescriptions({accountId: this.recordId})
        }
        this.refreshTable()
        const payload = { message: 'reload dispensing history' };
        publish(this.messageContext, medicationDispensed, payload);
        this.showSpinner=false
    }

    get popup(){
        return this.template.querySelector('c-modal-popup-lwc')
    }

    get table(){
        return this.template.querySelector('c-dispensing-prescriptions-table')
    }
    

    async finalizeClickHandler(e, skipCheck) {
        this.showSpinner=true
        let me = this
        let dispensedList = this.table.getRecords().filter(x=>x.Dispensed__c).map(x=>x.Medication_Finalize_Display__c || x.Medication_Filled_with__c || x.Drug_Name__c)
        if(dispensedList.length == 0){
            me.toast('Please Dispense first and then Finalize.','','error')
            this.showSpinner=false
            return
        }
        let ul = dispensedList.map(x=>`<li>${x}</li>`).join('')
        let result = await this.popup.confirm(
            `Are you sure you want to finalize the following dispensed medications?  <br/> <ul>${ul}</ul>`
        )
        if ( result ) {
            let finalizeResult = await finalizePrescriptions({
                prescriptionIds : me.table.dispensedIds,
                patientId: me.recordId                
            })
            if(finalizeResult) {
                me.toast( finalizeResult ,'Error','error')
                this.showSpinner=false
            }else {
                me.toast("Dispensed Records Finalized",'','success')
                me.refreshTable()
                const payload = { message: 'reload dispensing history' };
                publish(this.messageContext, medicationDispensed, payload);
                this.showSpinner=false
            }
        }
        this.showSpinner=false
    }

    fillCmp(){
        return this.template.querySelector('c-dispensing-prescription-fill')
    }

    packageCmp(){
        return this.template.querySelector('c-dispensing-prescription-package')
    }

    closeFillModal(e){
        this.fillId = null
    }

    closePackageModal(e){
        this.openPackage = false
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

    async packageSaveClickHandler(e){
        console.info('packageSaveClickHandler');
        let myPackage = this.packageCmp()
        if ( !myPackage.isValid() ) {
            return
        } else {
            this.packageCmp().showSpinner = true;
            let record = await myPackage.getRecord(this.recordId)
            
            let prescriptions = this.selectedIds.map(x=>{
                return { Id:x }
            })
            console.log('prescriptions : ', prescriptions)

            let insertResult = await insertPackage( {record, prescriptionIdsArr:prescriptions})
            if( !insertResult ){
                this.closePackageModal()
                this.toast("Package created.",'','success')            
                // this.refreshTable()
            }else{
                this.toast(insertResult,"Error",'error')
            }
            this.packageCmp().showSpinner = false;
            this.openPackage = false
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

    enableDispensingButton() {
        const dispensePrescriptionBtn = this.template.querySelector('[data-id="dispensePrescriptionBtn"]');
        dispensePrescriptionBtn.disabled = false;
    }

    disableDispensingButton() {
        const dispensePrescriptionBtn = this.template.querySelector('[data-id="dispensePrescriptionBtn"]');
        dispensePrescriptionBtn.disabled = true;
    }
}