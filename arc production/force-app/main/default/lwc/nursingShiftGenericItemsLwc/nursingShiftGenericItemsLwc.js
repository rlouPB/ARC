import { LightningElement, api, track, wire } from 'lwc'
import getGenericItems from '@salesforce/apex/NursingShiftGenericItemsService.getGenericItems'
import closeGenericItem from '@salesforce/apex/NursingShiftGenericItemsService.closeGenericItem'
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'
import SHIFT_DATE_FIELD from '@salesforce/schema/Nursing_Shift__c.Date__c'
import SHIFT_NUMBER_FIELD from '@salesforce/schema/Nursing_Shift__c.Shift_Number__c'
import { NavigationMixin } from 'lightning/navigation';
import getNursingShiftItem from '@salesforce/apex/NursingShiftService.getNursingShiftItem';
import cancelShiftItem from '@salesforce/apex/NursingShiftService.cancelShiftItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class NursingShiftGenericItemsLwc extends NavigationMixin(LightningElement) {
    @api
    recordId

    @wire(getRecord, { recordId: '$recordId', fields: [SHIFT_DATE_FIELD, SHIFT_NUMBER_FIELD] })
    nursingShift;

    get shiftNumber(){
        return getFieldValue(this.nursingShift.data, SHIFT_NUMBER_FIELD);
    }

    get shiftDate(){
        return getFieldValue(this.nursingShift.data, SHIFT_DATE_FIELD);
    }

    @track
    showModal

    @track
    rawData=[]

    @track
    data=[]

    @track
    pagedData=[]

    @track
    columns=[
        {style:'width:180px;', name:'Nurse__r.Professional_Name__c', label:'Assigned To', tdClass:"slds-cell-wrap"},
        {style:'width:180px;', name:'Item_Name__c', label:'Item Name', tdClass:"slds-cell-wrap"},
        {name:'Additional_Information__c', label:'Additional Information', tdClass:"slds-cell-wrap"},
        {style: 'width:100px;', name:'Due_Date__c', label:'Due Date', type:'date'},
        {style: 'width:100px;', name:'Status__c', label:'Status'},
    ]

    @track
    selectedMode='Open'

    @track
    sortBy

    @track 
    fieldPath

    @track
    sortASC

    @api
    showAdd

    @track
    showReassignModal

    @track
    nursingShiftItemId

    @track
    loading

    @track
    closingModal

    get iframeReassignSrc(){
        console.log('shiftItemIdVar : ', this.nursingShiftItemId)
        console.log('shiftDateInputVar : ', this.shiftDate)
        console.log('shiftNumberInputVar : ', this.shiftNumber)
        return `/flow/Nursing_Shift_Item_Reassingment?shiftItemIdVar=${this.nursingShiftItemId}&shiftDateInputVar=${this.shiftDate}&shiftNumberInputVar=${this.shiftNumber}`      
    }

    get iframeSrc(){
        return `/flow/Build_New_Nursing_Shift_Item_V2?shiftIdVar=${this.recordId}`
    }

    connectedCallback(){
        this.load()
    }

    renderedCallback(){        
        console.info('****************renderedCallback***************', this.showModal)
        if( this.closingModal){
            this.paginator.pageChanged( me.currentData )
            this.closingModal = false
        }
    }

    onDetailsClickHandler(e){
        e.preventDefault()
        let itemId = e.target.dataset.id
        
        getNursingShiftItem({ nursingShiftItemId: itemId}).then(item=>{
            let physicalMonitorId = item.Physical_Monitor__c;
            let patientNoteId = item.Patient_Note__c;
            let formId = item.Form__c;

            var url = "/";
            if(physicalMonitorId) {
                url += physicalMonitorId;
            } else if(patientNoteId) {
                url += patientNoteId;
            } else if(formId){
                url += formId + '/e';
            } else {
                url += itemId;
            }
            window.open(url, "_blank");
        })
    }

    onReasignHandler(e){
        e.preventDefault()
        
        this.nursingShiftItemId = e.target.dataset.id

        this.showReassignModal = true
    }

    get popup(){
        return this.template.querySelector('.popup')
    }

    onCloseItemHandler(e){
        e.preventDefault()        
        let id = e.target.dataset.id
        this.popup.confirm('Are you sure to close this item?','Confirm','ERROR').then(async (confirmed)=>{
            if(confirmed){
                let closeResult = await closeGenericItem({itemId: id})
                if( closeResult ) {
                    this.toastFail(closeResult)                    
                }else{
                    this.toastSuccess('"Shift Item Closed')
                    this.load()
                }
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

    onReassignClose(){
        this.nursingShiftItemId = ''

        this.showReassignModal = false

        setTimeout(()=>{ 
            this.load()
        }, 1000)
    }
    
    onDetailsHandler(e){
        e.preventDefault()
    }

    get hasPagedData(){
        return this?.pagedData?.length > 0
    }

    get hasColumns(){
        return this.columns?.length > 0
    }

    get modes(){
        return 'All,Open,Closed,Cancelled'.split(',').map(x=>{return {label:x,value:x}})
    }

    get paginator(){
        return this.template.querySelector('c-paginator-lwc')
    }

    get columnsSize(){
        return this.columns?.length
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

    get currentData(){
        let me = this
        let results = this.rawData.map(x=>{
            return {
                record:{...x},                
                link: `/${x.Id}`,
                showClose: (x.Status__c == 'Open') && !(x.Form__c || x.Patient_Note__c || x.Physical_Monitor__c ),
                showCancel: x.Status__c == 'Open',
                showReassign: x.Status__c == 'Open',
                detailButtonText: x.Status__c == 'Open'? 'Open' : 'View',
                fields: me.columns.map(col=>{
                    return {                        
                        type: col.type,
                        name: col.name,
                        value: me.deep_value(x,col.name),
                        valueId: me.deep_value(x,col.lookupid),
                        tdClass: col.tdClass,
                        isLookup: col.type=='lookup',
                        isDate: col.type=='date',
                        isName: col.type=='nameField',
                        isText: col.type? col.type=='text': true,                        
                    }
                }),                
            }
        })

        //Sorting...
        if( this.sortBy ){
            results.sort((x, y) => {
                let x1 = x.fields.find(f=>f.name==me.fieldPath).value
                let y1 = y.fields.find(f=>f.name==me.fieldPath).value
    
                // sorting values based on direction
                return (this.sortASC ? 1 : -1) * ((x1 > y1) - (y1 > x1));
            })
        }

        //Filtering...
        if( this.selectedMode != 'All' ){
            return results.filter(x=> x.record?.Status__c == me.selectedMode)
        }else{
            return results
        }
        
    }

    async load(){
        this.loading = true
        this.rawData = await getGenericItems({nursingShiftId: this.recordId})
        await setTimeout(()=>{
            this.paginator.pageChanged( this.currentData )
            this.loading = false
        },500)
    }

    onModeChange(e){
        this.selectedMode = e.detail.value
        setTimeout(()=>{ 
            this.paginator.pageChanged() 
        }, 500)
    }

    openModal(e){
        this.showModal = true;
    }
    
    closeBtnHandler(e){
        this.showModal = false;

        setTimeout(()=>{ 
            this.load()
        }, 1000)
    }

    onClickHandler(e){
        let me = this;
        
        let fieldname = e.target.dataset.fieldname
        
        for(let f of this.columns){
            f.sorted = false
        }
        
        let col = this.columns.find(x=>x.name==fieldname)
        
        col.isDESC = !col.isDESC

        col.sorted = true

        this.sortBy = col.name
        this.sortASC = !col.isDESC
        this.fieldPath = col.path? col.path : col.name

        setTimeout(()=>me.paginator.pageChanged(), 500)
    }

    clone(obj){
        return obj? JSON.parse(JSON.stringify(obj)) : obj
    }

    getCancelMessage( item ) {
        console.debug('************* getCancelMessage **********', this.clone(item))
        let relatedBase = 'It will also delete the related '  
        let related = ''
        if ( item.Physical_Monitor__c ) {
            related = 'Physical Monitor.'
        } else if ( item.Patient_Note__c ) {
            related = 'Patient Note.'
        } else if ( item.Form__c ) {
            related = 'Form/Assessment.'
        } else if ( item.Procedure_Order__c ) {
            related = 'Procedure Order.'
        }
        
        return `Are you sure you want to cancel this Nursing Shift Item? ${related? relatedBase+related  : ''}`
    }

    async onCancelHandler(e) {
        let itemId = e.target.dataset.id;
        let item = this.rawData.find(x=>x.Id==itemId)
        this.popup.confirm( this.getCancelMessage(item) ).then(async (result)=>{            
            if( result ) {
                this.loading = true
                try{
                    let cancelResult = await cancelShiftItem({nursingShiftItemId: itemId })
                    if ( cancelResult ) {s
                        this.toastFail(cancelResult)
                    }else {
                        this.toastSuccess('Successfully removed.')
                        this.load()                        
                    }
                }catch(ex){
                    this.toastFail(ex)
                    this.loading = false
                }
            }
        })
    }

    pageChangedHandler(e){
        this.pagedData = e.detail.values
        console.info('PAGED RESULTS', this.pagedData?.length )
    }
}