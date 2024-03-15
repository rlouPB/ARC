import { LightningElement, track, wire } from 'lwc';
import { getPicklistValues,getObjectInfo } from 'lightning/uiObjectInfoApi';
import ADMISSION_OBJECT from '@salesforce/schema/Admission__c';
import DISPENSING_STATUS from '@salesforce/schema/Admission__c.Dispensing_Status__c';
import getPatients from '@salesforce/apex/DispensingService.getPatients';
import packageAndPrintForPatients from '@salesforce/apex/DispensingService.packageAndPrintForPatients';
import checkUserCanAccessFields from '@salesforce/apex/FLSUtils.checkUserCanAccessFields';
import checkPerms from '@salesforce/apex/PermissionUtils.checkPerms';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class DispensingPatientsLwc extends LightningElement { 
    @wire(checkPerms, {perms:'DispansingShowPackagePrintBtns'})
    hasDispansingShowPackagePrintBtns

    get showPackageAndPrint(){
        return this.hasDispansingShowPackagePrintBtns?.data;
    }

    @wire(getObjectInfo, { objectApiName: ADMISSION_OBJECT })
    admissionInfo;
    
    @wire(getPicklistValues, {
        recordTypeId: '$admissionInfo.data.defaultRecordTypeId',
        fieldApiName: DISPENSING_STATUS
    })
    dispensingStatusPkInfo

    @track
    data=[]

    @track
    pagedData=[]

    @track
    selectedIds=[]

    @track
    sortBy='Patient_LastName__c'

    @track
    sortDirection='asc'

    @track
    selectedMode='All'

    @track
    loading
    @track
    openPackage
    @track
    hasPackageAndPrintButtons


    get showPackageAndPrint() {
        return hasDispansingShowPackagePrintBtns
    }

    get dispensingStatusPkValues(){
        return this.dispensingStatusPkInfo?.data?.values? this.dispensingStatusPkInfo?.data?.values?.map(x=>x.value) : []
    }

    @track
    columns=[        
        {name:'Patient_LastName__c', fullApiName:'Account.Patient_LastName__c', label:'Last Name', sortable: true},
        {name:'Name', fullApiName:'Account.Name', label:'Patient', type:'nameField', sortable: true},
        {name:'Photo__c', fullApiName:'Account.Photo__c', label:'Photo', type:'html', sortable: true },
        {name:'Date_of_Birth__c',fullApiName:'Account.Date_of_Birth__c', label:'DOB', sortable: true},
        {name:'Mother_s_Maiden_Name__c',fullApiName:'Account.Mother_s_Maiden_Name__c', label:'Mother\'s Maiden Name', sortable: true},
        {name:'Current_Admission__r.Dispensing_Status__c',fullApiName:'Admission__c.Dispensing_Status__c', label:'Dispensing Status', sortable: true},
        {name:'Current_Admission__r.MSA_Schedule__c',fullApiName:'Admission__c.MSA_Schedule__c', label:'MSA Schedule', sortable: true},
        {name:'Current_Admission__r.MSA_Pickup_Location__c',fullApiName:'Admission__c.MSA_Pickup_Location__c', label:'MSA Location', sortable: true},
    ]

    @track
    fieldsAccessibleToUser=[]

    get accessibleColumns(){
        return this.columns.filter(x=>x.isAccessible==true)
    }

    get columnsSize(){
        return this.columns.length;
    }

    get hasColumns(){
        return this.columnsSize > 0
    }

    get hasPagedData(){
        return this.pagedData?.length > 0
    }

    get hasColumns(){
        return this.columns?.length > 0
    }

    get modes() {
        return ['All'].concat(this.dispensingStatusPkValues).map(x => { return { label: x, value: x } })
    }

    get showPackageAndPrintButtons() {
        return this.hasDispansingShowPackagePrintBtns?.data;
    }

    async connectedCallback() {
        let flsCheckResults =  await checkUserCanAccessFields(  {fullApiNames: this.columns.map(x=>x.fullApiName) })
        
        this.fieldsAccessibleToUser = []
        for ( let f in flsCheckResults ){
            if ( flsCheckResults[f] ) {
                this.fieldsAccessibleToUser.push(f)
            }
        }

        for ( let col of this.columns ) {
            col.isAccessible = this.fieldsAccessibleToUser.indexOf(col.fullApiName) >= 0
        }

        await this.load()

        this.refreshPaginator()
    }

    async load() {
        this.loading = true
        this.data = await getPatients()
        this.hasPackageAndPrintButtons = await checkPerms({perms: 'DispensingShowPackagePrintBtns'})
        this.loading = false
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

    selectAll(e){
        if (this.selectedMode == 'All') {
            this.selectedIds = e.target.checked ? this.data.map(x=>x.Id) : []
        } else {
            let base = this.getBaseItems();
            this.selectedIds = e.target.checked ? base.filter(x => x.record?.Current_Admission__r?.Dispensing_Status__c == this.selectedMode).map(x=>x.id) : []
        }
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

    async refreshPaginator(){
        await setTimeout(()=>this.querySelector('c-paginator-lwc').pageChanged(),500)

    }

    getBaseItems() {
        let me = this

        let base = this.data ? this.data.map(item => {
            return {
                id: item.Id,
                record: {...item},
                selected: me.selectedIds.indexOf(item.Id) >= 0,
                fields: me.accessibleColumns.map(col=>{
                    return {
                        type: col.type,
                        name: col.name,
                        value: (col.fieldNameOrList?.length > 0)? me.getOrValue(item, col.fieldNameOrList) : me.deep_value(item, col.name),
                        valueId: me.deep_value(item, col.lookupid),  
                        lookupName:  me.deep_value(item, col.lookupName),
                        title : me.deep_value(item, col.name) || me.deep_value(item, col.lookupName),
                        action: col.actionName,
                        isLookup: col.type=='lookup',
                        isDate: col.type=='date',
                        isName: col.type=='nameField',
                        isHtml: col?.type == 'html',
                        isAction: col?.type == 'action',
                        isText: col.type? col.type=='text': true,
                        isFieldAccessible: me.fieldsAccessibleToUser?.indexOf( col.fullApiName ) >= 0
                    }
                }), 
            }
        }) : []

        return base;
    }

    get dataItems() {
        let base = this.getBaseItems();
        
        //Sorting
        if (this.sortBy) {
            let isReverse = this.sortDirection === 'asc' ? 1 : -1;
            let col = this.columns.find(x=>x.fieldName == this.sortBy)

            // sorting data 
            base.sort((x, y) => {
                let xi = x.fields.find(field=>field.name==this.sortBy)?.value || ''
                let yi = y.fields.find(field=>field.name==this.sortBy)?.value || ''

                // sorting values based on direction
                return isReverse * ((xi > yi) - (yi > xi));
            });
        }


        //Filtering
        if (this.selectedMode == 'All') {
            return base.map(x=>x)
        } else {
            return base.filter(x => x.record?.Current_Admission__r?.Dispensing_Status__c == this.selectedMode)
        }
    }

    onRecordActionClickHandler(e){
        let id = e.target.dataset.rowid
        let action = e.target.dataset.action
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

        setTimeout(()=>this.refreshPaginator(), 500)
    }

    onModeChange(e) {
        this.selectedIds = []
        Array.from(this.template.querySelectorAll('.selectall')).forEach(el=>el.checked=false)
        this.selectedMode = e.detail.value
        this.refreshPaginator()
    }

    refreshPaginator() {
        setTimeout(() => this.template.querySelector('.paginator').pageChanged(), 100)
    }

    pageChangedHandler(e) {
        this.pagedData = e.detail.values
    }

    packageAndPrintClickHandler(e){        
        let selectedIds = this.selectedIds
        if (!selectedIds?.length ){
            this.toast('Please select one or more patients to prepare packages for.','','warn')
        } 
        // else if (selectedIds?.length > 10) {
        //     this.toast('Please select ten or less patients to prepare packages for.','','warn')
        // } 
        else {
            this.openPackage = true
            this.selectedIds = selectedIds;
        }
    }

    closePackageModal(e){
        this.openPackage = false
    }

    packageCmp(){
        return this.template.querySelector('c-dispensing-prescription-package')
    }

    async packageSaveClickHandler(e){
        let myPackage = this.packageCmp()
        if ( !myPackage.isValid() ) {
            console.log('package cmp is not valid.')
            return
        } else {
            this.packageCmp().showSpinner = true;
            let results = await packageAndPrintForPatients({patientIds:this.selectedIds, 
                startDate:this.packageCmp().getStartDate(), 
                endDate:this.packageCmp().getEndDate(),
                packageDeliveryETA:this.packageCmp().getPackageDeliveryETA()})

            console.log('results : ', results)
            if(results) {
                const resultsArray = results.split(",");  
                console.log('resultsArray : ', resultsArray)
                resultsArray.forEach((sDocId) => {
                    console.log('sDocId : ', sDocId)
                    var pdfUrl = "/apex/PrintedDispensingPackagesPDF?Ids="+sDocId;
                    window.open(pdfUrl);
                });      
                // var pdfUrl = "/apex/PrintedDispensingPackagesPDF?Ids="+results;
                // window.open(pdfUrl);
            } else {
                this.toast(results,"Error",'error')
            }   

            // if(results.length == 15 || results.length == 18){
            //     if(results.length == 15 || results.length == 18) {
            //         // window.open('/apex/SDOC__SDCreate1?id=' + results + '&Object=SDocCallableParent__c&doclist=PackagesPrintingTemplate&autoopen=0');
            //         var pdfUrl = "/apex/PrintedDispensingPackagesPDF?Id="+results;
            //         window.open(pdfUrl);
            //     }
            // } else{
            //     this.toast(results,"Error",'error')
            // }
            this.packageCmp().showSpinner = false;
            this.openPackage = false
        }
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