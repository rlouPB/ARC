import { LightningElement, api, track } from 'lwc';
import getAllCategories from '@salesforce/apex/MedRecordHierarchy.getAllCategories'

export default class MedRecordCategoriesLwc extends LightningElement {

    @track
    data;

    @track
    categories;

    @track
    searchText;

    selected;

    connectedCallback(){
        let me = this;
        getAllCategories({}).then((result)=>{
            me.data = JSON.parse(result).map((catItem)=>{
                return {
                    label: catItem.obj.Name__c,
                    expanded: true,
                    items: catItem.docTypes.map((docType)=>{
                        return {
                            label : docType.obj.Name__c,
                            name: docType.obj.Id,
                            expanded : true,
                        };
                    }),
                }
            });
            me.categories = me.data;
        });
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
        let val = value.trim().toLowerCase();
        if( val ){
            let cloned = JSON.parse(JSON.stringify(this.data));
            this.categories = cloned.map(x=>{
                let include = x.label.toLowerCase().includes(val);
                x.include = include || x.items.filter(y=>y.label.toLowerCase().includes(val)).length > 0;
                x.items = include ? x.items.map(x1=>x1) : x.items.filter(x1=>x1.label.toLowerCase().includes(val));
                return x;
            }).filter(x=>x.include);
        }else{
            this.categories = this.data.map(x=>x);
        }
    }
    onSelectHandler(e){
        if(e.detail && e.detail.name){
            if(this.selected == e.detail.name  ){
                this.categoryselected(e.detail.name);
                this.selected = null;
            }else{
                this.selected = e.detail.name;            
            }
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
                y.expanded - expanded
                return y;
            })
            return x;
        });
    }
    categoryselected(categoryId){
        this.dispatchEvent(new CustomEvent('categoryselected',{detail: {categoryId: categoryId} }));
    }
}