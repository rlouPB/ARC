import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSobjectRecords from '@salesforce/apex/DynamicListViewController.getSobjectRecords'
import TIME_ZONE from '@salesforce/i18n/timeZone';
import { refreshApex } from "@salesforce/apex";
import {getRecordNotifyChange } from 'lightning/uiRecordApi';

var typeAttributes = {day: "numeric",month: "short", year: "numeric",hour: "2-digit",minute: "2-digit", second: "2-digit",hour12: true, timeZone: TIME_ZONE};

export default class DynamicListView extends NavigationMixin(LightningElement) {
    @track mydata;
    @track mycolumns;
    @track nameUrl;
    @track error;
    @track itemCount=0;
    @api showNewButton=false;
    @api sObjectName='';
    @api fieldSetName='';
    @api recordId='';
    @api sObjectLookupIDField = '';
    @api additionalWhereClause = '';
    @api tableTitle = '';
    @api includeName = false;
    @api orderBy = '';
    @api iconName;
    @api showMyRecordsOnly=false;
    @api enableColumnSorting=false;
    @track sortBy;
    @track sortDirection;

    wiredActivities;

    connectedCallback(){
        console.log(this.recordId);        
        //this.load();
    }

    @wire(getSobjectRecords,({
        sObjectName : '$sObjectName',
        fieldSetName : '$fieldSetName',
        recordId : '$recordId',
        sObjectLookupIDField : '$sObjectLookupIDField',
        additionalWhereClause : '$additionalWhereClause',
        includeName: '$includeName',
        orderBy: '$orderBy',
        showMyRecordsOnly: '$showMyRecordsOnly',
        enableColumnSorting: '$enableColumnSorting'
    }))

    wiredAccounts(value){
        this.wiredActivities = value;
        const { data, error } = value;
        if(data){
            if(this.includeName){
                var nameField = [{
                    label: 'Name',
                    fieldName: 'nameUrl',
                    type: 'url',
                    typeAttributes: {label: { fieldName: 'Name' }, 
                    target: '_self'},
                    sortable: true
                }];
                this.mycolumns = nameField.concat( data.listColumns );
                let nameUrl;
                if(this.includeName)
                    this.mydata = data.dataTableData.map(row => { 
                        nameUrl = `/${row.Id}`;
                        console.log("----" + row);
                        return {...row , nameUrl} 
                    })
                this.error = undefined;
            }
            else{
                this.mydata = data.dataTableData;
                this.mycolumns = data.listColumns;
            }
            if(data.dataTableData) {
                this.itemCount = data.dataTableData.length;
            }
            console.log('this.myData=' + this.mydata);
            //convert date time
            this.mycolumns = this.mycolumns.map(element => { 
                if(element.type == 'string'){
                    return {...element,wrapText:true};
                } else if(element.type == 'date'){
                    return {...element,typeAttributes};
                } else if(element.type == 'richtextfield') {
                    return {...element,wrapText:true,typeAttributes: {
                        value: { fieldName: element.fieldName },
                        disabled: "true"
                    }};
                }
                else return element;
            })
            console.log('this my converted columns:' + JSON.stringify(this.mycolumns) );
        }else if(error){
            this.error = error;
            this.mydata = undefined;    
            this.mycolumns = undefined;
        }
    }

    handleNewClick() {
        // Navigate to the Account home page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.sObjectName,
                actionName: 'new',
            },
            state: {
                useRecordTypeCheck: 1
              }
        });
    }

    handleRefresh() {
        refreshApex(this.wiredActivities);		
    }

    handleSortEvent(event) {       
        this.sortBy = event.detail.fieldName;       
        this.sortDirection = event.detail.sortDirection;       
        this.doSorting(event.detail.fieldName, event.detail.sortDirection);
    }

    doSorting(fieldName, sortDirection) {
        let sortResult = [...this.mydata]; // Same as Object.assign([], this.data)
        let parser = (v) => v;
        let column = this.mycolumns.find(c=>c.fieldName===fieldName);
        if(column.type==='date' || column.type==='datetime') {
          parser = (v) => (v && new Date(v));
        }
        let sortMult = sortDirection === 'asc'? 1: -1;
        this.mydata = sortResult.sort((a,b) => {
          let a1 = parser(a[fieldName]), b1 = parser(b[fieldName]);
          let r1 = a1 < b1, r2 = a1 === b1;
          return r2? 0: r1? -sortMult: sortMult;
        });
      }
      
}