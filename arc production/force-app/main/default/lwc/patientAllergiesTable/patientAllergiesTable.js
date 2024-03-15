import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPatientAllergies from '@salesforce/apex/ScriptSureController.getPatientAllergies';


const actions = [
    { label: 'Edit', name: 'edit' },
    // { label: 'Delete', name: 'delete' },
];

const columns = [
    { label: 'Name', fieldName: 'recordLink', type: 'url', typeAttributes:{ label: { fieldName: "name" }, target: '_blank', wrapText: true}, 
    hideDefaultActions: true},
    // { label: 'On Set Date', fieldName: 'onsetDate', type: 'date', hideDefaultActions: true },
    // { label: 'End Date', fieldName: 'endDate', type: 'date', hideDefaultActions: true },
    // { label: 'Type', fieldName: 'allergyTypeText', hideDefaultActions: true },
    { label: 'Type', fieldName: 'adverseEventCodeText', hideDefaultActions: true, wrapText: true},
    { label: 'Reaction', fieldName: 'reactionText', hideDefaultActions: true },
    { label: 'Severity', fieldName: 'severityCodeText', hideDefaultActions: true },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class PatientAllergiesTable extends LightningElement {
    @api externalpatientid = '';
    @api accountid = '';
        
    
    @track allergyColumns = columns;
    @track allergyData = [];
    @track originalAllergyData = [];
    @track showAllergySearchModal = false;
    @track showAllergyFormModal = false;
    @track selectedAllergy = '';
    @track allergyToEdit;
    @track allergyFilter = 'active';
    @track irisOnly = false;

    @track selectedAllergieValue;

    @track value = '';

    get options() {
        return [
            // { label: 'Drug', value: '1' },
            // { label: 'Food', value: '0' },
            // { label: 'Environment', value: 'enrionment' },
            // { label: 'All', value: 'all' },
            { label: 'Show All', value: 'all' },
            { label: 'Show Active', value: 'active' }
        ];
    }

    connectedCallback() {
        
        this.loadPatientAllergies();
    }

    renderedCallback() {
        //this.loadPatientAllergies();
    }

    loadPatientAllergies() {
        console.log('##### this.accountId ---> ' + this.accountid);
        // if (this.externalpatientid) {
        //     console.log('##### this.externalPatientId ---> ' + this.externalpatientid);

            getPatientAllergies({accountId: this.accountid, filter: this.allergyFilter})
            .then(allergies => {

                console.log('##### this.accountId ---> ' + this.accountid);

                if (allergies) {
                    let allergyListProcessed = new Array();

                    for (let i = 0; i < allergies.length; i++) {
                        let allergy = allergies[i];
                        allergy.recordLink = "/" + allergy.recordId;
                        console.log('##### allergy ---> ', allergy);
                        allergyListProcessed.push(allergy);
                    }

                    this.allergyData = allergyListProcessed;
                    //this.allergyData = allergies;
                    //this.originalAllergyData = allergies;
                }
            })
            .catch(error => {
                this.notifyUser('Form data Error', 'An error occured while loading the Patient Allergies.', 'error');
                console.error('**** Form Data Error: ', error);
            });
        // } else {
        //     window.setTimeout(this.loadPatientAllergies(), 500);
        // }
    }


    get isallergyData(){
        return this.allergyData.length > 0 ? true : false;
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

    handleAllergyFilter(event) {

        this.allergyFilter = event.detail.value;

        this.loadPatientAllergies();

        // this.allergyData = this.originalAllergyData;

        // if (event.detail.value === 'all') {
        //     //this.allergyData = this.originalAllergyData;
        //     return;
        // }        

        // this.selectedAllergieValue = parseInt(event.detail.value);
        // console.log('Option selected with value: ' + this.selectedAllergieValue);

        // //Filter the table
        // let allergies = new Array(...JSON.parse(JSON.stringify(this.allergyData)));

        // let filteredAllergies = allergies.filter(allergie => allergie.allergyType === this.selectedAllergieValue);
        // console.log('**** filteredAllergies: ' + filteredAllergies);

        // this.allergyData = filteredAllergies;

    }

    openAllergySearchModal() {
        this.showAllergySearchModal = true;
    }

    closeAllergySearchModal() {
        this.showAllergySearchModal = false;
    }

    openAllerFormModal(event) {
        console.log('****** openAllerFormModal ---');
        console.log('****** openAllerFormModal ---', event.detail);
        this.selectedAllergy = event.detail;

        this.showAllergySearchModal = false;
        this.showAllergyFormModal = true;

        this.allergyToEdit = null;
    }

    closeAllergyFormModal() {
        this.showAllergyFormModal = false;
        this.irisOnly = false;
        this.selectedAllergy = '';
        this.loadPatientAllergies();
    }

    closeFormOpenSearch() {
        this.closeAllergyFormModal();
        this.openAllergySearchModal();
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.allergyToEdit = row;
                console.log('**** to edit --> ', JSON.parse(JSON.stringify(this.allergyToEdit)));
                break;
            default:
        }

        this.showAllergyFormModal = true;
    }

    handleotherallergy(event){
        this.irisOnly = true;
        this.showAllergyFormModal = true;
    }
    
}