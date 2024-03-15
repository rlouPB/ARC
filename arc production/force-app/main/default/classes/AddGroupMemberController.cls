public class AddGroupMemberController {
	// @AuraEnabled
	// public static List<String> getStaffRoles()
	// {
	//   List<String> options = new List<String>();

	//    Schema.DescribeFieldResult fieldResult = Staff_Group_Member__c.Role__c.getDescribe();
	//    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	//    options.add('--None--');
	//    for( Schema.PicklistEntry f : ple)
	//    {
	//       options.add(f.getValue());
	//    }
	//    return options;
	// }
	// @AuraEnabled
	// public static List<String> getPatientRoles()
	// {
	//   List<String> options = new List<String>();

	//    Schema.DescribeFieldResult fieldResult = Patient_Group_Member__c.Role__c.getDescribe();
	//    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	//    options.add('--None--');
	//    for( Schema.PicklistEntry f : ple)
	//    {
	//       options.add(f.getValue());
	//    }
	//    return options;
	// }

	@AuraEnabled
	public static List<String> getRoles(String roleType, String groupID) {
		List<String> options = new List<String>();
		options.add('--None--');

		Schema.DescribeFieldResult fieldResult;

		switch on roleType {
			when 'Staff' {
				fieldResult = Staff_Group_Member__c.Role__c.getDescribe();
			}
			when 'Patient' {
				Group__c currentGroup = [SELECT Type__c FROM Group__c WHERE ID = :groupID LIMIT 1];
				if (currentGroup.Type__c == 'Patient_Government') {
					fieldResult = Patient_Group_Member__c.Patient_Government_Role__c.getDescribe();
				} else {
					fieldResult = Patient_Group_Member__c.Role__c.getDescribe();
				}
			}
			when else {
				return options;
			}
		}

		List<Schema.PicklistEntry> picklistOptions = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry currentOption : picklistOptions) {
			options.add(currentOption.getValue());
		}

		return options;
	}

	@AuraEnabled
	public static Staff_Group_Member__c saveStaffGroupMember(Staff_Group_Member__c sgm, String EditType, Staff_Group_Member__c Oldsgm) {
		Staff_Group_Member__c sg = new Staff_Group_Member__c();
		Staff_Group_Member__c sgOld = new Staff_Group_Member__c();

		if (String.isNotBlank(sgm.Staff_Member__c)) {
			List<User> u = [SELECT Name FROM user WHERE Id = :sgm.Staff_Member__c];
			if (u.size() > 0) {
				sgm.Name = u[0].Name;
			}
		}
		if (EditType == 'Role') {
			sgm.Staff_Member__c = Oldsgm.Staff_Member__c;
			sgm.Name = Oldsgm.Name;
			sgm.Group_Name__c = Oldsgm.Group_Name__c;
			sgm.Previous_Group_Member__c = Oldsgm.Id;
		}

		upsert sgm;
		/*if(String.isBlank(sgm.Previous_Group_Member__c) ){
             sgm.Previous_Group_Member__c = sgm.Id;
             upsert sgm;
         }*/
		if (EditType == 'Role') {
			update Oldsgm;
		}

		return sgm;
	}

	@AuraEnabled
	public static Patient_Group_Member__c saveGroupMember(Patient_Group_Member__c pgm, String EditType, Patient_Group_Member__c Oldpgm) {
		Patient_Group_Member__c pm = new Patient_Group_Member__c();
		Patient_Group_Member__c pmOld = new Patient_Group_Member__c();

		if (String.isNotBlank(pgm.Patient__c)) {
			List<Contact> c = [SELECT Name FROM Contact WHERE Id = :pgm.Patient__c];
			if (c.size() > 0) {
				pgm.Name = c[0].Name;
			}
		}
		if (EditType == 'Role') {
			pgm.Patient__c = Oldpgm.Patient__c;
			pgm.Name = Oldpgm.Name;
			pgm.Group_Name__c = oldpgm.Group_Name__c;
			pgm.Previous_Group_Member__c = oldpgm.Id;
		}

		upsert pgm;
		//if(String.isBlank(pgm.Previous_Group_Member__c) ){
		//   pgm.Previous_Group_Member__c = pgm.Id;
		//   upsert pgm;
		//}

		if (EditType == 'Role') {
			update Oldpgm;
		}
		return pgm;
	}

	@AuraEnabled
	public static Patient_Group_Member__c getPatientGroupMember(String patientId) {
		Patient_Group_Member__c pg = [SELECT Id, Name, Previous_Group_Member__c, Joined_Date__c, Start_Date__c, Group_Name__c, Role__c, Planned_End_Date__c, Patient__c, Patient__r.Name FROM Patient_Group_Member__c WHERE id = :patientId];
		return pg;
	}
	@AuraEnabled
	public static Staff_Group_Member__c getStaffGroupMember(String staffId) {
		Staff_Group_Member__c sg = [SELECT Id, Name, Start_Date__c, Previous_Group_Member__c, Joined_Date__c, Group_Name__c, Role__c, Planned_End_Date__c, Staff_Member__c, Staff_Member__r.Name, Authorized_Signer__c FROM Staff_Group_Member__c WHERE id = :staffId];
		return sg;
	}
}