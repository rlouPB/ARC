import { LightningElement, track, api } from 'lwc';
import SearchByText from "@salesforce/apex/NursingShiftAssignmentLookupService.SearchByText";
import SearchById from "@salesforce/apex/NursingShiftAssignmentLookupService.SearchById";

export default class NursingShiftAssignmentLookup extends LightningElement {
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
    searchResultItems=[]

    @track
    navigatorIndex=0    

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
    
    async connectedCallback(){
        if(this.recordId){
            let result = await SearchById({ 
                recordId: this.recordId, 
                sobjectType: 'User', 
                fieldName: 'Name'
            })
            this.selectedRecord = result
            if( !this.nursingShiftId && result?.data?.Nursing_Shift__c){
                this.nursingShiftId = result?.data?.Nursing_Shift__c
            }
        }
    }

    clear(){
        this.searchKeyWord = ''
        this.searchResultItems = []
        this.selectedRecord = null
        this.dispatchRecordSelected()
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
        this.selectedRecord = item
        this.searchResultItems = []
        this.navigatorIndex = 0
        this.dispatchRecordSelected()
    }

    dispatchRecordSelected(){
         const selectedEvent = new CustomEvent('recordselected', { detail: { value:this.selectedRecord?.id } })

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
    
    async searchTerm(searchText){
        if( !`${searchText}`.trim() ){
            this.searchResultItems = []
            return
        }

        let results = await SearchByText( { 
            searchText: searchText, 
            nursingShiftId: this.nursingShiftId
        } )

        this.searchResultItems = results.map((item, idx)=>{
            return {
                idx,
                selected: idx===0,
                ...item,                
            }
        });
    }
}