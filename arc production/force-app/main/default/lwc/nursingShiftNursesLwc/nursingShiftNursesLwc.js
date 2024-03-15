import { LightningElement, api, track, wire } from 'lwc';
import getNursingShiftAssigmentsByShiftId from '@salesforce/apex/NursingShiftService.getNursingShiftAssigmentsByShiftId';
import signOutNurseFromShift from '@salesforce/apex/NursingShiftService.signOutNurseFromShift';
import removeShiftAssignment from '@salesforce/apex/NursingShiftService.removeShiftAssignment';
import checkCustomPermission from '@salesforce/apex/NursingShiftService.checkCustomPermission';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NursingShiftNursesLwc extends LightningElement {
    @api
    recordId

    @track
    rawData

    @track
    columns

    @track
    loading

    @track
    hasIsNursingAdmin

    @track
    loaded

    get IsNursingAdmin() { 
        return this.hasIsNursingAdmin? true : false
    }

    fieldLabel(fieldName){
        return this.nsainfo?.data?.fields?.[fieldName]?.label
    }

    @track
    data=[]

    @track
    pagedData=[]

    get paginator(){
        return this.template.querySelector('c-paginator-lwc')
    }
    pageChanged(){
        this.paginator.pageChanged()
    }

    async connectedCallback(){
        let me = this
        this.columns = [
            { name: 'Name', label: 'Name' },
            { name: 'Nurse', label: 'Nurse' },            
            { name: 'Status', label: 'Status' },
            { name: 'signInDateTime', label: 'Sign In'},
            { name: 'signOutDateTime', label: 'Sign Out'},
        ]
        this.hasIsNursingAdmin = await checkCustomPermission({customPermission:'IsNursingAdmin'})
        await this.load()
        this.loaded = true                        
    }

    async load(){
        this.loading = true
        this.rawData = await getNursingShiftAssigmentsByShiftId({nursingShiftId: this.recordId})
        this.data = this.rawData.map(x=>{
            return {
                record: {...x},
                Id: x.Id,
                Name: x.Name,
                Nurse: `${x.Owner__r?.FirstName} ${x.Owner__r?.LastName}`,
                Role: x.Role__c || '',
                Status: x.Status__c || '',
                signInDateTime: x.Sign_In_Date_Time__c || '',
                signOutDateTime: x.Sign_Out_Date_Time__c || '',
                isFinalized: x.Sign_Out_Date_Time__c,
                showButtons: this.IsNursingAdmin && 'Open' == x.Status__c,
            }
        })
        this.pageChanged()
        this.loading = false
    }

    onClickHandler(e){
        let name = e.target.dataset.fieldname
        this.columns.forEach(x=>x.sorted=false)
        let col = this.columns.find(x=>x.name==name)
        col.isDESC = !col.isDESC
        
        col.sorted = true

        //sort
        this.data = this.data.sort((x, y) => {
            x = x[name] ? x[name] : '';
            y = y[name] ? y[name] : '';

            // sorting values based on direction
            return (col.isDESC?-1:1) * ((x > y) - (y > x));
        });

        this.pageChanged()
    }

    get popup(){
        return this.template.querySelector('c-modal-popup-lwc')
    }

    async onSignOutClick(e) {
        let itemId = e.target.dataset.id
        let item = this.data.find(x=>x.Id == itemId)
        let nurseName = this.getNurseName( itemId )
        this.popup.confirm(`Are you sure you want to sign ${nurseName} out of this shift?`).then(async (res)=>{
            if(res){
                this.loading = true
                try{
                    let params = { nursingShiftId:  this.recordId, nurseId: item.record?.Owner__r?.Id }
                    console.info("***** onSignOutClick *****", JSON.parse(JSON.stringify(params)), JSON.parse(JSON.stringify(item)))
                    let signOutResult = await signOutNurseFromShift( params )
                    if( signOutResult ) {
                        this.showToast('Error', signOutResult,'error')
                    } else {
                        this.showToast('Success', 'Nurse signed out.','success')
                    }
                } catch(err) {
                    console.info('*****ERROR ON signOutFromShift*****', err)
                }
                this.loading = false
            }
        })
    }

    onRemoveClick(e) {
        let itemId = e.target.dataset.id
        let nurseName = this.getNurseName( itemId )
        this.popup.confirm(`Are you sure you want to remove ${nurseName} nurse from this shift?  This should only be used if ${nurseName} did not work this shift.`).then(async (res)=>{
            if(res){                
                this.loading = true
                try {
                    let params = {nursingShiftAssignmentId: itemId}
                    let removeResult = await removeShiftAssignment( params )
                    if( removeResult ) {
                        this.showToast('Error', removeResult,'error')
                    } else {
                        this.showToast('Success', 'Nurse assignment removal.','success')
                    }
                } catch (ex) {}
                this.loading = false
            }
        })
    }

    getNurseName(nurseId) {
        return this.rawData.find(x=>x.Id==nurseId)?.Owner__r?.Professional_Name__c || ''
    }

    async pageChangedHandler(e){
        this.pagedData = e.detail.values
    }

    showToast(title='',message='',variant='info'){
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
        }));
    }
}