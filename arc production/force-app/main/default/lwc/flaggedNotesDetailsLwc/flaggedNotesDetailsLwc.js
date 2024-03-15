import { LightningElement, api } from "lwc";

export default class FlaggedNotesDetailsLwc extends LightningElement {
	@api
	selected;

	get createdBy() {
		return this.selected?.record?.CreatedBy?.Name;
	}

	get subject() {
		return this.selected?.subject;
	}

	get type() {
		return this.selected?.type;
	}

	get isAlert() {
		return this.type == "Alert";
	}

	get snapshot() {
		// Reformat Snapshot__c.Html__c output for Flagged Notes modal
		let result = this.selected?.snapshot;
		result = result.replace(/h1/g, "div");
		result = result.replace(/<hr class="slds-m-top_x-small slds-m-bottom_x-small">/g, "");
		result = result.replace(/slds-text-heading_small/g, "slds-box_xx-small");
		result = result.replace(/slds-form-element c/g, "slds-form-element c slds-var-p-left_xx-small");
		result = result.replace(/<p>/g, '<p class="slds-var-p-bottom_small slds-var-p-left_xx-small">');
		result = result.replace(/<table>/g, '<table class="slds-border_bottom" style="width: 100%;">');
		result = result.replace(/<br>/g, "");
		result = result.replace(/slds-text-title/g, "slds-page-header__title slds-p-vertical_medium slds-var-p-left_xx-small");
		console.log(result);
		return result;
	}

	get dateOrder() {
		return this.selected?.dateOrder;
	}

	get body() {
		return this.selected?.record?.Body__c;
	}

	get documentType() {
		return this.selected?.documentType;
	}
}