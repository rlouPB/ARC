import { LightningElement, api, track, wire } from "lwc";
import getCaseAbstract from "@salesforce/apex/CaseAbstract.getCaseAbstract";
import finalizeCaseAbstract from "@salesforce/apex/CaseAbstract.finalizeCaseAbstract";
import reopenCaseAbstract from "@salesforce/apex/CaseAbstract.reopenCaseAbstract";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import send from "@salesforce/apex/CreateMessageController.send2";

export default class CaseAbstractLwc extends LightningElement {
	@api
	recordId;
    @api
	showSpinner = false;
    @track
	caseAbstract;
	caseAbstractStatus;
	generatedDateTimeInteger;
    
	showConfirmModal = false;
	showReOpenConfirmationModal = false;
	showCreateMessageModal = false;
	confirmationModalText = "Are you sure you want to finalize the Case Abstract?";
	reOpenconfirmationModalText = "Are you sure you want to re-open the Case Abstract?";
    scrollOptions = {
        left: 0,
        top: 0,
		behavior: "smooth"
	};
	get disableGeneratePresentation() {
		return !this.caseAbstract.canGeneratePresentation || this.caseAbstract.record.Status__c == "Finalized";
    }

	get disableViewPresentation() {
		return !this.caseAbstract.hasPresentation;
    }

    get isFinalized() {
        return this.caseAbstractStatus == "Finalized";
    }
    get canReopen() {
        return (this.caseAbstract.record.Status__c == "Finalized")  && (this.caseAbstract.canReopen);
    }
    
	showToast(title = "", message = "", variant = "info") {
		this.dispatchEvent(
			new ShowToastEvent({
            title,
            message,
				variant
			})
		);
    }

	get pageColumns() {
        //TODO: change to 11 & 1 based on IsCollapsed? That's how the Aura PatientNote.cmp works with the sidebar
        var pageColumns = {
			mainWidth: 9,
			sidebarWidth: 3
        };
        return pageColumns;
    }

	get popup() {
		return this.template.querySelector(".popup");
    }

    get presentationUrl() {
        return `/apex/CaseAbstractPresentationPDF?id=${this.recordId}`;
      }

	get msg() {
		return this.template.querySelector("c-create-user-group-message");
    }

	connectedCallback() {
		this.load();
    }

	async load() {
		console.log("record Id = " + this.recordId);
		var serializedResult = await getCaseAbstract({ recordId: this.recordId });
		var parsedResult = JSON.parse(serializedResult);
		if (parsedResult.record) {
			this.caseAbstract = parsedResult;
            this.caseAbstractStatus = this.caseAbstract.record.Status__c;
            //generatedDateTimeInteger = this.caseAbstract.record.Presentation_Generated_Date_Time__c.getTime();
			this.generatedDateTimeInteger = new Date(this.caseAbstract.record.Presentation_Generated_Date_Time__c);
			//this.sectionRecords = this.caseAbstract.sectionRecords
			console.info("results**************************", JSON.parse(JSON.stringify(this.caseAbstract)));
			console.log("caseAbstract " + JSON.stringify(this.caseAbstract.record));
			console.log("caseAbstract.Id " + this.caseAbstract.record.Id);
		} else {
			console.log("problem getting Case Abstract: " + JSON.stringify(parsedResult));
		}
    }

    // async onRecordChange(e){
    //     let me = this;
    //     let fieldName = e.target.dataset.id
    //     let fieldValue = e.detail.value
    //     let fieldLabel = me.getLabel(fieldName)
    //     let fieldValueLabel = e.detail.label
    //     let old = e.detail.old

    //     console.info(`SELECTED:   ${fieldName} : ${fieldValue}`, JSON.parse(JSON.stringify(e.detail)));
        
    //     console.info('INFO', JSON.parse(JSON.stringify(me.nursingShiftInfo?.data)))

    //     let fieldRef = me.nursingShiftInfo?.data?.fields[fieldName]?.referenceToInfos

    //     let isUser = (fieldRef && fieldRef.length > 0)? fieldRef[0]?.apiName == 'User' : false

    //     console.info('EVENT', {event: e})

    //     let cmp = this.template.querySelector(`[data-id="${fieldName}"]`)

    //     me.saveFieldChange(
    //         fieldName,
    //         fieldValue,
    //     )
    // }

    // async saveFieldChange(fieldName,value){
    //     let result = await saveNursingFieldChange({
    //         nursingShiftId: this.recordId,
    //         fieldName,
    //         value,
    //     })
    //     if(result){
    //         this.popup.alert(`Updating ${fieldName} to value: ${value}.  ERROR: ${result}`,'ERROR','error')
    //         this.load()
    //     }else{
    //         console.info(`Updating ${fieldName} to value: ${value}, success.`)
    //     }
    // }

	onSubmitHandler(e) {
        e.preventDefault();
		console.info("onSubmitHandler");
    }

    handleSendAsMessage(event) {
		console.log("handleSendAsMessage");
        this.showCreateMessageModal = true;
    }

    handleGeneratePresentation(event) {
		console.log("handleGeneratePresentation");
		var url = "/apex/CaseAbstractPresentation?id=" + this.recordId;
		window.open(url, "_self");
    }

    handleSave(event) {
		console.log("handleSave");
    }

    handleViewPresentaion(event) {
		console.log("handleViewPresentaion");
		var url = "/apex/CaseAbstractPresentationPDF?id=" + this.recordId;
		window.open(url, "_blank");
    }

    showConfirmationBox() {
        this.showConfirmModal = true;
    }

    closeConfirmationBox() {
        this.showConfirmModal = false;
    }

    closeCreateMessageBox() {
        this.showCreateMessageModal = false;
    }

    showReOpenConfirmation() {
        this.showReOpenConfirmationModal = true;
    }
    closeReOpenConfirmationModal() {
        this.showReOpenConfirmationModal = false;
    }
    
    async handleReOpen(event) {
		window.scrollTo(this.scrollOptions);
        this.showReOpenConfirmationModal = false;
        this.showSpinner = true;
		console.log("handleReOpen");
		console.log("record Id = " + this.recordId);
		var serializedResult = await reopenCaseAbstract({ recordId: this.recordId });
		if (serializedResult == "Success") {
			window.open("/" + this.recordId, "_self");
        } else {
            //handle error condition
        }
		this.showSpinner = false;
    }

    async handleFinalize(event) {
        window.scrollTo(this.scrollOptions)
        this.showConfirmModal = false;
        this.showSpinner = true;
		console.log("handleFinalize");
		console.log("record Id = " + this.recordId);
		var serializedResult = await finalizeCaseAbstract({ recordId: this.recordId });
		if (serializedResult == "Success") {
			window.open("/" + this.recordId, "_self");
            //var url = '/apex/CaseAbstractPresentation?id=' + this.recordId;
			this.showSpinner = false;
		    //window.open(url, "_self");
        } else {
            //handle error condition
        }
    }
    refreshCaseAbstract(event) {
		window.open("/" + this.recordId, "_self");
    }
	async sendMessage(e) {
		try {
            let msgToSend = {
                ...this.msg.messageInfo,
				type: "Case Abstract",
				previewUrl: this.caseAbstract.presentation.previewUrl
			};
			let previewUrl = this.template.querySelector(".previewUrl");
			const content = '<br/><a href="' + previewUrl.href + '">Latest Case Abstract Presentation</a>';
            msgToSend.body += content;
			console.log("msgToSend : ", msgToSend);
            
			if (msgToSend.userRecipients.length == 0 && msgToSend.groupRecipients.length == 0) {
				this.showToast("error", "A recipient is required.", "error");
				return;
            }
			console.log("msgToSend : ", msgToSend);
			console.log("msgToSend.userRecipients : ", msgToSend.userRecipients);

            await send({            
				sClientRecipients: "[]",
                sUserRecipients: JSON.stringify(msgToSend.userRecipients),
				sClientGroupRecipients: "[]",
                sUserGroupRecipients: JSON.stringify(msgToSend.groupRecipients),
                sMessage: JSON.stringify({
					subject: msgToSend.subject,
					body: msgToSend.body,
					type: "Standard Message",
					isReply: false,
					hasNotification: false,
					notificationMessage: ""
                }),
                // sIsReply: JSON.stringify(cmp.get("v.isReply")),
                sMessageProfile: "Staff",
                sHasNotification: "false",
                sNotificationMessage: null
			});

			this.showToast("", "message created.", "success");
			this.closeCreateMessageBox();
		} catch (err) {
			alert(err);
        }
    }
}