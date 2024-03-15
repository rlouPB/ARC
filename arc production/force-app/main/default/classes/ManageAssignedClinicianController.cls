public class ManageAssignedClinicianController {
	@AuraEnabled
	public static List<CaseTeamMember> getCaseTeamMember(String accId) {
		Account objAccount = [SELECT Id, Current_Case__c FROM Account WHERE id = :accId];
		List<CaseTeamMember> lstCaseMember = new List<CaseTeamMember>();
		CaseTeamMember ctm = new CaseTeamMember();
		if (String.isNotBlank(objAccount.Current_Case__c)) {
			lstCaseMember = [
				SELECT
					Id,
					TeamRole.Name,
					MemberId,
					TYPEOF Member
						WHEN User THEN Name, Professional_Name__c, IsActive
					END
				FROM CaseTeamMember
				WHERE parentId = :objAccount.Current_Case__c
			];
			lstCaseMember.add(ctm);
		}
		return lstCaseMember;
	}

	@AuraEnabled
	public static List<CaseTeamRole> getCaseTeamMemberRole() {
		return [SELECT Id, Name FROM CaseTeamRole];
	}
	@AuraEnabled
	public static CaseTeamMember getCaseTeamMemberInstance() {
		CaseTeamMember ctm = new CaseTeamMember();
		return ctm;
	}
	@AuraEnabled
	public static void deleteCaseTeamMemberInstance(String ctmId) {
		try {
			CaseTeamMember ctm = new CaseTeamMember();
			ctm.id = ctmId;
			delete ctm;
		} catch (Exception e) {
			// "Convert" the exception into an AuraHandledException
			throw new AuraHandledException('Darn it! Something went wrong: ' + e.getMessage());
		}
	}
	@AuraEnabled
	public static String saveCaseTeamMember(String lstCTM, String parentId) {
		try {
			JSONCTMParser objParser = new JSONCTMParser();
			List<JSONCTMParser> listMeta = objParser.Parse(lstCTM);
			List<CaseTeamMember> lstCtmNew = new List<CaseTeamMember>();
			List<CaseTeamMember> lstCtmtoDelete = new List<CaseTeamMember>();
			for (JSONCTMParser obj : listMeta) {
				CaseTeamMember ctm = new CaseTeamMember();
				if (String.isNotBlank(obj.Id)) {
					ctm.Id = obj.Id;
				} else {
					ctm.MemberId = (Id) obj.MemberId;
					ctm.ParentId = parentId;
				}

				ctm.TeamRoleId = (Id) obj.TeamRoleId;

				if ((String.isNotBlank(ctm.MemberId) || String.isNotBlank(ctm.Id)) && (obj.isDeleted == null || obj.isDeleted == 'false')) {
					lstCtmNew.add(ctm);
				}

				if (obj.isDeleted == 'true' && String.isNotBlank(ctm.Id)) {
					lstCtmtoDelete.add(ctm);
				}
			}

			delete lstCtmtoDelete;
			upsert lstCtmNew;
			return null;
		} catch (Exception e) {
			// "Convert" the exception into an AuraHandledException
			throw new AuraHandledException('Darn it! Something went wrong: ' + e.getMessage());
		}
	}

	public class JSONCTMParser {
		public String Id;
		public String MemberId;
		public String TeamRoleId;
		public String isDeleted;

		public List<JSONCTMParser> parse(String json) {
			return (List<JSONCTMParser>) System.JSON.deserialize(json, List<JSONCTMParser>.class);
		}
	}
}