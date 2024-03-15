import { LightningElement, api, track } from "lwc";
import refreshSection from "@salesforce/apex/CaseAbstract.refreshSection";
import saveSection from "@salesforce/apex/CaseAbstract.saveSection";
import setStatus from "@salesforce/apex/CaseAbstract.setStatus";
import setOwner from "@salesforce/apex/CaseAbstract.setOwner";
import Id from "@salesforce/user/Id";
import hasClinicalAdmin from "@salesforce/customPermission/Clinical_Admin";
import hasMedical_Records from "@salesforce/customPermission/Medical_Records";

export default class CaseAbstractSectionLwc extends LightningElement {
	@api
	sectionReadOnly;
	@api
	caseAbstractStatus;
	@track
	section;
	showSpinner;
	sectionObject = {};
	action;
	completed = false;
	completedBy;
	completedDatetime;
	showConfirmModal = false;
	showLookupComponent = false;
	confirmationModalText = "Are you sure you want to refresh from source? Any changes will be overwritten";
	sectionOewnerId;
	userId = Id;

	isFinalized() {
		console.log("this.caseAbstractStatus=" + this.caseAbstractStatus);
		return this.caseAbstractStatus == "Finalized";
	}
	get isSectionHeaderLarge() {
		return this.section.sectionMdt.Header_Size__c == "Large" ? true : false;
	}

	get canRefreshFromSourceDisabled() {
		return !this.canRefreshFromSource || this.isFinalized();
	}

	get canRefreshFromSource() {
		return this.section.canRefreshFromSource || hasClinicalAdmin;
	}

	get isChangeResponsibleUserDisabled() {
		return this.caseAbstractStatus == "Finalized" || this.completed;
	}

	get canViewChangeResponsibleUser() {
		return !(this.isResponsibleQueueType || this.caseAbstractStatus == "Finalized" );
	}

	get isSectionDisabled() {
		return !this.section.canSave || this.isFinalized();
	}

	get markCompleteDisabled() {
		//return this.section.record.OwnerId != this.userId;
		return !(this.section.canEdit || hasClinicalAdmin) || this.isFinalized();
	}

	get reOpenDisabled() {
		//return this.section.record.OwnerId != this.userId;
		return !(this.section.canEdit || hasClinicalAdmin || hasMedical_Records) || this.isFinalized() ;
	}

	get isResponsibleQueueType() {
		return this.section.ownerType == "Responsible Queue";
	}
	// get sectionHeaderClassName() {
	// 	let className = 'slds-text-heading_small';
	// 	console.log('className ' + className);
	// 	if (this.section.sectionMdt.Header_Size__c == 'Large') {
	// 		className = 'slds-text-heading_large';
	// 	}
	// 	return className;
	// }

	get changeOwnerLabel() {
		return "Change " + this.section.ownerType;
	}

	get sectionDivClassName() {
		let className = "slds-m-left_none";
		if (this.section.sectionMdt.Header_Size__c == "Normal") {
			className = "slds-m-left_none slds-p-left_medium";
		}

		return className;
	}

	get errorMessagesClassName() {
		let className = "errorMessages slds-m-left_x-large slds-text-heading_small slds-border_top slds-border_left slds-border_right slds-border_bottom slds-p-around_small";
		return className;
	}

	get confirmationModalText() {
		return this.confirmationModalText;
	}

	connectedCallback() {
		this.section = JSON.parse(JSON.stringify(this.sectionReadOnly));
		console.log("Running connectedCallback() on caseAbstractSection");
		this.completed = this.section.record.Status__c == "Completed" ? true : false;
		if (this.section?.record?.Completed_Date_Time__c) {
			this.completedDatetime = new Date(this.section.record.Completed_Date_Time__c);
		}
		this.completedBy = this.section?.record?.Completed_By_Professional_Name__c;
	}

	handleButtonClick(event) {
		console.log("handleButtonClick() event.currentTarget.id " + event.currentTarget.id);
		this.action = event.currentTarget.dataset.action;
		this.showConfirmModal = true;
		switch (this.action) {
			case "Save":
				// code block
				this.showConfirmModal = false;
				this.save();
				break;
			case "Refresh From Source":
				this.confirmationModalText = "Are you sure you want to refresh from source? Any changes will be overwritten";
				break;
			case "Change Responsible User":
				this.showConfirmModal = false;
				this.showLookupComponent = true;
				break;
			case "Mark Completed":
				this.confirmationModalText = "Are you sure you want to mark this section completed?";
				break;
			case "Re-Open":
				this.confirmationModalText = "Are you sure you want to re-open this section?";
				break;
			default:
			// code block
		}
	}
	closeConfirmationBox(event) {
		this.showConfirmModal = false;
	}
	performAction(event) {
		switch (this.action) {
			case "Refresh From Source":
				this.showConfirmModal = false;
				this.refresh();

				break;
			case "Change Responsible User":
				this.showConfirmModal = false;
				this.showLookupComponent = true;

				break;
			case "Mark Completed":
				this.showConfirmModal = false;
				this.markCompleted();

				break;
			case "Re-Open":
				this.showConfirmModal = false;
				this.reopen();

				break;
			default:
			// code block
		}
	}
	handleItemChange(event) {
		const payload = event.detail.data;

		this.sectionObject[payload.fieldName] = payload.fieldValue;
	}
	refreshFromSource(event) {
		console.log("handleButtonClick() event.currentTarget.id " + event.currentTarget.id);
		//let sectionId = event.currentTarget.dataset.id;

		this.refresh();

		// this.showConfirmModal = true;
	}

	saveSection(event) {
		this.save();

		// this.showConfirmModal = true;
	}

	async save() {
		this.showSpinner = true;
		this.sectionObject.Id = this.section.record.Id;
		let result = await saveSection({
			sectionString: JSON.stringify(this.sectionObject)
		});
		if (result) {
			//this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')
			//this.refresh();
			//this.section = JSON.parse(result);
			this.showSpinner = false;
		} else {
			console.info(`Updating ${fieldName} to value: ${value}, success.`);
		}
	}

	async refresh() {
		this.showSpinner = true;

		let result = await refreshSection({
			sectionString: JSON.stringify(this.section)
		});
		if (result) {
			//this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')

			this.section = JSON.parse(result);
			this.completed = this.section.record.Status__c == "Completed" ? true : false;
			if (this.section?.record?.Completed_Date_Time__c) {
				this.completedDatetime = new Date(this.section.record.Completed_Date_Time__c);
			}
			this.completedBy = this.section?.record?.Completed_By_Professional_Name__c;
		} else {
			console.info(`Updating ${fieldName} to value: ${value}, success.`);
		}
		this.showSpinner = false;
	}

	async markCompleted() {
		var me = this;
		this.showSpinner = true;
		this.sectionObject.Id = this.section.record.Id;
		this.sectionObject.Status__c = "Completed";

		let result = await saveSection({
			sectionString: JSON.stringify(this.sectionObject)
		});

		if (result) {
			//this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')
			//this.refresh();
			//this.section = JSON.parse(result);
			this.showSpinner = false;
			this.completed = result.Status__c == "Completed" ? true : false;
			if (result.Completed_Date_Time__c) {
				this.completedDatetime = new Date(result.Completed_Date_Time__c);
			}
			this.completedBy = result.Completed_By_Professional_Name__c;
			this.section.items.map((item) => {
				for (var key in me.sectionObject) {
					if (key == item.sectionItemMdt.Section_Field_Name__c) {
						item.sectionFieldValue = me.sectionObject[key];
					}
				}
			});
		} else {
			console.info(`Updating ${fieldName} to value: ${value}, success.`);
		}
	}

	async reopen() {
		var me = this;
		this.showSpinner = true;
		this.sectionObject.Id = this.section.record.Id;
		this.sectionObject.Status__c = "Draft";

		let result = await saveSection({
			sectionString: JSON.stringify(this.sectionObject)
		});

		if (result) {
			//this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')
			//this.refresh();
			//this.section = JSON.parse(result);
			this.showSpinner = false;
			this.completed = result.Status__c == "Completed" ? true : false;
			if (result.Completed_Date_Time__c) {
				this.completedDatetime = new Date(result.Completed_Date_Time__c);
			}
			this.completedBy = result.Completed_By_Professional_Name__c;
			this.section.items.map((item) => {
				for (var key in me.sectionObject) {
					if (key == item.sectionItemMdt.Section_Field_Name__c) {
						item.sectionFieldValue = me.sectionObject[key];
					}
				}
			});
		} else {
			console.info(`Updating ${fieldName} to value: ${value}, success.`);
		}
	}
	changeResponsibleUser() {
		let me = this;
		me.showLookupComponent = false;
		me.showSpinner = true;
		setOwner({
			sectionId: me.section.record.Id,
			ownerId: me.sectionOwnerId
		})
			.then((result) => {
				//reload the section
				//this.refresh();
				this.dispatchEvent(new CustomEvent("refreshcaseabstract"));
			})
			.catch((e) => {
				console.warn("markSectionCompleted Error thrown: ", e);
			})
			.finally(() => {
				me.showSpinner = false;
			});
	}
	closeLookupComponent() {
		this.showLookupComponent = false;
	}
	handleLookupChanged(event) {
		this.sectionOwnerId = event.detail.value;
	}
}