import { api, LightningElement, track } from 'lwc';
import getControlledSubstanceFormsToAttach from '@salesforce/apex/DispensingService.getControlledSubstanceFormsToAttach';

export default class DispensingMedRecordsAttachControlledSubstanceFormsLwc extends LightningElement {
    
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
        {name:'Name', fullApiName:'Name', label:'Form Number', type:'nameField', sortable: true},
        {name:'disco__Form_Contact__r.Name', fullApiName:'disco__Form_Contact__r.Name', label:'Contact Name', type:"text", sortable: true, wrapText: true },
        {name:'CreatedBy.Name', fullApiName:'CreatedBy.Name', label:'Created By', type:"text", sortable: true, wrapText: true },
        {name:'CreatedDate', fullApiName:'CreatedDate', label:'Created Date', type:"date", sortable: true, wrapText: true },
        // {name:'disco__File_Count__c', fullApiName:'disco__File_Count__c', label:'File Count', type:'text', sortable: true},        
        {name:'Signature_Attached_Later__c', fullApiName:'Signature_Attached_Later__c', label:'Signature Attached Later', type:'checkbox', sortable: true}
    ]

    @api
    getRecords(){
        console.log('this.data : ', this.data)
        return this.data.map(x=>({...x}))
    }

    async connectedCallback(){
        await this.load()
    }

    @api
    async load(){
        this.loading = true        
        this.data = await getControlledSubstanceFormsToAttach()
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

        console.log('this.data : ', this.data)

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


        if( this.selectedMode == 'Show Active' ) {
            return base.filter(x => x.record?.Status__c == 'Active')
        }else {
            return base?.map(x=>x)
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