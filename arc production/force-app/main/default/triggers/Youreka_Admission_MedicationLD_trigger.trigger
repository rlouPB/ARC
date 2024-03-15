/* This trigger was created by the Youreka package and is integral to it.
 Please do not delete */
trigger Youreka_Admission_MedicationLD_trigger on Admission_Medication__c(after update) {
	disco.Util.updateAnswersInLinkedSections(Trigger.new, 'Admission_Medication__c');
}