import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPatientInformation from '@salesforce/apex/ContactSensitiveFormDataCtl.getPatientInformation';


export default class ManageSensitiveContactData extends LightningElement {
    @track patientData = {};
    @track name = 'New test';
    @track showSSNModal = false;
    

    connectedCallback() {
        this.loadPatientData();
    }

    loadPatientData() {
        //Load the patient info
        getPatientInformation()
        .then(results => {
            if (results) {
                this.patientData = results;
                console.log('this.patientData.Birthdate : ' + this.patientData.Birthdate)
            }
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while loading Patient information.', 'error');
            console.error('Form Data Error: ', error);
        });
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

    get hasSSN() {
        return this.patientData.SSN !== '' && this.patientData.SSN !== null && this.patientData.SSN !== undefined;
    }

    openSSNModal() {
        this.showSSNModal = true;
    }

    modalclosed() {
        this.showSSNModal = false;
    }
}