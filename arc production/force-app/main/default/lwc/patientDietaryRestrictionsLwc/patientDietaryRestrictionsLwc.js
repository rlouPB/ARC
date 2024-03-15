import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import ACCOUNT_OBJECT from "@salesforce/schema/Account";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Account.Name";
import ACCOUNT_RESTRICTIONS_FIELD from "@salesforce/schema/Account.Dietary_Restrictions__c";
import ACCOUNT_COMMENTS_FIELD from "@salesforce/schema/Account.Dietary_Allergy_Comments__c";

export default class PatientDietaryRestrictionsLwc extends LightningElement {
	@api recordId;
	objectApiName = ACCOUNT_OBJECT;
	@track loading;
	fields = [ACCOUNT_NAME_FIELD, ACCOUNT_RESTRICTIONS_FIELD, ACCOUNT_COMMENTS_FIELD];

	handleSuccess() {
		this.dispatchEvent(
			new ShowToastEvent({
				title: "Success",
				message: this.recordId ? "Account updated" : "Account created",
				variant: "success",
			})
		);
		this.loading = false;
	}

	handleCancel(event) {
		const inputFields = this.template.querySelectorAll("lightning-input-field");
		if (inputFields) {
			inputFields.forEach((field) => {
				field.reset();
			});
		}
	}

	handleSubmit(event) {
		event.preventDefault();
		const fields = event.detail.fields;
		this.template.querySelector("lightning-record-edit-form").submit(fields);
		this.loading = true;
	}

	handleError() {
		this.dispatchEvent(
			new ShowToastEvent({
				title: "Error",
				message: this.recordId ? "Error updating Account" : "Error creating Account",
				variant: "error",
			})
		);
	}
}