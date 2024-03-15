/* eslint-disable no-unused-expressions */
({
	doInit: function (component, event, helper) {
		console.log("PatientNoteItemController doInit...");

		var noteItem = component.get("v.noteItem");

		// console.log("noteItem isRequired: " + component.get("v.noteItem").noteItem.Is_Required__c);

		// console.log("noteItem.value: " + JSON.stringify(component.get("v.noteItem").noteItem));
		// console.log("patientNote.value: " + JSON.stringify(component.get("v.patientNote")));
		// console.log(
		//   "noteItem instance " + JSON.stringify(component.get("v.instanceName"))
		// );
		component.set("v.hideNoteItem", noteItem.hideNoteItem);
		if (noteItem.noteItem.Type__c == "Embedded Component") {
			helper.instantiateEmbeddedComponent(component, event, helper);
		}
		helper.checkHideNoteItem(component, event, helper);
	},
	onValueChanged: function (component, event, helper) {
		// console.log("PatientNoteItemController onValueChanged...");
		var patientNote = component.get("v.patientNote");
		var noteItem = component.get("v.noteItem");
		var oldValue = patientNote.patientNote[noteItem.noteItem.Field_Name__c];

		//changing from null/undefined/"" to a different null/undefined/"" value, don't need to fire noteChangedEvent
		if (!oldValue && !noteItem.value) return;

		//value changed
		if (oldValue != noteItem.value) {
			//TODO
			// patientNote.patientNote[noteItem.noteItem.Field_Name__c] = noteItem.value;
			// console.log("instance " + component.get("v.instanceName"));
			// console.log("oldValue " + oldValue);
			// console.log("newValue " + noteItem.value);
			// console.log("fieldName " + noteItem.noteItem.Field_Name__c);

			// **************** Commenting these lines out to prevent recursion and "Maximum call stack size exceeded"
			// **************** Also, the noteChange event is just calling the handleNoteChanged method whitch is only doing a console log.

			// JN 210929: commented out previously, these probably need to be put back into active code, but will need to figure out what the stack size thing is

			var noteChangedEvent = component.getEvent("noteChanged");
			var instanceName = component.get("v.instanceName");
			var changedFields = [
				{
					field: noteItem.noteItem.Field_Name__c,
					value: noteItem.value,
				},
			];
			noteChangedEvent.setParams({
				changedFields: changedFields,
				instanceName: instanceName,
			});
			// JN removed 210930, patient Note field will be updated by PatientNote cmp when it gets the event
			// component.set('v.patientNote.patientNote', patientNote.patientNote);

			//This event will be handled by PatientNote
			noteChangedEvent.fire();
		}
	},

	//NoteChangedEvent aura event fired
	handleNoteChanged: function (component, event, helper) {
		console.log("PatientNoteItem handleNoteChanged c:NoteChangedEvent params: " + JSON.stringify(event.getParams()));
		// console.log('handleNoteChanged event instanceName ' + event.getParam('instanceName'));
		// if (event.getSource().get('v.instanceName') == component.get('v.instanceName'))
		// {
		//     console.log('Changed fields on event: ' + JSON.stringify(event.getParam('changedFields')));
		//     console.log('Current field value in the Patient Note object: ' + component.get('v.patientNote.patientNote')[component.get('v.noteItem.noteItem.Field_Name__c')]);
		//     return; //ignore if this same instance did the changing
		// }
		// helper.checkHideNoteItem(component, event, helper, event.getParam('changedFields'));
	},

	//change in Patient Note sObject record
	onPatientNoteChanged: function (component, event, helper) {
		// console.log("PatientNoteItemController onPatientNoteChanged ...");
		// console.log('onPatientNoteChanged: patientNote was changed, being handled by instance ' + component.get('v.instanceName'));
		// console.log('This NoteItem\'s current field value in the Patient Note object: ' + component.get('v.patientNote.patientNote')[component.get('v.noteItem.noteItem.Field_Name__c')]);
		// console.log('This NoteItem\'s current noteItem.value: ' + component.get('v.noteItem.value'));
		helper.checkHideNoteItem(component, event, helper);
	},
});