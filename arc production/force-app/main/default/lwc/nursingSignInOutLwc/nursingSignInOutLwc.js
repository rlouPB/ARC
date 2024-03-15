/**
 * @description       : 
 * @author            : Saadain Ali
 * @file type         : 
 * @created modified  : 
 * @last modified on  : 01-06-2022
 * @last modified by  : Saadain Ali
**/
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSignInOutData from '@salesforce/apex/NursingSignInOutService.getSignInOutData';
import getMyNursingShiftAssigments from '@salesforce/apex/NursingSignInOutService.getMyNursingShiftAssigments';
import signIntoShift from '@salesforce/apex/NursingSignInOutService.signIntoShift';
import signOutFromShift from '@salesforce/apex/NursingSignInOutService.signOutFromShift';

import momentjs from '@salesforce/resourceUrl/momentjs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class NursingSignInOutLwc extends LightningElement {

    @track
    loading

    @track
    data

    @track
    myAssignments

    @track
    selectedItem

    get popup(){
        return this.template.querySelector('.popup')
    }

    get haveAssignments(){
        return this.myAssignments?.length > 0
    }

    get currentAssignments(){
        return this.myAssignments? this.myAssignments.map(item=>{
            return {
                Id: item?.Id,
                ShiftId : item?.Nursing_Shift__c,
                ShiftName : `${item.Nursing_Shift__r?.Shift__c}`
            }
        }) : [];
    }

    connectedCallback(e){   
        
        loadScript(this, momentjs)
            .then(() => {
            console.log('Moment js loaded.');
            })
            .catch(error => {
            console.log('Failed to load the moment js : ' + error);
            });
        
        this.load()
    }
    
    async load(){     
        this.loading = true   
        this.myAssignments = await getMyNursingShiftAssigments()
        this.data = await getSignInOutData()
        debugger;
        console.info('LOAD => ',{
            'this.myAssignments: ': JSON.parse(JSON.stringify(this.myAssignments)),
            'this.data': JSON.parse(JSON.stringify(this.data))
        })
        this.loading = false
    }


    // getter to remap dates values in correct format
    get getData(){
        if (this.data){
            return this.data.map(x => {
                var Shift_Open_Date_Time__c = x.Shift_Open_Date_Time__c != null ? moment(x.Shift_Open_Date_Time__c).format("DD/MM/YYYY h:mm:ss"):''
                return {...x , Shift_Open_Date_Time__c:Shift_Open_Date_Time__c}
            })
        }
        return this.data
    }

    onDateClickHandler(e){
        e.preventDefault();
        this.selectedItem = this.data.find(x=>x.Id==e.target.dataset.id)
        this.popup.confirm(`Signing into shift ${this.selectedItem.Shift__c}.`,'Sign In').then(result=>{
            if(result){
                this.assignedIntoShift();
            }
        })
    }

    @track
    selectedShiftAssignmentId

    async onSignOutHandler(e){
        this.selectedShiftAssignmentId = e.target.dataset.id
        let selected = this.currentAssignments.find(item=>item.Id==this.selectedShiftAssignmentId)

        this.popup.confirm(`Are you sure you want to Sign Out from ${selected.ShiftName}`,'Signing Out').then(async confirmed=>{
            if(confirmed){
                this.loading = true
                let result = await signOutFromShift({
                    nursingShiftAssignmentId : this.selectedShiftAssignmentId
                })
                if( result ){
                    this.toast(result,'Error','error')
                }else{
                    this.load()
                    this.refreshView()
                }
                this.loading = false
            }
        })        
    }

    async assignedIntoShift(){
        this.loading = true
        let assignResults = await signIntoShift({
            shiftId: this.selectedItem?.Id
        })
        if( assignResults ){
            this.toast(assignResults,'Error','error')
        }else{
            this.load()
            this.refreshView()
        }
        this.loading = false
    }

    @api
    refreshView(){
        // Creates the event with the contact ID data.
        const selectedEvent = new CustomEvent('refreshview');

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }


    toast(message,title='alert',variant='info') {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}