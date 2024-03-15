import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getSessionToken from '@salesforce/apex/scriptSureController.getSessionToken';
import getUrl from '@salesforce/apex/ScriptSureController.getUrl';



export default class ScriptSureEmbeddedUI extends LightningElement {
    @api externalpatientid = '';
    @api patientcontactid = '';
    @track scripSureURL = '';

    @track isLoading = false;

    connectedCallback() {

        this.buildURL();
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('modalclosed'));
    }

    buildURL() {
        // getSessionToken({})
        // .then(token => {
        //     if (token) {
        //         this.scripSureURL = 'https://stage.scriptsure.com/?sessiontoken='+token+'#/chart/'+this.externalpatientid+'/dashboard';
        //         console.log('**** URL ---> ', this.scripSureURL);
                
        //     }
        // })
        // .catch(error => {
        //     this.notifyUser('Form data Error', 'An error occured while getting Session Token.', 'error');
        //     console.error('**** Form Data Error: ', error);
        // });

        // getUrl({externalPatientId : this.externalpatientid})
        this.isLoading = true;
        getUrl({patientAccounttid : this.patientcontactid})
        .then(url => {
            if (url) {
                this.scripSureURL = url;
                this.isLoading = false;
            }
        })
        .catch(error => {
            this.notifyUser('Form data Error', 'An error occured while getting Session Token.', 'error');
            console.error('**** Form Data Error: ', error);
            this.isLoading = false;
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
}