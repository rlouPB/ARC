trigger MedicationAdministrationLineTrigger on Medication_Administration_Line__c(
    before insert,
    after insert,
    before update,
    after update,
    before delete,
    after delete
) {
    TriggerFactory.createHandler(Medication_Administration_Line__c.sObjectType);
}