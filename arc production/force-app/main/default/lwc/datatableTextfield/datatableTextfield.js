import { LightningElement, api } from 'lwc';

export default class DatatableTextfield extends LightningElement {
    @api label;
    @api placeholder;
    @api disabled;
    @api value;
    @api context;

    renderedCallback(){

        console.log('this.context');
        console.log(this.context);
        console.log('this.value');
        console.log(this.value);
        console.log('this.disabled');
        console.log(this.disabled);
    }

    handleChange(event) {
        //show the selected value on UI
        this.value = event.detail.value;

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('textfieldchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.value }
            }
        }));
    }
    
}