import { LightningElement, api, track } from 'lwc';
import getNursingShifts from '@salesforce/apex/NursingShiftService.getNursingShifts';

export default class NursingShiftsLwc extends LightningElement {
    
    @track data
    @track sortBy;
    @track sortDirection;
    @track loading

    columns = [
        {label: 'Shift', fieldName: 'shiftUrl', type: 'url', typeAttributes: {label: { fieldName: 'shift' }, target: '_blank'}, sortable: true},
        {label: 'Type of Day', fieldName: 'typeOfDay', sortable: true},
        {label: 'Status', fieldName: 'status', sortable: true},
        {label: 'Charge Nurse', fieldName: 'chargeNurse', sortable: true},
        {label: 'Shift Open Date/Time', fieldName: 'shiftOpenDateTime', type: 'date', sortable: true, typeAttributes: {
            day:'numeric',month:'numeric',year:'numeric',hour:'2-digit',minute:'2-digit',hour12:true
          },
        }
        // {label: 'Shift Close Date/Time', fieldName: 'shiftCloseDateTime', type: 'date', typeAttributes: {
        //     day:'numeric',month:'numeric',year:'numeric',hour:'2-digit',minute:'2-digit',hour12:true
        //   },
        // }
    ]

    connectedCallback(){        
        this.load()
    }

    async load(){
        this.loading = true
        let results = await getNursingShifts({statuses: ['New', 'Open']})
        console.log('results : ', results)
        this.data = results.map(item=>{
            return {
                id: item.Id,
                shift: item.Shift__c,
                shiftUrl: "/" + item.Id,
                typeOfDay: item.Type_of_Day__c,
                status: item.Status__c,
                chargeNurse: item.Charge_Nurse__r?.Professional_Name__c,
                shiftOpenDateTime: item.Shift_Open_Date_Time__c,
                shiftCloseDateTime: item.Shift_Closed_Date_Time__c
            }
        })
        this.sortData("status", "desc")
        this.loading=false
    }

    updateColumnSorting(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;
        this.sortData(fieldName, sortDirection);
   }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.data));
        console.log('parseData : ', parseData)
        console.log('fieldname : ', fieldname)
        console.log('direction : ', direction)

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        console.log('keyValue : ', keyValue)

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;
        console.log('isReverse : ', isReverse)

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        console.log('parseData 2 : ', parseData)

        // set the sorted data to data table data
        this.data = parseData;
        console.log('this.data : ', this.data)
    }
}