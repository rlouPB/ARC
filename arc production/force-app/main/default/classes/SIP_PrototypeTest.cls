@isTest
public class SIP_PrototypeTest {
	@isTest
	static void test1() {
		String scheduledItemDefQueryString = 'SELECT id, sObjects_to_Watch__c, ScheduledItemProcessor_to_Use__c, ' + 'ScheduledItemProcessor_Parameters__c, MasterLabel ' + 'FROM Scheduled_Item_Definition__mdt';
		Scheduled_Item_Definition__mdt[] sid = database.query(scheduledItemDefQueryString);
		Scheduled_Item_Run__c sir = new Scheduled_Item_Run__c();
		Set<Id> scheduledDefIds = new Map<Id, Scheduled_Item_Definition__mdt>(sid).keySet();

		sir.Scheduled_Item_Def__c = (new List<id>(scheduledDefIds))[0];
		sir.Name = 'tba';
		sir.Scheduled_Item_Def_Status__c = 'active';
		insert sir;

		SIP_Prototype.process(sid);
		SIP_Prototype.process(null);
	}
}