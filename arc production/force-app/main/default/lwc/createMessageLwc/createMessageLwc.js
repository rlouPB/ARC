import { LightningElement, track, api } from 'lwc';


export default class CreateMessageLwc extends LightningElement {
    @track
    users=[]

    @track
    groups=[]

    @track
    body=''

    @track
    subject=''

    @track
    type=''

    get userItems(){
        return this.users.map(x=>({
            value: x.value,
            label: x.label,
            // type:'avatar',
            isLink:false, 
            // src: 'https://www.lightningdesignsystem.com/assets/images/avatar1.jpg',           
        }))
    }

    get groupItems(){
        return this.groups.map(x=>({
            value: x.value,
            label: x.label,
            type:'avatar',
            isLink:false,            
        }))
    }

    subjectChanged(e){
        this.subject = e.detail.value
    }

    bodyChanged(e){
        this.body = e.detail.value
    }

    onUserSelected(e){
        console.info('User',JSON.stringify(e.detail))
        this.users.push(e.detail)
    }
    onGroupSelected(e){
        console.info('GROUP',JSON.stringify(e.detail))
        this.groups.push(e.detail)
    }
    handleUserRemove(e){
        let idx = this.users.findIndex((x)=> x.value == e.detail.item.value )
        this.users.splice(idx, 1);
    }
    handleGroupRemove(e){
        let idx = this.groups.findIndex((x)=> x.value == e.detail.item.value )
        this.groups.splice(idx, 1);
    }

    @api
    get messageInfo(){
        let me = this
        console.log('me.users.map(x=>x.value) : ', me.users.map(x=>x.value))
        return {
            type: me.type,
            subject : me.subject,
            body : me.body,
            userRecipients: me.users.map(x=>x.value),
            groupRecipients: me.groups.map(x=>x.value)
        }
    }

    // @api
    // async sendMessage(){
    //     let me = this
    //     let message = {
    //         type: this.type,
    //         subject: this.subject,
    //         body: this.body,
    //         patientNoteId: cmp.get("v.patientNoteId"),
    //         isReply: cmp.get("v.isReply"),
    //         messageProfile: cmp.get("v.messageProfile")
    //       };
    //     //   let userRecipients = cmp.get("v.userPillItems").map((r) => r.value);
    //     //   let groupRecipients = cmp.get("v.groupPillItems").map((r) => r.value);
      
    //     //   if (userRecipients.length === 0 && groupRecipients.length === 0) {
    //     //     cmp.find("notifLib").showToast({
    //     //       variant: "error",
    //     //       title: "Error!",
    //     //       message: "A recipient is required."
    //     //     });
      
    //     //     return;
    //     //   }
      
    //     //   let action = cmp.get("c.send");
      
    //     //   action.setParams({
    //     //     sClientRecipients: null,
    //     //     sUserRecipients: JSON.stringify(userRecipients),
    //     //     sClientGroupRecipients: null,
    //     //     sUserGroupRecipients: JSON.stringify(groupRecipients),
    //     //     sMessage: JSON.stringify(message),
    //     //     sIsReply: JSON.stringify(cmp.get("v.isReply")),
    //     //     sMessageProfile: "Staff",
    //     //     sHasNotification: false,
    //     //     sNotificationMessage: null
    //     //   });
    // }
}