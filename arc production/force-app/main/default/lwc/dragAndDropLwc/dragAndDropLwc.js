import { api, LightningElement, track, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { loadScript } from 'lightning/platformResourceLoader';
import momentjs from '@salesforce/resourceUrl/momentjs';
// import OBJECT from '@salesforce/schema/Variance__c'
// import groupByField from '@salesforce/schema/Variance__c.Affected_Process__c'
// import id_field from '@salesforce/schema/Variance__c.Id'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class DragAndDropLwc extends LightningElement {
	@api listViewApiName;
	@api id_field;

	renderedCallback() {
		// this.listViewApiName = 'Medication_Variances_In_Process'
		// this.id_field = 'Id'
		Promise.all([loadScript(this, momentjs)])
			.then(() => {
				console.log('momentjs Loaded');
			})
			.catch((error) => {
				console.error('Failed to load the MomentJS : ' + error);
			});
	}

	connectedCallback() {
		// this.listViewApiName = 'Medication_Variances_In_Process'
		// this.id_field = 'Id'
	}

	@api objectApiName;
	@api fieldApiName; //  field for GROUP BY
	@api requiredFields = ''; //contains comma seperated fields
	get required() {
		let fields = this.requiredFields.split(',');
		return fields;
	}

	recordTypeId;
	objfiedAPIName;
	records = [];
	pickVals;
	recordId;
	listTitle; // for title of the list
	objectName; // for object name
	icon; // for object icon

	/*** fetching Opportunity lists ***/
	@wire(getListUi, {
		objectApiName: '$objectApiName',
		listViewApiName: '$listViewApiName',
	})
	wiredListView({ error, data }) {
		if (data) {
			this.records = [];
			console.log('getListUi', data);
			// this.records = data.records.records.map(item => {
			//     let field = item.fields
			//     const stageName =  {displayValue: null, value: this.fieldApiName}
			//     // return { ...field , 'StageName': stageName}
			//     return { 'Id': field.Id.value, 'Name': field.Name.value, 'Variance_Category__c': field.Variance_Category__c.value, 'Description__c': field.Description__c.value, 'Date_of_Variance__c': field.Date_of_Variance__c.value, 'StageName': field[this.fieldApiName].value}

			// })

			this.listTitle = data.info.label ? data.info.label : this.listViewApiName;

			data.records.records.forEach((x) => {
				var obj = {};
				Object.keys(x.fields).forEach((i) => {
					if (i == this.fieldApiName) {
						obj['StageName'] = x.fields[i].value;
					} else {
						// console.log(`********* ${x.fields[i].value} === ${this.isDate(x.fields[i].value)}`)
						obj[i] = this.isDate(x.fields[i].value) == true ? moment(x.fields[i].value).format('MM/DD/YYYY') : x.fields[i].value;
					}
				});
				this.records.push(obj);
			});
			console.log('records', this.records);
		}
		if (error) {
			console.error(error);
		}
	}

	/** Fetch metadata abaout the opportunity object**/
	@wire(getObjectInfo, { objectApiName: '$objectApiName' })
	objectInfo(result) {
		if (result.data) {
			this.picklistlabel = result.data.fields[this.fieldApiName].label;
			console.log('picklistlabel ' + this.picklistlabel);

			this.objfiedAPIName = {};
			this.objfiedAPIName.fieldApiName = result.data.fields[this.fieldApiName].apiName;
			console.log('objfiedAPIName.fieldApiName ' + this.objfiedAPIName.fieldApiName);
			this.objfiedAPIName.objectApiName = result.data.apiName;
			console.log('objfiedAPIName.objectApiName ' + this.objfiedAPIName.objectApiName);

			this.recordTypeId = result.data.defaultRecordTypeId;
			console.log('recordTypeId ' + this.recordTypeId);
			this.objectName = result.data.label;
			console.log('objectName ' + this.objectName);
			this.icon = result.data.themeInfo.iconUrl;
			console.log('icon ' + this.icon);
			console.log('getObjectInfo', result.data);
		} else if (result.error) {
			window.console.log('error ===> ' + JSON.stringify(result.error));
		}
	}
	/*** fetching Stage Picklist ***/

	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: '$objfiedAPIName' })
	stagePicklistValues({ data, error }) {
		if (data) {
			console.log('Stage Picklist', data);
			this.pickVals = data.values.map((item) => item.value);
		}
		if (error) {
			console.error(error);
		}
	}

	/****getter to calculate the  width dynamically*/
	get calcWidth() {
		let len = this.pickVals.length + 1;
		return `width: calc(100vw/ ${len})`;
	}

	handleListItemDrag(event) {
		this.recordId = event.detail;
	}

	handleItemDrop(event) {
		let stage = event.detail;
		// this.records = this.records.map(item=>{
		//     return item.Id === this.recordId ? {...item, StageName:stage}:{...item}
		// })
		this.updateHandler(stage);
	}
	updateHandler(stage) {
		const fields = {};
		fields[this.id_field] = this.recordId;
		fields[this.fieldApiName] = stage;
		const recordInput = { fields };
		updateRecord(recordInput)
			.then(() => {
				console.log('Updated Successfully');
				this.showToast();
				return refreshApex(this.wiredListView);
			})
			.catch((error) => {
				console.error(error);
			});
	}

	showToast() {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Success',
				message: 'Stage updated Successfully',
				variant: 'success',
			})
		);
	}

	isDate(string) {
		var formats = [moment.ISO_8601, 'MM/DD/YYYY HH*mm*ss', 'MM/DD/YYYY', 'MM-DD-YYYY'];
		// console.log(
		// moment(string, formats, true).isValid()
		// );

		return moment(string, formats, true).isValid();
	}
}