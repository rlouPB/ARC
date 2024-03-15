import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import { api, track, LightningElement } from 'lwc';
import getFieldDefinitions from '@salesforce/apex/DispensingService.getFieldDefinitions'

export default class DispensingPrescriptionFill extends LightningElement {
    @api
    recordId

    @track
    metadataLoaded

    @track
    fieldsMetadata=[]

    defaultStartDate = new Date();
    
    @track
    // defaultStartDateStr = '2022-11-7'
    defaultStartDateStr = this.defaultStartDate.getFullYear() + "-" + (this.defaultStartDate.getMonth()+1) + "-" + this.defaultStartDate.getDate();


    get inputFields(){
        return Array.from( this.template.querySelectorAll('lightning-input-field') )
    }

    @api
    async getRecord() {
        let me = this
        return new Promise((resolve) => {            
            let record = this.inputFields
            .filter( (input) => input.value != undefined)
            .reduce( (acc,cur) => ({...acc, [cur.fieldName]: cur.value}), { Id:me.recordId } )

            console.info("prescription fill record ===> ", JSON.parse(JSON.stringify(record)) )
            resolve( record )
        })
    }

    @api
    isValid(){
        this.template.querySelector('lightning-record-edit-form').submit()        
        let calcs = this.inputFields.map(item=>({
            el:item,
            name:item.fieldName,
            type: this.fieldTypes[item.fieldName],
            value: item.value || item.checked,            
            required: item.required,
        }))
        let filtered = calcs.filter(x => x.type != 'Checkbox' && x.required && !x.value)
        console.info('****** calcs ******* ', {...calcs} )
        console.info('****** filtered ******* ', {...filtered} )
        filtered.forEach(x=>x.el.click())
        return filtered.length == 0
    }

    onSubmitHandler(e) {
        e.preventDefault();
    }

    get fieldTypes(){
        return this.fieldsMetadata? 
        this.fieldsMetadata.reduce( (acc,cur) => ({...acc, [cur.QualifiedApiName]: cur.DataType}), {  } )
        :
        []
    }

    async onloadHandler(e){
        console.log('in onload of fill screen')
        if( this.metadataLoaded ) {
            return
        }
        this.metadataLoaded = true
        let fieldNames = this.inputFields.map(x=>x.fieldName)
        this.fieldsMetadata = await getFieldDefinitions({ sobjectType:'Prescription__c', fieldNames })
    }
}