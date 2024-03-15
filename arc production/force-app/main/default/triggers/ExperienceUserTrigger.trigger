trigger ExperienceUserTrigger on User(before insert, after insert) {
  ExperienceUserTriggerHandler handler;
  handler = new ExperienceUserTriggerHandler();

  if (Trigger.isInsert) {
    if (Trigger.isBefore) {
      handler.beforeInsert(Trigger.new);
    }
    if (Trigger.isAfter) {
      handler.afterInsert(Trigger.new, Trigger.newMap);
    }
  }
}