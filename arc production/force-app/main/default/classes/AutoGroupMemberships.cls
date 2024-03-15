public class AutoGroupMemberships 
{
	@testVisible
	static final Map<String, String> memberType2SobjectField = new Map<String, String>{
		'Staff' => 'Staff_Group_Member__c.Staff_Member__c',
		'Patient' => 'Patient_Group_Member__c.Patient__c'
	};
	static final String groupMembershipQueryString =
		'SELECT Id, Name, Type__c,' +
				' (SELECT Id, Staff_Member__c, Role__c' +
						' FROM Staff_Group_Members__r' +
						' WHERE Start_Date__c <= TODAY AND (Planned_End_Date__c = null OR Planned_End_Date__c > TODAY)),' +
				' (SELECT Id, Patient__c, Role__c' +
						' FROM Patient_Group_Members__r' +
						' WHERE Start_Date__c <= TODAY AND (Planned_End_Date__c = null OR Planned_End_Date__c > TODAY))' +
		' FROM Group__c' +
		' WHERE Name in :groupMembershipNamesToQuery';
	
	Set<String> groupMembershipNamesToQuery = new Set<String>();
	
	List<Group__c> groupMemberships;
	
	public List<sObject> sgmsToUpsert = new List<sObject>();
	public List<sObject> pgmsToUpsert = new List<sObject>();
	
	//constructor
	public AutoGroupMemberships() {
		this(true);
	}
	public AutoGroupMemberships(Boolean buildEverything) 
    {
		if (buildEverything) {
			//query for Group Memberships by Name
			queryGroupMemberships();
			
			Set<String> missingGroupMembershipNames = findMissingGroupMembershipNames(new Set<String>(syncDefMap.keySet()));
			
			if (!missingGroupMembershipNames.isEmpty()) {
				makeNewGroupMemberships(missingGroupMembershipNames);
			}
			
			compareGroupMembersToQueriedObjects();
		}
	}
	
	void queryGroupMemberships() 
    {
		groupMembershipNamesToQuery.addAll(syncDefMap.keySet());
		groupMemberships = (List<Group__c>) Database.query(groupMembershipQueryString);
	}
	
	Set<String> findMissingGroupMembershipNames(Set<String> missingGroupMembershipNames) 
	{
		for (Group__c groupMembership : groupMemberships) {
			//Check that we have all Group Memberships in org, create new Group__c as necessary
			missingGroupMembershipNames.remove(groupMembership.Name);
		}
		return missingGroupMembershipNames;
	}
	
	void makeNewGroupMemberships(Set<String> newGroupMembershipNames) 
    {
		List<Group__c> groupMembershipsToInsert = new List<Group__c>();
		//any Group names left in this set need to be created
		for (String grpName : newGroupMembershipNames) {
			SyncDefinition def = syncDefMap.get(grpName);
			groupMembershipsToInsert.add(new Group__c(
                Name = grpName,
                Active__c = true,
                Attendance_Tracking__c = 'Do not Track Attendance',
                Closed_Membership__c = false,
                Description__c = 'Automatically maintained Group Membership',
                Duration__c = 'Standing',
                Planned_End_Date__c = null,
                Primary_Function__c = def.memberType,
                Type__c = 'Center-wide'));
		}
		insert groupMembershipsToInsert;
		groupMemberships.addAll(groupMembershipsToInsert);
	}
	
	void compareGroupMembersToQueriedObjects() 
    {
		//for each autoGroup
		for (Group__c groupMembership : groupMemberships) 
        {
			SyncDefinition def = syncDefMap.get(groupMembership.Name);
			
			List<String> sObjDetails = memberType2SobjectField.get(def.memberType).split('\\.');
			String memberObjectName = sObjDetails[0];
			String memberObjectField = sObjDetails[1];
			
			List<sObject> objsToUpsert = new List<sObject>();
			
			//Collect queried Sobjects to sync to members
			Set<Id> queriedIds = collectQueriedIds(def);
			
			//Collect existing relevant group members, Map of userId or contactId to Group_Member__c record
			Map<Id, sObject> personId2ExistingMemberMap = collectExistingMembers( def, groupMembership );
			Set<Id> existingMemberIds = new Set<Id>(personId2ExistingMemberMap.keySet());
			
			//eliminate everybody that is in both groups
			Set<Id> allQueriedIds = new Set<Id>(queriedIds);
			
			queriedIds.removeAll(existingMemberIds);
			existingMemberIds.removeAll(allQueriedIds);
			
			//Check for Members to remove (add End Date)
			for (Id personIdToEnd : existingMemberIds) 
            {
				sObject existingMemberRecord = personId2ExistingMemberMap.get(personIdToEnd);
				existingMemberRecord.put('Planned_End_Date__c', System.today());
				
				objsToUpsert.add(existingMemberRecord);
			}
			
			//Check for Members to create (Start Date = today)
			for (Id memberIdToCreate : queriedIds) 
            {
				sObject newMember = Schema.getGlobalDescribe().get(memberObjectName).newSObject();
				newMember.put('Group_Name__c', groupMembership.Id);
				newMember.put('Role__c', 'Member');
				newMember.put(memberObjectField, memberIdToCreate);
				newMember.put('Start_Date__c', System.today());
				
				objsToUpsert.add(newMember);
			}
			
			if (def.memberType == 'Staff') {
				sgmsToUpsert.addAll(objsToUpsert);
			} else if (def.memberType == 'Patient') {
				pgmsToUpsert.addAll(objsToUpsert);
			}
		}
	}
	
	Set<Id> collectQueriedIds(SyncDefinition def) 
    {
		Set<Id> queriedIds = new Set<Id>();
		for (sObject obj : def.newMemberQueryResults) {
			queriedIds.add((Id) obj.get(def.idField));
		}
		return queriedIds;
	}
	Map<Id, sObject> collectExistingMembers(SyncDefinition def, Group__c groupMembership) 
	{
		// Set<Id> existingMemberIds = new Set<Id>();
		Map<Id, sObject> personId2ExistingMemberMap = new Map<Id, sObject>();
		if (def.memberType == 'Staff') {
			for (Staff_Group_Member__c gm : groupMembership.Staff_Group_Members__r) {
				// existingMemberIds.add(gm.Staff_Member__c);
				personId2ExistingMemberMap.put(gm.Staff_Member__c, gm);
			}
		} else if (def.memberType == 'Patient') {
			// System.assert(false, 'patient ' + groupMembership.Patient_Group_Members__r.size());
			for (Patient_Group_Member__c gm : groupMembership.Patient_Group_Members__r) 
            {
				// existingMemberIds.add(gm.Patient__c);
				personId2ExistingMemberMap.put(gm.Patient__c, gm);
			}
		}
		return personId2ExistingMemberMap;
	}
	
	public void upsertUpdatedMembers() 
    {
		upsert sgmsToUpsert;
		upsert pgmsToUpsert;
	}
	
	//called from SystemSchedulingBatch or schedulable execute()
	public static void syncToGroupMemberships() 
    {
		AutoGroupMemberships agm = new AutoGroupMemberships();
		agm.upsertUpdatedMembers();
	}
	
	public static Map<String, SyncDefinition> syncDefMap = new Map<String, SyncDefinition>
    {
		'All Admitted Patients' => new SyncDefinition(
            'All Admitted Patients',
            'Patient',
            'SELECT Id, Distinguished_Name__c, AccountId, Account.Current_Admission__r.Service_Type__c' +
                ' FROM Contact' +
                ' WHERE Recordtype.Name = \'Patient\'' +
                    ' AND Account.Current_Admission_Stage__c = \'Admitted\'' +
                    ' AND Account.Current_Admission__r.Service_Type__c = \'Residential\'',
            'Id'
            ),
		'Current Active Staff' => new SyncDefinition(
            'Current Active Staff',
            'Staff',
            'SELECT Id, Professional_Name__c, Staff_User__c' +
                ' FROM Contact' +
                ' WHERE Recordtype.Name = \'ARC Staff\'' +
                    ' AND Active_Employee__c = true' +
                    ' AND Staff_User__r.IsActive = true',
            'Staff_User__c'
            ),
		'Current Clinical Staff' => new SyncDefinition(
            'Current Clinical Staff',
            'Staff',
            'SELECT Id, Professional_Name__c, Staff_User__c' +
                ' FROM Contact' +
                ' WHERE Recordtype.Name = \'ARC Staff\'' +
                    ' AND Active_Employee__c = true' +
                    ' AND Staff_User__r.IsActive = true' +
                    ' AND Staff_User__c IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = \'Clinical\')',
            'Staff_User__c'
            ),
		'Nursing' => new SyncDefinition(
            'Nursing',
            'Staff',
            'SELECT Id, Professional_Name__c, Staff_User__c' +
                ' FROM Contact' +
                ' WHERE Recordtype.Name = \'ARC Staff\'' +
                    ' AND Active_Employee__c = true' +
                    ' AND Staff_User__r.IsActive = true' +
                    ' AND Staff_User__c IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = \'Nursing\')',
            'Staff_User__c'
            ),
		'Social Work' => new SyncDefinition(
            'Social Work',
            'Staff',
            'SELECT Id, Professional_Name__c, Staff_User__c' +
                ' FROM Contact' +
                ' WHERE Recordtype.Name = \'ARC Staff\'' +
                    ' AND Active_Employee__c = true' +
                    ' AND Staff_User__r.IsActive = true' +
                    ' AND Staff_User__c IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = \'SocialWorker\')',
            'Staff_User__c'
            )

	};
	
	public class SyncDefinition 
    {
		public String groupMembershipName;
		public String memberType; //Staff or Patient
		public String newMemberQueryString;
		public String idField;
		
		public List<sObject> newMemberQueryResults 
        {
			get {
				if (newMemberQueryResults == null) {
					runNewMemberQuery();
				}
				return newMemberQueryResults;
			}
			set;
		}
		
		public SyncDefinition( String groupMembershipName, String memberType, String newMemberQueryString, String idField ) 
        {
			this.groupMembershipName = groupMembershipName;
			this.memberType = memberType;
			this.newMemberQueryString = newMemberQueryString;
			this.idField = idField;
		}
		
		void runNewMemberQuery() {
			newMemberQueryResults = Database.query(newMemberQueryString);
		}
	}
}