import { LightningElement, api } from 'lwc';

export default class DispensingPrescriptionWarnings extends LightningElement {
    @api
    isMaxDosageWarning

    @api
    maxDailyDosage

    @api
    maxDailyDosageLastDispensed
    
    @api 
    isScheduledDrugWarning

    @api 
    isDurationWarning

    @api 
    isDateRangeWarning

    @api
    duration

    @api
    medicationName

    connectedCallback() {
        // console.log('this.isMaxDosageWarning', this.isMaxDosageWarning)
        // console.log('this.maxDailyDosage', this.maxDailyDosage)
        // console.log('this.isDurationWarning', this.isDurationWarning)
        // console.log('this.isDateRangeWarning', this.isDateRangeWarning)
    }
}