import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getResult from "@salesforce/apex/ViewOutstandingItemsApexController.getResult";
import getFilteredResult from "@salesforce/apex/ViewOutstandingItemsApexController.getFilteredResult";
// import search from "@salesforce/apex/ViewOutstandingItemsApexController.search";
import Id from "@salesforce/user/Id";

const columns = [
	
	{
		label: "Label",
		fieldName: "LongTagLabel",
		type: "text",
		sortable: true,
		wrapText: true
		// typeAttributes: {
		// 	label: { fieldName: "LongTagLabel" },
		// 	tooltip: { fieldName: "LongTagLabel" },
		// 	target: "_blank",
		// 	wrapText: true,
		// }
	},
	{
		label: "Link",
		fieldName: "recordLink",
		type: "url",
		sortable: false,
		typeAttributes: {
			label: "Open",
			tooltip: { fieldName: "LongTagLabel"},
			target: "_blank"
		},
	},
	// { label: 'Doc Date', fieldName: 'DocDate', type: 'date', sortable: true, cellAttributes: { alignment: 'center' }, typeAttributes:{
	//     year: "2-digit",
	//     month: "2-digit",
	//     day: "2-digit"
	// } },
	{
		label: "Due Date",
		fieldName: "TargetDate",
		//type: "date",
		type: "date-local",
		sortable: true,
		cellAttributes: { alignment: "center" },
		typeAttributes: {
			year: "2-digit",
			month: "2-digit",
			day: "2-digit",
		},
	},
	{ 	label: "Days Past Due", 
		fieldName: "Overdue", 
		sortable: true, 
		cellAttributes: { alignment: "center" } 
	},
];

export default class ViewOutstandingItemsLwc extends LightningElement {
	@api mode = "Open Items";
	@api patientId = "";

	currentUserId = Id;
	dataOpenItems = [];
	columnsOpenItems = [];
	@track sortBy;
	@track sortDirection;

	title = "Open Items";
	radioButtonTitleValue = "openItems";
	selectedUserID = "";
	categoryOptions = [];
	outstandingResult = {};
	selectedCategories = [];
	categoryValue = [];
	allNoneValue = "all";
	isAllSelected = false;
	isLoading = false;

	//For the Looup
	initialLookupSelection = [];
	errors = [];
	isMultiEntry = false;
	maxSelectionSize = 0;

	get options() {
		return [
			{ label: "Open Items", value: "openItems" },
			{ label: "Shared Open Items", value: "teamOpenItems" },
		];
	}

	get optionsAllNone() {
		return [
			{ label: "Select All", value: "all" },
			{ label: "Select None", value: "none" },
		];
	}

	get selectAllNoneLabel() {
		return this.isAllSelected ? "Select all" : "Select none";
	}

	connectedCallback() {
		this.selectedUserID = this.currentUserId;

		this.handleColumns();

		this.loadItems();
	}

	handleColumns() {
		this.dataOpenItems = [];
		this.columnsOpenItems = columns;
		let patientColumnIndex = 1;
		if (this.mode == "Shared Open Items") {
			let tempColumns = [...this.columnsOpenItems];
			tempColumns.splice(0, 0, { label: "Queue", fieldName: "OwnerName", sortable: true });
			this.columnsOpenItems = tempColumns;
			patientColumnIndex = 2;
		}

		if (this.patientId == "" || this.patientId == null) {
			let tempColumns = [...this.columnsOpenItems];
			tempColumns.splice(patientColumnIndex, 0, { label: "Patient", fieldName: "PatientName", sortable: true });
			this.columnsOpenItems = tempColumns;
		}
	}

	handleOpenItemTitle(event) {
		console.log("****** event ---> ", event);
		console.log("****** event ---> ", JSON.parse(JSON.stringify(event.detail)));
		this.title = event.detail.value == "openItems" ? "Open Items" : "Shared Open Items";
		this.mode = this.title;
		this.selectedCategories = [];

		this.handleColumns();
		this.loadItems();
	}

	loadItems() {
		if (!this.selectedUserID) {
			return;
		}

		this.isLoading = true;

		if (this.selectedCategories.length > 0) {
			getFilteredResult({
				selectedUserID: this.selectedUserID,
				chosenCategories: this.selectedCategories,
				patientId: this.patientId,
				mode: this.mode,
			})
				.then((results) => {
					if (results) {
						console.log("::::: results ---> ", JSON.parse(JSON.stringify(results)));
						this.outstandingResult = results;
						//this.dataOpenItems = this.processResults(this.outstandingResult);
						this.dataOpenItems = this.processResults(this.outstandingResult.outstandingWrappers); //JN 210616
						this.isLoading = false;
					}
				})
				.catch((error) => {
					this.notifyUser("Form data Error", "An error occured while loading the Open Items.", "error");
					console.error("**** Form Data Error: ", error);
					this.isLoading = false;
				});
		} else {
			getResult({
				selectedUserID: this.selectedUserID,
				patientId: this.patientId,
				mode: this.mode,
			})
				.then((results) => {
					if (results) {
						console.log("::::: results ---> ", JSON.parse(JSON.stringify(results)));
						this.outstandingResult = results;
						
						this.isAllSelected = false;

						this.loadCategories(this.outstandingResult.categories);
						this.dataOpenItems = this.processResults(this.outstandingResult.outstandingWrappers);
						this.isLoading = false;
					}
				})
				.catch((error) => {
					this.notifyUser("Form data Error", "An error occured while loading the Open Items.", "error");
					console.error("**** Form Data Error: ", error);
					this.isLoading = false;
				});
		}
	}

	notifyUser(title, message, variant) {
		if (this.notifyViaAlerts) {
			// Notify via alert
			// eslint-disable-next-line no-alert
			alert(`${title}\n${message}`);
		} else {
			// Notify via toast
			const toastEvent = new ShowToastEvent({ title, message, variant });
			this.dispatchEvent(toastEvent);
		}
	}

	loadCategories(categoryResult) {
		if (!categoryResult) {
			return;
		}

		let newList = [];
		let selectValues = [];

		for (let i = 0; i < categoryResult.length; i++) {
			const category = categoryResult[i];

			newList.push({
				label: category,
				value: category,
			});
			selectValues.push(category);
		}

		this.categoryOptions = newList;
		this.categoryValue = selectValues;
	}

	handleChangeCategories(event) {
		this.selectedCategories = event.detail.value;

		this.isAllSelected = this.categoryOptions.length > this.selectedCategories.length;

		if (this.selectedCategories.length > 0) {
			this.loadItems();
		} else {
			this.dataOpenItems = [];
			this.isAllSelected = true;
		}
	}

	/**
	 * Handles the lookup search event.
	 * Calls the server to perform the search and returns the resuls to the lookup.
	 * @param {event} event `search` event emmitted by the lookup
	 */
	// handleLookupSearch(event) {
	// 	const lookupElement = event.target;
	// 	// Call Apex endpoint to search for records and pass results to the lookup
	// 	search(event.detail)
	// 		.then((results) => {
	// 			lookupElement.setSearchResults(results);
	// 		})
	// 		.catch((error) => {
	// 			this.notifyUser("Lookup Error", "An error occured while searching with the lookup field.", "error");
	// 			// eslint-disable-next-line no-console
	// 			console.error("Lookup error", JSON.stringify(error));
	// 			this.errors = [error];
	// 		});
	// }

	/**
	 * Handles the lookup selection change
	 * @param {event} event `selectionchange` event emmitted by the lookup.
	 * The event contains the list of selected ids.
	 */
	// eslint-disable-next-line no-unused-vars
	handleLookupSelectionChange(event) {
		this.checkForErrors();
	}

	checkForErrors() {
		this.errors = [];
		const selection = this.template.querySelector("c-lookup-lwc").getSelection();
		console.log("::::: selection ---> ", JSON.parse(JSON.stringify(selection)));
		// Custom validation rule
		if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
			this.errors.push({ message: `You may only select up to ${this.maxSelectionSize} users.` });
			return;
		}
		// Enforcing required field
		if (selection.length === 0) {
			this.clearValues();
			this.errors.push({ message: "Please make a selection." });
		}

		if (selection.length > 0) {
			this.selectedUserID = selection[0].id;
			this.loadItems();
		}
	}

	clearValues() {
		this.dataOpenItems = [];
		this.categoryOptions = [];
	}

	processResults(results) {
		if (results) {
			let resultsListProcessed = new Array();

			for (let i = 0; i < results.length; i++) {
				let result = results[i];
				// result.recordLink = "/" + result.Record_to_Link_To__c; //performed on server now
				resultsListProcessed.push(result);
			}

			return resultsListProcessed;
		}

		return results;
	}

	handleSortdata(event) {
		console.log('handleSortdata event ' + event);
		// field name
		var selectedSortBy = event.detail.fieldName;
		// if (selectedSortBy == 'recordLink') {
		// 	selectedSortBy = 'LongTagLabel';
		// }
		this.sortBy = selectedSortBy;

		// sort direction
		this.sortDirection = event.detail.sortDirection;

		// calling sortdata function to sort the data based on direction and selected field
		this.sortData(selectedSortBy, event.detail.sortDirection);
	}

	sortData(fieldname, direction) {
		// serialize the data before calling sort function
		let parseData = JSON.parse(JSON.stringify(this.dataOpenItems));

		// Return the value stored in the field
		let keyValue = (a) => {
			return a[fieldname];
		};

		// cheking reverse direction
		console.log('started sorting by ' + direction);
		let isReverse = direction === "asc" ? 1 : -1;
		console.log('this time sorting by ' +direction + ' isReverse = ' + isReverse);

		// sorting data
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : ""; // handling null values
			y = keyValue(y) ? keyValue(y) : "";
			console.log('sorting ' + x + ' against ' + y);
			// sorting values based on direction
			return isReverse * ((x > y) - (y > x));
		});

		// set the sorted data to data table data
		console.log('parseData ' + JSON.stringify(parseData));
		this.dataOpenItems = parseData;
	}

	// handleAllNone(event) {
	// 	console.log("****** value --> ", event.detail.value);
	// 	this.categoryValue = [];

	// 	if (event.detail.value == "all") {
	// 		let selectValues = [];

	// 		for (let i = 0; i < this.categoryOptions.length; i++) {
	// 			const category = this.categoryOptions[i];
	// 			selectValues.push(category.value);
	// 			console.log("****** category --> ", category.value);
	// 		}

	// 		console.log("****** selectValues --> ", selectValues);

	// 		this.categoryValue = selectValues;
	// 		this.selectedCategories = this.categoryValue;
	// 		this.loadItems();
	// 	} else {
	// 		this.dataOpenItems = [];
	// 		this.selectedCategories = [];
	// 	}
	// }

	handleSelectAllNone() 
	{
		this.isAllSelected = !this.isAllSelected;
		// if (forceSelectAll != null && forceSelectAll != undefined)
		// {
		// 	this.isAllSelected = forceSelectAll;
		// }

		this.categoryValue = [];

		if (!this.isAllSelected) {
			let selectValues = [];

			for (let i = 0; i < this.categoryOptions.length; i++) {
				const category = this.categoryOptions[i];
				selectValues.push(category.value);
				console.log("****** category --> ", category.value);
			}

			console.log("****** selectValues --> ", selectValues);

			this.categoryValue = selectValues;
			this.selectedCategories = this.categoryValue;
			this.loadItems();
		} else {
			this.dataOpenItems = [];
			this.selectedCategories = [];
		}
	}
}