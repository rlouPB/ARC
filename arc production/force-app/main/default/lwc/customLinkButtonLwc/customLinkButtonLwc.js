import { LightningElement, api } from 'lwc';

export default class CustomLinkButtonLwc extends LightningElement {
    @api recordId;
    @api buttonLabelA;
    @api buttonHideA = false;
    @api buttonLabelB;
    @api buttonHideB = false;
    @api styleVariantA = "destructive";
    @api styleVariantB = "destructive";

    connectedCallback() {
        if(!this.styleVariantA)
            this.styleVariantA = "destructive";

        if(!this.styleVariantB)
            this.styleVariantB = "destructive";
    }

    fireButtonA() {
        this.launchCustomEvent(this.buttonLabelA);
    }

    fireButtonB() {
        this.launchCustomEvent(this.buttonLabelB);
    }

    launchCustomEvent(label) {
        console.log('@@@@@ From Custom Column type @@@@ -----> ', label);
        console.log('@@@@@ recordId @@@@ -----> ', this.recordId);
        const event = new CustomEvent('customlinkbutton', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                recordId : this.recordId,
                label : label
            }
        });
        
        this.dispatchEvent(event);
    }
}