import { LightningElement, api, track } from 'lwc';
import loadRecordData from "@salesforce/apex/PatientSidebarCls.loadRecordData";


export default class PatientSidebarLwc extends LightningElement

{

	@api
	patientAccountId

	@api
	previewUrl

	@track
	patient

	@api
	recordId

	@api
	parameters

	@api
	isCollapsed

	eventDetailValue

	connectedCallback(){
        this.load()        
    }

	handleSendAsMessageClick(event) {
		this.eventDetailValue = event.target.value;
		// Creates the event with the data.
		const selectedEvent = new CustomEvent("sendasmessage", {
			detail: this.eventDetailValue
		});
	
		// Dispatches the event.
		this.dispatchEvent(selectedEvent);
	}
	handleGeneratePresentationClick(event) {
		this.eventDetailValue = event.target.value;
		// Creates the event with the data.
		const selectedEvent = new CustomEvent("generatepresentation", {
			detail: this.eventDetailValue
		});
	
		// Dispatches the event.
		this.dispatchEvent(selectedEvent);
	}
	handleSaveClick(event) {
		this.eventDetailValue = event.target.value;
		// Creates the event with the data.
		const selectedEvent = new CustomEvent("save", {
			detail: this.eventDetailValue
		});
	
		// Dispatches the event.
		this.dispatchEvent(selectedEvent);
	}
	handlePreviewPresentationClick(event) {
		this.eventDetailValue = event.target.value;
		// Creates the event with the data.
		const selectedEvent = new CustomEvent("previewpresentation", {
			detail: this.eventDetailValue
		});
	
		// Dispatches the event.
		this.dispatchEvent(selectedEvent);
	}
	handleFinalizeClick(event) {
		this.eventDetailValue = event.target.value;
		// Creates the event with the data.
		const selectedEvent = new CustomEvent("finalize", {
			detail: this.eventDetailValue
		});
	
		// Dispatches the event.
		this.dispatchEvent(selectedEvent);
	}

    async load()
	{

		// let me = this;

		// let recordId = cmp.get("v.recordId");

		// let parameters = cmp.get("v.parameters")[0] || cmp.get("v.parameters");

		// cmp.set("v.data");


		// if (parameters && parameters.fieldNames) {

		// let isCollapsed = localStorage.getItem("isCollapsed") || "NO";

		// cmp.set("v.isCollapsed", isCollapsed == "YES");

		// localStorage.setItem("isCollapsed", isCollapsed);

		// let patientAccountId = cmp.get("v.patientAccountId");

		// let defaultPatientFields = "Id,Name,Photo__c".split(",");

		// let patientFieldNames = parameters.patientFields

		// 	? defaultPatientFields

		// 		.concat(parameters.patientFields.map((x) => x.fieldName))

		// 		.filter((x) => x && x.fieldName)

		// 	: defaultPatientFields;

		// let loadRecordDataParams = {

		// 	recordId: patientAccountId,

		// 	fieldNames: patientFieldNames

		// };


		var patientFieldNames = [

			'Id',

			'Name',

			'Photo__c',

			'Current_Admission__c',

			'Gender_Identifies_As__c',

			'Preferred_Pronouns__c',

			'Age__c',

			'Admit_Date__c',

			'Previous_Admissions_Numeric__c'

		];


		console.log('loadRecordData recordId ' + this.patientAccountId);

		console.log('fieldNames ' + patientFieldNames );


        var result = await loadRecordData({'recordId': this.patientAccountId, 'fieldNames': patientFieldNames});

		console.log('result ' + JSON.stringify(result));

		

		//TODO remove

		// return;


		if (result.record)

		{

			this.patient = result.record;

			console.info('Side Bar patient result*****************', JSON.parse(JSON.stringify(this.patient)))

			// console.log('caseAbstract ' + JSON.stringify(this.caseAbstract.record))

			// console.log('caseAbstract.Id ' + this.caseAbstract.record.Id)

		} else {

			console.log('problem getting Patient in PatientSideBarLwc: ' + result.errorMessage);

			console.log('PatientSideBarLwc Stack Trace: ' + result.stackTrace);

		}

    }

}