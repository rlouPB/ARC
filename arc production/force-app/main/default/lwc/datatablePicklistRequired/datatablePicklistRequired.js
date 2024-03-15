import { LightningElement, api } from 'lwc';

export default class DatatablePicklistRequired extends LightningElement {
    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api context;
    
    handleChange(event) {

        // Dave Avery : 16Feb2022 : The below doesn't work but leaving for now in case of inspiration.
        // var dropdown = this.template.querySelector('lightning-combobox');
        // console.log('dropdown', dropdown)
        // if(dropdown){
        //     dropdown.className='slds-has-error';
        //     this.template.querySelector('lightning-combobox').className='slds-has-error';
        // } 

        //show the selected value on UI
        this.value = event.detail.value;

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.value }
            }
        }));
    }

}