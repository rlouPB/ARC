import { LightningElement, track, api, wire  } from 'lwc';
import getNursingShiftItems from '@salesforce/apex/NursingShiftService.getNursingShiftItems';
import { getRecord } from 'lightning/uiRecordApi';

import DATE_FIELD from '@salesforce/schema/Nursing_Shift__c.Date__c';
import SHIFT_NUMBER_FIELD from '@salesforce/schema/Nursing_Shift__c.Shift_Number__c';

export default class NursingShiftItemsLwc extends LightningElement {
    @api
    recordId

    @track
    data

    columns = [
        {label: 'Patient', fieldName: 'patientId', type: 'recordView', typeAttributes:{ nameField:'Name' }},
        {label: 'Team', fieldName: 'team'},
        {label: 'Program', fieldName: 'program'},
        {label: 'In PAS', fieldName: 'inpass'},
        {label: 'Shift Assigned To', fieldName: 'shiftAssignedToOwnerId'},
        {label: 'Open Items', fieldName: 'openItems', type: 'number'},
    ]

    @wire(getRecord, { recordId: '$recordId', fields: [DATE_FIELD,SHIFT_NUMBER_FIELD] })
    nursingShift;
    

    get header(){
        return this.nursingShift? `${this.nursingShift?.data?.fields?.Date__c?.value} - ${this.nursingShift?.data?.fields?.Shift_Number__c?.value}` : ''
    }
    

    connectedCallback(){        
        this.load()
    }

    async load(){
        let results = await getNursingShiftItems({nursingShiftId: this.recordId})
        this.data = results.map(item=>{
            return {
                id: item.Id,
                patientId: item.Patient__c,
                team: item.Patient__r.Team__c,
                program: item.Patient__r.Current_Admitted_Program_Name__c,
                inpass: item.Patient__r?.Current_Admission__r?.In_PAS__c? 'Yes' : 'No',
                shiftAssignedToOwnerId: item.Nursing_Shift_Assignment__r?.Owner__c,
                openItems: item.Nursing_Shift_Assignment__r?.Open_Shift_Items__c,                
            }
        })
    }
}