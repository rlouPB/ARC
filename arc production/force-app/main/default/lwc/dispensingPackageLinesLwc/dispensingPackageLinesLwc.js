import { LightningElement, api, wire, track } from "lwc";
import getPackageLines from "@salesforce/apex/DispensingService.getPackageLines";
import { NavigationMixin } from "lightning/navigation";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

// import { getPicklistValues } from "lightning/uiObjectInfoApi";
// import EFFICACY_FIELD from "@salesforce/schema/Package_Line__c.Efficacy__c";
// import { getRecord, getFieldValue } from "lightning/uiRecordApi";

const columns = [
	{
		label: "Package Line Name",
		fieldName: "nameLink",
		hideDefaultActions: true,
		initialWidth: 120,
		type: "url",
		sortable: true,
		typeAttributes: { label: { fieldName: "Name" }, target: "_self" },
	},
	{
		label: "Prescription",
		fieldName: "rxLink",
		hideDefaultActions: true,
		initialWidth: 220,
		type: "url",
		sortable: true,
		typeAttributes: { label: { fieldName: "filledWith" }, target: "_self" },
	},
	{
		label: "Prescription Quantity",
		fieldName: "Prescription_Quantity__c",
		hideDefaultActions: true,
		initialWidth: 180,
		type: "number",
		editable: true,
		sortable: true,
		typeAttributes: {
			minimumFractionDigits: "2",
			maximumFractionDigits: "2",
		},
		cellAttributes: { alignment: "left" },
	},
	{
		label: "Medication and Format",
		fieldName: "Medication_and_Format__c",
		hideDefaultActions: true,
		initialWidth: 200,
		type: "text",
		editable: false,
		sortable: true,
	},
	{
		label: "Amount Taken",
		fieldName: "Amount_Taken__c",
		hideDefaultActions: true,
		initialWidth: 140,
		type: "number",
		editable: true,
		sortable: true,
		typeAttributes: {
			minimumFractionDigits: "2",
			maximumFractionDigits: "2",
		},
		cellAttributes: { alignment: "left" },
	},
	{
		label: "Amount Returned",
		fieldName: "Amount_Returned__c",
		hideDefaultActions: true,
		initialWidth: 140,
		type: "number",
		editable: true,
		sortable: true,
		typeAttributes: {
			minimumFractionDigits: "2",
			maximumFractionDigits: "2",
		},
		cellAttributes: { alignment: "left" },
	},
	{
		label: "Efficacy",
		fieldName: "Efficacy__c",
		hideDefaultActions: true,
		initialWidth: 140,
		type: "text",
		editable: false,
		sortable: true,
	},
	{
		label: "Pharmacy Returned",
		fieldName: "Pharmacy_Amount_Returned_Variance__c",
		hideDefaultActions: true,
		initialWidth: 140,
		type: "text",
		editable: true,
		sortable: true,
	},
];

// const pickVals = [EFFICACY_FIELD];

export default class DispensingPackageLinesLwc extends NavigationMixin(LightningElement) {
	@track data = [];
	columns = columns;
	// @track packageLines;
	defaultSortDirection = "asc";
	sortDirection = "asc";
	sortedBy = "Prescription";
	@track packageLineNodes;
	@track dataLength;
	@api recordId;
	fldsItemValues = [];
	@track loading = false;
	async connectedCallback() {
		console.log("DispensingPackageLinesLwc connectedCallback...");
		await this.load();
	}

	async load() {
		console.log("DispensingPackageLinesLwc load...");
		this.loading = true;
		this.data = await getPackageLines({ packageId: this.recordId });
		console.log("c/dispensingPackageLinesLwc load return data: " + JSON.stringify(this.data));
		this.dataLength = this.data.length;
		this.createPackageLineNodes(this.data);
		console.log("c/dispensingPackageLinesLwc load node data: " + JSON.stringify(this.data));
		this.loading = false;
	}

	sortBy(field, reverse, primer) {
		console.log("DispensingPackageLinesLwc sortBy...");
		// console.log("DispensingPackageLinesLwc sortBy field: " + field);
		// console.log("DispensingPackageLinesLwc sortBy reverse: " + reverse);
		// console.log("DispensingPackageLinesLwc sortBy primer: " + primer);
		const key = primer
			? function (x) {
					return primer(x[field]);
			  }
			: function (x) {
					return x[field];
			  };

		return function (a, b) {
			a = key(a);
			b = key(b);
			return reverse * ((a > b) - (b > a));
		};
	}

	navigateToPackageLines() {
		// Navigate to the Account home page
		this[NavigationMixin.Navigate]({
			type: "standard__recordRelationshipPage",
			attributes: {
				recordId: this.recordId,
				objectApiName: "Package__c",
				relationshipApiName: "Package_Lines__r",
				actionName: "view",
			},
		});
	}

	// hideCardFooter(event) {
	// 	console.log("DispensingPackageLinesLwc hideCardFooter...");
	// 	let _self = this;
	// 	console.log(_self);
	// 	console.log(JSON.stringify(_self.data));
	// 	console.log(JSON.stringify(_self.fldsItemValues));

	// var tableFooter = _self.template.querySelector(".slds-docked-form-footer");
	// console.log(tableFooter);

	// var footer = _self.template.querySelector('[data-id="footer"]');
	// if (footer) {
	// 	_self.template.querySelector('[data-id="footer"]').className = "slds-card__footer slds-hide";
	// }
	// _self = this;
	// console.log(_self);
	// console.log(cardFooter);
	// cardFooter.classList.addClass("slds-hide");
	// console.log(self.template.querySelector("article"));
	// ('footer').addClass("slds-hide");
	// }

	onHandleSort(event) {
		console.log("DispensingPackageLinesLwc onHandleSort...");
		console.log("DispensingPackageLinesLwc onHandleSort event.detail: " + JSON.stringify(event.detail));
		const { fieldName: sortedBy, sortDirection } = event.detail;
		const cloneData = [...this.data];
		console.log("DispensingPackageLinesLwc onHandleSort cloneData: " + JSON.stringify(cloneData));

		cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
		console.log("DispensingPackageLinesLwc onHandleSort sortDirection: " + sortDirection);
		console.log("DispensingPackageLinesLwc onHandleSort sortedBy: " + sortedBy);
		this.data = cloneData;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
	}

	saveHandleAction(event) {
		console.log("DispensingPackageLinesLwc saveHandleAction...");
		this.loading = true;
		this.fldsItemValues = event.detail.draftValues;
		console.log("DispensingPackageLinesLwc saveHandleAction fldsItemValues: " + JSON.stringify(this.fldsItemValues));
		const inputsItems = this.fldsItemValues.slice().map((draft) => {
			const fields = Object.assign({}, draft);
			return { fields };
		});

		const promises = inputsItems.map((recordInput) => updateRecord(recordInput));
		Promise.all(promises)
			.then((res) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Success",
						message: "Records Updated Successfully!!",
						variant: "success",
					})
				);
				this.fldsItemValues = [];
				return this.load();
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Error",
						message: "An Error Occured!!",
						variant: "error",
					})
				);
				console.log(error.body.message);
			})
			.finally(() => {
				this.fldsItemValues = [];
			});
		this.loading = false;
	}

	createPackageLineNodes(data) {
		console.log("DispensingPackageLinesLwc createPackageLineNodes...");
		const mynodes = [];
		this.data.forEach((element) => {
			let node1 = {
				Id: element.Id,
				Name: element.Name,
				nameLink: "/" + element.Id,
				filledWith:
					element.Prescription__r.Medication_Filled_with__c === undefined
						? element.Prescription__r.Name
						: element.Prescription__r.Medication_Filled_with__c,
				rxLink: "/" + element.Prescription__c,
				// Quantity: element.Prescription_Quantity__c === undefined ? 0 : element.Prescription_Quantity__c,
				Prescription_Quantity__c: element.Prescription_Quantity__c,
				Medication_and_Format__c: element.Medication_and_Format__c,
				Amount_Taken__c: element.Amount_Taken__c === undefined ? 0 : element.Amount_Taken__c,
				// Amount_Taken__c: element.Amount_Taken__c,
				Amount_Returned__c: element.Amount_Returned__c === undefined ? 0 : element.Amount_Returned__c,
				// Amount_Returned__c: element.Amount_Returned__c,
				Efficacy__c: element.Efficacy__c,
				Pharmacy_Amount_Returned_Variance__c: element.Pharmacy_Amount_Returned_Variance__c
			};
			mynodes.push(node1);
		});

		this.data = mynodes;
		// console.log(JSON.stringify(this.data));
	}

	async refresh() {
		console.log("DispensingPackageLinesLwc refresh...");
		await refreshApex(this.data);
	}
}