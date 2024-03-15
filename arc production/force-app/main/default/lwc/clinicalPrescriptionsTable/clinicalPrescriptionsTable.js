import { api, LightningElement, track } from "lwc";
import getPrescriptions from "@salesforce/apex/DispensingService.getPrescriptions";
import getMARLinesForMaxDosageValidationForPrescription from "@salesforce/apex/DispensingService.getMARLinesForMaxDosageValidationForPrescription";
import getPrescription from "@salesforce/apex/DispensingService.getPrescription";
import getUserProfileName from "@salesforce/apex/DispensingHomeController.getUserProfileName";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ClinicalPrescriptionsTable extends LightningElement {
  @api
  accountId;

  @track
  data = [];

  @track
  pagedData = [];

  @track
  selectedIds = [];

  @track
  sortBy = "Medication_Filled_with__c";

  @track
  sortDirection = "asc";

  @track
  selectedMode = "Show Active";

  @track
  loading;

  @track
  modeOptions = 'Show All;Show Active;Show Discontinued'.split(';').map(x=>{return {label:x,value:x}})

  @track
  mode='Show Active'

  @track
  columns = [
    // {name:'Name', fullApiName:'Name', label:'Prescription', type:'nameField', sortable: true},
    // {name:'Drug_Name__c', fullApiName:'Drug_Name__c', label:'Medication', type:'action',actionName:"medclick", sortable: true},
    // { name: "Medication_Filled_with__c", fullApiName: "Medication_Filled_with__c", label: "Medication", type: "lookup2", lookupid: "Id", lookupNameFields: ["Medication_Filled_with__c", "Drug_Name__c"], sortable: true },
    // { name: "Medication_Format__c", fullApiName: "Medication_Format__c", label: "Medication Format", type: "text", sortable: true },
    // { name: "As_Needed__c", fullApiName: "As_Needed__c", label: "As Needed", type: "checkbox", sortable: true },
    // { name: "Dispensing_Comment__c", fullApiName: "Dispensing_Comment__c", label: "Dispensing Comment", type: "text", sortable: true },
    // { name: "Last_Dispensed__c", fullApiName: "Last_Dispensed__c", label: "Last Dispensed", type: "datetime", sortable: true },
    // // {name:'Indication_Text__c', fullApiName:'Indication_Text__c', label:'Indication', type:'text', sortable: true},
    // { name: "Control_Group__c", fullApiName: "Control_Group__c", label: "Control Group", type: "text", sortable: true },
    // { name: "Dispensed__c", fullApiName: "Dispensed__c", label: "Dispensed", type: "checkbox", sortable: true },
    // { name: "Location__c", fullApiName: "Location__c", label: "Location", type: "text", sortable: true },
    // // {name:'Dosage_Quantity__c', fullApiName:'Dosage_Quantity__c', label:'Dosage Quantity', type:'text', sortable: true},
    // // {name:'Written_Date__c', fullApiName:'Written_Date__c', label:'Written Date', type:'date', sortable: true},
    // // {name:'Fill_Date__c', fullApiName:'Fill_Date__c', label:'Fill Date', type:'date', sortable: true},
    // { name: "Start_Date__c", fullApiName: "Start_Date__c", label: "Start Date", type: "date", sortable: true },
    // { name: "End_Date__c", fullApiName: "End_Date__c", label: "End Date", type: "date", sortable: true },
    // { name: "Times_Of_Day__c", fullApiName: "Times_Of_Day__c", label: "Times of Day", type: "text", sortable: true },
    // { name: "Times_of_Day_Sort__c", fullApiName: "Times_of_Day_Sort__c", label: "Time Sort", type: "number", sortable: true },
    // { name: "Status__c", fullApiName: "Status__c", label: "Status", type: "text", sortable: true }
    // {name: 'Account__c', label: 'Patient', fieldName: 'Account__c', type:"lookup", lookupid:'Account__c', lookupName:'Account__r.Name', sortable: true, wrapText: true },
    // {name:'Mother_s_Maiden_Name__c',fullApiName:'Account.Mother_s_Maiden_Name__c', label:'Mother\'s Maiden Name', sortable: true},
    // {name:'Current_Admission__r.Dispensing_Status__c',fullApiName:'Admission__c.Dispensing_Status__c', label:'Dispensing Status', sortable: true},
    // {name:'Current_Admission__r.MSA_Schedule__c',fullApiName:'Admission__c.MSA_Schedule__c', label:'MSA Schedule', sortable: true},
    // {name:'Current_Admission__r.MSA_Pickup_Location__c',fullApiName:'Admission__c.MSA_Pickup_Location__c', label:'MSA Location', sortable: true},
    { name: "Medication_Filled_with__c", fullApiName: "Medication_Filled_with__c", label: "Medication", type: "lookup2", lookupid: "Id", lookupNameFields: ["Medication_Filled_with__c", "Drug_Name__c"], sortable: true },
    { name: "Medication_Format__c", fullApiName: "Medication_Format__c", label: "Medication Format", type: "text", sortable: true },
    { name: "As_Needed__c", fullApiName: "As_Needed__c", label: "As Needed", type: "boolean", sortable: true },
    { name:'Written_Date__c', fullApiName:'Written_Date__c', label:'Written Date', type:'date', sortable: true, typeAttributes:{
        month: "2-digit",
        day: "2-digit"
    }},
    { name: "Prescriber_Professional_Name__c", fullApiName: "Prescriber_Professional_Name__c", label: "Prescriber", type: "text", sortable: true },
    { name: "Status__c", fullApiName: "Status__c", label: "Status", type: "text", sortable: true },
    { name: "Start_Date__c", fullApiName: "Start_Date__c", label: "Start Date", type: "date", sortable: true },
    { name: "End_Date__c", fullApiName: "End_Date__c", label: "End Date", type: "date", sortable: true },
    ];

  @api
  getRecords() {
    return this.data.map((x) => ({ ...x }));
  }

  @api
  changeMode(e) {
    console.info("-------------------r-changeMode---------------", e.detail.value);
    this.selectedMode = e.detail.value;
    this.refreshPaginator();
  }

  async connectedCallback() {
    await this.load();
  }

  @api
  async load() {
    this.loading = true;
    this.data = await getPrescriptions({ accountId: this.accountId });
    this.refreshPaginator();
    this.loading = false;
  }

  get hasColumns() {
    return this.columns?.length > 0;
  }

  get columnsSize() {
    return this.columns?.length || 0;
  }

  get dataItems() {
    let me = this;

    let today = new Date();

    let base = this.data
      ? this.data.map((item) => {
          return {
            id: item.Id,
            record: { ...item },
            selected: me.selectedIds.indexOf(item.Id) >= 0,
            rowClass: `slds-table-row`,
            fields: me.columns.map((col) => {
              return {
                type: col.type,
                name: col.name,
                value: col.fieldNameOrList?.length > 0 ? me.getOrValue(item, col.fieldNameOrList) : me.deep_value(item, col.fullApiName),
                valueId: me.deep_value(item, col.lookupid),
                lookupName: me.deep_value(item, col.lookupName),
                lookupName2: me.getOrValue(item, col.lookupNameFields),
                title: me.deep_value(item, col.name) || me.deep_value(item, col.lookupName),
                action: col.actionName,
                isLookup: col.type == "lookup",
                isLookup2: col.type == "lookup2",
                isDate: col.type == "date",
                isDateTime: col.type == "datetime",
                isName: col.type == "nameField",
                isHtml: col?.type == "html",
                isCheckbox: col?.type == "checkbox",
                isBoolean: col?.type == "boolean",
                isAction: col?.type == "action",
                isText: col.type ? col.type == "text" : true,
                isNumber: col.type ? col.type == "number" : true,
                isFieldAccessible: me.fieldsAccessibleToUser?.indexOf(col.fullApiName) >= 0
              };
            })
          };
        })
      : [];

    //Sorting
    if (this.sortBy) {
      let isReverse = this.sortDirection === "asc" ? 1 : -1;
      let col = this.columns.find((x) => x.name == this.sortBy);

      // sorting data
      base.sort((x, y) => {
        let xi = x.fields.find((field) => field.name == this.sortBy)?.value || "";
        let yi = y.fields.find((field) => field.name == this.sortBy)?.value || "";

        // sorting values based on direction
        return isReverse * ((xi > yi) - (yi > xi));
      });
    }

    if (this.selectedMode == "Show Active") {
      var results = base.filter((a) => {
        if (a.record?.Start_Date__c && a.record?.End_Date__c) {
          var startDateStr = a.record?.Start_Date__c;
          const startDateArray = startDateStr.split("-"); // 2022-09-13 (yyyy-mm-dd)
          var startDate = new Date(parseInt(startDateArray[0]), parseInt(startDateArray[1]) - 1, parseInt(startDateArray[2]));
          var endDateStr = a.record?.End_Date__c;
          const endDateArray = endDateStr.split("-");
          var endDate = new Date(parseInt(endDateArray[0]), parseInt(endDateArray[1]) - 1, parseInt(endDateArray[2]));
          var today = new Date();
          this.updateDateWithNoTime(today);
          // console.log("startDate : ", startDate);
          // console.log("endDate : ", endDate);
          // console.log("today : ", today);
          return a.record?.Status__c == "Active" && today >= startDate && today <= endDate;
        } else if (a.record?.Start_Date__c && undefined == a.record?.End_Date__c) {
          var startDateStr = a.record?.Start_Date__c;
          const startDateArray = startDateStr.split("-"); // 2022-09-13 (yyyy-mm-dd)
          var startDate = new Date(parseInt(startDateArray[0]), parseInt(startDateArray[1]) - 1, parseInt(startDateArray[2]));
          var today = new Date();
          this.updateDateWithNoTime(today);
          // console.log("startDate : ", startDate);
          // console.log("today : ", today);
          return a.record?.Status__c == "Active" && today >= startDate;
        } else if (a.record?.End_Date__c && undefined == a.record?.Start_Date__c) {
          var endDateStr = a.record?.End_Date__c;
          const endDateArray = endDateStr.split("-");
          var endDate = new Date(parseInt(endDateArray[0]), parseInt(endDateArray[1]) - 1, parseInt(endDateArray[2]));
          var today = new Date();
          this.updateDateWithNoTime(today);
          // console.log("endDate : ", endDate);
          // console.log("today : ", today);
          return a.record?.Status__c == "Active" && today <= endDate;
        } else {
          return a.record?.Status__c == "Active";
        }
      });
      return results;
    } else if(this.selectedMode == "Show Discontinued") {
      var results = base.filter((a) => {
        return a.record?.Status__c == "Discontinued" && null != a.record?.IRIS_Fill_Datetime__c;
      });
      return results;
    } else {
      return base?.map((x) => x);
    }
  }

  updateDateWithNoTime(d) {
    d.setHours(0);
    d.setMinutes(0);
    d.setSeconds(0);
    d.setMilliseconds(0);
  }

  updateColumnSorting(e) {
    var fieldName = e.target.dataset.fieldname;

    let col = this.columns.find((x) => x.name == fieldName);

    if (!col.sortable) {
      console.info(`${fieldName} field is NOT sortable`);
      return;
    }

    let sortDirection = this.sortDirection == "asc" ? "desc" : "asc";

    col.isDESC = sortDirection == "desc";
    col.sorted = true;

    this.sortBy = fieldName;
    this.sortDirection = sortDirection;

    // setTimeout(()=>this.refreshPaginator(), 500)
    this.refreshPaginator();
  }

  getOrValue(item, fieldPathList = []) {
    for (let fieldPath of fieldPathList) {
      let value = this.deep_value(item, fieldPath);
      if (value) {
        return value;
      }
    }
    return "";
  }

  deep_value(obj, path) {
    try {
      for (var i = 0, path = path.split("."), len = path.length; i < len; i++) {
        obj = obj[path[i]];
      }
      return obj;
    } catch (e) {}
    return "";
  }

  async refreshPaginator() {
    let me = this;

    let paginator = me.template.querySelector(".paginator");

    console.info("paginator===============>", paginator);

    setTimeout(() => paginator.pageChanged(), 200);
  }

  pageChangedHandler(e) {
    this.pagedData = e.detail.values;
  }

  onRecordActionClickHandler(e) {
    const id = e.target.dataset.rowid;
    const action = e.target.dataset.action;

    this.dispatchEvent(
      new CustomEvent("action", {
        detail: {
          id,
          action
        }
      })
    );
  }

  toast(message, title = "alert", variant = "info") {
    const evt = new ShowToastEvent({
      title,
      message,
      variant
    });
    this.dispatchEvent(evt);
  }

  openPrintedLastDispensedMeds() {
    var pdfUrl = "/apex/PrintedLastDispensedMedsPDF?accountId="+this.accountId
    window.open(pdfUrl);
  }
}