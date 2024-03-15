import { LightningElement, track, api } from 'lwc';

export default class PaginatorLwc extends LightningElement {
    @track
    currentPage

    @api
    pageSize=25
    
    @api 
    values=[]

    // @api
    // get values(){
    //     console.info('get values --- ', this._values)
    //     return this._values || []
    // }

    // set values(v){
    //     console.info('set values --- ', v)
    //     this._values = v
    //     this.pageChanged()
    // }

    get leftButtons(){
        return ['<<','<'].map(x=>{return {label:x,value:x}})
    }

    get rightButtons(){
        return ['>','>>'].map(x=>{return {label:x,value:x}})
    }

    get totalItems(){
        return this.values? this.values.length : 0
    }

    get totalPages(){
        return this.values? Math.ceil(parseInt(this.totalItems) / parseInt(this.pageSize) ) : 0
    }

    get offset(){
        return (this.currentPage-1)*this.pageSize
    }

    get showPaginator(){
        return this.pageSize < this.values?.length
    }
    
    get pagesArray(){
        if(this.values){            
            return [].concat(
                this.leftButtons, 
                [...Array(this.totalPages).keys()].map(x=>{
                    let v = x+1
                    return {
                        label: v.toString(),
                        value: v.toString(),
                    }
                }), 
                this.rightButtons
            )
        }
        return []
    }

    get pagedValues(){
        return this.values?  this.values.slice(this.offset,this.offset+this.pageSize) : []
    }

    connectedCallback(){        
        this.currentPage = '1'
        setTimeout(()=>this.pageChanged(),1000)
    }

    onPaging(e){
        switch( e.detail.value ){
            case '<':  
                this.onPrevClick()
                break
            case '<<':
                this.onFirstClick()
                break
            case '>':
                this.onNextClick()
                break
            case '>>':
                this.onLastClick()
                break
            default:
                this.currentPage = e.detail.value
                this.pageChanged()
        }
    }

    @api
    pageChanged(data){
        if(data){
            this.values = data;
        }
        const pagechanged = new CustomEvent('pagechanged',{
            detail: {                
                page: this.currentPage,
                totalSize: this.totalItems,
                totalPages: this.totalPages,
                values: JSON.parse(JSON.stringify(this.pagedValues)),
            }
        })
        this.dispatchEvent(pagechanged)
    }

    get hasValues(){
        return this.totalItems > 0
    }

    onFirstClick(){
        if(this.totalItems > 0){
            this.currentPage = '1'
            this.pageChanged()
        }
    }
    onLastClick(){
        if(this.totalItems > 0){
            this.currentPage = this.totalPages.toString()
            this.pageChanged()
        }
    }
    onPrevClick(){
        if(this.totalItems > 0){
            let prevPage = parseInt( this.currentPage ) - 1
            this.currentPage = (prevPage < 1 )? '1' : prevPage.toString()
            this.pageChanged()
        }
    }
    onNextClick(){
        if(this.totalItems > 0){
            let nextPage = parseInt( this.currentPage ) + 1
            this.currentPage = (nextPage > this.totalPages)? this.totalPages.toString() : nextPage.toString()
            this.pageChanged()
        }
    }
}