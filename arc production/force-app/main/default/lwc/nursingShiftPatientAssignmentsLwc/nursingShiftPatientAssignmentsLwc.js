import { LightningElement, track, api, wire  } from 'lwc';
import getPatientAssignmentsByNursingShift from '@salesforce/apex/NursingShiftService.getPatientAssignmentsByNursingShift';
import setShiftAssignedToUser from '@salesforce/apex/NursingShiftService.setShiftAssignedToUser';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

import ADMISSION_OBJECT from '@salesforce/schema/Admission__c';
import TEAM_FIELD from '@salesforce/schema/Admission__c.Team__c';

export default class NursingShiftPatientAssignmentsLwc extends NavigationMixin(LightningElement) {
    @api
    recordId

    @track
    rawData

    @track
    data = []

    @track
    columns = []

    @track
    pagedData = []

    @track
    sortBy

    @track
    sortField

    @track
    sortDirection

    @track
    selectedTeam='All Teams'

    @track
    selectedIds=[]

    @track
    showReassignModal

    @track
    addNewPatientModal

    @track
    loading

    get iframeReassignSrc(){
        return `/flow/Nursing_Shift_Item_Reassingment?shiftItemIdVar=${this.nursingShiftItemId}&shiftDateInputVar=${this.shiftDate}&shiftNumberInputVar=${this.shiftNumber}`      
    }

    get iframeNewPatientAssignSrc(){
        return `/flow/Add_Patient_to_Shift?nursingShiftIdVar=${this.recordId}`
    }


    @wire(getObjectInfo, { objectApiName: ADMISSION_OBJECT })
    admissionInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$admissionInfo.data.defaultRecordTypeId',
        fieldApiName: TEAM_FIELD
    })
    teamsPicklistValues

    get teams(){
        return ['All Teams'].map(x=>{return{label:x,value:x}}).concat(this.teamsPicklistValues?.data?.values ||  []);
    }

    get selectedRows(){
        return this.data.filter(x=>x.selected).map(x=>x.id)
    }

    async connectedCallback(){
        this.columns = [
            {label: 'Patient', fieldName: 'patientId', type: 'recordView', sortable:true, sortFieldPath:'patientName'},
            {label: 'Team', fieldName: 'team', sortable:true },            
            {label: 'Program', fieldName: 'program', sortable:true},
            {label: 'Status', fieldName: 'status', sortable:true },
            {label: 'Open Items', fieldName: 'openItems', type: 'number', sortable:true},
            {label: 'Assigned To', fieldName: 'nsaOwnerName', sortable:true},
            {label: 'Re-assign', fieldName: 'nsaAssign'},
        ]
        this.load()
    }

    onCloseModals(e){
        this.showReassignModal = false
        this.addNewPatientModal = false
        setTimeout(()=>this.load(),200)
    }

    onClickHandler(e){
        let fieldname = e.target.dataset.fieldname
        
        let col = this.columns.find(x=>x.fieldName==fieldname)
        
        if ( !col.sortable ){
            return
        }

        for(let f of this.columns){
            f.sorted = false
        }

        //let sortFieldPath = col.sortFieldPath
        if(col.sortable){
            col.isDESC = !col.isDESC
        }
        col.sorted = true

        let fieldToUse = col.sortFieldPath? col.sortFieldPath : col.fieldName

        this.sortedBy = col.fieldName
        this.sortDirection = !col.isDESC
        this.sortField = fieldToUse

        setTimeout(()=>this.refreshPaginator(), 500)
    }

    onCheckChanged(e){
        let id = e.target.dataset.id
        let checked = e.target.checked
        if( this.selectedIds.indexOf(id) >= 0 ){
            this.selectedIds = this.selectedIds.filter(x=>x!=id)
        }else{
            this.selectedIds.push(id)
        }
    }

    onSelectAllCheckChanged(e){
        let checked = e.target.checked
        this.selectedIds = checked? this.dataItems.map(x=>x.id) : []        
        this.refreshPaginator()
    }

    refreshPaginator(){
        setTimeout(()=>this.template.querySelector('c-paginator-lwc').pageChanged(),100)
    }
    
    addNewPatientModalHandler(e) {
        this.addNewPatientModal = true
    }

    onTeamChangeHandler(e){
        this.selectedTeam = e.detail.value
        this.selectedIds = []
        this.refreshPaginator()
    }

    navigateToRecord(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                actionName: 'view',
            }
        });
    }

    get paginator(){
        return this.template.querySelector('c-paginator-lwc')
    }    

    get dataItems(){
        let me = this
        // et physicalMonitorId = item.Physical_Monitor__c;
        // let patientNoteId = item.Patient_Note__c;
        // let formId = item.Form__c;
        let items = (this.rawData || []).map(item=>{
            return {
                record: {...item},
                id: item.Id,
                nsaId: item.Nursing_Shift_Assignment__r?.Id, 
                nsaOwnerName: item.Nursing_Shift_Assignment__r?.Owner__r?.Name,
                nsaName: item.Nursing_Shift_Assignment__r?.Owner__r?.Name,
                openShiftItems: item.Open_Patient_Shift_Items__c || 0,
                patientId: item.Patient__r?.Id,
                patientName: item.Patient__r?.Name,
                team: item.Patient__r?.Team__c,
                program: item.Patient__r?.Current_Admitted_Program_Product_Code__c,
                // inPas: item.Patient__r?.Current_Admission__r?.In_PAS__c,
                status: item.Patient__r?.Current_Admitted_Program_Status__c?.replace("Program Assessment Status (PAS)", "PAS"),
                shiftAssignedToId: item.Shift_Assigned_To__r?.Id,
                shiftAssignedToName: item.Shift_Assigned_To__r?.Name,
                // stage: item.Patient__r?.Current_Admission__r?.Stage__c,
                selected: this.selectedIds.indexOf(item.Id) >= 0,
                link: `/${item.Id}`,
            }
        })

        if( this.sortedBy ){
            // let isReverse = this.sortDirection ? 1 : -1;
            //sort
            items.sort((x, y) => {
                x = x[this.sortField] || '';
                y = y[this.sortField] || '';

                // sorting values based on direction
                return (this.sortDirection? 1 : -1) * ((x > y) - (y > x));
            });
        }

        return ( this.selectedTeam != 'All Teams' )? items.filter(x=>x.team == this.selectedTeam) : items
    }

    async load(){
        this.loading = true
        this.pagedData = null;
        this.rawData = await getPatientAssignmentsByNursingShift({nursingShiftId: this.recordId})        
        this.loading = false
        setTimeout(()=>this.refreshPaginator(),300)
        return this.data
    }

    onDetailsClick(e){
        e.preventDefault()
        this.navigateToRecord(e.target.dataset.id)
    }

    async onRowSelectedHandler(e){        
        let me = this
        let value = e.detail.value
        if( value && me.selectedIds.length > 0 ){
            this.loading = true
            let results = await setShiftAssignedToUser({
                nspaIds : me.selectedIds,
                userId : value,
                nursingShiftId: this.recordId,
            })
            if(results){
                me.showToast('Error',results,'error')
            }else{
                await me.load()
                me.refreshPaginator()
            }
            this.selectedIds = []
            this.template.querySelector('.selectAllCheck').checked = false
            this.loading = false
        }
    }

    async onRowSelectedRowHandler(e){
        let me = this
        let id = e.target.dataset.id
        let selected = e.detail.value
        console.log('id : ' + id + ', selected : ' + selected + ', this.recordId : ' + this.recordId);
        let results = await setShiftAssignedToUser({
            nspaIds : [id],
            userId : selected,
            nursingShiftId: this.recordId,
        })
        if(results){
            me.showToast('Error',results,'error')
        }else{
            await me.load()
            this.refreshPaginator()
            this.dispatchEvent(new CustomEvent('assigntoset'))
        }
    }
    
    pageChangedHandler(e){
        console.info('*************** pageChangedHandler *************', JSON.parse(JSON.stringify(e.detail)))
        this.pagedData = e.detail.values
    }

    showToast(title='',message='',variant='info'){
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
        }));
    }
}