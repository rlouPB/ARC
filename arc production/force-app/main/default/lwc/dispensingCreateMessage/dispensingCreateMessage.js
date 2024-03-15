import { api, LightningElement } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import send from '@salesforce/apex/CreateMessageController.send';

export default class DispensingCreateMessage extends LightningElement {

    @api
    recordId

    get msg(){
        return this.template.querySelector('c-create-user-group-message')
    }

    closePanel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title='',message='',variant='info'){
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
        }));
    }

    async sendMessage(e){
        try{        
            let msgToSend = {
                ...this.msg.messageInfo,
                type:'Dispensing'
            }

            console.log('msgToSend : ', msgToSend)
            
            if(msgToSend.userRecipients.length == 0 && msgToSend.groupRecipients.length == 0 ) {
                this.showToast('error','A recipient is required.','error')
                return
            }
            console.log('msgToSend : ', msgToSend)
            console.log('msgToSend.userRecipients : ', msgToSend.userRecipients)

            await send({            
                sClientRecipients: null,
                sUserRecipients: JSON.stringify(msgToSend.userRecipients),
                sClientGroupRecipients: null,
                sUserGroupRecipients: JSON.stringify(msgToSend.groupRecipients),
                sMessage: JSON.stringify({
                    subject:msgToSend.subject,
                    body:msgToSend.body,
                    type:'Standard Message',
                    isReply:false,
                    hasNotification:false,
                    notificationMessage:'',
                    prescriptionId: this.recordId,
                }),
                // sIsReply: JSON.stringify(cmp.get("v.isReply")),
                sMessageProfile: "Staff",
                sHasNotification: false,
                sNotificationMessage: null
            })

            this.showToast('','message created.','success')

            this.closePanel()
        }catch(err){
            alert(err)
        }
    }
}