import { LightningElement, api, track } from 'lwc';
import getPackages from '@salesforce/apex/DispensingService.getPackages';
import getPackage from '@salesforce/apex/DispensingService.getPackage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class DispensingPackagesTable extends LightningElement {
    @api
    accountId

    @track
    data=[]

    @track
    pagedData=[]

    @track
    selectedIds=[]

    @track
    sortBy='Name'

    @track
    sortDirection='desc'

    @track
    selectedMode='Show New'

    @track
    loading

    @track
    columns=[        
        {name:'Package_Name_Fml__c', fullApiName:'Package_Name_Fml__c', label:'Package', type:'nameField', sortable: true},
        {name:'Medications__c', fullApiName:'Medications__c', label:'Medications', type:'text', sortable: true},
        {name:'Start_Date__c', fullApiName:'Start_Date__c', label:'Start Date', type:'date', sortable: true, wrapText: true},
        {name:'Package_Delivery_ETA__c', fullApiName:'Package_Delivery_ETA__c', label:'Package Delivery ETA', type:'date', sortable: true, wrapText: true},
        {name:'Control_Group__c', fullApiName:'Control_Group__c', label:'Control Group', type:'text', sortable: true},
        // {name:'Dispensing_Comment__c', fullApiName:'Dispensing_Comment__c', label:'Dispensing Comment', type:'text', sortable: true},
        {name:'Dispensed__c', fullApiName:'Dispensed__c', label:'Dispensed', type:'checkbox', sortable: true},
        {name:'Dispensed_Datetime__c', fullApiName:'Dispensed_Datetime__c', label:'Dispensed Datetime', type:'datetime', sortable: true},
        {name:'Order__c', fullApiName:'Order__c', label:'Order', type:'lookup2', lookupid:"Order__c",lookupNameFields:['Order__r.Name'], sortable: true},
        {name:'Form__c', fullApiName:'Form__c', label:'Return Info Form', type:'lookup2', lookupid:"Form__c",lookupNameFields:['Form__r.Name'], sortable: true},
        {name:'Form_Status__c', fullApiName:'Form_Status__c', label:'Form Status', type:'text', sortable: true},
        {name:'Status__c', fullApiName:'Status__c', label:'Status', type:'text', sortable: true}
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
        if( this.selectedMode == 'Show New' ) {
            this.selectedIds = e.target.checked? this.data.filter(x => x.Status__c == 'New').map(x=>x.Id) : []
        }else {
            this.selectedIds = e.target.checked? this.data.map(x=>x.Id) : []
        }
        console.log('this.selectedIds : ', this.selectedIds)
        this.refreshPaginator()
    }

    async selectRow(e){
        let targetId = e.target.dataset.rowid
        this.dispatchEvent(new CustomEvent('disabledispensingbutton'))
        if ( e.target.checked && this.selectedIds.indexOf(targetId) == -1 ){
            this.selectedIds.push(targetId)
            let myPackage = await getPackage({packageId: targetId});
            if(undefined != myPackage && myPackage.Dispensed__c) {
                this.toast(myPackage.Package_Name_Fml__c + ' has already been dispensed.', '', 'error');
                const index = this.selectedIds.indexOf(myPackage.Id);
                if (index > -1) { // only splice array when item is found
                    this.selectedIds.splice(index, 1); // 2nd parameter means remove one item only
                }
                Array.from(this.template.querySelectorAll('.selectcheck')).forEach(function(el) {
                    if(targetId == el.getAttribute('data-rowid')) {
                        el.checked=false
                    }
                });
            }
            this.dispatchEvent(new CustomEvent('enabledispensingbutton'))
        }else if ( !e.target.checked && this.selectedIds.indexOf(targetId) >= 0 ){
            this.selectedIds = this.selectedIds.filter(x=>x != targetId)
            this.dispatchEvent(new CustomEvent('enabledispensingbutton'))
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
        this.selectedIds = []
        Array.from(this.template.querySelectorAll('.selectall')).forEach(el=>el.checked=false)
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
        Array.from(this.template.querySelectorAll('.selectcheck')).forEach(el=>el.checked=false)
    }
    
    @api
    async load(){
        this.loading = true        
        this.clearSelected()
        this.data = await getPackages({accountId: this.accountId})
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
                        isDateTime: col.type=='datetime',
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

        // this.data.map(item => {
        //     console.log('item.Name : ', item.Name)
        //     console.log('item.Order__c : ', item.Order__c)
        //     console.log('item.Form__c : ', item.Form__c)
        // })


        if( this.selectedMode == 'Show New' ) {
            return base.filter(x => x.record?.Status__c == 'New')
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

    toast(message,title='alert',variant='info') {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}