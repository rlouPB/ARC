import { LightningElement, api } from 'lwc';
import MarkForDelete from '@salesforce/apex/NoteDiagnosisCtl.MarkForDelete'

export default class NoteDiagnosisList extends LightningElement {
    @api
    diagnoses;

    @api
    source;
    
    get isComorbid(){
        return this.source == 'Comorbid';
    }
    get diagnosesCount(){
        return this.diagnoses.length
    }

    onMarkForDelete(e){
        let me = this;
        let value = true;
        let diagnosisId;
        MarkForDelete({ diagnosisId, value}).then(res=>{
            if( res.errorMessage ){
                //TODO: show error?
            }else{
                me.fireEvent('markedfordelete', { diagnosisId, value });
            }
        });
    }

    onCancelDelete(){
        let me = this;
        let value = false;
        let diagnosisId;
        MarkForDelete({ diagnosisId, value}).then(res=>{
            if( res.errorMessage ){
                //TODO: show error?
            }else{
                me.fireEvent('markedfordelete', { diagnosisId, value });
            }
        });
    }

    fireEvent( name, detail ){
        me.dispatchEvent(new CustomEvent( name,{detail: detail }));
    }
}