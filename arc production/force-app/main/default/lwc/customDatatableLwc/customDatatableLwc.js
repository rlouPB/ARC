import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import customNavigationTemplate from './customLinkButtonColumn.html';
import customRecordViewTemplate from './customRecordView.html';
import nursingShiftAssignmentLookupTemplate from './nursingShiftAssignmentLookup.html'

//Modified: 1/Feb/2022
//import the template so that it can be reused
import DatatablePicklistTemplate from './picklist-template.html';
import DatatablePicklistRequiredTemplate from './picklist-required-template.html';
//Textfield will get enable or disable on condition provided by each row [Boodlean]
import DatatableTextfieldTemplate from './textfield-template.html';
import DatatableRichTextfieldTemplate from './richTextfield-template.html';

import {
    loadStyle
} from 'lightning/platformResourceLoader';

// Custom CSS for Datatable
import CustomDataTableResource from '@salesforce/resourceUrl/CustomDataTable';

export default class CustomDatatableLwc extends LightningDatatable {
    static customTypes = {        
        customLinkButton : {
            template: customNavigationTemplate,
            typeAttributes: ['recordId', 'buttonLabelA', 'buttonHideA', 'buttonLabelB', 'buttonHideB', 'styleVariantA', 'styleVariantB']
        },
        recordView: {
            template: customRecordViewTemplate,
            typeAttributes: ['recordId', 'nameField']
        },
        nursingShiftAssignmentLookup: {
            template: nursingShiftAssignmentLookupTemplate,
            typeAttributes: ['recordId','nursingShiftId']
        },
        picklist: {
            template: DatatablePicklistTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context'],
        },
        picklistrequired: {
            template: DatatablePicklistRequiredTemplate,
            typeAttributes: ['label', 'placeholder', 'options', 'value', 'context'],
        },
        textfield: {
            template: DatatableTextfieldTemplate,
            typeAttributes: ['label', 'placeholder', 'disabled', 'value', 'context'],
        },
        richtextfield: {
            template: DatatableRichTextfieldTemplate,
            typeAttributes: ['label', 'placeholder', 'disabled', 'value', 'context'],
        },
    };

    connectedCallback(){
        super.connectedCallback()
        console.log('@@@@@ Hello There DataTable! @@@@');
        console.log('@@@@@ customNavigationTemplate @@@@ ---> ', customNavigationTemplate);
    }

    renderedCallback() {
        super.renderedCallback()
        
        console.info('***************** CUSTOMDATATABLELWC - DEBUG *****************',JSON.parse(JSON.stringify(this)))
    }

    constructor() {
        super();
        Promise.all([
            loadStyle(this, CustomDataTableResource),
        ]).then(() => {})
    }
}