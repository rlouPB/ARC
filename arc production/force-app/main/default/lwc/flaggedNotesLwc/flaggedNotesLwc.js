import { LightningElement, track, api } from "lwc";
import getFlaggedNotes from "@salesforce/apex/FlaggedNotesService.getFlaggedNotes";
import getAlerts from "@salesforce/apex/FlaggedNotesService.getAlerts";

export default class FlaggedNotesLwc extends LightningElement {
	descendingSort = "/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#arrowdown";
	ascendingSort = "/apexpages/slds/latest/assets/icons/utility-sprite/svg/symbols.svg#arrowup";

	currentSorting = this.descendingSort;

	@api
	recordId;

	@track
	rawNotes = [];

	@track
	rawAlerts = [];

	@track
	noteDefinitions = [];

	@track
	selectedOption = "24 Hours";

	@track
	options = "24 Hours;7 Days;1 Month;Custom".split(";").map((x) => {
		return { value: x, label: x };
	});

	@track
	loading;

	@track
	showModal;

	@track
	selectedIndex = 0;

	@track
	customDateFrom;

	@track
	customDateTo;

	@track
	selectedIndex;

	flaggedColumns = ["Patient", "Team", "By", "Subject/Title", "Date/Time"];

	get filterOption() {
		return [
			{ label: "Sort By Date", value: "Sort By Date" },
			{ label: "Sort By Team", value: "Sort By Team" }
		];
	}

	// Select Sort By Date by default
	value = "Sort By Date";

	get selected() {
		let items = this.items;
		return this.selectedIndex != null && items.length > 0 && this.selectedIndex < items.length ? items[this.selectedIndex] : null;
	}

	get selectedItemName() {
		return `${this.selected?.patientName} - ${this.selected?.finalizedBy} - ${this.selected?.type}`;
	}

	@track
	items = [];

	get itemSize() {
		return this.items?.length;
	}

	fromDateChange(e) {
		this.customDateFrom = e.detail.value;
		this.load();
	}

	toDateChange(e) {
		this.customDateTo = e.detail.value;
		this.load();
	}

	get showLeftArrow() {
		return this.items?.length > 0 && this.selectedIndex > 0;
	}
	get showRightArrow() {
		let lenth = this.items?.length;
		return lenth > 0 && this.selectedIndex < lenth - 1;
	}

	get showCustomDates() {
		return this.selectedOption == "Custom";
	}

	get rightColumnClass() {
		return this.showCustomDates ? "slds-show" : "slds-hide";
	}

	get hasAlerts() {
		return this.items?.length > 0;
	}

	getIndexValue(idx) {
		if (idx < 0) {
			return 0;
		} else if (idx >= this.items.length && this.items.length > 0) {
			return this.items.length - 1;
		}
		return 0;
	}

	arrowRightClick() {
		let lenth = this.items?.length;
		let idx = this.selectedIndex || 0;
		this.selectedIndex = this.selectedIndex + 1;
	}

	arrowLefttClick() {
		let idx = this.selectedIndex || 0;
		this.selectedIndex = idx > 0 ? idx - 1 : 0;
	}

	addHours(dt, h) {
		dt.setTime(dt.getTime() + h * 60 * 60 * 1000);
		return dt;
	}

	connectedCallback() {
		var d = new Date();
		let today = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
		this.customDateFrom = today + "";
		this.customDateTo = today + "";
		this.load();
	}

	handleOptionChange(e) {
		this.selectedOption = e.detail.value;
		this.load();
	}

	onItemClick(e) {
		let id = e.currentTarget.dataset.id;
		let item = this.items.find((x) => x.id == id);
		this.selectedIndex = this.items.indexOf(item);
		this.showModal = true;
	}

	closeDialog(e) {
		this.showModal = false;
		this.selectedIndex = null;
	}

	get json() {
		return JSON.stringify(this.selectedDateRange);
	}

	async load() {
		this.loading = true;
		let range = this.selectedDateRange;

		this.rawNotes = await getFlaggedNotes({ patientId: this.recordId, dateFrom: this.customDateFrom, dateTo: this.customDateTo, timeRange: this.selectedOption });
		this.rawAlerts = await getAlerts({ patientId: this.recordId, dateFrom: this.customDateFrom, dateTo: this.customDateTo, timeRange: this.selectedOption });

		let results = [].concat(this.rawNotes, this.rawAlerts).map((item) => {
			console.log(JSON.parse(JSON.stringify(item)));
			let retObj = {
				record: { ...item },
				id: item.Id,
				dateOrder: item.CreatedDate || item.Patient_Note__r?.Finalized_Date_Time__c,
				type: item.CreatedDate ? "Alert" : "Note",
				subject: item.Subject__c || item.Type__c,
				documentType: item.CreatedDate ? item.Patient_Note__r?.Type__c : item.Type__c,
				snapshot: item.CreatedDate ? item.Patient_Note__r?.Snapshot__r?.Html__c : item.Snapshot__r.Html__c,
				patientId: item.Account__r?.Id || item.Patient_Note__r?.Account__r?.Id,
				patientName: item.Account__r?.Name || item.Patient_Note__r?.Account__r?.Name,
				team: item.Account__r?.Team__c || item.Patient_Note__r?.Account__r?.Team__c
			};

			if(item.Status__c == 'Finalized' || item.Patient_Note__r?.Status__c == 'Finalized') {
				retObj.finalizedDateTime = item.Finalized_Date_Time__c || item.Patient_Note__r?.Finalized_Date_Time__c;
				retObj.finalizedBy = item.Finalized_By__r?.Contact_Professional_Name__c || item.Finalized_By__r?.Name || item.Patient_Note__r?.Finalized_By__r?.Contact_Professional_Name__c || item.Patient_Note__r?.Finalized_By__r?.Name;
				retObj.finalizedById = item.Finalized_By__r?.Id || item.Patient_Note__r?.Finalized_By__r?.Id;
			} else if(item.Status__c == 'Completed' || item.Patient_Note__r?.Status__c == 'Completed') {
				retObj.finalizedDateTime = item.Completed_Date_Time__c || item.Patient_Note__r?.Completed_Date_Time__c;
				retObj.finalizedBy = item?.Completed_By_Professional_Name__c || item.Patient_Note__r?.Completed_By_Professional_Name__c || item.Completed_By__r?.Name || item.Patient_Note__r?.Completed_By__r?.Name;
				retObj.finalizedById = item.Completed_By__r?.Id || item.Patient_Note__r?.Completed_By__r?.Id;
			}
			return retObj;
		});

		//Sorting...
		results.sort((x, y) => {
			let x1 = x.finalizedDateTime;
			let y1 = y.finalizedDateTime;

			//Descending order
			return -1 * ((x1 > y1) - (y1 > x1));
		});

		this.items = results;
		this.loading = false;
	}

	handleSort(event) {
		this.items.sort((x, y) => {
			//Descending order
			return event.detail.value == "Sort By Team" ? this.multipleColumnSort(x, y) : this.dateColumnSort(x, y);
		});
	}

	multipleColumnSort(a, b) {
		var firstTeam = a.team?.toLowerCase();
		var secondTeam = b.team?.toLowerCase();

		var firstPatientName = a.patientName?.toLowerCase();
		var secondPatientName = b.patientName?.toLowerCase();

		var firstDate = a.finalizedDateTime;
		var secondDate = b.finalizedDateTime;

		if (firstTeam < secondTeam) return -1;
		if (firstTeam > secondTeam) return 1;
		if (firstPatientName < secondPatientName) return -1;
		if (firstPatientName > secondPatientName) return 1;
		if (firstDate > secondDate) return -1;
		if (firstDate < secondDate) return 1;
		return 0;
	}

	dateColumnSort(x, y) {
		let x1 = x.finalizedDateTime;
		let y1 = y.finalizedDateTime;

		return -1 * ((x1 > y1) - (y1 > x1));
	}
}