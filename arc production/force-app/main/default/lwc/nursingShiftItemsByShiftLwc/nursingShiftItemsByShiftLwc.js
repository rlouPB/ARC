import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getNursingShiftPatientItems from '@salesforce/apex/NursingShiftService.getNursingShiftPatientItems';
import getMyNursingShiftPatientItems from '@salesforce/apex/NursingShiftService.getMyNursingShiftPatientItems'
import getNursingShiftItems from '@salesforce/apex/NursingShiftService.getNursingShiftItems';
import getMyNursingShiftItems from '@salesforce/apex/NursingShiftService.getMyNursingShiftItems';
import getNursingShiftItem from '@salesforce/apex/NursingShiftService.getNursingShiftItem';
import getNursingShiftItemsForPatient from '@salesforce/apex/NursingShiftService.getNursingShiftItemsForPatient';
import getMyNursingShiftItemsForPatient from '@salesforce/apex/NursingShiftService.getMyNursingShiftItemsForPatient';
import getMyNursingShiftAssigments from '@salesforce/apex/NursingShiftService.getMyNursingShiftAssigments';
import closeNursingShiftItem from '@salesforce/apex/NursingShiftService.closeNursingShiftItem';
import cancelShiftItem from '@salesforce/apex/NursingShiftService.cancelShiftItem';
import cancelShiftItemWithReasons from '@salesforce/apex/NursingShiftService.cancelShiftItemWithReasons';
import { getRecord } from 'lightning/uiRecordApi';
import DATE_FIELD from '@salesforce/schema/Nursing_Shift__c.Date__c';
import SHIFT_FIELD from '@salesforce/schema/Nursing_Shift__c.Shift__c';
import SHIFT_NUMBER_FIELD from '@salesforce/schema/Nursing_Shift__c.Shift_Number__c';
import GetRecordData from "@salesforce/apex/CustomRecordDataController.GetRecordData";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NSI_OBJECT from '@salesforce/schema/Nursing_Shift_Item__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Not_Performed_Reason_FIELD from '@salesforce/schema/Nursing_Shift_Item__c.Not_Performed_Reason__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NursingShiftItemsByShiftLwc extends NavigationMixin(LightningElement) {
    @api
    recordId

    @track
    Not_Performed_Reason__options=[]

    @track
    showCancelReasonsModal

    @track
    selectedCancelItemId

    @wire(getObjectInfo, { objectApiName: NSI_OBJECT })
    nsiObjectInfo

    @wire(getPicklistValues, { recordTypeId:'$nsiObjectInfo.data.defaultRecordTypeId', fieldApiName: Not_Performed_Reason_FIELD })
    NotPerformedReasonOptions

    @api
    columnArrangement = 'Default'
    
    get NotPerformedReasonOptionsValues(){
        return this.NotPerformedReasonOptions?.data?.values? this.NotPerformedReasonOptions?.data?.values : []
    }

    @track
    data

    @wire(getRecord, { recordId: '$recordId', fields: [DATE_FIELD, SHIFT_FIELD, SHIFT_NUMBER_FIELD] })
    nursingShift

    @track
    showModal

    @track
    accountIdItem_Name__c
    @api
    showAddNew

    @track
    iframeSrc

    @track
    selectedMode = 'Open'

    @api
    isPatientItems

    @api
    isFromPatientAccount

    @track
    sortBy

    @track
    sortDirection='asc'

    @track
    pagedData = []

    @track
    initialized

    @track
    showReassignModal

    @track
    iframeReassignSrc

    @api
    showReload

    @api
    showHeader

    @track
    loading

    @track
    selectedItemId

    @track
    NotPerformedReason

    @api 
    showOnlyMyItems=false

    get NotPerformedOtherReason_Required(){
        return this.NotPerformedReason == 'Other'
    }

    get selectedItemHeader(){
        return this.selectedItemId? this.dataItems.find(x=>x.id==this.selectedItemId).fields.find(x=>x.name=='itemName')?.value : ''
    }

    refreshPaginator() {
        setTimeout(() => this.template.querySelector('.paginator').pageChanged(), 100)
    }

    pageChangedHandler(e) {
        this.pagedData = e.detail.values
    }

    updateColumnSorting(e) {        
        this.updateTable(e.target.dataset.fieldname)
    }

    updateTable(fieldName) {
        console.log('fieldName is: ' + fieldName)
        
        let col = this.columns.find(x=>x.fieldName == fieldName)
        
        if( !col.sortable ){
            console.info(`${fieldName} is NOT sortable`)
            return
        }

        let sortDirection = this.sortDirection == 'asc' ? 'desc' : 'asc'

        col.isDESC = sortDirection == 'desc'
        col.sorted = true
        
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;

        console.info('******************************updateColumnSorting**********************')

        setTimeout(()=>this.refreshPaginator(), 500)
    }

    get modes() {
        return 'All,Open,Closed,Cancelled'.split(',').map(x => { return { label: x, value: x } })
    }

    @track
    columns = [
        { style:'width:150px;', label: 'Patient', fieldName: 'patientId', lookupName:'Patient__r.Name', type: 'lookup', lookupid:'Patient__r.Id', wrapText: true, typeAttributes: { nameField: 'Name' } },
        { style:'width:100px;', label: 'Status', fieldName: 'Status__c', sortable: true, fixedWidth: 10 },
        { style:'width:180px;', label: 'Item Name', fieldName: 'itemName', fieldNameOrList: [
            'Form__r.disco__Form_Template__r.DocType_Name__c',
            'Procedure_Order__r.Name',
            'Form__r.disco__Form_Template__r.Name',
            'Item_Name__c'
        ], sortable: true, wrapText: true },
        {
            style:'width:120px;',
            label: 'Due Date', fieldName: 'Due_Date__c', type: "date", sortable: true, wrapText: true,
            typeAttributes: {
                day: "numeric",
                month: "numeric",
                year: "numeric"
            }
        },
        { style:'', label: 'Additional Information', fieldName: 'Additional_Information__c', sortable: true, wrapText: true },        
    ]

    async connectedCallback() {

        if( this.columnArrangement == 'NursingPatientShiftItems' ) {
            this.columns = [
                { style:'width:180px;', label: 'Item Name', fieldName: 'itemName', fieldNameOrList: [
                    'DocTypeLabel__c',
                    'Form__r.disco__Form_Template__r.DocType_Name__c',
                    //'Procedure_Order__r.Name',
                    'Form__r.disco__Form_Template__r.Name',
                    'Item_Name__c'
                ], sortable: true, wrapText: true },
                { style:'width:100px;', label: 'Status', fieldName: 'Status__c', sortable: true, fixedWidth: 10 },
                {
                    style:'width:120px;',
                    label: 'Due Date', fieldName: 'Due_Date__c', type: "date", sortable: true, wrapText: true,
                    typeAttributes: {
                        day: "numeric",
                        month: "numeric",
                        year: "numeric"
                    }
                },
                // { style:'width:150px;', label: 'Nurse', fieldName: 'Nurse__c', type:"lookup", lookupid:'Nurse__c', lookupName:'Nurse__r.Professional_Name__c', sortable: true, wrapText: true },
                // { style:'width:150px;', label: 'Shift', fieldName: 'Nursing_Shift__c', type:"lookup", lookupid:'Nursing_Shift__c', lookupName:'Nursing_Shift__r.Shift__c', sortable: true, wrapText: true },
                { style:'width:150px;', label: 'Nurse', fieldName: 'Nurse__r.Professional_Name__c', sortable: true, wrapText: true },
                { style:'width:150px;', label: 'Shift', fieldName: 'Nursing_Shift__r.Shift__c', sortable: true, wrapText: true },
                { style:'', label: 'Additional Information', fieldName: 'Additional_Information__c', sortable: true, wrapText: true }, 
            ]
            this.sortBy = 'Nursing_Shift__c';
            this.sortDirection = 'desc';
        } else {
            this.columns = [
                { style:'width:120px;', label: 'Patient', fieldName: 'patientId', lookupName:'Patient__r.Name', type: 'lookup', lookupid:'Patient__r.Id', wrapText: true, typeAttributes: { nameField: 'Name' } },
                { style:'width:100px;', label: 'Status', fieldName: 'Status__c', sortable: true, fixedWidth: 10 },
                { style:'width:180px;', label: 'Item Name', fieldName: 'itemName', fieldNameOrList: [
                    'DocTypeLabel__c',
                    'Form__r.disco__Form_Template__r.DocType_Name__c',
                    //'Procedure_Order__r.Name',
                    'Form__r.disco__Form_Template__r.Name',
                    'Item_Name__c'
                ], sortable: true, wrapText: true },
                {
                    style:'width:100px;',
                    label: 'Due Date', fieldName: 'Due_Date__c', type: "date", sortable: true, wrapText: true,
                    typeAttributes: {
                        day: "numeric",
                        month: "numeric",
                        year: "numeric"
                    }
                },
                // { style:'width:150px;', label: 'Assigned To', fieldName: 'Nurse__c', type:"lookup", lookupid:'Nurse__c', lookupName:'Nurse__r.Professional_Name__c', sortable: true, wrapText: true },       
                { style:'width:150px;', fieldName:'Nurse__r.Professional_Name__c', label:'Assigned To', sortable: true, wrapText: true},
                { style:'', label: 'Additional Information', fieldName: 'Additional_Information__c', sortable: true, wrapText: true }, 
            ]
        }


        let today = new Date();
        let dd = String(today.getDate()).padStart(2, '0');
        let mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
        let yyyy = today.getFullYear();
        let shiftDate = yyyy + '-' + mm + '-' + dd;
        let shiftNumber = '';

        this.myShiftAssignments = await getMyNursingShiftAssigments();

        shiftDate = (this.myShiftAssignments?.length > 0) ? (this.myShiftAssignments[0]?.Nursing_Shift__r?.Date__c || shiftDate): shiftDate;
        shiftNumber = (this.myShiftAssignments?.length > 0) ? (this.myShiftAssignments[0]?.Nursing_Shift__r?.Shift_Number__c || ''): '';
        this.iframeSrc = '/flow/Build_New_Nursing_Shift_Item_V2?accountIdVar=' + this.recordId + '&defaultShiftDateVar=' + shiftDate + '&defaultShiftNumberVar=' + shiftNumber;
        this.load();
    }

    renderedCallback() {
        if (!this.initialized) {
            this.initialized = true
            this.load()
        }
    }

    onModeChange(e) {
        this.selectedMode = e.detail.value

        this.refreshPaginator()
    }

    get header() {
        return `${this.nursingShift?.data?.fields?.Shift__c?.value || ''}`
    }

    get jsonValue() {
        return JSON.stringify(this.nursingShift)
    }

    deep_value(obj, path){
        try{
            for (var i=0, path=path.split('.'), len=path.length; i<len; i++){
                obj = obj[path[i]];
            };
            return obj;
        }catch(e){}
        return ''
    };

    getOrValue(item,fieldPathList=[]){
        for(let fieldPath of fieldPathList){
            let value = this.deep_value(item, fieldPath)
            if(value){
                return value
            }
        }
        return ''
    }
    
    get dataItems() {
        let me = this
        let base = this.data ? this.data.map(item => {
            return {
                id: item.Id,
                shiftItemId: item.Id,               
                link: `/${ item.Physical_Monitor__c || item.Patient_Note__c || item.Form__c || item.Procedure_Order__c ||  item.Id }`, 
                record: {...item},
                showReassign: item.Status__c == 'Open',
                showCancel: item.Status__c == 'Open',
                cancelButtonText: item.Procedure_Order__c? 'Not Performed' : 'Cancel',
                detailButtonText: item.Status__c == 'Open'? 'Open' : 'View',
                showClose: null == item.Physical_Monitor__c && null == item.Patient_Note__c && null == item.Form__c && item.Status__c == 'Open',
                fields: me.columns.map(col=>{
                    return {                        
                        type: col.type,
                        name: col.fieldName,
                        value: (col.fieldNameOrList?.length > 0)? me.getOrValue(item, col.fieldNameOrList) : me.deep_value(item, col.fieldName),
                        valueId: me.deep_value(item, col.lookupid),  
                        lookupName:  me.deep_value(item, col.lookupName),
                        title : me.deep_value(item, col.lookupName) || ( (col.fieldNameOrList?.length > 0)? me.getOrValue(item, col.fieldNameOrList) : me.deep_value(item, col.fieldName) ),
                        isLookup: col.type=='lookup',
                        isDate: col.type=='date',
                        isName: col.type=='nameField',
                        isText: col.type? col.type=='text': true,                         
                    }
                }), 
            }
        }) : []

        //Sorting
        if (this.sortBy) {
            let isReverse = this.sortDirection === 'asc' ? 1 : -1;
            let col = this.columns.find(x=>x.fieldName == this.sortBy)

            // sorting data 
            base.sort((x, y) => {
                // let xi = x[this.sortBy] || ""                
                // let yi = y[this.sortBy] || ""
                let xi = x.fields.find(field=>field.name==this.sortBy)?.value || ''
                let yi = y.fields.find(field=>field.name==this.sortBy)?.value || ''

                // sorting values based on direction
                return isReverse * ((xi > yi) - (yi > xi));
            });
        }


        //Filtering
        if (this.selectedMode == 'All') {
            return base.map(x => x)
        } else {
            return base.filter(x => x.record?.Status__c == this.selectedMode)
        }
    }

    get isFromPatient(){
        try{
            return this.recordId.startsWith('006')
        }catch(ex){}
        return false
    }

    @api
    async load() {
        this.loading = true

        if ( this.isPatientItems) {
            let params = { nursingShiftId: this.recordId }
            if ( this.showOnlyMyItems ) {
                this.data = await getMyNursingShiftPatientItems(params)
            } else {
                this.data = await getNursingShiftPatientItems(params)
            }
        } else if ( this.isFromPatientAccount ) {
            let params = { accountId: this.recordId}
            if ( this.showOnlyMyItems ) {
                this.data =  await  getMyNursingShiftItemsForPatient(params)
            } else {
                this.data = await getNursingShiftItemsForPatient(params)
            }
        } else {
            let params = { nursingShiftId: this.recordId }
            if ( this.showOnlyMyItems ) {
                this.data = await getMyNursingShiftItems(params)
            } else {
                this.data = await getNursingShiftItems(params)
            }
        }

        console.info("**********RESULTS********", JSON.parse(JSON.stringify(this.data)))

        await setTimeout(()=>{
            this.refreshPaginator()
            this.loading = false
        },500)
    }

    onAddNewItemClickHandler(e) {
        this.showModal = true;
    }

    closeBtnHandler(e) {
        this.showModal = false
        this.showReassignModal = false
        this.selectedItemId = null
        this.showCancelReasonsModal = false
        console.info('*********************closeBtnHandler*************')
        // setTimeout(function(){
        //     console.info('*********************closeBtnHandler loading*************')
        //     // this.load()
        // },500)
        setTimeout(()=>{ 
            this.load()
        }, 1000)
    }

    handleRowDetailAction(e) {
        let recordId = e.detail.recordId;
        console.log('recordId : ' + recordId);
        var row = this.data.find(item => item.Id == recordId);

        let l = e.detail.label;

        if ('Details' == l) {
            getNursingShiftItem({ nursingShiftItemId: recordId }).then(item => {
                let physicalMonitorId = item.Physical_Monitor__c;
                let patientNoteId = item.Patient_Note__c;
                let formId = item.Form__c;

                var url = "/";
                if (physicalMonitorId) {
                    url += physicalMonitorId;
                } else if (patientNoteId) {
                    url += patientNoteId;
                } else if (formId) {
                    url += formId + '/e';
                } else {
                    url += recordId;
                }
                window.open(url, "_blank");
            })
        } else {
            getNursingShiftItem({ nursingShiftItemId: recordId }).then(item => {
                let shiftDate = item.Shift_Date__c;
                let shiftNumber = item.Shift_Number__c;
                this.iframeReassignSrc = `/flow/Nursing_Shift_Item_Reassingment?shiftItemIdVar=${recordId}&shiftDateInputVar=${shiftDate}&shiftNumberInputVar=${shiftNumber}`;
                this.showReassignModal = true;
            })
        }
    }
    onDetailsHandler(e){        
        this.selectedItemId = e.currentTarget.name
        getNursingShiftItem({ nursingShiftItemId: this.selectedItemId }).then(item => {
            let physicalMonitorId = item.Physical_Monitor__c;
            let patientNoteId = item.Patient_Note__c;
            let formId = item.Form__c;

            var url = "/";
            if (physicalMonitorId) {
                url += physicalMonitorId;
            } else if (patientNoteId) {
                url += patientNoteId;
            } else if (formId) {
                url += formId + '/e';
            } else {
                url += this.selectedItemId;
            }
            window.open(url, "_blank");
        })
    }

    get popup(){
        return this.template.querySelector('.popup')
    }

    onCloseItemHandler(e){
        e.preventDefault()        
        let id = e.currentTarget.name
        this.popup.confirm('Are you sure to close this item?','Confirm','ERROR').then(async (confirmed)=>{
            if(confirmed){
                let closeResult = await closeNursingShiftItem({itemId: id})
                if( closeResult ) {
                    this.toastFail(closeResult)                    
                }else{
                    this.toastSuccess('Shift Item Closed')
                    this.load()
                }
            }
        })
    }

    onReasignHandler(e){
        let recordId = e.currentTarget.name
        getNursingShiftItem({ nursingShiftItemId: recordId }).then(item => {
            let shiftDate = item.Shift_Date__c;
            let shiftNumber = item.Shift_Number__c;
            this.iframeReassignSrc = `/flow/Nursing_Shift_Item_Reassingment?shiftItemIdVar=${recordId}&shiftDateInputVar=${shiftDate}&shiftNumberInputVar=${shiftNumber}`;
            this.showReassignModal = true;
        })
    }

    clone(obj){
        return obj? JSON.parse(JSON.stringify(obj)) : obj
    }

    getCancelMessage( item ) {
        console.debug('************* getCancelMessage **********', this.clone(item))
        let relatedBase = 'It will also delete the related '  
        let related = ''
        if ( item.record?.Physical_Monitor__c ) {
            related = 'Physical Monitor.'
        } else if ( item.record?.Patient_Note__c ) {
            related = 'Patient Note.'
        } else if ( item.record?.Form__c ) {
            related = 'Form/Assessment.'
        } else if ( item.record?.Procedure_Order__c ) {
            related = 'Procedure Order.'
            return `Are you sure you want to mark this Nursing Shift Item as Not Performed?`
        }
        
        return `Are you sure you want to cancel this Nursing Shift Item? ${related? relatedBase+related  : ''}`
    }

    async onCancelHandler(e) {
        let itemId = e.target.dataset.id;
        let item = this.dataItems.find(x=>x.id==itemId)
        this.popup.confirm( this.getCancelMessage(item) ).then(async (result)=>{            
            if( result ) {
                this.loading = true
                try{
                    let getRecordResult = await GetRecordData({ record_id:itemId, fields : 'Procedure_Order__c'})
                    if( getRecordResult.data?.Procedure_Order__c ){
                        this.selectedCancelItemId = itemId
                        this.showCancelReasonsModal = true
                    }else{
                        let cancelResult = await cancelShiftItem({nursingShiftItemId: itemId })
                        if ( cancelResult ) {
                            this.toastFail(cancelResult)
                        }else {
                            this.toastSuccess('Successfully removed.')
                            this.load()                        
                        }
                    }
                }catch(ex){
                    this.toastFail(ex)
                }
                this.loading = false
            }
        })
    }

    toast({message, title, variant,}){
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }

    toastSuccess(message){
        this.toast({message, title:'Success', variant: 'success'})
    }

    toastFail(message){
        this.toast({message, title:'Fail', variant: 'error'})
    }

    NotPerformedReasonChanged(e){
        this.NotPerformedReason = e.detail.value
    }

    get NotPerformedOtherReasonClass(){
        return this.NotPerformedReason == 'Other'? 'slds-has-error' : ''
    }

    async cancelModalConfirmHandler(e){ 
        e.preventDefault()
        
        let NotPerformedReason = this.template.querySelector(`[data-id="NotPerformedReason"]`).value
        let NotPerformedOtherReason = this.template.querySelector(`[data-id="NotPerformedOtherReason"]`).value

        if( !NotPerformedReason || ( NotPerformedReason=='Other' && !NotPerformedOtherReason ) ) {
            return
        }

        this.loading = true
        try{
            
            let cancelShiftItemWithReasonsResult = await cancelShiftItemWithReasons({
                nursingShiftItemId: this.selectedCancelItemId,
                NotPerformedReason,
                NotPerformedOtherReason,
            })
            if( cancelShiftItemWithReasonsResult ) {
                this.toastFail(cancelShiftItemWithReasonsResult)
            }else{
                this.toastSuccess('Successfully removed.')
                this.load()                        
            }
            this.closeBtnHandler(null)
        }catch(ex){}
        this.loading = false
    }
}