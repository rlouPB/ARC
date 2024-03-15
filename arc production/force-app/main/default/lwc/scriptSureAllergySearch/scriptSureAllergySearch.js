import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchAllergies from "@salesforce/apex/ScriptSureController.searchAllergies";

export default class ScriptSureAllergySearch extends LightningElement {

    @track allergyList;
    @track isLoading = false;
    @track message = '';
    
    async connectedCallback() 
    {       
        // Focus on input field (once rendering done)
        window.setTimeout(() => {
                //const firstInput = this.template.querySelector('lightning-input');
                const searchInput = this.template.querySelector('.allergySearch');
                if (searchInput) console.log('searchInput exists! ' + JSON.stringify(searchInput));
                if (searchInput) searchInput.focus();
            }, 50);
    }
    closeModal() {
        this.dispatchEvent(new CustomEvent('modalclosed'));
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

    handleKeyUpSearch(event) {
        let value = event.target.value;

        if (value.length >= 3) {
            this.isLoading = true;

            searchAllergies({allergyName: value})
            .then(allergies => {
                this.allergyList = null;

                if (allergies) {
                    let modifiedAllergies = JSON.parse(JSON.stringify(allergies));

                    for (let i = 0; i < modifiedAllergies.length; i++) {
                        modifiedAllergies[i].id = i;
                    }

                    this.allergyList = modifiedAllergies;
                } else {
                    this.message = 'No allergy found for search input.';
                }

                this.isLoading = false;
            })
            .catch(error => {
                this.notifyUser('Form data Error', 'An error occured while retrieving Allergies.', 'error');
                console.error('**** Form Data Error: ', error);
            });
        }
        
    }

    handleSelectAllergy(event) {
        console.log('****** handleSelectAllergy ---');
        let allergyName = event.detail.name;
        console.log('****** allergyName ---> ', allergyName);

        this.dispatchEvent(new CustomEvent('selectedallergy', {detail: allergyName}));
    }

    handleOtherAllergy(event) {
        this.dispatchEvent(new CustomEvent('otherallergy', {detail: true}));
    }
}