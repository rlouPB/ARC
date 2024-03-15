({
  doInit: function (component, event, helper) {
    helper.doInit(component, event, helper);
  },
  sortByName: function (component, event, helper) {
    let target = event.currentTarget;
    let columnName = target.getAttribute("data-columnName");
    helper.sortBy(component, columnName);
  },
  handlerSearchOptionBtnClick: function (component, event, helper) {
    var searchOptions = event.getParam("data").contactSearchInfo,
      butonName = event.getParam("name");
    helper.handlerSearchOptionBtnClick(
      component,
      event,
      helper,
      searchOptions,
      butonName
    );
  },
  filterCalls: function (component, event, helper) {
    var selectedFilterOption = component.get("v.selectedFilterOption");
    var notes = component.get("v.notes");
    // console.log('notes ' + JSON.stringify(notes));
    // console.log('selectedFilterOption ' + JSON.stringify(selectedFilterOption));
    var filteredNotes = notes.filter(function (note) {
      var isFilterSatisfied = true;
      //debugger;
      if (selectedFilterOption.patient) {
        isFilterSatisfied =
          note.accountId != null
            ? note.accountId === selectedFilterOption.patient
            : note.accountName != null
            ? note.accountName.toLowerCase() ===
              selectedFilterOption.patient.toLowerCase()
            : false;
      }

      if (selectedFilterOption.caller && isFilterSatisfied === true) {
        isFilterSatisfied =
          note.callerId != null
            ? note.callerId === selectedFilterOption.caller
            : note.callerName != null
            ? note.callerName.toLowerCase() ===
              selectedFilterOption.caller.toLowerCase()
            : false;
      }

      if (selectedFilterOption.ARCUser && isFilterSatisfied === true) {
        // isFilterSatisfied = (note.ARCUserId === selectedFilterOption.ARCUser);
        isFilterSatisfied = selectedFilterOption.ARCUser.includes(
          note.ARCUserId
        );
      }

      if (selectedFilterOption.callStatus && isFilterSatisfied === true) {
        if (selectedFilterOption.callStatus)
          isFilterSatisfied =
            note.callStatus == selectedFilterOption.callStatus;
      }

      return isFilterSatisfied;
    });
    // console.log(filteredNotes);
    component.set("v.filteredNotes", filteredNotes);

    component.set("v.currentPage", 1);
    helper.renderPage(
      component,
      component.get("v.pagesPerRecord"),
      component.get("v.currentPage")
    );
  },

  onSearch: function (component, event, helper) {
    let btnEvent = component.getEvent("buttonClicked");

    btnEvent.setParams({
      name: event.getSource().get("v.name"),
      data: {
        contactSearchInfo: {
          startDate: component.get("v.searchData.startDate"),
          endDate: component.get("v.searchData.endDate")
        }
      }
    });
    // console.log(JSON.stringify(btnEvent.getParams()))
    btnEvent.fire();
  },

  toggleShowUsers: function (component, event, helper) {
    let showFilterOptions = component.get("v.showFilterOptions");
    showFilterOptions.ARCUsers = !showFilterOptions.ARCUsers;
    component.set("v.showFilterOptions", showFilterOptions);
  },

  resetSearchOptions: function (component, event, helper) {
    var options = component.get("v.searchData");
    var searchFor = options.searchFor;
    var searchData = {
      name: "",
      startDate: "",
      endDate: "",
      isIncludeNonStarterCalls: true,
      ARCUser: ""
    };

    searchData.searchFor = searchFor || "";
    component.set("v.searchData", searchData);

    var btnEvent = component.getEvent("buttonClicked");
    btnEvent.setParams({
      name: event.getSource().get("v.name"),
      data: {
        contactSearchInfo: component.get("v.searchData")
      }
    });
    btnEvent.fire();
    component.set("v.currentPage", 1);
    helper.toggleSpinner(component, 0);
    helper.doInit(component, event, helper);
  },

  renderPage: function (component, event, helper) {
    let pagesPerRecord = component.get("v.pagesPerRecord"),
      currentPageNumber = component.get("v.currentPage");

    helper.renderPage(component, pagesPerRecord, currentPageNumber);
  },

  onViewChange: function (component, event, helper) {
    const viewState = event.getSource().get("v.title");

    if (viewState === "allColumns") {
      // console.log(viewState);
      component.set("v.isSelectedAll", true);
    } else {
      //  console.log(viewState);
      component.set("v.isSelectedAll", false);
    }
  },

  handleMouseLeaveColumn: function (component, event, helper) {
    component.set("v.cursorOnColumn", false);
    // console.log('handleMouseLeaveColumn');
    helper.handleHidePopover(component, event, helper);
    // let action = component.get('c.handleHidePopover');
    // $A.enqueueAction(action);
  },

  handleMouseLeavePopover: function (component, event, helper) {
    component.set("v.cursorOnPopover", false);
    // console.log('handleMouseLeavePopover');
    helper.handleHidePopover(component, event, helper);
    // let action = component.get('c.handleHidePopover');
    // $A.enqueueAction(action);
  },

  handleMouseOverColumn: function (component, event, helper) {
    component.set("v.cursorOnColumn", true);
    // console.log('handleMouseOverColumn');
    helper.handleShowPopover(component, event, helper);
    // let action = component.get('c.handleShowPopover');
    // $A.enqueueAction(action);
  },

  handleMouseOverPopover: function (component, event, helper) {
    component.set("v.cursorOnPopover", true);
    // console.log('handleMouseOverPopover');
    // helper.handleShowPopover(component, event, helper);
    // let action = component.get('c.handleShowPopover');
    // $A.enqueueAction(action);
  },

  populateRecordToLogACall: function (component, event, helper) {
    var recordId = component.get("v.recordId");
    if (recordId) {
      const noteId = event.currentTarget.getAttribute("data-id");
      const noteRecordtypeName =
        event.currentTarget.getAttribute("data-rtName");
      $A.get("e.c:onPopulateLogACall")
        .setParams({
          noteId: noteId,
          noteRecordtypeName: noteRecordtypeName,
          isFromCallSearch: true
        })
        .fire();
    } else {
      //   console.log('populateRecordToLogACall')
      const dataIndex = event.currentTarget.getAttribute("data-index"),
        records = component.get("v.rowsToDisplay");
      // console.log(records[dataIndex]);
      const noteRecordtypeName =
        event.currentTarget.getAttribute("data-rtName");

      helper.navigateToRespectivePage(
        component,
        records[dataIndex],
        noteRecordtypeName
      );
    }
  },

  handleRefreshList: function (component, event, helper) {
    if (!event.getParam("isFromCallSearch")) {
      let options = component.get("v.searchData"),
        searchFor = options.searchFor;

      options.patient = "";
      options.caller = "";
      options.ARCUser = "";
      component.set("v.searchData", options);
      // console.log(options);
      helper.handlerSearchOptionBtnClick(
        component,
        event,
        helper,
        options,
        "search"
      );
    }
  }
});