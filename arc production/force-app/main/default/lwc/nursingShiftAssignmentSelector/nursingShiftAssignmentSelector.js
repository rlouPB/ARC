import { LightningElement, track, api, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
// import getNursingShiftAssigments from "@salesforce/apex/NursingShiftService.getNursingShiftAssigments";
// import GetById from '@salesforce/apex/CustomLookupService.GetById';
import SearchByText from '@salesforce/apex/NurseShiftLookupService.SearchByText';
// import SearchById from '@salesforce/apex/NursingShiftAssignmentLookupService.SearchById';
import NAME_FIELD from '@salesforce/schema/User.Name';
// import NSPA_NS_FIELD from '@salesforce/schema/Nursing_Shift_Patient_Assignment__c.Nursing_Shift__c';
// import NSPA_NSA_FIELD from '@salesforce/schema/Nursing_Shift_Patient_Assignment__c.Nursing_Shift_Assignment__c';
// import RECORD_NAME_FIELD from '@salesforce/schema/Nursing_Shift_Patient_Assignment__c.Nursing_Shift_Assignment__r.Owner__r.Name';

export default class NursingShiftAssignmentSelector extends LightningElement {
    @api
    recordId

    @api
    hidetext

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD] })
    record

    get iconSize(){
        return 'small'
    }

    @track
    searchKeyWord

    @api
    labelHidden

    @api
    label

    @track
    showModal

    @track
    records

    @api
    readOnly

    @api
    placeHolder='Find nurse to assign. . .'

    async connectedCallback(){}

    get hasRecord(){
        return this.record?.data
    }

    get recordName(){
        return getFieldValue(this.record?.data, NAME_FIELD)
    }

    onSearchIconClickHandler(e){
        this.search(this.searchKeyWord? this.searchKeyWord : '')
    }

    onTextInputChange(e){
        this.searchKeyWord = e.target.value;
    }

    async search(searchText){
        this.records = []
        this.showModal = true
        this.records = await SearchByText({
            searchText: searchText,
        })
    }

    closeBtnHandler(e){
        console.log('pick one closed button clicked')
        this.showModal = false
        this.records = []
    }

    onSelectorItemClick(e){
        this.showModal = false
        let id = e.target.dataset.id
        let label = e.target.dataset.label
        this.template.querySelector('.popup').confirm(`Are you sure you want to reassign this patient to "${label}"?`).then(results=>{
            if(results){
                const rowselected = new CustomEvent('rowselected',{
                    detail: {
                        value: id,
                        label: label,
                    }
                })
                this.dispatchEvent(rowselected)
            }
        })
    }

    handleOnKeyDown(e){
        let me = this;
        if(e.keyCode == 13 ){  
            setTimeout(()=>me.search(me.searchKeyWord), 500)
        }
    }
}