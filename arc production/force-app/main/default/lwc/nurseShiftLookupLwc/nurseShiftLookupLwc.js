import { LightningElement, track, api } from 'lwc';
import SearchByText from "@salesforce/apex/NurseShiftLookupService.SearchByText";
import SearchById from "@salesforce/apex/CustomLookupService.SearchById";

export default class NurseShiftLookupLwc extends LightningElement {
    @api 
    recordId

    @api
    nursingShiftId

    @api
    label
    
    @api
    labelHidden

    @api
    required    

    @api
    customSearch

    @track
    searchKeyWord=''
    
    @track
    selectedRecord

    @track
    oldSelectedRecord

    @track
    searchResultItems=[]

    @track
    navigatorIndex=0    

    @api
    isFlow

    @api
    avoidSelectedRecord=false

    @api
    placeholder='search...'

    get elementClass(){
        return `slds-form-element slds-lookup ${this.isOpen? 'slds-is-open' : 'slds-is-close' }`
    }

    get isOpen(){
        return this.searchResultItems.length > 0
    }

    get elementControllClass(){
        return `slds-form-element__control ${this.required? 'required': ''}`
    }

    get selectedRecordName(){
        return this.selectedRecord?.label
    }

    get showDropDown(){
        return this.searchKeyWord && !this.selectedRecord
    }

    get popup(){
        return this.template.querySelector('.popup')
    }
    
    async connectedCallback(){
        if ( this.recordId && !this.avoidSelectedRecord ) {
            this.selectedRecord= await SearchById({ 
                recordId: this.recordId, 
                sobjectType: 'User', 
                fieldName: 'Name'
            })
            this.oldSelectedRecord = this.selectedRecord? JSON.parse(JSON.stringify(this.selectedRecord)) : null
        }
    }

    clear(){
        this.popup.confirm("Are you sure you want to clear this field?").then(results=>{
            if(results){
                this.searchKeyWord = ''
                this.searchResultItems = []
                this.selectedRecord = null
                this.dispatchRecordSelected()
            }
        })
    }
    
    onTextInputBlurHandler(e){
        this.searchKeyWord = e.target.value;
        this.searchTerm(e.target.value)
    }

    onTextInputKeyUpHandler(e){
        console.info('onTextInputKeyUpHandler::::', e.detail)
        this.searchKeyWord = e.target.value;
        this.searchTerm(e.target.value)
    }

    onSearchItemClickHandler(e){
        this.select( this.searchResultItems.find(x=>x.id==e.currentTarget.dataset.id) )
    }

    select(item){
        if(this.isFlow) {
            this.oldSelectedRecord = this.selectedRecord? JSON.parse(JSON.stringify(this.selectedRecord)) : null
            if ( !this.avoidSelectedRecord ){
                this.selectedRecord = item
            }
            console.log('recordId before : ' + this.recordId);
            this.recordId = item.id
            console.log('recordId after : ' + this.recordId);
            this.searchResultItems = []
            this.navigatorIndex = 0
            this.dispatchRecordSelected()
        } else {
            this.popup.confirm(`Are you sure you want to assign to "${item.label}"?`).then(results=>{
                if(results){
                    this.oldSelectedRecord = this.selectedRecord? JSON.parse(JSON.stringify(this.selectedRecord)) : null
                    if ( !this.avoidSelectedRecord ){
                        this.selectedRecord = item
                    }
                    this.searchResultItems = []
                    this.navigatorIndex = 0
                    this.dispatchRecordSelected( this.avoidSelectedRecord? item : null)
                }
            })
        }
    }

    dispatchRecordSelected(record){
        const selectedEvent = new CustomEvent('recordselected', { detail: { 
            value:this.selectedRecord?.id || record?.id,
            label:this.selectedRecord?.label || record?.label,
            old:this.oldSelectedRecord,
        } })

        this.dispatchEvent(selectedEvent);
    }

    handleOnKeyDown(e){
        let keyCode = e.keyCode
        let target = e.target

        setTimeout(()=>{
            let value = target.value
            
            if ( [40,38,13].indexOf(keyCode ) < 0 ){
                this.searchKeyWord = value;
                this.searchTerm(value)
                return
            }
            if(!this.searchResultItems || this.searchResultItems.length === 0 ){
                return
            }
            if( keyCode == 40 ){
                this.navigatorIndex += (( this.navigatorIndex < (this.searchResultItems.length -1) )? 1 : 0)
            }else if ( keyCode == 38 ){
                this.navigatorIndex -= (( this.navigatorIndex > 0 )? 1 : 0)
            }else if (keyCode == 13){
                // e.preventDefaults()
                this.select(this.searchResultItems[this.navigatorIndex])
            }
            for(let i=0; i<this.searchResultItems.length; i++){
                this.searchResultItems[i].selected = ( i===this.navigatorIndex )
            }
        },1)
    }

    @api
    selectedId(){
        this.recordId = this.selectedRecord?.id
        return this.selectedRecord?.id
    }

    @api
    hardsetId(id){
        this.select(id)
        // if(id){            
        //     SearchById({ 
        //         recordId: id,
        //         sobjectType: 'User', 
        //         fieldName: 'Name'
        //     }).then(results=>{
        //         this.oldSelectedRecord = this.selectedRecord? JSON.parse(JSON.stringify(this.selectedRecord)) : null                          
        //         this.selectedRecord = results
        //         this.searchResultItems = []
        //         this.navigatorIndex = 0      
        //     })
        // }else{
        //     this.selectedRecord = undefined
        //     this.searchResultItems = []
        //     this.navigatorIndex = 0      
        //     // alert(JSON.stringify(this.selectedRecord))
        // }        
    }
    
    async searchTerm(searchText){
        if( !`${searchText}`.trim() ){
            this.searchResultItems = []
            return
        }

        let params = { 
            searchText: searchText, 
        }

        console.info('params ==> ',JSON.parse(JSON.stringify(params)))

        let results = await SearchByText( params )

        console.info('results ==> ',JSON.parse(JSON.stringify(results)))
      
        this.searchResultItems = results.map((item, idx)=>{
            return {
                idx,
                selected: idx===0,
                ...item,                
            }
        });
    }
}