public without sharing class ProgramGroupMemberships {
	public static Boolean hasSyncedGroups = false;
	static List<Patient_Group_Member__c> pgmsToUpsert = new List<Patient_Group_Member__c>();

	public static String syncAdmittedProgramsToGroup() {
		if (!hasSyncedGroups) {
			//make sure all Programs have Groups
			checkPrograms();

			//query for all Current Admitted Programs (~65)
			List<Admitted_Program__c> admPrograms = [SELECT Id, Admission__c, Admission__r.Patient_Account__c, Admission__r.Patient_Contact__c, Program__c, Top_Parent_Program_Id__c, Start_Date__c, End_Date__c FROM Admitted_Program__c WHERE Admission__r.Stage__c = 'Admitted' AND Program__c != NULL AND Top_Parent_Program_Id__c != NULL AND Start_Date__c <= TODAY AND (End_Date__c = NULL OR End_Date__c > TODAY)];

			//build Patient Group Members based on Current Admitted Programs
			Map<String, Admitted_Program__c> existingAdmProgMap = new Map<String, Admitted_Program__c>();
			Set<Id> programIds = new Set<Id>();
			for (Admitted_Program__c admProg : admPrograms) {
				//programIds.add(admProg.Program__c);
				programIds.add(admProg.Top_Parent_Program_Id__c);
				//Map using key of patientId-programId
				//existingAdmProgMap.put(getKey(admProg.Admission__r.Patient_Account__c, admProg.Program__c), admProg);
				existingAdmProgMap.put(getKey(admProg.Admission__r.Patient_Account__c, admProg.Top_Parent_Program_Id__c), admProg);
			}

			//query for all "Program" Group Memberships with active Patient Group Members (15 Group Memberships with total 65 PGMs)
			List<Group__c> programGroups = [SELECT Id, Program__c, (SELECT Id, Patient__r.AccountId FROM Patient_Group_Members__r WHERE Start_Date__c <= TODAY AND (Planned_End_Date__c = NULL OR Planned_End_Date__c > TODAY)) FROM Group__c WHERE Type__c = 'Program' AND Program__c IN :programIds]; //!= null

			Map<Id, Group__c> programIdToGroupMap = new Map<Id, Group__c>();
			//deactivate or create Patient Group Members so that Program matches Group Membership
			for (Group__c grp : programGroups) {
				programIdToGroupMap.put(grp.Program__c, grp);
				//loop on PGMs
				for (Patient_Group_Member__c pgm : grp.Patient_Group_Members__r) {
					//check map by patientId-programId
					Admitted_Program__c admProg = existingAdmProgMap.get(getKey(pgm.Patient__r.AccountId, grp.Program__c));
					if (admProg == null) {
						pgmsToUpsert.add(new Patient_Group_Member__c(Id = pgm.Id, Planned_End_Date__c = System.today()));
					} else {
						//remove from map so we don't create another pgm
						existingAdmProgMap.remove(getKey(pgm.Patient__r.AccountId, grp.Program__c));
					}
				}
			}

			//loop on remaining admProgs in map
			for (String key : existingAdmProgMap.keySet()) {
				Admitted_Program__c admProg = existingAdmProgMap.get(key);
				//Group__c thisGrp = programIdToGroupMap.get(admProg.Program__c);
				Group__c thisGrp = programIdToGroupMap.get(admProg.Top_Parent_Program_Id__c);

				if (admProg == null || thisGrp == null)
					continue;
				Patient_Group_Member__c newPgm = new Patient_Group_Member__c(Group_Name__c = thisGrp.Id, Patient__c = admProg.Admission__r.Patient_Contact__c, Start_Date__c = admProg.Start_Date__c, Joined_Date__c = admProg.Start_Date__c, Planned_End_Date__c = admProg.End_Date__c, Role__c = 'Member');
				pgmsToUpsert.add(newPgm);
			}

			commitMembers();
			// hasSyncedGroups = true;
		}
		return 'Successfully Synced Group Members';
	}

	public static void checkPrograms() {
		List<Program__c> progsWithGroups = [SELECT Id, Name, Short_Name__c, Product_Code__c, (SELECT Id, Name FROM Group_Memberships__r LIMIT 1) FROM Program__c WHERE Is_Parent_Program__c = TRUE];
		List<Group__c> parentGroupsToInsert = new List<Group__c>();

		for (Program__c p : progsWithGroups) {
			if (p.Group_Memberships__r.isEmpty()) {
				parentGroupsToInsert.add(new Group__c(Program__c = p.Id, Type__c = 'Program', Name = p.Short_Name__c, Description__c = 'Automatically Maintained Group Membership', Primary_Function__c = 'Patient', Duration__c = 'Standing', Closed_Membership__c = false, Attendance_Tracking__c = 'Track Attendance', Active__c = true));
			}
		}
		insert parentGroupsToInsert;
	}

	static void commitMembers() {
		upsert pgmsToUpsert;
	}

	static String getKey(String patientId, String programId) {
		return patientId.left(15) + '-' + programId.left(15);
	}
}