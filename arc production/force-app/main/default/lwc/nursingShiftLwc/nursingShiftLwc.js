import { LightningElement, api, track, wire } from 'lwc';
// import SearchById from "@salesforce/apex/CustomLookupService.SearchById";
import getNursingShiftSingle from '@salesforce/apex/NursingShiftService.getNursingShiftSingle';
import saveNursingFieldChange from '@salesforce/apex/NursingShiftService.saveNursingFieldChange';
// import getNursingShiftAssigmentsByShiftId from '@salesforce/apex/NursingShiftService.getNursingShiftAssigmentsByShiftId';
import NURSING_SHIFT_OBJECT from '@salesforce/schema/Nursing_Shift__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class NursingShiftLwc extends LightningElement {
    @api
    recordId 

    @track
    nursingShift

    @track
    nurseAssignments

    @wire(getObjectInfo, {objectApiName: NURSING_SHIFT_OBJECT})
    nursingShiftInfo

    //Labels
    get Charge_Nurse__c(){ return this.getLabel('Charge_Nurse__c') }
    get Med_Nurse__c(){ return this.getLabel('Med_Nurse__c') }
    get Backup_Med_Nurse__c(){ return this.getLabel('Backup_Med_Nurse__c') }

    getLabel(apiName){
        if(this.nursingShiftInfo?.data?.fields){
            console.info(`Field ${apiName}`, JSON.parse(JSON.stringify(this.nursingShiftInfo?.data?.fields[apiName])))
            return this.nursingShiftInfo?.data?.fields[apiName].label
        }
        return ''
    }

    @track
    nursingFields = [
        'Date__c',
        'Type_of_Day__c',
        'Shift_Number__c',
        'Status__c',        
    ]

    get popup(){
        return this.template.querySelector('.popup')
    }

    connectedCallback(){
        this.load()        
    }

    async load(){
        debugger
        this.nursingShift = await getNursingShiftSingle({'recordId': this.recordId})
        console.info('results**************************', JSON.parse(JSON.stringify(this.nursingShift)))
    }

    async onRecordChange(e){
        let me = this;
        let fieldName = e.target.dataset.id
        let fieldValue = e.detail.value
        let fieldLabel = me.getLabel(fieldName)
        let fieldValueLabel = e.detail.label
        let old = e.detail.old

        console.info(`SELECTED:   ${fieldName} : ${fieldValue}`, JSON.parse(JSON.stringify(e.detail)));
        
        console.info('INFO', JSON.parse(JSON.stringify(me.nursingShiftInfo?.data)))

        let fieldRef = me.nursingShiftInfo?.data?.fields[fieldName]?.referenceToInfos

        let isUser = (fieldRef && fieldRef.length > 0)? fieldRef[0]?.apiName == 'User' : false

        console.info('EVENT', {event: e})

        let cmp = this.template.querySelector(`[data-id="${fieldName}"]`)

        me.saveFieldChange(
            fieldName,
            fieldValue,
        )
    }

    async saveFieldChange(fieldName,value){
        let result = await saveNursingFieldChange({
            nursingShiftId: this.recordId,
            fieldName,
            value,
        })
        if(result){
            this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')
            this.load()
        }else{
            console.info(`Updating ${fieldName} to value: ${value}, success.`)
        }
    }

    onSubmitHandler(e){
        e.preventDefault();
        console.info('onSubmitHandler')
    }
}