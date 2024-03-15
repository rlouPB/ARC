/**
 * @description       : 
 * @author            : 
 * @file type         : 
 * @created modified  : 
 * @last modified on  : 01-13-2022
 * @last modified by  : 
**/
import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getExistingPrescriptions from "@salesforce/apex/ScriptSureController.getExistingPrescriptions";
import getExistingPrescriptionsWithQuery from "@salesforce/apex/ScriptSureController.getExistingPrescriptionsWithQuery";
import getAccount from "@salesforce/apex/ScriptSureController.getAccount";
import getDispensingHistoryForPrescriptions from "@salesforce/apex/DispensingService.getDispensingHistoryForPrescriptions";
import getPatientNoteRecord from "@salesforce/apex/PatientNoteCtl.getPatientNoteRecord";
import saveAwayMedOrderNoteDetails from "@salesforce/apex/PatientNoteCtl.saveAwayMedOrderNoteDetails";
import getPatientNoteAwayOrderInfo from "@salesforce/apex/PatientNoteCtl.getPatientNoteAwayOrderInfo";

//1. import the methods getRecord and getFieldValue
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
//2. Import reference to the object and the fields
import DAYSAWAY_START_DATE_FIELD from "@salesforce/schema/Patient_Note__c.Away_First_Date__c";
import DAYSAWAY_END_DATE_FIELD from "@salesforce/schema/Patient_Note__c.Away_Last_Date__c";
import DAYSAWAY_FIELD from "@salesforce/schema/Patient_Note__c.Away_Number_of_Days__c";
import FINAL_DISCHARGE_MED_ORDER from "@salesforce/schema/Patient_Note__c.Final_Discharge_Med_Order__c";
import DAYS_TO_PACKAGE from "@salesforce/schema/Patient_Note__c.Days_to_Package__c";
import PATIENT_NOTE_STATUS from "@salesforce/schema/Patient_Note__c.Status__c";
const fields = [DAYSAWAY_FIELD, PATIENT_NOTE_STATUS, DAYSAWAY_START_DATE_FIELD, DAYSAWAY_END_DATE_FIELD, FINAL_DISCHARGE_MED_ORDER, DAYS_TO_PACKAGE];

// ** FOR SAVING RECORDS **
import updatePrescriptions from '@salesforce/apex/ScriptSureController.updatePrescriptions';
import { refreshApex } from '@salesforce/apex';

// FOR LMS
import SAMPLEMC from "@salesforce/messageChannel/PatientNoteToScriptSureDatatableMessageChannel__c"
import {MessageContext, publish,subscribe, APPLICATION_SCOPE, unsubscribe} from 'lightning/messageService'

let columns = [
   
];

export default class ScriptSurePrescriptionTable extends LightningElement {

    @api externalpatientid = '';
    @api accountid = '';
    @api patientNoteId;
    @api medicationQuery;

    @api forMSA = false;
    @api forAwayOrder = false;
    forOther = false;
    @api includeAdherence = false;
    @api suppressStatus = false;

    @track prescriptionColumns // = columns;
    @track prescriptionData = [];
    @track originalPrescriptionData = [];
    @track selectedPrescriptionValue;
    @track prescriptionFilter = 'active';
    @api showrefresh = false;

    draftValues = [];
    contactDate = null;

    @track startDate
    @track endDate
    @track numberOfDaysAway
    @track finalDischargeMedOrder
    @track daysToPackage
    @track initialRenderComplete

    get options() {
        return [
            { label: 'Show All', value: 'all' },
            { label: 'Show Active', value: 'active' }
        ];
    }


     //3. Wire the output of the out of the box method getRecord to the property account
    // @wire(getRecord, {
    //     recordId: "$patientNoteId",
    //     fields
    // })
    patientNote;

    //4. Fetch the field values from the record
    async loadPatientNote() {
        this.patientNote = await getPatientNoteAwayOrderInfo({patientNoteId: this.patientNoteId});
        if('Discharge Medication Order' == this.patientNote.Type__c) {
            this.finalDischargeMedOrder = true;
        }
        
        this.showHideAwayFields();
    }

    showHideAwayFields() {
        if(null != this.patientNote) {
            this.template.querySelector('[data-id="startDate"]').value = this.patientNote.Away_First_Date__c;
            this.template.querySelector('[data-id="endDate"]').value = this.patientNote.Away_Last_Date__c;
            this.template.querySelector('[data-id="numberOfDaysAway"]').value = this.patientNote.Away_Number_of_Days__c;
            // this.template.querySelector('[data-id="dischargeCheckbox"]').checked = this.patientNote.Final_Discharge_Med_Order__c;
            this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]').value = this.patientNote.Days_to_Package__c;
            
            console.log('in renderedCallback - this.finalDischargeMedOrder : ', this.finalDischargeMedOrder)
            console.log('in renderedCallback - this.initialRenderComplete : ', this.initialRenderComplete)
            if(this.finalDischargeMedOrder && !this.initialRenderComplete) {
                // var daysAwayInp = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]');
                // console.log("daysAwayInp in connected callback : ", daysAwayInp)
                
                if(this.finalDischargeMedOrder) {
                    this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]').className = 'item-number';
                    this.template.querySelector('[data-id="endDate"]').className = 'item-date slds-hide';
                    this.template.querySelector('[data-id="numberOfDaysAway"]').className = 'item-number slds-hide';
                }
            }
        }
    }

    // get AwayStartDateFromPatientNote() {
    //     console.log('Away Start Date => ', this.patientNote.Away_First_Date__c);
    //     return this.patientNote.Away_First_Date__c;
    //     // console.log('Away Start Date => '  + getFieldValue(this.patientNote.data, DAYSAWAY_START_DATE_FIELD));
    //     // return getFieldValue(this.patientNote.data, DAYSAWAY_START_DATE_FIELD);
    // }

    // get AwayEndDateFromPatientNote() {
    //     return this.patientNote.Away_Last_Date__c;
    //     // console.log('Away End Date => '  + getFieldValue(this.patientNote.data, DAYSAWAY_END_DATE_FIELD));
    //     // return getFieldValue(this.patientNote.data, DAYSAWAY_END_DATE_FIELD);
    // }

    // get AwayNumberOfDaysFromPatientNote() {
    //     return this.patientNote.Away_Number_of_Days__c;
    //     // console.log('Days Away => '  + getFieldValue(this.patientNote.data, DAYSAWAY_FIELD));
    //     // return getFieldValue(this.patientNote.data, DAYSAWAY_FIELD);
    // }

    // get FinalDischargeMedOrderFromPatientNote() {
    //     return this.patientNote.Final_Discharge_Med_Order__c
    //     // console.log('Final Discharge Med Order => '  + getFieldValue(this.patientNote.data, FINAL_DISCHARGE_MED_ORDER));
    //     // return getFieldValue(this.patientNote.data, FINAL_DISCHARGE_MED_ORDER);
    // }

    // get DaysToPackageFromPatientNote() {
    //     return this.patientNote.Days_to_Package__c
    //     // console.log('Days to Package => '  + getFieldValue(this.patientNote.data, DAYS_TO_PACKAGE));
    //     // return getFieldValue(this.patientNote.data, DAYS_TO_PACKAGE);
    // }

    // get patientNoteStatus() {
    //     return this.patientNote.Status__c;
    //     // console.log('Patient Note Status => '  + getFieldValue(this.patientNote.data, PATIENT_NOTE_STATUS));
    //     // return getFieldValue(this.patientNote.data, PATIENT_NOTE_STATUS);
    // }

    connectedCallback() {

        if(this.forAwayOrder){
            this.loadPatientNote();
        }

        //Subscribing to LMS
        this.subscribeMessage()

        console.log('medicationQuery ----- ' + this.medicationQuery)
        if(this.forAwayOrder){
            this.prescriptionColumns = [
                { label: 'Medication', fieldName: 'Medication_Filled_with__c', hideDefaultActions: true, wrapText: true },
                { label: 'Medication Format', fieldName: 'MediFormat', hideDefaultActions: true, wrapText: true },
                { label: 'As Needed', fieldName: 'As_Needed__c', hideDefaultActions: true, wrapText: true, type: 'boolean'},
                // { label: 'Away Package Instruction',type: 'picklist', fieldName: 'away_package_Instruction__c',editable: true, hideDefaultActions: true, wrapText: true },
                {
                    label: 'Package Instruction', fieldName: 'away_package_Instruction__c', type: 'picklist', 
                    typeAttributes: {
                        placeholder: 'Choose a value', options: [
                            { label: 'Packaged', value: 'Packaged' },
                            { label: 'Not Packaged', value: 'Not Packaged' },
                            { label: 'Reduced', value: 'Reduced' },
                        ] // list of all picklist options
                        , value: { fieldName: 'away_package_Instruction__c' } // default value for picklist
                        , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
                        , hideDefaultActions: true
                        , wrapText: true
                    }
                },
                
                //{ label: 'Quantity To Package', fieldName: 'Daily_Dosage_Quantity__c',editable: true, hideDefaultActions: true, wrapText: true },
                {
                    label: 'Quantity To Package', fieldName: 'Quantity_to_Package_Temp__c', type: 'textfield', typeAttributes: {
                        disabled: { fieldName: 'isAwayPackageInstructionDisabled' } // DISABLE value for TEXTFIELD
                        , value: { fieldName: 'Quantity_to_Package_Temp__c' } // default value for TEXTFIELD
                        , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
                        , hideDefaultActions: true
                        , wrapText: true
                        , editable: true,
                        
                    }
                },
                { label: 'End Date', fieldName: 'End_Date__c', type: 'date-local', hideDefaultActions: true, typeAttributes:{
                    month: "2-digit",
                    day: "2-digit"
                } },
            ];
        }else if(this.forMSA){
            this.prescriptionColumns = [
                { label: 'Medication', fieldName: 'Medication_Filled_with__c', hideDefaultActions: true, wrapText: true },
                { label: 'Medication Format', fieldName: 'MediFormat', hideDefaultActions: true, wrapText: true },
                { label: 'As Needed', fieldName: 'As_Needed__c', hideDefaultActions: true, wrapText: true, type: 'boolean'},
                // { label: 'Location', fieldName: 'location_temp__c', hideDefaultActions: true, wrapText: true  , editable: true},
                
                {
                    label: 'Location', fieldName: 'location_temp__c', type: 'picklist', typeAttributes: {
                        placeholder: 'Choose a value', options: [
                            { label: 'Closet Dispensed', value: 'Closet Dispensed' },
                            { label: 'Package', value: 'Package' },
                            { label: 'Keep', value: 'Keep' },
                            { label: 'OTC', value: 'OTC' },
                        ] // list of all picklist options// default value for picklist
                        , value: { fieldName: 'location_temp__c' } // default value for picklist
                        , context: { fieldName: 'Id' } // binding account Id with context variable to be returned back
                        , hideDefaultActions: true
                        , wrapText: true
                        , editable: true,
                        
                    }
                },
                
                
                // { label: 'On Going Quantity', fieldName: 'On_Going_Quantity__c', hideDefaultActions: true, wrapText: true  },
                { label: 'End Date', fieldName: 'End_Date__c', type: 'date-local', hideDefaultActions: true, typeAttributes:{
                    month: "2-digit",
                    day: "2-digit"
                } },
            ]
        }else{
            this.prescriptionColumns = [
                 // { label: 'Allergy Number', fieldName: 'name', hideDefaultActions: true},
                // { label: 'Drug Name', fieldName: 'Drug_Name__c', hideDefaultActions: true},
                // { label: 'Drug Name',  sortable: true , fieldName: 'recordLink', type: 'url', typeAttributes:{ label: { fieldName: "Drug_Name__c" }, target: '_blank' }, 
                // hideDefaultActions: true, wrapText: true},
                // { label: 'Drug Format', fieldName: 'Drug_Format_Description__c', hideDefaultActions: true, wrapText: true , sortable: true},
                { label: 'Medication', fieldName: 'Medication_Filled_with__c', hideDefaultActions: true, wrapText: true },
                { label: 'Medication Format', fieldName: 'MediFormat', hideDefaultActions: true, wrapText: true },
                { label: 'As Needed', fieldName: 'As_Needed__c', hideDefaultActions: true, wrapText: true, type: 'boolean'},
                { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date-local', hideDefaultActions: true, typeAttributes:{
                    month: "2-digit",
                    day: "2-digit"
                } },
                { label: 'End Date', fieldName: 'End_Date__c', type: 'date-local', hideDefaultActions: true, typeAttributes:{
                    month: "2-digit",
                    day: "2-digit"
                }},
                { label: 'Prescriber', fieldName: 'Prescriber_Professional_Name__c', hideDefaultActions: true, sortable: true },
                // { label: 'Indication Text', fieldName: 'Indication_Text__c', sortable: true, hideDefaultActions: true },
            ];

            console.log('this.suppressStatus :', this.suppressStatus)
            if(!this.suppressStatus){
                this.prescriptionColumns.push({ label: 'Status', fieldName: 'Status__c',  sortable: true,
                    actions: [
                        { label: 'All', checked: true, name: 'all' },
                        { label: 'Active', checked: false, name: 'active' },
                    ],
                });
            }

            if(this.includeAdherence) {
                this.prescriptionColumns.push({label: 'Adherence',  sortable: true , fieldName: 'adherence', 
                    hideDefaultActions: true, wrapText: true});
            }
        }


        console.log(
            `
            account  ==== ${this.accountid}            
            external ==== ${this.externalpatientid}   
            patientNoteId ==== ${this.patientNoteId}  
            medicationQuery === ${this.medicationQuery}
            `
        )

        //for other
        this.forOther = this.forMSA == false  &&  this.forAwayOrder == false

        console.log('for Other = ' + this.forOther);


        this.getPrescriptions();
        
    }

    renderedCallback(){
        console.log('in rendredCallback. . . this.patientNote : ', this.patientNote)
        
        if(this.forAwayOrder){
            this.showHideAwayFields();
        }
    }

    @api getPrescriptions() {
        let me = this;
        if( me.medicationQuery ){
            var forMSAOrAway = this.forMSA || this.forAwayOrder ? true : false;

            // if(this.forAwayOrder) {
            //     this.startDate = this.AwayStartDateFromPatientNote;
            //     this.endDate = this.AwayEndDateFromPatientNote;
            //     this.numberOfDaysAway = this.AwayNumberOfDaysFromPatientNote;
            //     this.finalDischargeMedOrder = this.FinalDischargeMedOrderFromPatientNote;
            //     this.daysToPackage = this.DaysToPackageFromPatientNote;
            // }

            getExistingPrescriptionsWithQuery({accountId: me.accountid, medicationQuery: me.medicationQuery, patientNoteId: me.patientNoteId, forMSAOrAway: forMSAOrAway}).then((prescriptions)=>{
                console.log('prescriptions from apex call : ', prescriptions)
                if(prescriptions.length > 0){
                    var prescriptionIds = [];
                    prescriptions.forEach(function(prescription){
                        prescriptionIds.push(prescription.Id);
                    });
                    console.log('prescriptionIds : ', prescriptionIds)

                    if(this.includeAdherence){

                        getPatientNoteRecord({patientNoteId: me.patientNoteId}).then((pn)=>{
                            console.log('pn from apex call : ', pn)
                            var contactDateMilliseconds = Date.parse(pn.Contact_Date__c)
                            this.contactDate = new Date(contactDateMilliseconds)
                            console.log('this.contactDate : ', this.contactDate)

                            const firstDayOfNoteMonth = new Date(this.contactDate.getFullYear(), this.contactDate.getMonth(), 1);
                            const lastDayOfNoteMonth = new Date(this.contactDate.getFullYear(), this.contactDate.getMonth() + 1, 0); 
                            console.log('firstDayOfNoteMonth : ', firstDayOfNoteMonth)
                            console.log('lastDayOfNoteMonth : ', lastDayOfNoteMonth)

                            getDispensingHistoryForPrescriptions({prescriptionIds: prescriptionIds, startDate: firstDayOfNoteMonth, endDate: lastDayOfNoteMonth}).then((dispensingHistoryMap)=>{
                                me.processPrescriptions(prescriptions, dispensingHistoryMap)
                            }).catch(e=>me.handleErrors(e))
                        })
                    } else {
                        me.processPrescriptions(prescriptions)
                    }
                }
                
                // console.log('getExistingPrescriptionsWithQuery - prescriptions', prescriptions)
            }).catch( e=>me.handleErrors(e) )
            
        }else{
            getExistingPrescriptions({externalPatientId: me.externalpatientid, accountId: me.accountid}).then(prescriptions => {
                me.processPrescriptions(prescriptions)
                // console.log('getExistingPrescriptions - prescriptions', prescriptions)
            }).catch( e=>me.handleErrors(e) )
        }
    }

    handleErrors(error){
        let me = this;
        me.notifyUser('Form data Error', 'An error occured while pulling Patient Prescriptions.', 'error');
        console.error('Form Data Error: ', error);
    }

    async processPrescriptions(prescriptions){
        this.processPrescriptions(prescriptions, null);
    }

    async processPrescriptions(prescriptions, dispensingHistoryMap){
        let me = this;
        console.log('this.accountId', this.accountid)
        console.log('processing prescriptions. . .')
        // let account = await getCurrentAdmissionForAccount({accountId: me.accountId})
        let account2;
        await getAccount({accountId: me.accountid}).then(account => {
            account2=account
        }).catch( e=>me.handleErrors(e) )
        console.log('account2.Current_Admission__r.Dispensing_Status__c : ', account2.Current_Admission__r.Dispensing_Status__c)

        if ( prescriptions ) {
            me.prescriptionData = prescriptions.map((prep)=>{
                if(account2 && 'Closet' == account2.Current_Admission__r.Dispensing_Status__c && (prep.location_temp__c == '' || prep.location_temp__c == undefined)
                    && ('' == prep.Location__c || undefined == prep.Location__c)) {
                    prep.location_temp__c = 'Closet Dispensed'
                    var obj = {Id:prep.Id,location_temp__c:prep.location_temp__c}
                    this.updateDraftValues(obj)
                } else if(account2 && 'Closet' == account2.Current_Admission__r.Dispensing_Status__c && (prep.location_temp__c == '' || prep.location_temp__c == undefined)
                    && 'Closet Dispensed' == prep.Location__c) {
                    prep.location_temp__c = 'Package'
                    var obj = {Id:prep.Id,location_temp__c:prep.location_temp__c}
                    this.updateDraftValues(obj)
                } else if(this.forMSA) {
                    var obj = {Id:prep.Id,location_temp__c:prep.location_temp__c}
                    this.updateDraftValues(obj)
                }

                var location = prep.location_temp__c == '' || prep.location_temp__c == undefined ? prep.Location__c : prep.location_temp__c
                
                var Quantity_to_Package__c;
                var daysMultiplier = this.finalDischargeMedOrder ? this.daysToPackage : this.numberOfDaysAway;
                // if Quantity_to_Package_Temp__c already has a vallue then we use that otherwise we'll use the formula
                if((prep.Quantity_to_Package_Temp__c == '' || prep.Quantity_to_Package_Temp__c == undefined ) && daysMultiplier != null && null != prep.Daily_Dosage_Quantity__c && 'Package' == prep.away_package_Instruction__c){
                    // CALCULATING QUANTITY TO PACKAGE THROUGH THIS WAY ONLY FOR THE FIRST TIME
                    console.log('daysMultiplier : ', daysMultiplier)
                    console.log('prep.Daily_Dosage_Quantity__c : ', prep.Daily_Dosage_Quantity__c)
                    console.log('prep.Dosage_Quantity__c : ', prep.Dosage_Quantity__c)
                    Quantity_to_Package__c = daysMultiplier * prep.Daily_Dosage_Quantity__c * prep.Dosage_Quantity__c
                    var obj = {Id:prep.Id,Quantity_to_Package_Temp__c:Quantity_to_Package__c}
                    this.updateDraftValues(obj)
                    this.updateDataValues(obj)
                }else{
                    Quantity_to_Package__c = prep.Quantity_to_Package__c
                }
                var Quantity_to_Package_Temp__c = null;

                console.log('prep.away_package_Instruction__c : ', prep.away_package_Instruction__c)
                if ('Packaged' != prep.away_package_Instruction__c) {
                    console.log('Not Packaged or Reduced to clearing quantity.')
                    Quantity_to_Package_Temp__c = null
                    var obj = {Id:prep.Id,Quantity_to_Package_Temp__c:null}
                    this.updateDraftValues(obj)
                    this.updateDataValues(obj)
                } else {
                    Quantity_to_Package_Temp__c = prep.Quantity_to_Package_Temp__c == '' || prep.Quantity_to_Package_Temp__c == undefined ?
                        Quantity_to_Package__c : prep.Quantity_to_Package_Temp__c
                }

                // TO STORE THE Quantity_to_Package_Temp__c VALUE IF DATATABLE IS RESET
                var orignalQuantity_to_Package_TempVaraiable = Quantity_to_Package_Temp__c;
                // T0 ENABLE OR DISABLE THE Quantity_to_Package_Temp__c TEXTBOX
                var isAwayPackageInstructionDisabled = prep.away_package_Instruction__c == 'Reduced' ? false : true

                var MediFormat = prep.Medication_Format__c;
                console.log(MediFormat);

                var adherence = ''
                console.log('dispensingHistoryMap in processing : ', dispensingHistoryMap)
                if(dispensingHistoryMap) {
                    const filteredMarLines = []
                    for (const [key, value] of Object.entries(dispensingHistoryMap)) {
                        console.log(`${key}: ${value}`);
                        console.log('current prep.Id : ', prep.Id)
                        if(key == prep.Id) {
                            console.log('prescription had ' + value.length + ' MAR Lines created.')
                            console.log('prep.As_Needed__c : ', prep.As_Needed__c)
                            if(prep.Daily_Dosage_Quantity__c && !prep.As_Needed__c) {
                                var marLinesCount = value.length;
                                var daysSoFarInNoteMonth = this.contactDate.getMonth() < new Date().getMonth() ? new Date(this.contactDate.getFullYear(), this.contactDate.getMonth() + 1, 0).getDate() : new Date().getDate();
                                var daysInNoteMonthPatientShouldHaveTakenPrep = daysSoFarInNoteMonth
                                var startDate
                                var endDate
                                if(prep.Start_Date__c) {
                                    var startDateMilliseconds = Date.parse(prep.Start_Date__c)
                                    var startDateLocalNoTimeMilliseconds = new Date(startDateMilliseconds).setHours(0, 0, 0, 0)
                                    startDate = new Date(startDateLocalNoTimeMilliseconds)
                                    startDate.setDate(startDate.getDate() + 1)
                                    daysInNoteMonthPatientShouldHaveTakenPrep = startDate < new Date(this.contactDate.getFullYear(), this.contactDate.getMonth(), 1) ? daysSoFarInNoteMonth : daysSoFarInNoteMonth - startDate.getDate();    
                                }
                                if(prep.End_Date__c) {
                                    var endDateMilliseconds = Date.parse(prep.End_Date__c)
                                    var endDateLocalNoTimeMilliseconds = new Date(endDateMilliseconds).setHours(0, 0, 0, 0)
                                    endDate = new Date(endDateLocalNoTimeMilliseconds)
                                    endDate.setDate(endDate.getDate() + 1)
                                    daysInNoteMonthPatientShouldHaveTakenPrep = endDate < new Date(this.contactDate.getFullYear(), this.contactDate.getMonth() + 1, 0) ? 
                                        !startDate || startDate < new Date(this.contactDate.getFullYear(), this.contactDate.getMonth(), 1) ? endDate.getDate() + 1 : endDate.getDate() - startDate.getDate() + 1
                                        : daysInNoteMonthPatientShouldHaveTakenPrep;    
                                }

                                if(endDate) {
                                    endDate.setDate(endDate.getDate() + 1) // Increment to the next day so we inlude any entries on the end date.
                                }

                                if(startDate){
                                    marLinesCount = 0
                                    value.forEach((marLine) => {
                                        console.log('marLine.CreatedDate : ', marLine.CreatedDate)
                                        var createdDateMillinseconds = Date.parse(marLine.CreatedDate)
                                        var createdDate = new Date(createdDateMillinseconds)
                                        console.log('createdDate : ', createdDate)
                                        if(startDate <= createdDate) {
                                            if(endDate) {
                                                if(createdDate <= endDate) {
                                                    marLinesCount++
                                                }
                                            } else {
                                                marLinesCount++
                                            }
                                        }
                                    });
                                }

                                if(!startDate && endDate) {
                                    marLinesCount = 0
                                    value.forEach((marLine) => {
                                        console.log('marLine.CreatedDate : ', marLine.CreatedDate)
                                        var createdDateMillinseconds = Date.parse(marLine.CreatedDate)
                                        var createdDate = new Date(createdDateMillinseconds)
                                        console.log('createdDate : ', createdDate)
                                        if(createdDate <= endDate) {
                                            marLinesCount++
                                        }
                                    });
                                }

                                console.log('startDate : ', startDate)
                                console.log('endDate : ', endDate)
                                console.log('daysInNoteMonthPatientShouldHaveTakenPrep : ', daysInNoteMonthPatientShouldHaveTakenPrep)
                                var expectedDailyQuantity = prep.Daily_Dosage_Quantity__c;
                                var totalExpectedDispensingSoFar = expectedDailyQuantity * daysInNoteMonthPatientShouldHaveTakenPrep;
                                var adherencePercentage = marLinesCount / totalExpectedDispensingSoFar * 100
                                var adherencePercentageRounded = Math.round((adherencePercentage + Number.EPSILON) * 100) / 100;
                                adherence = 'CD: ' + adherencePercentageRounded + '\%'
                                console.log('marLinesCount : ', marLinesCount)
                                console.log('expectedDailyQuantity : ', expectedDailyQuantity)
                                console.log('totalExpectedDispensingSoFar : ', totalExpectedDispensingSoFar)
                                console.log('adherencePercentage : ', adherencePercentage)
                                console.log('adherencePercentageRounded : ', adherencePercentageRounded)
                                console.log('adherence : ', adherence)
                            } else {
                                var marLinesCount = value.length;
                                if(1 == marLinesCount) {
                                    adherence = 'CD: 1 Dose'
                                } else if(1 < marLinesCount){
                                    adherence = 'CD: ' + marLinesCount + ' Doses'
                                }  
                            }
                        }
                    }
                }

                return {
                    recordLink: "/" + prep.Id,
                    location_temp__c:location,
                    orignalQuantity_to_Package_TempVaraiable:orignalQuantity_to_Package_TempVaraiable,
                    Quantity_to_Package_Temp__c:Quantity_to_Package_Temp__c,
                    MediFormat:MediFormat,
                    isAwayPackageInstructionDisabled:isAwayPackageInstructionDisabled,
                    adherence: adherence,
                    ...prep,   
                                     
                }
            })
        }

        this.originalPrescriptionData = this.prescriptionData;

        console.log('Final Prescription Data -------------- ');
        console.log(JSON.parse(JSON.stringify(this.prescriptionData)));
    }


    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts){
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }

    handlePrescriptionFilter(event) {
        console.log('handlePrescriptionFilter------');
        this.prescriptionFilter = event.detail.value;
        // let me = this;
        // if (event.detail.value === 'all') {
        //     getExistingPrescriptions({externalPatientId: me.externalpatientid, accountId: me.accountid}).then(prescriptions => {
        //         me.processPrescriptions(prescriptions)
        //     }).catch( e=>me.handleErrors(e) )
        // } else {
        //     getExistingPrescriptionsWithQuery({accountId: me.accountid, medicationQuery: me.medicationQuery, patientNoteId: me.patientNoteId}).then((prescriptions)=>{
        //         me.processPrescriptions(prescriptions)
        //     }).catch( e=>me.handleErrors(e) )
        // }

        
        //this.prescriptionData = this.originalPrescriptionData;

        // if (event.detail.value === 'all') {
        //     return;
        // }        

        // this.selectedPrescriptionValue = parseInt(event.detail.value);
        // console.log('Option selected with value: ' + this.selectedPrescriptionValue);

        // //Filter the table
        // let prescriptions = new Array(...JSON.parse(JSON.stringify(this.prescriptionData)));

        // let filteredPrescriptions = prescriptions.filter(prescription => prescription.aprescriptionType === this.selectedPrescriptionValue);
        // console.log('**** filteredPrescriptions: ' + filteredPrescriptions);

        // this.prescriptionData = filteredPrescriptions;

    }

    handleSave() {
        this.handleSave(true);
    }

    handleSave(displaySuccessToastAndRefreshPrescriptions) {

        this.patientNoteStatus;

        const updatedFields = this.draftValues; //JSON.parse(JSON.stringify(this.template.querySelector('lightning-datatable').draftValues)) //event.detail.draftValues;

        var fieldsToUpdate = [];
        
        // FOR AWAYORDERS ONLY
        if(this.forAwayOrder){

            var tempPrescriptionData = this.prescriptionData;
            updatedFields.forEach((currentValue , index) => {
                
                // fetching current row from orignal data
                var orignalValue ;
                for (let i = 0; i < this.prescriptionData.length; i++) {
                    if(this.prescriptionData[i].Id == currentValue.Id){
                        orignalValue = this.prescriptionData[i];
                        if(undefined != currentValue.away_package_Instruction__c) {
                            tempPrescriptionData[i].away_package_Instruction__c = currentValue.away_package_Instruction__c
                        }
                        break
                    }    
                }

                if(( orignalValue.Daily_Dosage_Quantity__c != currentValue.Daily_Dosage_Quantity__c && currentValue.Daily_Dosage_Quantity__c != undefined )){
                        // IF REDUCED and Daily Dosage is changed
                        if(// // 
                            ( orignalValue.away_package_Instruction__c == 'Reduced'  && currentValue.away_package_Instruction__c  == undefined ) // row away_package_Instruction__c is reduced  AND  [ row Daily_Dosage_Quantity__c is also changed ]
                                || currentValue.away_package_Instruction__c == 'Reduced'
                            )
                        {
                            console.log('[IF] away_package_Instruction__c = Reduced :  Daily_Dosage_Quantity__c = '   + currentValue.Daily_Dosage_Quantity__c)
                            fieldsToUpdate.push(currentValue)
                        }
                        // IF PACKAGED OR NOT PACKAGED FIELD IS CHANGED,REVERT CHANGES
                        else{
                            console.log('[ELSE IF] REVERING FIELDS TO ORIGNAL \n away_package_Instruction__c = ' + currentValue.away_package_Instruction__c +' AND Daily_Dosage_Quantity__c = '   + currentValue.Daily_Dosage_Quantity__c)
                            var obj =  {    ...currentValue ,
                                        Daily_Dosage_Quantity__c : orignalValue.Daily_Dosage_Quantity__c ,
                                        away_package_Instruction__c : orignalValue.away_package_Instruction__c
                                    }
                            fieldsToUpdate.push(obj)
                        }
                }
                // row away_package_Instruction__c is changed from orginal value
                else //if(currentValue.away_package_Instruction__c != x.away_package_Instruction__c ){
                {   
                    console.log('[ELSE] Away pkg changes from : ' + currentValue.away_package_Instruction__c + ' to ' + currentValue.away_package_Instruction__c)
                    fieldsToUpdate.push(currentValue)
                }
                
            })

            var hasValidationError = false;
            // tempPrescriptionData.forEach((currentValue , index) => {
            //     if(undefined == currentValue.away_package_Instruction__c && !hasValidationError) {
            //         this.notifyUser('Form data Error', 'Please specify all Away Package Instructions.', 'error');
            //         hasValidationError = true;
            //     }
            // })

            const startDateStr = this.template.querySelector('[data-id="startDate"]')
            if(startDateStr) {
                this.startDate = startDateStr.value;
            }

            const endDateStr = this.template.querySelector('[data-id="endDate"]')
            if(endDateStr) {
                this.endDate = endDateStr.value;
            }
        
            if(startDateStr && endDateStr) {
                var startDate = new Date(startDateStr.value)
                var endDate = new Date(endDateStr.value)
                const diffInMs   = endDate - startDate
                const diffInDays = (diffInMs / (1000 * 60 * 60 * 24)) + 1;
                this.numberOfDaysAway = diffInDays;
            }
    
            // const finalDischargeMedOrderCheckbox = this.template.querySelector('[data-id="dischargeCheckbox"]')
            // if(finalDischargeMedOrderCheckbox) {
            //     this.finalDischargeMedOrder = finalDischargeMedOrderCheckbox.checked
            // }

            const daysToPackageInput = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]')
            if(daysToPackageInput){
                this.daysToPackage = daysToPackageInput.value
            }

            if(this.finalDischargeMedOrder) {
                const daysToPackageInput = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]')
                this.daysToPackage = daysToPackageInput.value
                console.log('this.daysToPackage validation check : ', this.daysToPackage);
                if(null == this.daysToPackage || '' == this.daysToPackage || !this.daysToPackage) {
                    this.notifyUser('Form data Error', 'Please specify the Days to Package.', 'error');
                    hasValidationError = true;
                }
            } else {
                console.log('this.endDate validation check : ', this.endDate);
                if(null == this.endDate || '' == this.endDate || !this.endDate) {
                    this.notifyUser('Form data Error', 'Please specify the Last Day Away.', 'error');
                    hasValidationError = true;
                }
            }

            if(!hasValidationError) {
                console.log('this.startDate : ', this.startDate);
                console.log('this.endDate : ', this.endDate);
                console.log('this.finalDischargeMedOrder : ', this.finalDischargeMedOrder);
                if(this.finalDischargeMedOrder) {
                    this.endDate = null;
                    this.numberOfDaysAway = null;
                } else {
                    this.daysToPackage = null;
                }
                
                console.log('this.daysToPackage : ', this.daysToPackage);
                
            }
        } else if(this.forMSA){
            var tempPrescriptionData = this.prescriptionData;
            updatedFields.forEach((currentValue , index) => {
                
                // fetching current row from orignal data
                for (let i = 0; i < this.prescriptionData.length; i++) {
                    if(this.prescriptionData[i].Id == currentValue.Id){
                        tempPrescriptionData[i].location_temp__c = currentValue.location_temp__c;
                        fieldsToUpdate.push(currentValue)
                        break
                    }    
                }
            })

            var hasValidationError = false;
            // tempPrescriptionData.forEach((currentValue , index) => {
            //     if(undefined == currentValue.location_temp__c && !hasValidationError) {
            //         this.notifyUser('Form data Error', 'Please specify a Location for all medications.', 'error');
            //         hasValidationError = true;
            //     }
            // })
        } else{
            fieldsToUpdate =  updatedFields
        }

        if(!hasValidationError) {
            console.log('Saving Data Table');
            console.log(fieldsToUpdate);

            updatePrescriptions( { data: fieldsToUpdate } ).then( result => {

                console.log( JSON.stringify( "Apex update result: " + result ) );
                if(displaySuccessToastAndRefreshPrescriptions){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Prescriptions updated',
                            variant: 'success'
                        })
                    );
                }

                this.draftValues = [];
                if(displaySuccessToastAndRefreshPrescriptions){
                    this.prescriptionData = []
                    this.originalPrescriptionData = [];
                    this.getPrescriptions();
                }
            
                console.log('after updating prescriptions. . .')
                this.patientNoteStatus
            }).catch( error => {

                console.log( 'Error is ' + JSON.stringify( error ) );
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating or refreshing records',
                        message: error,
                        variant: 'error'
                    })
                );

            });
        }

    }

    // HANDLING DRAFT VALUES
        //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
    }
    // 


    //handling Picklists and Textfields from custom datatable

    // TO UPDATING PRESDATA VALUES
    updateDataValues(updateItem) {
        let copyData = [... this.prescriptionData];
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.prescriptionData = [...copyData];
    }


    // TO UPDATES DRAFT VALUES
    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    //listener handler to get the context and data
    //updates datatable
    picklistChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem;
        
        if(this.forAwayOrder){ // CHECKING WHETHER THE away_package_Instruction__c IS CHANGED, IF REDUCE THE ENABLE THE Quantity_to_Package_Temp__c TEXTBOX ELSE DISABLE IT AND RESET THE VALUE
            updatedItem = { Id: dataRecieved.context, away_package_Instruction__c : dataRecieved.value };
            // [1]  FINDING THE CURENT ROW BY FILTERING ORIGNALPRESCRIPTIONS BY THE DATARECIEVED ID
            // [2]  THEN CHANGING THE REACTIVE VALUE OF THE isAwayPackageInstructionDisabled TO TRUE OR FALSE
            // [3]  IF THE away_package_Instruction__c VALUE IS CHANGE TO VALUE OTHER THAN REDUCED THAN REVERTING Quantity_to_Package_Temp__c BACK TO THE ORIGNAL
            for (let i = 0; i < this.prescriptionData.length; i++) {
                var prep = this.prescriptionData[i];
                if(dataRecieved.context == prep.Id){
                        prep.isAwayPackageInstructionDisabled = dataRecieved.value == 'Reduced' ? false : true  //THIS VALUE IS REACTIVE AND IS BEING PASSED TO THE THE CUSTOM TEXTFIELD COMPONENT ALONG WITH EVERY COLUMN, sO WHEN IT VALUE IS CHNAGE IN THE PARENT IT WILL ALSO REACT IN THE CHILD
                        console.log('in picklistChanged - dataRecieved.value : ', dataRecieved.value)
                        if(dataRecieved.value != 'Reduced' ){ // RESETING THE ROW Quantity_to_Package_Temp__c VALUE BACK TO ORIGNAL
                            // prep.Quantity_to_Package_Temp__c = prep.orignalQuantity_to_Package_TempVaraiable
                            
                            if(null == this.numberOfDaysAway || !this.numberOfDaysAway){
                                this.numberOfDaysAway = this.patientNote.Away_Number_of_Days__c;
                            }
                            console.log('this.numberOfDaysAway : ', this.numberOfDaysAway)

                            if(null == this.daysToPackage || !this.daysToPackage){
                                this.daysToPackage = this.patientNote.Days_to_Package__c;
                            }
                            console.log('this.daysToPackage : ', this.daysToPackage)
                            
                            if(null == this.finalDischargeMedOrder || !this.finalDischargeMedOrder){
                                this.finalDischargeMedOrder = this.patientNote.Final_Discharge_Med_Order__c;
                            }
                            console.log('b4 check - this.finalDischargeMedOrder : ', this.finalDischargeMedOrder)
                            var daysMultiplier = this.finalDischargeMedOrder ? this.daysToPackage : this.numberOfDaysAway;
                            console.log('b4 check - daysMultiplier : ', daysMultiplier)
                            if('Packaged' == dataRecieved.value) {
                                if(daysMultiplier != null && null != prep.Daily_Dosage_Quantity__c && null != prep.Dosage_Quantity__c){
                                    // CALCULATING QUANTITY TO PACKAGE THROUGH THIS WAY ONLY FOR THE FIRST TIME
                                    console.log('daysMultiplier : ', daysMultiplier)
                                    console.log('prep.Daily_Dosage_Quantity__c : ', prep.Daily_Dosage_Quantity__c)
                                    console.log('prep.Dosage_Quantity__c : ', prep.Dosage_Quantity__c)
                                    let Quantity_to_Package__c = daysMultiplier * prep.Daily_Dosage_Quantity__c * prep.Dosage_Quantity__c
                                    console.log('Quantity_to_Package__c from math on picklistChanged : ', Quantity_to_Package__c)
                                    var obj = {Id:prep.Id,Quantity_to_Package_Temp__c:Quantity_to_Package__c}
                                    this.updateDraftValues(obj)
                                    this.updateDataValues(obj)
                                }
                            } else if ('Not Packaged' == dataRecieved.value) {
                                this.updateDataValues({ Id: dataRecieved.context , Quantity_to_Package_Temp__c : null });
                                this.updateDraftValues({ Id: dataRecieved.context , Quantity_to_Package_Temp__c : null })
                            }
                        }
                        break;
                }
            }
        } else if(this.forMSA) {
            updatedItem = { Id: dataRecieved.context, location_temp__c : dataRecieved.value };
        }

        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
        this.handleSave(false);
    }

    textfieldChanged(event) {
        event.stopPropagation();
        let dataRecieved = event.detail.data;
        let updatedItem = { Id: dataRecieved.context, Quantity_to_Package_Temp__c : dataRecieved.value };
        this.updateDraftValues(updatedItem);
        this.updateDataValues(updatedItem);
        this.handleSave(false);
    }
    // === //

    // TO HANDLE SORTING
    columns = this.prescriptionColumns;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    // // Used to sort the 'Age' column
    // sortBy(field, reverse, primer) {
    //     const key = primer
    //         ? function (x) {
    //               return primer(x[field]);
    //           }
    //         : function (x) {
    //               return x[field];
    //           };

    //     return function (a, b) {
    //         a = key(a);
    //         b = key(b);
    //         return reverse * ((a > b) - (b > a));
    //     };
    // }

    // onHandleSort(event) {
    //     const { fieldName: sortedBy, sortDirection } = event.detail;
    //     const cloneData = [...this.prescriptionData];

    //     cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
    //     this.prescriptionData = cloneData;
    //     this.sortDirection = sortDirection;
    //     this.sortedBy = sortedBy;
    // }


    onHandleSort(event) {       
        this.sortedBy = event.detail.fieldName;       
        this.sortDirection = event.detail.sortDirection;       
        this.sortAccountData(event.detail.fieldName, event.detail.sortDirection);
    }


    sortAccountData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.prescriptionData));
       
        let keyValue = (a) => {
            var v = a[fieldname]
            if(v.startsWith('/')) {
                v = a['Drug_Name__c']
            }
            return v;
        };

        let isReverse = direction === 'asc' ? 1: -1;
        
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';
           
            return isReverse * ((x > y) - (y > x));
        });
        
        this.prescriptionData = parseData;
    }



    // ------------------------------ //



    // TO FILTER ALL DATA AND ACTIVE DATA
    handleHeaderAction(event) {
        // gives the selection header action name
        const actionName = event.detail.action.name;
        
        // gives selected column definition
        const colDef = event.detail.columnDefinition;
        
        // assigning colmuns to new variable
        let cols = this.prescriptionColumns;
    
        if (actionName !== undefined && actionName !== 'all') {
            // filtering cases on selected actionname
            this.prescriptionData = this.originalPrescriptionData.filter(_case => _case[colDef.fieldName].toLowerCase() === actionName.toLowerCase());
        } else if (actionName === 'all') {
            // returning all cases
            this.prescriptionData = this.originalPrescriptionData;
        }
    
        /* Following line is responsible for finding which header action selected and return corresponding actions then we will mark selcted as checked/true and remaining will be marked as unchecked/marked */
        
            cols.find(col => col.label === colDef.label).actions.forEach(action => action.checked = action.name === actionName);
            this.prescriptionColumns = [...cols];
        }

        // LMS HANDLERS
    inputValue

    recievedMessage
    subscription

    @wire(MessageContext)
    context

    inputHandler(event){
        this.inputValue = event.target.value
    }

    publishMessage(){
        const message={
            lmsData:{
                value:this.inputValue
            }
        }
        //publish(messageContext, messageChannel, message)
        publish(this.context, SAMPLEMC, message)
    }

    subscribeMessage(){
        //subscribe(messageContext, messageChannel, listener, subscriberOptions)
        this.subscription= subscribe(this.context, SAMPLEMC, (message)=>{this.handleMessage(message)}, {scope:APPLICATION_SCOPE})
    }

    handleMessage(message){

        if(message.lmsData.value == 'Save Prescriptions' ){
            this.handleSave();
        }

        this.recievedMessage = message.lmsData.value? message.lmsData.value :'NO Message published'
        console.log(this.recievedMessage)

    }

    unsubscribeMessage(){
        unsubscribe(this.subscription)
        this.subscription = null
    }

    openPrintedLastDispensedMeds() {
        var pdfUrl = "/apex/PrintedLastDispensedMedsPDF?accountId="+this.accountid
        window.open(pdfUrl);
    }

    // handleFinalDischargeMedOrderChange(event) {
    //     this.value = event.target.checked;        
    //     console.log("handleFinalDischargeMedOrderChange - Final Discharge Med Order : " + this.value);
    //     this.finalDischargeMedOrder = this.value
    //     this.patientNote.Final_Discharge_Med_Order__c = this.finalDischargeMedOrder;

    //     var daysAwayInp = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]');
    //     console.log("daysAwayInp : ", daysAwayInp)
    //     if(this.value) {
    //         if(daysAwayInp) {
    //             this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]').className = 'item-number slds-has-error';
    //             this.template.querySelector('[data-id="endDate"]').className = 'item-date slds-hide';
    //             this.template.querySelector('[data-id="numberOfDaysAway"]').className = 'item-number slds-hide';
    //             this.updateCountsForDaysAway()
    //         }
    //     } else {
    //         if(daysAwayInp){
    //             this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]').className = 'item-number slds-hide';
    //             this.template.querySelector('[data-id="endDate"]').className = 'item-date slds-has-error';
    //             this.template.querySelector('[data-id="numberOfDaysAway"]').className = 'item-number';
    //         }
    //         this.calculateDaysAway();
    //     }
    // }

    calculateDaysAway() {
        const startDateStr = this.template.querySelector('[data-id="startDate"]')
        const endDateStr = this.template.querySelector('[data-id="endDate"]')
        var numberOfDaysAwayInput = this.template.querySelector('[data-id="numberOfDaysAway"]')
        
        if(startDateStr && endDateStr && numberOfDaysAwayInput) {
            this.initialRenderComplete = true;
            console.log('startDateStr.value : ', startDateStr.value)
            console.log('endDateStr.value : ', endDateStr.value)
            var startDate = new Date(startDateStr.value)
            var endDate = new Date(endDateStr.value)
            console.log('startDate : ', startDate)
            console.log('endDate : ', endDate)
            const diffInMs   = endDate - startDate
            console.log('diffInMs : ', diffInMs)
            const diffInDays = (diffInMs / (1000 * 60 * 60 * 24)) + 1;
            console.log('diffInDays : ', diffInDays)
            this.numberOfDaysAway = diffInDays;
            numberOfDaysAwayInput.value = diffInDays;
            this.patientNote.Away_Number_of_Days__c = diffInDays
            this.startDate = startDateStr.value;
            this.patientNote.Away_First_Date__c = this.startDate
            this.endDate = endDateStr.value;
            this.patientNote.Away_Last_Date__c = this.endDate
            this.processPrescriptionsForDaysAwayChange(this.prescriptionData);
            this.updatePatientNoteAwayFields();
        }
    }

    updateCountsForDaysAway() {
        const daysToPackageInput = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]')
        this.daysToPackage = daysToPackageInput.value
        this.patientNote.Days_to_Package__c = this.daysToPackage
        console.log('in updateCountsForDaysAway - this.daysToPackage : ', this.daysToPackage)
        if(null != this.daysToPackage && '' != this.daysToPackage) {
            this.numberOfDaysAway = this.daysToPackage
            this.processPrescriptionsForDaysAwayChange(this.prescriptionData);
            this.updatePatientNoteAwayFields();
        }
    }

    async processPrescriptionsForDaysAwayChange(prescriptions){
        let me = this;
        let temp = [];

        console.log('in processPrescriptionsForDaysAwayChange - prescriptions : ', prescriptions)
        
        if ( prescriptions ) {
            temp = prescriptions.map((prep)=>{
                var Quantity_to_Package__c;
                var daysMultiplier = this.finalDischargeMedOrder ? this.daysToPackage : this.numberOfDaysAway;
                // if Quantity_to_Package_Temp__c already has a vallue then we use that otherwise we'll use the formula
                if(daysMultiplier != null && null != prep.Daily_Dosage_Quantity__c && 'Packaged' == prep.away_package_Instruction__c){
                    // CALCULATING QUANTITY TO PACKAGE THROUGH THIS WAY ONLY FOR THE FIRST TIME
                    console.log('daysMultiplier : ', daysMultiplier)
                    console.log('prep.Daily_Dosage_Quantity__c : ', prep.Daily_Dosage_Quantity__c)
                    console.log('prep.Dosage_Quantity__c : ', prep.Dosage_Quantity__c)
                    Quantity_to_Package__c = daysMultiplier * prep.Daily_Dosage_Quantity__c * prep.Dosage_Quantity__c
                    console.log('Quantity_to_Package__c from math : ', Quantity_to_Package__c)
                    var obj = {Id:prep.Id,Quantity_to_Package_Temp__c:Quantity_to_Package__c}
                    me.updateDraftValues(obj)
                    me.updateDataValues(obj)
                }else{
                    Quantity_to_Package__c = prep.Quantity_to_Package__c
                }
                // var Quantity_to_Package_Temp__c = prep.Quantity_to_Package_Temp__c == '' || prep.Quantity_to_Package_Temp__c == undefined ?
                                                                                        // Quantity_to_Package__c : prep.Quantity_to_Package_Temp__c

                var Quantity_to_Package_Temp__c = Quantity_to_Package__c;
                // TO STORE THE Quantity_to_Package_Temp__c VALUE IF DATATABLE IS RESET
                var orignalQuantity_to_Package_TempVaraiable = Quantity_to_Package_Temp__c;
                console.log('orignalQuantity_to_Package_TempVaraiable from daysAwayChange : ', orignalQuantity_to_Package_TempVaraiable)
                // T0 ENABLE OR DISABLE THE Quantity_to_Package_Temp__c TEXTBOX
                var isAwayPackageInstructionDisabled = prep.away_package_Instruction__c == 'Reduced' ? false : true

                var MediFormat = prep.Medication_Format__c;
                console.log(MediFormat);

                var location = prep.location_temp__c == '' || prep.location_temp__c == undefined ? prep.Location__c : prep.location_temp__c
                
                return {
                    recordLink: "/" + prep.Id,
                    location_temp__c:location,
                    orignalQuantity_to_Package_TempVaraiable:orignalQuantity_to_Package_TempVaraiable,
                    Quantity_to_Package_Temp__c:Quantity_to_Package_Temp__c,
                    MediFormat:MediFormat,
                    isAwayPackageInstructionDisabled:isAwayPackageInstructionDisabled,
                    ...prep,   
                                     
                }
            })
        }

        me.prescriptionData = temp;

        console.log('Final Prescription Data -------------- ');
        console.log(JSON.parse(JSON.stringify(me.prescriptionData)));
    }

    updatePatientNoteAwayFields() {
        const startDateStr = this.template.querySelector('[data-id="startDate"]')
        if(startDateStr) {
            this.startDate = startDateStr.value;
        }

        const endDateStr = this.template.querySelector('[data-id="endDate"]')
        if(endDateStr) {
            this.endDate = endDateStr.value;
        }
    
        if(startDateStr && endDateStr) {
            var startDate = new Date(startDateStr.value)
            var endDate = new Date(endDateStr.value)
            const diffInMs   = endDate - startDate
            const diffInDays = (diffInMs / (1000 * 60 * 60 * 24)) + 1;
            this.numberOfDaysAway = diffInDays;
        }

        // const finalDischargeMedOrderCheckbox = this.template.querySelector('[data-id="dischargeCheckbox"]')
        // console.log('updatePatientNoteAwayFields - finalDischargeMedOrderCheckbox : ', finalDischargeMedOrderCheckbox)
        // if(finalDischargeMedOrderCheckbox) {
        //     console.log('finalDischargeMedOrderCheckbox.checked : ', finalDischargeMedOrderCheckbox.checked)
        //     this.finalDischargeMedOrder = finalDischargeMedOrderCheckbox.checked
        // }

        const daysToPackageInput = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]')
        if(daysToPackageInput){
            this.daysToPackage = daysToPackageInput.value
        }

        var hasValidationError = false;
        if(this.finalDischargeMedOrder) {
            const daysToPackageInput = this.template.querySelector('[data-id="numberOfDayForFinalDischarge"]')
            this.daysToPackage = daysToPackageInput.value
            console.log('this.daysToPackage validation check : ', this.daysToPackage);
            if(null == this.daysToPackage || '' == this.daysToPackage || !this.daysToPackage) {
                hasValidationError = true;
            }
        } else {
            console.log('this.endDate validation check : ', this.endDate);
            if(null == this.endDate || '' == this.endDate || !this.endDate) {
                hasValidationError = true;
            }
        }

        if(!hasValidationError) {
            console.log('this.startDate : ', this.startDate);
            console.log('this.endDate : ', this.endDate);
            console.log('this.finalDischargeMedOrder : ', this.finalDischargeMedOrder);
            if(this.finalDischargeMedOrder) {
                this.endDate = null;
                this.numberOfDaysAway = null;
            } else {
                this.daysToPackage = null;
            }
            
            console.log('this.daysToPackage : ', this.daysToPackage);
            let saveStatus = saveAwayMedOrderNoteDetails({pId:this.patientNoteId, 
                firstDayAwayStr:this.startDate, lastDayAwayStr:this.endDate, 
                finalDischargeMedOrder:this.finalDischargeMedOrder, daysToPackage:this.daysToPackage})
            console.log('saveAwayMedOrderNoteDetails results : ', saveStatus)

            this.dispatchEvent(new CustomEvent("saveawayorderinfo", {
                detail: {
                    firstDayAwayStr:this.startDate,
                    lastDayAwayStr:this.endDate,
                    finalDischargeMedOrder:this.finalDischargeMedOrder,
                    daysToPackage:this.daysToPackage
                } 
            }));

        }
    }
}