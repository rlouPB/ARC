trigger PackageLineTrigger on Package_Line__c(
  before insert,
  after insert,
  before update,
  after update,
  before delete,
  after delete
) {
  TriggerFactory.createHandler(Package_Line__c.sObjectType);
}