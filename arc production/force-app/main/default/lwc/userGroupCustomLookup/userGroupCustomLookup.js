import { LightningElement, track, api } from 'lwc';
import SearchById from "@salesforce/apex/CustomLookupService.SearchById";
import SearchByUserGroup from "@salesforce/apex/CustomLookupService.SearchByUserGroup";
export default class UserGroupCustomLookup extends LightningElement {
    
    @api 
    recordId

    @api
    sobjectType

    @api
    fieldName

    @api
    label
    
    @api
    labelHidden

    @api
    required    

    @api
    customSearch

    @api
    placeholder

    @track
    searchKeyWord=''
    
    @track
    selectedRecord

    @track
    searchResultItems=[]

    @track
    navigatorIndex=0    

    @api
    selectionMode = 'default' //Possible: default, eventonly

    get isEventOnly(){
        return this.selectionMode == 'eventonly'
    }

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
            this.selectedRecord= await SearchById({ 
                recordId: this.recordId, 
                sobjectType: this.sobjectType, 
                fieldName: this.fieldName 
            })
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
        if(!this.isEventOnly){
            this.selectedRecord = item
        }else{
            let input = this.template.querySelector('.slds-lookup__search-input')
            console.info('input ===> ',input)
            if (input){
                input.value = ''
            }
        }
        this.searchResultItems = []
        this.navigatorIndex = 0
        this.dispatchRecordSelected(item)
    }

    dispatchRecordSelected(item){
        const selectedEvent = new CustomEvent('recordselected', { detail: { 
            value: item?.id,
            label: item?.label,
        } })

        this.dispatchEvent(selectedEvent);
    }

    handleOnKeyDown(e){
        let keyCode = e.keyCode
        let target = e.target

        setTimeout(()=>{
            if ( [40,38,13].indexOf( keyCode ) < 0 ){
                this.searchKeyWord = target.value;
                this.searchTerm(target.value)
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
        }, 1)
    }

    @api
    selectedId(){
        return this.selectedRecord?.id
    }
    
    async searchTerm(searchText){
        
        if( !searchText.trim() ){
            this.searchResultItems = []
            return
        }

        let params = { 
            searchText: searchText, 
            sobjectType: this.sobjectType, 
            fieldName: this.fieldName 
        }

        let results = await SearchByUserGroup( params )

        this.searchResultItems = results.map((item, idx)=>{
            return {
                idx,
                selected: idx===0,
                ...item,                
            }
        });
    }
}