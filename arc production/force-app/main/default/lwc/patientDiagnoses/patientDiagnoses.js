import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LoadData from "@salesforce/apex/PatientDiagnosesCls.LoadData";
import getRecordInfo from "@salesforce/apex/NoteDiagnosisCtl.getRecordInfo";

export default class PatientDiagnoses extends LightningElement {
    @api
    patientId;

    @track
    principals = [];

    @track
    comorbids = [];

    @track
    selected = "Psychotherapist";

    options = [
        { label: "Diagnosis of Record", value: "Psychotherapist" },
        { label: "Psychiatrist", value: "Psychiatrist" },
        { label: "Admissions", value: "Admissions" },
        { label: "SCID", value: "Assessment" }
    ];

    columns = [{
            label: "Description",
            fieldName: "description",
            hideDefaultActions: true,
            wrapText: true
        },
        {
            label: "Code",
            fieldName: "code",
            hideDefaultActions: true,
            wrapText: true,
            initialWidth: 100
        },
        {
            label: "Additional Specifiers",
            fieldName: "specifiers",
            hideDefaultActions: true,
            wrapText: true,
            initialWidth: 400
        }
    ];

    onActiveHandler(e) {
        this.load(e.target.value);
    }

    onSelectedOption(e) {
        this.load(e.target.value);
    }

    connectedCallback() {
        let me = this;
        console.info("connectedCallback");
        me.getDefailtSource().then((source) => {
            console.info("connectedCallback returned ", source);
            me.selected = source;
            me.load(source);
        });
    }

    @api
    initialize() {
        this.connectedCallback();
    }

    async load(source) {
        try {
            console.info("load ", source);
            let results = await LoadData({ patientId: this.patientId, source });
            console.info("load - results", results);
            if (!results.errorMessage) {
                this.principals = results.principals;
                this.comorbids = results.comorbids;
            } else {
                this.showToast({ variant: "error", message: results.errorMessage });
            }
        } catch (ex) {
            console.error("LOADING....", ex);
        }
    }

    getDefailtSource() {
        let me = this;
        return new Promise(function(resolve, reject) {
            getRecordInfo({
                    recordId: me.patientId,
                    sobjectType: "Account",
                    fields: "Current_Admission__r.Principal_Diagnosis__r.Source__c"
                })
                .then((result) => {
                    resolve(
                        result.Current_Admission__r.Principal_Diagnosis__r.Source__c ||
                        "Psychotherapist"
                    );
                })
                .catch((e) => {
                    console.warn("getDefailtSource Error thrown: ", e);
                    resolve("Psychotherapist");
                });
        });
    }

    showToast(params) {
        const evt = new ShowToastEvent(params);
        this.dispatchEvent(evt);
    }
}