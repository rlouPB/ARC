import { api, LightningElement, track } from 'lwc';
import getPrescriptionsToProcess from '@salesforce/apex/DispensingService.getPrescriptionsToProcess';

export default class PharmacyScriptsToProcessTableLwc extends LightningElement {
    @api
    accountId

    @track
    data=[]

    @track
    pagedData=[]

    @track
    selectedIds=[]

    @track
    sortBy='Medication_Filled_with__c'

    @track
    sortDirection='asc'

    @track
    selectedMode='All'

    @track
    loading

    @track
    columns=[        
        {name:'Account__r.Name', fullApiName:'Account__r.Name', label:'Patient', type:'lookup2', lookupid:"Account__c",lookupNameFields:['Account__r.Name'], sortable: true},
        {name:'Status__c', fullApiName:'Status__c', label:'Status', type:'text', sortable: true},
        {name:'Medication_Filled_with__c', fullApiName:'Medication_Filled_with__c', label:'Medication', type:'lookup2', lookupid:"Id",lookupNameFields:['Medication_Filled_with__c','Drug_Name__c'], sortable: true},
        {name:'Medication_Format__c', fullApiName:'Medication_Format__c', label:'Medication Format', type:'text', sortable: true},        
        // {name:'Dispensing_Comment__c', fullApiName:'Dispensing_Comment__c', label:'Dispensing Comment', type:'text', sortable: true},
        // {name:'Control_Group__c', fullApiName:'Control_Group__c', label:'Control Group', type:'text', sortable: true},
        {name:'Written_Date__c', fullApiName:'Written_Date__c', label:'Written Date', type:'date', sortable: true},
        {name:'Fill_Date__c', fullApiName:'Fill_Date__c', label:'Fill Date', type:'date', sortable: true},
        // {name:'Start_Date__c', fullApiName:'Start_Date__c', label:'Start Date', type:'date', sortable: true},
        // {name:'End_Date__c', fullApiName:'End_Date__c', label:'End Date', type:'date', sortable: true}
        {name:'Prescriber_Professional_Name__c', fullApiName:'Prescriber_Professional_Name__c', label:'Prescriber', type:'text', sortable: true},        
        {name:'Pharmacy_Note__c', fullApiName:'Pharmacy_Note__c', label:'Pharmacy Note', type:'text', sortable: true},        
    ]

    @api
    clearSelection(){
        this.selectedIds = []
        this.refreshPaginator()
    }

    @api
    get selectedRowIds(){
        return JSON.parse(JSON.stringify(this.selectedIds))
    }

    @api
    get dispensedIds(){
        let me = this
        return this.data.filter(item=>item.Dispensed__c).map(x=>x.Id)
    }

    async selectAll(e){
        if(this.selectedMode == 'Active Pending Fill') {
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c == 'Active Pending Fill').map(x=>x.Id) : []
        } else if(this.selectedMode == 'Discontinued') {
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c == 'Discontinued' || x.Status__c == 'Canceled').map(x=>x.Id) : []
        } else if(this.selectedMode == 'Canceled') {
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c == 'Canceled').map(x=>x.Id) : []
        } else if(this.selectedMode == 'Source Script') {
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c == 'Source Script').map(x=>x.Id) : []
        } else {
            // this.selectedIds = e.target.checked? this.data.map(x=>x.Id) : []
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c != 'Source Script').map(x=>x.Id) : []
        }
        console.log('this.selectedIds : ', this.selectedIds)
        this.refreshPaginator()
    }

    selectRow(e){
        let targetId = e.target.dataset.rowid
        if ( e.target.checked && this.selectedIds.indexOf(targetId) == -1 ){
            this.selectedIds.push(targetId)
        }else if ( !e.target.checked && this.selectedIds.indexOf(targetId) >= 0 ){
            this.selectedIds = this.selectedIds.filter(x=>x != targetId)
        }else{
            alert('holup')
        }
    }

    @api
    getRecords(){
        return this.data.map(x=>({...x}))
    }

    @api
    changeMode(value){
        console.info('-------------------r-changeMode---------------', value)
        this.selectedMode = value
        this.refreshPaginator()
    }

    async connectedCallback(){
        await this.load()
    }

    @api
    clearSelected(){
        this.selectedIds = []                       
        Array.from(this.template.querySelectorAll('.selectall')).forEach(el=>el.checked=false)
        // let selectAllCheck = this.template.querySelector('.selectall')
        // if ( selectAllCheck ) selectAllCheck.checked = false
        Array.from(this.template.querySelectorAll('.selectcheck')).forEach(el=>el.checked=false)
    }
    
    @api
    async load(){
        this.loading = true        
        this.clearSelected()
        this.data = await getPrescriptionsToProcess()
        // this.data.forEach(element => {
        //     console.log('prescription : ', element.Drug_Name__c)
        //     console.log('Status : ', element.Status__c)
        // });
        this.refreshPaginator()
        this.loading = false
    }

    get hasColumns(){
        return this.columns?.length > 0
    }
    
    get columnsSize(){
        return this.columns?.length || 0
    }

    get dataItems() {
        let me = this

        let today = new Date()

        console.log('this.data : ' + this.data)

        let base = this.data ? this.data.map(item => {
            return {
                id: item.Id,
                record: {...item},
                selected: me.selectedIds.indexOf(item.Id) >= 0,
                rowClass : `slds-table-row`,
                fields: me.columns.map(col=>{
                    return {
                        type: col.type,
                        name: col.name,
                        value: (col.fieldNameOrList?.length > 0)? me.getOrValue(item, col.fieldNameOrList) : me.deep_value(item, col.fullApiName),
                        valueId: me.deep_value(item, col.lookupid),  
                        lookupName:  me.deep_value(item, col.lookupName),
                        lookupName2: me.getOrValue( item, col.lookupNameFields ),
                        title : me.deep_value(item, col.name) || me.deep_value(item, col.lookupName),
                        action: col.actionName,
                        isLookup: col.type=='lookup',
                        isLookup2: col.type=='lookup2',
                        isDate: col.type=='date',
                        isName: col.type=='nameField',
                        isHtml: col?.type == 'html',
                        isCheckbox: col?.type == 'checkbox',
                        isAction: col?.type == 'action',
                        isText: col.type? col.type=='text': true,
                        isFieldAccessible: me.fieldsAccessibleToUser?.indexOf( col.fullApiName ) >= 0
                    }
                }), 
            }
        }) : []
        

        //Sorting
        if (this.sortBy) {
            let isReverse = this.sortDirection === 'asc' ? 1 : -1;
            let col = this.columns.find(x=>x.name == this.sortBy)

            // sorting data 
            base.sort((x, y) => {
                let xi = x.fields.find(field=>field.name==this.sortBy)?.value || ''
                let yi = y.fields.find(field=>field.name==this.sortBy)?.value || ''

                // sorting values based on direction
                return isReverse * ((xi > yi) - (yi > xi));
            });
        }

        if(this.selectedMode == 'Active Pending Fill') {
            return base.filter(x => x.record?.Status__c == 'Active Pending Fill')
        } else if(this.selectedMode == 'Discontinued') {
            return base.filter(x => x.record?.Status__c == 'Discontinued' || x.record?.Status__c == 'Canceled')
        } else if(this.selectedMode == 'Canceled') {
            return base.filter(x => x.record?.Status__c == 'Canceled')
        } else if(this.selectedMode == 'Source Script') {
            return base.filter(x => x.record?.Status__c == 'Source Script')
        } else {
            return base.filter(x => x.record?.Status__c != 'Source Script')
            // return base?.map(x=>x)
        }
    }

    updateColumnSorting(e) {        
        var fieldName = e.target.dataset.fieldname;
        
        let col = this.columns.find(x=>x.name == fieldName)
        
        if( !col.sortable ){
            console.info(`${fieldName} field is NOT sortable`)
            return
        }

        let sortDirection = this.sortDirection == 'asc' ? 'desc' : 'asc'

        col.isDESC = sortDirection == 'desc'
        col.sorted = true
        
        this.sortBy = fieldName;
        this.sortDirection = sortDirection;

        // setTimeout(()=>this.refreshPaginator(), 500)
        this.refreshPaginator()
    }

    getOrValue(item,fieldPathList=[]){
        for(let fieldPath of fieldPathList){
            let value = this.deep_value(item, fieldPath)
            if(value){
                return value
            }
        }
        return ''
    }

    deep_value(obj, path){
        try{
            for (var i=0, path=path.split('.'), len=path.length; i<len; i++){
                obj = obj[path[i]];
            };
            return obj;
        }catch(e){}
        return ''
    }

    async refreshPaginator(){
        let me = this;
        
        let paginator = me.template.querySelector('.paginator')
        
        console.info('paginator===============>', paginator)

        setTimeout(()=>paginator.pageChanged(),200)
        
    }

    pageChangedHandler(e) {
        this.pagedData = e.detail.values
    }

    onRecordActionClickHandler(e){
        const id = e.target.dataset.rowid
        const action = e.target.dataset.action

        this.dispatchEvent(new CustomEvent('action',{detail:{ 
           id,action 
        }}));
    }
}