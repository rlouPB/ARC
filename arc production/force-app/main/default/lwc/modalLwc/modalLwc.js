import { LightningElement, api, track } from 'lwc';

export default class ModalLwc extends LightningElement {
    @api
    header

    //Possible values: small, medium, large
    @api
    size='large'    

    @api
    showFooter

    @api
    modalStyle

    onCloseHandler(e){
        this.dispatchEvent('close')
    }

    closeModal(e) {
        this.dispatchEvent(new CustomEvent('close'));
    }

    get modalClass(){
        return `slds-modal slds-modal_${this.size || 'large'} slds-fade-in-open`
    }
}