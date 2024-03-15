import { LightningElement, wire, api } from 'lwc';
import retrieveBundle from '@salesforce/apex/LabCompendiumController.retrieveBundle';
import retrieveCompendiumEntries from '@salesforce/apex/LabCompendiumController.retrieveCompendiumEntries';
import saveBundle from '@salesforce/apex/LabCompendiumController.saveBundle';
const columns = [
    
    { label: 'Test Name', fieldName: 'testName'},
    { label: 'Code', fieldName: 'code' },
    { label: 'Category', fieldName: 'category'},
];
export default class CompendiumBundleAssignments extends LightningElement {
    data = [];
    compendia = [];
    values = [];
    columns = columns;
    record = {};
    error;
    @api recordId;
    @api isModalOpen = false;
    @wire(retrieveBundle, { bundleId: '$recordId' })
    retrieveBundleFunc({ error, data }) {
        if (data) {
            this.data = data;
            this.values = data.map(x=>(x.sfid))
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }
    @wire(retrieveCompendiumEntries)
    retrieveCompendiumEntriesFunc({ error, data }) {
        if (data) {
            this.compendia = data.map(x=>({label: x.testName, value: x.sfid}))
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }
    saveBundle() {
        console.log(`Options selected: ${this.values}`);
        console.log(`record Id: ${this.recordId}`);
        saveBundle({ 
            bundleId : this.recordId, 
            itemIds : this.values, 
        })
        .then(result => {
            if (result) {
                this.data = result;
                this.values = result.map(x=>(x.sfid))
                this.error = undefined;
                this.isModalOpen = false;
            } 
        })
        .catch(error => {
            const event = new ShowToastEvent({
                title : 'Error',
                message : 'Error creating contact. Please Contact System Admin',
                variant : 'error'
            });
            this.dispatchEvent(event);
        });
       
    }
    handleChange(event) {
        // Get the list of the "value" attribute on all the selected options
        const selectedOptionsList = event.detail.value;
        this.values = event.detail.value;
        
        //alert(`Options selected: ${selectedOptionsList}`);
    }
}