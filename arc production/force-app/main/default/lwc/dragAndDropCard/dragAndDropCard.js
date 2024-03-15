import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'
export default class DragAndDropCard extends NavigationMixin(LightningElement) {
    @api stage
    @api record
    @api objectapiname
    @api required // contians required fields to display on kanban

    get isSameStage(){
        return this.stage === this.record.StageName
    }
    navigateOppHandler(event){
        event.preventDefault()
        // this.navigateHandler(event.target.dataset.id, 'Variance__c')
        this.navigateHandler(event.target.dataset.id, this.objectapiname)

    }
    navigateAccHandler(event){
        event.preventDefault()
        this.navigateHandler(event.target.dataset.id, this.objectapiname)
    }
    navigateHandler(Id, apiName) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: Id,
                objectApiName: apiName,
                actionName: 'view',
            },
        }).then(generatedUrl => {
            window.open(generatedUrl, "_blank");
        });
        
    }
    itemDragStart(){
        const event = new CustomEvent('itemdrag', {
            detail: this.record.Id
        })
        this.dispatchEvent(event)
    }

    get fields(){
        var arr = []
        Object.keys(this.record).forEach(i => {
            if(this.required.includes(i)){
                const obj = {label: i , value : this.record[i] }
                arr.push(obj)
            }
        })
        return arr
    }
}