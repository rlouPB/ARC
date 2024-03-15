import { LightningElement, track, api } from "lwc";

export default class ModalPopupLwc extends LightningElement {
	@api
	labelforokbtn = "";

	@api
	labelforcancelbtn = "";

	@track
	showDialog;

	@track
	message;

	@track
	title;

	@track
	promptMessage;

	@track
	isConfirm;

	@track
	isPrompt;

	@track
	isError;

	@track
	isInfo;

	@track
	isWarn;

	resolveFunc;
	rejectFunc;

	get isConfirmOrPrompt() {
		return this.isPrompt || this.isConfirm ? true : false;
	}

	get headerClass() {
		let result = "slds-modal__header slds-theme_alert-texture";
		if (this.isSuccess) {
			return `${result} slds-theme_success`;
		} else if (this.isWarn) {
			return `${result} slds-theme_warning`;
		} else if (this.isError) {
			return `${result} slds-theme_error`;
		} else if (this.isInfo) {
			return `${result} slds-theme_info`;
		} else {
			return result;
		}
	}

	get okBtnLabel() {
		// return `${this.isConfirm?'YES':'OK'}`;
		let label;
		if (this.labelforokbtn != "" && this.labelforokbtn != null) {
			label = this.labelforokbtn;
		} else {
			label = `${this.isConfirm ? "YES" : "OK"}`;
		}
		return label;
	}

	get cancelBtnLabel() {
		// return `${this.isConfirm?'NO':'CANCEL'}`;
		let label;
		if (this.labelforcancelbtn != "" && this.labelforcancelbtn != null) {
			label = this.labelforcancelbtn;
		} else {
			label = `${this.isConfirm ? "NO" : "CANCEL"}`;
		}
		return label;
	}

	get showPrompt() {
		return this.isPrompt ? true : false;
	}

	get titleView() {
		return this.isPrompt ? this.message : this.title;
	}

	okBtnHandler(e) {
		console.log("patientLogicPath20 modalPopupLwc okBtnHandler...");
		this.okProcess();
	}
	cancelBtnHandler(e) {
		console.log("patientLogicPath20 modalPopupLwc cancelBtnHandler...");
		this.cancelProcess();
	}
	resetState() {
		console.log("patientLogicPath20 modalPopupLwc resetState...");
		this.showDialog = false;
		this.isPrompt = false;
		this.isConfirm = false;
		this.returnBooleanOnConfirm = false;
		this.isInfo = false;
		this.isError = false;
		this.isWarn = false;
		this.isSuccess = false;
		this.promptMessage = "";
	}
	process(message, title, type, toFocus) {
		console.log("patientLogicPath20 modalPopupLwc process...");
		let me = this;
		this.message = message;
		this.showDialog = true;
		if (title) {
			this.title = title;
		}
		switch (`${type}`.toUpperCase()) {
			case "INFO":
				this.isInfo = true;
				break;
			case "ERROR":
				this.isError = true;
				break;
			case "WARN":
				this.isWarn = true;
				break;
			case "SUCCESS":
				this.isSuccess = true;
				break;
		}
		if (toFocus) {
			debugger;
			toFocus.focus();
		}
		return new Promise(function (resolve, reject) {
			me.resolveFunc = resolve;
			me.rejectFunc = reject;
		});
	}
	promptChangeHandler(e) {
		console.log("patientLogicPath20 modalPopupLwc promptChangeHandler...");
		this.promptMessage = e.target.value;
	}
	promptOnKeyUpHandler(e) {
		console.log("patientLogicPath20 modalPopupLwc promptOnKeyUpHandler...");
		if (e.key && e.key.toUpperCase() == "ENTER") {
			this.okProcess();
		}
	}
	okProcess() {
		console.log("patientLogicPath20 modalPopupLwc okProcess...");
		try {
			if (this.resolveFunc && typeof this.resolveFunc == "function") {
				this.resolveFunc(this.isPrompt ? `${this.promptMessage}` : true);
			}
		} catch (e) {
			if (this.rejectFunc && typeof this.rejectFunc == "function") {
				this.rejectFunc(e);
			} else {
				console.error("ERRORS-> ModalPopupLwc.okBtnHandler", e);
			}
		} finally {
			this.resetState();
		}
	}
	cancelProcess() {
		console.log("patientLogicPath20 modalPopupLwc cancelProcess...");
		try {
			if (this.resolveFunc && typeof this.resolveFunc == "function") {
				if (this.isConfirm) {
					this.resolveFunc(false);
				}
			}
		} catch (e) {
			if (this.rejectFunc && typeof this.rejectFunc == "function") {
				this.rejectFunc(e);
			} else {
				console.error("ERRORS-> ModalPopupLwc.cancelBtnHandler", e);
			}
		} finally {
			this.resetState();
		}
	}
	get promptInput() {
		return this.template.querySelector('[data-id="promptInput"]');
	}
	@api
	alert(message, title = "Alert", type) {
		console.log("patientLogicPath20 modalPopupLwc alert...");
		this.resetState();
		return this.process(message, title, type);
	}
	@api
	confirm(message, title = "Confirm", type) {
		console.log("patientLogicPath20 modalPopupLwc confirm...");
		this.resetState();
		this.isConfirm = true;
		return this.process(message, title, type);
	}
	@api
	prompt(message, type) {
		console.log("patientLogicPath20 modalPopupLwc prompt...");
		this.resetState();
		this.isPrompt = true;
		return this.process(message, "", type, this.promptInput);
	}

	renderedCallback() {
		console.log("patientLogicPath20 modalPopupLwc renderedCallback...");
		if (this.promptInput) {
			this.promptInput.focus();
		}
	}
}