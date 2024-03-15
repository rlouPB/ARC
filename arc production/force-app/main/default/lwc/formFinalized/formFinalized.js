import { LightningElement, api } from 'lwc';

export default class FormFinalized extends LightningElement 
{
	@api recordId;
	@api objectApiName;
}