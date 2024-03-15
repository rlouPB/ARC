import { LightningElement, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class CaseAbstractSectionItemLwc extends LightningElement {
	@api
	section

	@api
    recordId

	@api
	sectionitem

	itemVal

	@api 
	sectionCompleted

	get canEdit() {
		return this.sectionitem.sectionItemMdt.Allow_Editing__c && !this.sectionCompleted
	}

	connectedCallback() {
		console.log('connectedCallback sectionItem ' + this.sectionitem);
	}

	get digitalFileInfo() {
		// let textAnswer = '[{"versionID":"0682i000002zhuKAAQ","externalFileID":"Yh8PLVzcuMc5rSNrOLN60m","error":"","docTitle":"Genogram sample","docSize":"196 KB"}]';
		console.log('digitalFileInfo string ' + this.sectionitem.sectionFieldValue);
		let fileObjArray = JSON.parse(this.sectionitem.sectionFieldValue);
		// let fileObjArray = JSON.parse(textAnswer);
		return fileObjArray[0];
	}

	get showTitle() {
		//return ( !this.sectionitem.sectionItemMdt.Hide_Item_Title__c && this.sectionitem.sectionFieldValue != null );
		return !this.sectionitem.sectionItemMdt.Hide_Item_Title__c;
	}

	get isRichText() {
		return this.sectionitem.sectionItemMdt.Item_Type__c == 'Rich Text Area' ? true : false;
	}

	get isDigitalFile() {
		return this.sectionitem.sectionItemMdt.Item_Type__c == 'Digital File' ? true : false;
	}


	handleRichTextChange(event) {
		this.itemVal = event.target.value;
		var detailObj = {
			fieldName: this.sectionitem.sectionItemMdt.Section_Field_Name__c,
			fieldValue: this.sectionitem.sectionFieldValue
		}
		// this.sectionitem.sectionFieldValue;
		console.log('field value ' + event.target.value);
		console.log('field name ' + this.sectionitem.sectionItemMdt.Section_Field_Name__c);
		this.dispatchEvent(new CustomEvent('itemchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { fieldName: this.sectionitem.sectionItemMdt.Section_Field_Name__c, fieldValue: event.target.value }
            }
        }));
	}

	// handleRefreshItem(event) {

	// }

	// handleSaveButton(event) {

	// }

	
}