import { LightningElement, api, wire } from 'lwc';
import getRecord from '@salesforce/apex/RecordViewService.getRecord';

export default class RecordView extends LightningElement {
    @api
    recordId

    @api
    nameField='Name'

    @wire(getRecord, { recordId: '$recordId', nameField: '$nameField' })
    recordResponse;
}