({
	buildFilterOptions: function (component, notes, helper) {
	var patientId = [],
		patients = [{ label: "-All-", value: "" }],
		callerIds = [],
		callers = [{ label: "-All-", value: "" }],
		ARCUserIds = [],
		ARCUsers = [], //[{label:"-All-", value:""}],
		callStatusIds = [],
		callStatuses = [{ label: "-All-", value: "" }],
		selectedARCUser = [];

	let returnCount = notes.length >= 1000 ? "at least 1000" : notes.length;
	component.set("v.returnCount", returnCount);

	notes.map(function (note) {
		if (
		note.accountId &&
		note.accountName &&
		patientId.indexOf(note.accountId) == -1
		) {
		patientId.push(note.accountId);
		patients.push({
			label: note.accountName,
			value: note.accountId
		});
		}
		// });

		// notes.map(function (note) {
		if (
		note.callerId &&
		note.callerName &&
		callerIds.indexOf(note.callerId) == -1
		) {
		callerIds.push(note.callerId);
		callers.push({
			label: note.callerName,
			value: note.callerId
		});
		}
		// });

		// notes.map(function (note) {
		if (
		note.ARCUserId &&
		note.ARCUserName &&
		ARCUserIds.indexOf(note.ARCUserId) == -1
		) {
		ARCUserIds.push(note.ARCUserId);
		ARCUsers.push({
			label: note.ARCUserName,
			value: note.ARCUserId,
			selected: true
		});
		selectedARCUser.push(note.ARCUserId);
		}
		// });

		// notes.map(function (note) {
		if (note.callStatus && callStatusIds.indexOf(note.callStatus) == -1) {
		callStatusIds.push(note.callStatus);
		callStatuses.push({
			label: note.callStatus,
			value: note.callStatus
		});
		}
	});
	this.sortOptionsByLabel(patients);
	this.sortOptionsByLabel(callers);
	this.sortOptionsByLabel(ARCUsers);
	this.sortOptionsByLabel(callStatuses);
	// patients.sort(function(a,b){
	//     let aname = a.label.toLowerCase();
	//     let bname = b.label.toLowerCase();
	//     if (aname < bname) { return -1; }
	//     if (aname > bname) { return 1; }
	//     return 0;
	// });
	// callers.sort(function(a,b){
	//     let aname = a.label.toLowerCase();
	//     let bname = b.label.toLowerCase();
	//     if (aname < bname) { return -1; }
	//     if (aname > bname) { return 1; }
	//     return 0;
	// });
	// ARCUserIds.sort(function(a,b){
	//     let aname = a.label.toLowerCase();
	//     let bname = b.label.toLowerCase();
	//     if (aname < bname) { return -1; }
	//     if (aname > bname) { return 1; }
	//     return 0;
	// });
	// callStatuses.sort(function(a,b){
	//     let aname = a.label.toLowerCase();
	//     let bname = b.label.toLowerCase();
	//     if (aname < bname) { return -1; }
	//     if (aname > bname) { return 1; }
	//     return 0;
	// });

	var filterOption = {
		patients: patients,
		callers: callers,
		ARCUsers: ARCUsers,
		callStatuses: callStatuses
	};
	component.set("v.filterOption", filterOption);
	let selectedFilterOption = component.get("v.selectedFilterOption");
	selectedFilterOption.ARCUser = selectedARCUser;
	component.set("v.selectedFilterOption", selectedFilterOption);
	},

	sortOptionsByLabel: function (options) {
	//debugger;
	options.sort(function (a, b) {
		//if (!aname || !bname) debugger;
		let aname = a.label.toLowerCase();
		let bname = b.label.toLowerCase();
		if (aname < bname) {
		return -1;
		}
		if (aname > bname) {
		return 1;
		}
		return 0;
	});
	},

	sortBy: function (component, field, sortDirection) {
	var sortAsc = component.get("v.sortAsc"),
		sortField = component.get("v.sortField"),
		records = component.get("v.filteredNotes");
	if (sortDirection) {
		//explicitly set direction
		sortAsc = sortDirection == "ASC" ? true : false;
	} else {
		//sortAsc true if changing columns or if current sortAsc is false, otherwise true
		sortAsc = sortField != field || sortAsc == false;
	}
	records.sort(function (a, b) {
		var t1 = a[field] == b[field],
		t2 = (a[field] && !b[field]) || a[field] < b[field];
		return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
	});
	component.set("v.sortAsc", sortAsc);
	component.set("v.sortField", field);
	component.set("v.filteredNotes", records);
	//Pagination Filter
	component.set("v.currentPage", 1);
	this.renderPage(
		component,
		component.get("v.pagesPerRecord"),
		component.get("v.currentPage")
	);
	},

	renderPage: function (component, pagesPerRecord, pageNumber) {
	--pageNumber;
	this.totalPages(component, pagesPerRecord);
	let records = component.get("v.filteredNotes");
	const rowsToDisplay = records.slice(
		pageNumber * pagesPerRecord,
		(pageNumber + 1) * pagesPerRecord
	);
	component.set("v.rowsToDisplay", rowsToDisplay);
	},

	totalPages: function (component, pagesPerRecord) {
	const max = Math.ceil(
		component.get("v.filteredNotes").length / pagesPerRecord
	);
	component.set("v.maxPage", max);
	},

	doInit: function (component, event, helper) {
	var recordId = component.get("v.recordId"),
		self = this;
	if (recordId) {
		// if (!component.get('v.title')) {
		// component.set("v.title", "Patient Calls Search");
		// }
		component.set("v.context", "contact");
		component.set("v.isSelectedAll", false);
	} else {
		//component.set("v.title", "Calls Search");
		component.set("v.context", "other");
	}
	if (recordId) {
		helper.callApexMethod(
		component,
		"getPatientNotes",
		{
			searchOptionsMap: { startDate: "", endDate: "" },
			recordId: component.get("v.recordId")
		},
		function (response) {
			console.log("response**", response);
			component.set("v.loading", false);
			component.set("v.isSearchBtnClicked", true);
			//console.log('response**',response);
			var result = JSON.parse(response);
			//console.log('response**',result);

			helper.buildFilterOptions(component, result, self);
			component.set("v.notes", result);
			component.set("v.filteredNotes", result);
			//Pagination Filter
			helper.renderPage(
			component,
			component.get("v.pagesPerRecord"),
			component.get("v.currentPage")
			);

			helper.sortBy(component, component.get("v.defaultSortField"), "DESC");

			self.toggleSpinner(component, 0);
		},
		function (errorMessage) {
			component.set("v.loading", false);
			console.log("error");
			component.find("notifLib").showToast({
			message: errorMessage,
			variant: "error",
			mode: "dismissable"
			});
			self.toggleSpinner(component, 0);
		},
		false
		);
	} else {
		helper.sortBy(component, component.get("v.defaultSortField"), "DESC");
		self.toggleSpinner(component, 0);
	}
	},

	toggleSpinner: function (component, duration) {
	window.setTimeout(
		$A.getCallback(function () {
		if (component.find("spinner")) {
			var spinnerCls = component.find("spinner").get("v.class");
			if (spinnerCls) {
			if (spinnerCls === "slds-show") {
				component.find("spinner").set("v.class", "slds-hide");
			} else {
				component.find("spinner").set("v.class", "slds-show");
			}
			} else {
			component.find("spinner").set("v.class", "slds-hide");
			}
		}
		}),
		duration
	);
	},

	handlerSearchOptionBtnClick: function (
	component,
	event,
	helper,
	searchOptions,
	butonName
	) {
	helper.toggleSpinner(component, 0);
	var recordId = component.get("v.recordId"),
		controllerMethodName = "getPatientNotes",
		params = {
		searchOptionsMap: searchOptions,
		recordId: component.get("v.recordId")
		};

	if (!recordId) {
		controllerMethodName = "searchByCall";
		params = {
		searchOptions: JSON.stringify(searchOptions),
		recordId: component.get("v.recordId")
		};
	}

	console.log(searchOptions, controllerMethodName);
	if (butonName === "search") {
		helper.callApexMethod(
		component,
		controllerMethodName,
		params,
		function (response) {
			// console.log('response**',response);
			component.set("v.loading", false);
			component.set("v.isSearchBtnClicked", true);
			// console.log('response**',response);
			var result = JSON.parse(response);
			// console.log('response**',result);

			helper.buildFilterOptions(component, result);
			component.set("v.notes", result);
			component.set("v.filteredNotes", result);
			component.set("v.currentPage", 1);
			if (component.get("v.sortField")) {
			component.set("v.sortAsc", !component.get("v.sortAsc"));
			helper.sortBy(component, component.get("v.sortField"));
			} else {
			helper.renderPage(
				component,
				component.get("v.pagesPerRecord"),
				component.get("v.currentPage")
			);
			}
			helper.toggleSpinner(component, 0);
		},
		function (errorMessage) {
			component.set("v.loading", false);
			helper.toggleSpinner(component, 0);
			console.log("error");
			component.find("notifLib").showToast({
			message: errorMessage,
			variant: "error",
			mode: "dismissable"
			});
		},
		false
		);
	} else {
		component.set("v.notes", []);
		component.set("v.filteredNotes", []);
		component.set("v.isSearchBtnClicked", false);
		helper.toggleSpinner(component, 0);
	}
	},

	isValidAccountId: function (recordId) {
	if (!recordId) {
		return false;
	}

	var prefix = recordId.substring(0, 3);
	console.log("recordId", recordId, prefix, recordId.length);
	return (
		prefix === "001" && (recordId.length === 15 || recordId.length === 18)
	);
	},

	navigateToRespectivePage: function (cmp, Note, recordType) {
	console.log("Note", Note, recordType);

	let tabParam = "";

	if (recordType == "Admissions Officer Highlight") {
		tabParam = "notes";
	}

	if (Note.noteId != null && this.isValidAccountId(Note.accountId)) {
		// $A.get("e.force:navigateToURL").setParams({
		//     "url": "/lightning/r/Account/"+Note.accountId+"/view?c__noteId="+Note.noteId+tabParam
		// }).fire();
		var navService = cmp.find("navService");
		// Sets the route to /lightning/o/Account/home
		var pageReference = {
		type: "standard__recordPage",
		attributes: {
			objectApiName: "Account",
			recordId: Note.accountId,
			actionName: "view"
		},
		state: {
			c__noteId: Note.noteId,
			c__tab: tabParam
		}
		};
		cmp.set("v.pageReference", pageReference);

		navService.navigate(pageReference);
	} else {
		$A.get("e.force:navigateToURL")
		.setParams({
			url: "/lightning/n/Log_a_Call?c__noteId=" + Note.noteId
		})
		.fire();
	}
	},

	showHidePopover: function (component, event, helper) {
	let cursorOnPopover = component.get("v.cursorOnPopover");
	let cursorOnColumn = component.get("v.cursorOnColumn");
	let popoverIsOpen = component.get("v.popoverIsOpen");
	console.log(
		"showhide? " +
		cursorOnPopover +
		" " +
		cursorOnColumn +
		" " +
		popoverIsOpen +
		" " +
		(cursorOnPopover || cursorOnColumn)
	);

	if (cursorOnPopover || cursorOnColumn) {
		if (!popoverIsOpen) {
		let action = component.get("c.handleShowPopover");
		$A.enqueueAction(action);
		}
	} else {
		if (popoverIsOpen) {
		let action = component.get("c.handleHidePopover");
		$A.enqueueAction(action);
		}
	}
	},

	handleHidePopover: function (component, event, helper) {
	// event.stopPropagation();
	// event.preventDefault();

	let cursorOnPopover = component.get("v.cursorOnPopover");
	let cursorOnColumn = component.get("v.cursorOnColumn");
	console.log(
		"handleHidePopover popoverisopen " +
		component.get("v.popoverIsOpen") +
		" cursorOnPopover " +
		cursorOnPopover +
		" cursorOnColumn " +
		cursorOnColumn
	);
	if (component.get("v.popoverIsOpen")) {
		if (!cursorOnPopover && !cursorOnColumn) {
		console.log("hiding popover");
		let overlay = component.get("v.overlay");
		if (overlay) {
			// window.setTimeout(
			//     $A.getCallback(function() {
			//         overlay.close();
			//         component.set('v.popoverIsOpen', false);
			//     }), 100
			// );

			overlay.close();
			component.set("v.popoverIsOpen", false);
		}
		}
	}
	},

	handleShowPopover: function (component, event, helper) {
	// event.stopPropagation();
	// event.preventDefault();
	let cursorOnPopover = component.get("v.cursorOnPopover");
	let cursorOnColumn = component.get("v.cursorOnColumn");
	console.log(
		"handleShowPopover popoverisopen " +
		component.get("v.popoverIsOpen") +
		" cursorOnPopover " +
		cursorOnPopover +
		" cursorOnColumn " +
		cursorOnColumn
	);
	if (!component.get("v.popoverIsOpen")) {
		if (cursorOnPopover || cursorOnColumn) {
		console.log("showing popover");
		const notesContent = event.currentTarget.getAttribute("data-title"),
			index = event.currentTarget.getAttribute("data-index"),
			formFactor = component.get("v.formFactor");
		let cssCls = "";

		let Selector = ".showCustomPopover" + index,
			modalBody;

		if (formFactor !== "LARGE") {
			//cssCls +=  'slds-p-around--small,slds-popover,slds-nubbin_left,no-pointer,slds-scrollable_y,popoverclass,cCallSearch';
			//cssCls +=  'slds-p-around--small,slds-popover,slds-nubbin_left,no-pointer,popoverclass,cCallSearch';
			cssCls +=
			"slds-p-around--small,slds-popover,popoverclass,cCallSearch";
		} else {
			//cssCls += 'slds-p-around--small,slds-popover,slds-nubbin_right,no-pointer,cMyCmp,popoverclass';
			//cssCls += 'slds-p-around--small,slds-popover,slds-nubbin_right,no-pointer,slds-scrollable_y,popoverclass,cCallSearch';
			cssCls +=
			"slds-p-around--small,slds-popover,slds-nubbin_right,no-pointer,popoverclass,cCallSearch";
		}

		console.log("cssCls " + cssCls);
		$A.createComponents(
			[
			[
				"c:notesPopover",
				{
				"aura:id": "notesPop",
				popoverBody: notesContent,
				mouseLeaveNotes: component.getReference(
					"c.handleMouseLeavePopover"
				),
				mouseOverNotes: component.getReference(
					"c.handleMouseOverPopover"
				)
				}
			]
			// ["lightning:formattedText", {
			//     "value": notesContent

			// }]
			// ,
			// ["lightning:formattedRichText", {
			//     "value": "<span class='slds-p-around--small' >" + formFactor + "<br/>" + notesContent + " </span>"
			// }],
			],
			function (components, status) {
			if (status === "SUCCESS") {
				modalBody = components[0];

				component
				.find("overlayLib")
				.showCustomPopover({
					body: modalBody,
					referenceSelector: Selector,
					cssClass: cssCls
				})
				.then(function (overlay) {
					component.set("v.overlay", overlay);
					component.set("v.popoverIsOpen", true);
				});
			}
			}
		);
		}
	}
	}
});