import { LightningElement, track, api } from 'lwc';
import getAllCategories from '@salesforce/apex/MedRecordHierarchy.getAllCategories'
import getRecord from '@salesforce/apex/RecordUtils.getRecord'
//import getDraftAwayOrdersForPatient from '@salesforce/apex/DispensingService.getDraftAwayOrdersForPatient'

export default class CreateNewLwc extends LightningElement {
    
    data;
    
    categories;
    
    searchText;
    
    @api
    sobjectName;
    
    @api
    recordId;
    
    recordName;
    
    selected;
    
    rawData;

    connectedCallback(){
        let me = this;               
        getRecord({ recordId: me.recordId, fields: 'Name' }).then(record=>{
            me.recordName = record? record.Name : '';
        }); 
        getAllCategories({}).then((result)=>{
            me.rawData = JSON.parse(result);
            me.data = me.rawData.map((catItem)=>{
                return {
                    label: catItem.obj.Name__c,
                    expanded: true,
                    items: catItem.docTypes.filter(docType=>docType.obj.Creatable__c).map((docType)=>{
                        return {
                            label : docType.obj.Name__c,
                            name: docType.obj.Id,
                            expanded : true,
                        };
                    }),
                }
            }).filter(cats=>cats.items.length > 0);
            me.categories = me.data;
        });        
    }

    getDocTypeById(docTypeId){
        let me = this;
        for (let cat of me.rawData){
            for(let docType of cat.docTypes ){
                if( docType.obj.Id ==  docTypeId){
                    return JSON.parse(JSON.stringify(docType.obj));
                }
            }
        }
        return null;
    }

    onChangeHandler(e){
        this.searchText = e.target.value;
        this.search(e.target.value);
    }

    onKeyUpHandler(e){
        this.searchText = e.target.value;
        this.search(e.target.value);
    }

    search(value){   
        if(this.data){
            let me = this;     
            let val = value.trim().toLowerCase();
            let cloned = JSON.parse(JSON.stringify(me.data));
            if( val ){
                me.categories = cloned.map(x=>{
                    let include = x.label.toLowerCase().includes(val);
                    x.include = include || x.items.filter(y=>y.label.toLowerCase().includes(val)).length > 0;
                    x.items = include ? x.items.map(x1=>x1) : x.items.filter(x1=>x1.label.toLowerCase().includes(val));
                    return x;
                }).filter(x=>x.include);            
            }else{
                me.categories = me.data.map(x=>x);
            }
            me.selected = null;
        }
    }

    onSelectHandler(e){
        if(e.detail && e.detail.name){
            this.categoryselected(e.detail.name);            
        }else if (e.detail && !e.detail.name){
            this.selected = null;
        }       
    }

    onExpandAll(e){
        this.expandAll(true);
    }

    onColapseAll(e){
        this.expandAll(false);
    }

    expandAll(expanded){
        this.categories = this.categories.map(x=>{
            x.expanded = expanded;
            x.items = x.items.map(y=>{
                y.expanded = expanded;
                return y;
            })
            return x;
        });
    }

    async categoryselected(docTypeId){
        let me = this;
        let docType = me.getDocTypeById(docTypeId);

        me.dispatchEvent(new CustomEvent('categoryselected',{detail: {docType: docType, recordName: me.recordName } }));
    }
}