import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveSSN from '@salesforce/apex/ContactSensitiveFormDataCtl.saveSSN';

export default class AddSsnContactForm extends LightningElement {

    @track ssn1 = '';
    @track ssn2 = '';
    @track ssn3 = '';

    @track func = "javascript: if (this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);"



    closeModal() {
        this.dispatchEvent(new CustomEvent('modalclosed'));
    }

    save() {

        let ssn = this.ssn1 + this.ssn2 + this.ssn3;

        // if(ssn === '' || ssn.length < 9) {
        //     this.notifyUser('Validation', 'Please enter a valid Social Security Number.', 'warning');
        //     return;
        // }

        if(ssn === '' || ssn.length < 9) {
            this.notifyUser('Validation', 'Please enter a valid Social Security Number. Must be 9 digits.', 'warning');
            return;
        }

        saveSSN({ssn})
        .then(isSaved => {

            if (isSaved) {
                this.notifyUser('Success!', 'Social Security Number was submitted successfully', 'success');
                this.dispatchEvent(new CustomEvent('refresh'));
            } else {
                this.notifyUser('Operation failed!', 'An error occured while saving the SSN. Please contact your Administrator.', 'error');
            }

            this.closeModal();
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while saving the SSN.', 'error');
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

    updateSsn1(event){        
        this.validateLength(event, 3, '[data-ss1]');
        // this.ssn1 = event.currentTarget.value;
    }

    updateSsn2(event){
        //this.ssn2 = event.currentTarget.value;
        this.validateLength(event, 2, '[data-ss2]');
    }

    updateSsn3(event){
        //this.ssn3 = event.currentTarget.value;
        this.validateLength(event, 4, '[data-ss3]');
    }

    validateLength(event, length, field) {
        let entry = event.target.value;
        if (entry.length <= length) {
            if (field === '[data-ss1]') {
                this.ssn1 = entry;
            } else if (field === '[data-ss2]') {
                this.ssn2 = entry;
            } else if (field === '[data-ss3]') {
                this.ssn3 = entry;
            }
            
        } else {

            if (field === '[data-ss1]') {
                this.template.querySelector(field).value = this.ssn1;
            } else if (field === '[data-ss2]') {
                this.template.querySelector(field).value = this.ssn2;
            } else if (field === '[data-ss3]') {
                this.template.querySelector(field).value = this.ssn3;
            }

            
        }
        
    }
}