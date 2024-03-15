import { LightningElement, api } from 'lwc';

export default class DatatableRichTextfield extends LightningElement {
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
}