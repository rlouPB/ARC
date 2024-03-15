import { api, LightningElement, track } from 'lwc';
import getPatientNoteOrdersToProcess from '@salesforce/apex/DispensingService.getPatientNoteOrdersToProcess';

export default class PharmacyOrdersToProcessTableLwc extends LightningElement {
    @track
    data=[]

    @track
    pagedData=[]

    @track
    selectedIds=[]

    @track
    sortBy='Name'

    @track
    sortDirection='asc'

    @track
    loading

    @track
    columns=[        
        {name:'Name', fullApiName:'Name', label:'Order', type:'nameField', sortable: true},
        {name:'Type__c', fullApiName:'Type__c', label:'Type', type:'text', sortable: true},
        {name:'Account__r.Name', fullApiName:'Account__r.Name', label:'Patient', type:'lookup2', lookupid:"Account__c",lookupNameFields:['Account__r.Name'], sortable: true},
        {name:'Away_First_Date__c', fullApiName:'Away_First_Date__c', label:'First Day Away', type:'date', sortable: true},
        {name:'Contact_Date__c', fullApiName:'Contact_Date__c', label:'Ordered Date', type:'date', sortable: true},
        {name:'Account__r.Current_Admission__r.MSA_Schedule__c', fullApiName:'Account__r.Current_Admission__r.MSA_Schedule__c', label:'MSA Schedule', type:'text', sortable: true},
        {name:'Account__r.Current_Admission__r.MSA_Pickup_Location__c', fullApiName:'Account__r.Current_Admission__r.MSA_Pickup_Location__c', label:'MSA Pickup Location', type:'text', sortable: true}
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

    async selectAll(e){
        this.selectedIds = e.target.checked? this.data.map(x=>x.Id) : []
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

    async connectedCallback(){
        await this.load()
    }

    @api
    clearSelected(){
        this.selectedIds = []                       
        Array.from(this.template.querySelectorAll('.selectall')).forEach(el=>el.checked=false)
        Array.from(this.template.querySelectorAll('.selectcheck')).forEach(el=>el.checked=false)
    }
    
    @api
    async load(){
        this.loading = true        
        this.clearSelected()
        this.data = await getPatientNoteOrdersToProcess()
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
        return base?.map(x=>x)
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