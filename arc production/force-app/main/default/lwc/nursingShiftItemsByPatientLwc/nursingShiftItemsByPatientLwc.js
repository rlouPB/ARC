import { LightningElement, track, api, wire  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import getNursingShiftItemsForPatient from '@salesforce/apex/NursingShiftService.getNursingShiftItemsForPatient';
import getNursingShiftItem from '@salesforce/apex/NursingShiftService.getNursingShiftItem';
import getMyNursingShiftAssigments from '@salesforce/apex/NursingShiftService.getMyNursingShiftAssigments';
import { getRecord } from 'lightning/uiRecordApi';
import DATE_FIELD from '@salesforce/schema/Nursing_Shift__c.Date__c';

export default class NursingShiftItemsByPatientLwc extends LightningElement {
    @api recordId
    @track data
    @track formattedData
    formattedDataFull
    @track pagedData=[]
    @track showModal
    @track iframeSrc
    @track showReassignModal
    @track iframeReassignSrc
    @track myShiftAssignments
    @track sortBy;
    @track sortDirection;
    @track fieldPath
    @track selectedMode='Open'
    @track loading
    
    columns = [
        {label: 'Item Name', fieldName: 'itemName', sortable: "true", initialWidth: 60 },
        {label: 'Status', fieldName: 'status', sortable: "true" },
        {label: 'Due Date', fieldName: 'dueDate', sortable: "true" },
        {label: 'Nurse', fieldName: 'nurse', sortable: "true" },
        {label: 'Shift', fieldName: 'shift', sortable: "true" },
        {label: 'Actions', fieldName: 'shiftItemId', type: "customLinkButton", 
            typeAttributes: {
                buttonLabelA: 'Details',
                buttonHideA: false,
                buttonLabelB: 'Reassign',
                buttonHideB: false,
                styleVariantA: 'Brand',
                styleVariantB: 'brand-outline',
                disabled: { fieldName: 'isButtonDisabled'}
            }
        }     
    ]

    async connectedCallback(){
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
        this.formatData = [];
        this.load();
    }
    
    get header(){
        return "Nursing Shift Items"
    }

    get hasPagedData(){
        return this?.pagedData?.length > 0
    }

    get paginator(){
        return this.template.querySelector('c-paginator-lwc')
    }

    get modes(){
        return 'All,Open,Closed,Cancelled'.split(',').map(x=>{return {label:x,value:x}})
    }

    // get pagedData(){
    //     console.log('called get pagedData - this.selectedMode : ' + this.selectedMode);
    //     //Filtering...
    //     if( this.selectedMode != 'All' ){
    //         return this.formattedData.filter(x=> x.record?.Status__c == this.selectedMode)
    //     }else{
    //         return this.formattedData
    //     }
    // }

    async load(){
        this.loading = true
        getNursingShiftItemsForPatient({ accountId: this.recordId}).then(item=>{
            this.data = item

            this.formattedData = [];
            this.data?.map(item=>{
                var nurseVar = ''
                if(null != item.Nurse__c) {
                    nurseVar = item.Nurse__r.Professional_Name__c;
                }
    
                var shiftVar = ''
                if(null != item.Shift_Index__c) {
                    shiftVar = item.Shift_Index__c;
                }
                this.formattedData.push({
                    shiftItemId: item.Id,
                    itemName: item?.Form__r?.disco__Form_Template__r?.DocType_Name__c || item.Item_Name__c,
                    nurse: nurseVar,
                    shift: shiftVar,
                    status: item.Status__c,
                    dueDate: item.Due_Date__c,
                })
            })

            this.formattedDataFull = this.formattedData;

            //Filtering...
            if( this.selectedMode != 'All' ){
                this.formattedData = this.formattedData.filter(x=> x?.status == this.selectedMode)
            }

            this.paginator.pageChanged()
            this.loading = false
        })

        
    }

    onAddNewItemClickHandler(e){
        this.showModal = true;
    }

    closeBtnHandler(e){
        this.showModal = false;
        this.showReassignModal = false;        
        setTimeout(async ()=>{
            this.template.querySelector('lightning-button-icon').click()
            // this.load()
            // this.paginator.pageChanged()
        },5000)
    }

    handleRowDetailAction(e) {
        let recordId = e.detail.recordId;
        var row = this.data.find(item => item.Id == recordId);
        
        let l = e.detail.label;
        
        if('Details' == l) {
            getNursingShiftItem({ nursingShiftItemId: recordId}).then(item=>{
                let physicalMonitorId = item.Physical_Monitor__c;
                let patientNoteId = item.Patient_Note__c;
                let formId = item.Form__c;

                var url = "/";
                if(physicalMonitorId) {
                    url += physicalMonitorId;
                } else if(patientNoteId) {
                    url += patientNoteId;
                } else if(formId){
                    url += formId;
                } else {
                    url += recordId;
                }
                window.open(url, "_blank");
            })
        } else {
            getNursingShiftItem({ nursingShiftItemId: recordId}).then(item=>{
                let shiftDate = item.Shift_Date__c;
                let shiftNumber = item.Shift_Number__c;
                this.iframeReassignSrc = `/flow/Nursing_Shift_Item_Reassingment?shiftItemIdVar=${recordId}&shiftDateInputVar=${shiftDate}&shiftNumberInputVar=${shiftNumber}`;
                this.showReassignModal = true;
            })
        }
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);

        setTimeout(()=>{this.paginator.pageChanged(), 100})
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.formattedData));
        
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        this.formattedData = parseData;
    }    

    pageChangedHandler(e){
        this.pagedData = e.detail.values
        console.info('PAGED RESULTS', this.pagedData?.length )
    }

    onModeChange(e){
        this.selectedMode = e.detail.value
        this.formattedData = this.formattedDataFull;

        //Filtering...
        if( this.selectedMode != 'All' ){
            this.formattedData = this.formattedData.filter(x=> x?.status == this.selectedMode)
        }else{
            this.formattedData = this.formattedDataFull;
        }

        setTimeout(()=>{this.paginator.pageChanged(), 100})
    }
}