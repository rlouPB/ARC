/**
 * Controller class for Discharge Disposition component.
 */
public without sharing class DischargeDispositionCtl {
	public static Map<String, Integer> sectionRowIndexMap = new Map<String, Integer>{ 'Psychotherapy' => 0, 'Psychopharmacology' => 1, 'Medical Care Instructions' => 2, 'Nursing' => 3, 'Substance Use Services' => 4, 'Social Work' => 5, 'Team Leader' => 6 };

	@AuraEnabled
	public static String getReferralPhone(String mode, String referralId) {
		String retval = null;
		if (String.isNotBlank(mode)) {
			if (mode.equalsIgnoreCase('individual')) {
				Contact referral = [SELECT Id, npe01__PreferredPhone__c, Phone, MobilePhone, npe01__WorkPhone__c FROM Contact WHERE Id = :referralId];
				if (String.isNotBlank(referral.npe01__PreferredPhone__c)) {
					if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('home')) {
						retval = referral.phone;
					} else if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('mobile')) {
						retval = referral.MobilePhone;
					} else if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('work')) {
						retval = referral.npe01__WorkPhone__c;
					}
				}
			} else {
				Account referral = [SELECT Id, Phone FROM Account WHERE Id = :referralId];
				retval = referral.Phone;
			}
		}
		return retval;
	}
	@AuraEnabled
	public static Map<String, String> getReferralPhonesMap(String mode, List<String> referralIdList) {
		String retval = null;
		Map<String, String> referralIdPhoneMap = new Map<String, String>();
		if (String.isNotBlank(mode)) {
			if (mode.equalsIgnoreCase('individual')) {
				List<Contact> referralList = [SELECT Id, npe01__PreferredPhone__c, Phone, MobilePhone, npe01__WorkPhone__c FROM Contact WHERE Id = :referralIdList];
				for (Contact referral : referralList) {
					retval = null;
					if (String.isNotBlank(referral.npe01__PreferredPhone__c)) {
						if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('home')) {
							retval = referral.phone;
						} else if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('mobile')) {
							retval = referral.MobilePhone;
						} else if (referral.npe01__PreferredPhone__c.equalsIgnoreCase('work')) {
							retval = referral.npe01__WorkPhone__c;
						}
					}
					referralIdPhoneMap.put(referral.Id, retval);
				}
			} else {
				List<Account> referralList = [SELECT Id, Phone FROM Account WHERE Id = :referralIdList];
				for (Account referral : referralList) {
					referralIdPhoneMap.put(referral.Id, referral.Phone);
				}
			}
		}
		return referralIdPhoneMap;
	}

	@AuraEnabled
	public static DischargeDisposition createDischargeDisposition(String patientId, Boolean isEmergencyTransfer) {
		Account patient = [SELECT Id, Name, Current_Admission__c, Current_Admission__r.Discharge_Date__c, Current_Admission__r.Team__c, Photo__c, (SELECT Id, Admission__c, End_Date__c, Start_Date__c, Role__c, Professional_Name__c, User__c FROM Assigned_Clinicians__r WHERE Start_Date__c <= TODAY AND (End_Date__c = NULL OR END_DATE__C >= TODAY)) FROM Account WHERE Id = :patientId];
		MAP<String, String> roleMap = new Map<String, String>();
		for (Assigned_Clinician__c ac : patient.Assigned_Clinicians__r) {
			if (patient.Current_Admission__c == ac.Admission__c) {
				roleMap.put(ac.Role__c, ac.User__c);
			}
		}
		Discharge_Disposition__c dischargeDispositionObj = new Discharge_Disposition__c(Patient_Account__c = patientId, Admission__c = patient.Current_Admission__c, Responsible_Social_Worker__c = roleMap.get('Clinical Social Worker'), Emergency_Transfer__c = isEmergencyTransfer, Status__c = 'Draft');
		if (isEmergencyTransfer) {
			dischargeDispositionObj.Anticipated_Discharge_Date__c = patient.Current_Admission__r.Discharge_Date__c;
		}

		insert dischargeDispositionObj;

		DischargeDisposition dischargeDisposition = new DischargeDisposition();
		dischargeDisposition.dischargeSectionList = new List<DischargeSection>();
		dischargeDisposition.patient = patient;
		dischargeDisposition.dischargeDispositionObj = dischargeDispositionObj;
		String socialWorkerId = dischargeDispositionObj.Responsible_Social_Worker__c;
		if (socialWorkerId == null) {
			socialWorkerId = UserInfo.getUserId();
		}
		dischargeDisposition.currentUser = [SELECT Id, Name, Profile.Name, UserRole.Name, Professional_Name__c FROM User WHERE Id = :UserInfo.getUserId()];
		dischargeDisposition.responsibleSocialWorker = [SELECT Id, Name, Profile.Name, UserRole.Name, Professional_Name__c FROM User WHERE Id = :socialWorkerId];
		if (!isEmergencyTransfer) {
			Map<String, String> roleSectionNameMap = new Map<String, String>{ 'Psychotherapist' => 'Psychotherapy', 'Psychiatrist' => 'Psychopharmacology', 'Clinical Social Worker' => 'Social Work', 'Senior Nurse' => 'Nursing', 'Substance Use Counselor' => 'Substance Use Services', 'Med Office' => 'Medical Care Instructions', 'Team Leader' => 'Team Leader' };
			// List<CaseTeamMember> caseTeamMemberList=[SELECT Id,MemberId,Member.Name,Member.ProfileId,Member.Profile.Name,TeamRole.Name FROM CaseTeamMember WHERE ParentId=:patient.Current_Case__c];
			List<Assigned_Clinician__c> assignedClinicianList = [SELECT Id, User__c, User__r.Name, User__r.ProfileID, User__r.Profile.Name, Role__c FROM Assigned_Clinician__c WHERE Admission__c = :patient.Current_Admission__c AND Start_Date__c <= TODAY AND (End_Date__c = NULL OR End_Date__c >= TODAY)];

			// Assuming same role does not repeat for the team.
			Map<String, Integer> caseTeamRoleIndexMap = new Map<String, Integer>();
			Integer caseTeamRoleIndex = 0;
			Assigned_Clinician__c tempAssignedClinician;
			for (Assigned_Clinician__c assignedClinicianObj : assignedClinicianList) {
				caseTeamRoleIndexMap.put(assignedClinicianObj.Role__c, caseTeamRoleIndex);
				caseTeamRoleIndex++;
			}

			List<Discharge_Section__c> insertDischargeSectionList = new List<Discharge_Section__c>();
			for (String roleName : roleSectionNameMap.keySet()) {
				// ARC-765 - Use Assigned Clinician instead if(!roleName.equalsIgnoreCase('team leader') && !roleName.equalsIgnoreCase('senior nurse')){
				if (!roleName.equalsIgnoreCase('senior nurse')) {
					Discharge_Section__c dischargeSectionObj = new Discharge_Section__c(Discharge_Disposition__c = dischargeDispositionObj.Id, Role__c = roleSectionNameMap.get(roleName), Status__c = 'Draft');
					dischargeSectionObj.OwnerId = dischargeDisposition.currentUser.Id;
					DischargeSection dischargeSection = new DischargeSection();
					dischargeSection.responsiblePerson = dischargeDisposition.currentUser.Name;
					if (roleName.equalsIgnoreCase('med office')) {
						try {
							Group medOfficeQueue = [SELECT Id, Name FROM GROUP WHERE type = 'Queue' AND developername = 'Med_Office' LIMIT 1];
							dischargeSectionObj.OwnerId = medOfficeQueue.Id;
							dischargeSection.responsiblePerson = medOfficeQueue.Name;
						} catch (Exception e) {
							// No med office queue found, assign to current user
							// dischargeSectionObj.OwnerId =dischargeDisposition.currentUser.Id;
							// dischargeSection.responsiblePerson =dischargeDisposition.currentUser.Name;
						}
					} else {
						// If the map does not contain the role, it could be assumed that no proper clinician assigned.
						caseTeamRoleIndex = caseTeamRoleIndexMap.get(roleName);
						if (caseTeamRoleIndex != null) {
							tempAssignedClinician = assignedClinicianList.get(caseTeamRoleIndex);
							dischargeSectionObj.OwnerId = tempAssignedClinician.User__c;
							dischargeSection.responsiblePerson = tempAssignedClinician.User__r.Name;
						}
					}
					dischargeSection.dischargeSectionObj = dischargeSectionObj;
					dischargeDisposition.dischargeSectionList.add(dischargeSection);
				}
			}

			// Generate Senior Nurse
			Discharge_Section__c nurseSectionObj = new Discharge_Section__c(Discharge_Disposition__c = dischargeDispositionObj.Id, Role__c = 'Nursing', Status__c = 'Draft');
			nurseSectionObj.OwnerId = dischargeDisposition.currentUser.Id;
			DischargeSection nursingSection = new DischargeSection();
			nursingSection.responsiblePerson = dischargeDisposition.currentUser.Name;
			try {
				String teamName = 'Team ' + patient.Current_Admission__r.Team__c;
				Staff_Group_Member__c seniorNurse = [SELECT Staff_Member__c, Staff_Member__r.Name FROM Staff_Group_Member__c WHERE Group_Name__r.Name = :teamName AND Role__c = 'Senior Nurse' AND (Planned_End_Date__c = NULL OR Planned_End_Date__c > TODAY) ORDER BY Start_Date__c ASC LIMIT 1];
				nurseSectionObj.OwnerId = seniorNurse.Staff_Member__c;
				nursingSection.responsiblePerson = seniorNurse.Staff_Member__r.Name;
			} catch (Exception e) {
				// No team leader found, assign to current user
				// nurseSectionObj.OwnerId=dischargeDisposition.currentUser.Id;
				// nursingSection.responsiblePerson=dischargeDisposition.currentUser.Name;
			}
			// finally
			// {
			nursingSection.dischargeSectionObj = nurseSectionObj;
			dischargeDisposition.dischargeSectionList.add(nursingSection);
			// }

			// Rearrange according to wireframe
			dischargeDisposition.dischargeSectionList.sort();
			for (DischargeSection dischargeSectionObj : dischargeDisposition.dischargeSectionList) {
				insertDischargeSectionList.add(dischargeSectionObj.dischargeSectionObj);
			}

			insert insertDischargeSectionList;
		}
		return dischargeDisposition;
	}

	@AuraEnabled
	public static DischargeDisposition getDischargeDisposition(String dischargeDispositionId) {
		Discharge_Disposition__c dischargeDispositionObj = [
			SELECT Id, Name, DDR_Type__c, Patient_Account__c, Responsible_Social_Worker__c, Responsible_Social_Worker__r.Professional_Name__c, Emergency_Transfer__c, Snapshot__c, Snapshot__r.Name, Snapshot__r.Html__c, Print_Link__c, Post_Discharge_Address_Summary__c, Anticipated_Discharge_Date__c, Transfer_Details__c, Finalized_By__r.Name, Finalized_Date_Time__c, Finalized_By_Professional_Name__c, Status__c, Date_Delivered_to_Patient__c, Method__c, Post_Discharge_Address__c, Post_Discharge_Address__r.Summary__c
			FROM Discharge_Disposition__c
			WHERE Id = :dischargeDispositionId
		];

		Account patient = [SELECT Id, Name, Current_Case__c, Photo__c, Patient_Contact__c, Current_Admission__c, Phone FROM Account WHERE Id = :dischargeDispositionObj.Patient_Account__c];

		DischargeDisposition dischargeDisposition = new DischargeDisposition();
		dischargeDisposition.patient = patient;
		dischargeDisposition.dischargeDispositionObj = dischargeDispositionObj;
		dischargeDisposition.currentUser = [SELECT Id, Name, Profile.Name, UserRole.Name, Professional_Name__c FROM User WHERE Id = :UserInfo.getUserId()];
		User responsibleSocialWorker = dischargeDisposition.currentUser;
		try {
			responsibleSocialWorker = [SELECT Id, Name, Profile.Name, UserRole.Name, Professional_Name__c FROM User WHERE Id = :dischargeDispositionObj.Responsible_Social_Worker__c];
		} catch (Exception e) {
			system.debug('There is no assigned Social Worker, set it to current user');
		}
		dischargeDisposition.responsibleSocialWorker = responsibleSocialWorker;
		// try
		// {
		// 	dischargeDisposition.assignedClinician = [SELECT Id, User__c, User__r.Name, User__r.ProfileID,
		// 																User__r.Profile.Name, Role__c
		//                                             FROM Assigned_Clinician__c
		//                                             WHERE Admission__c = :patient.Current_Admission__c
		//                                                 AND Start_Date__c <= TODAY
		//                                                 AND (End_Date__c = NULL OR End_Date__c >= TODAY)];
		// } catch(Exception e) {
		//     // Nothing to handle
		// }
		dischargeDisposition.isMedOfficeUser = false;
		try {
			GroupMember medOfficeQueue = [SELECT Id FROM GROUPMEMBER WHERE Group.type = 'Queue' AND Group.developername = 'Med_Office' AND UserOrGroupId = :UserInfo.getUserId() LIMIT 1];
			dischargeDisposition.isMedOfficeUser = true;
		} catch (Exception e) {
			system.debug('Not med office queue member:' + e.getMessage());
		}
		dischargeDisposition.dischargeSectionList = new List<DischargeSection>();
		if (dischargeDispositionObj.Emergency_Transfer__c == false) {
			dischargeDisposition.dischargeSectionList = getDischargeSectionWrappers(dischargeDisposition.dischargeDispositionObj.Id, null);
			// List<Discharge_Section__c> dischargeSectionList = getDischargeSections(dischargeDisposition.dischargeDispositionObj.Id, null);
			// List<Discharge_Referral__c> dischargeReferralList = getDischargeReferrals(dischargeDisposition.dischargeDispositionObj.Id, new Map<Id, Discharge_Section__c>(dischargeSectionList).keySet());

			// String dischargeSectionQuery='SELECT ';
			// Set<String> dischargeSectionFieldNameSet = new Set<String>(Discharge_Section__c.getSobjectType().getDescribe().fields.getMap().keySet());
			// Set<String> removeFields = new Set<String>{
			//     'LastModifiedDate', 'LastModifiedById', 'CreatedDate', 'CreatedById', 'IsDeleted', 'SysModStamp', 'LastViewedDate', 'LastViewedById'
			// };
			// dischargeSectionFieldNameSet.removeAll(removeFields);
			// dischargeSectionFieldNameSet.add('Completed_By__r.Name');
			// dischargeSectionFieldNameSet.add('Completed_By__r.Professional_Name__c');
			// dischargeSectionFieldNameSet.add('Owner.Name');
			// List<String> dischargeSectionFieldNameList=new List<String>(dischargeSectionFieldNameSet);
			// dischargeSectionQuery+=String.join(dischargeSectionFieldNameList,',')+' FROM Discharge_Section__c WHERE Discharge_Disposition__c = :dischargeDispositionId';
			// List<Discharge_Section__c> dischargeSectionList=(List<Discharge_Section__c>)Database.query(dischargeSectionQuery);

			// List<Discharge_Referral__c> dischargeReferralList=[SELECT Id, Clinician__c, Clinician__r.Name, Discharge_Disposition__c, Name, Institution__c, Institution__r.Name,
			//                                                         Is_Primary__c, Referral_Notes__c, Referred_By__c, Role__c, Section__c, Grouping__c
			//                                                    FROM Discharge_Referral__c
			//                                                    WHERE Discharge_Disposition__c = :dischargeDispositionId
			//                                                         AND Section__c = :dischargeSectionList];

			// Map<Id,List<Integer>> sectionIdReferralIndexMap=new Map<Id,List<Integer>>();
			// Integer index=0;

			// // Setup Referral Phone number
			// List<String> individualReferralIdList=new List<String>();
			// List<String> institutionReferralIdList=new List<String>();
			// for(Discharge_Referral__c dischargeReferralObj:dischargeReferralList)
			// {
			//     if(dischargeReferralObj.Clinician__c!=null)
			//     {
			//         individualReferralIdList.add(dischargeReferralObj.Clinician__c);
			//     }
			//     if(dischargeReferralObj.Institution__c!=null)
			//     {
			//         institutionReferralIdList.add(dischargeReferralObj.Institution__c);
			//     }
			//     List<Integer> referralIndexList = sectionIdReferralIndexMap.get(dischargeReferralObj.Section__c);
			//     if(referralIndexList==null)
			//     {
			//         referralIndexList=new List<Integer>();
			//     }
			//     referralIndexList.add(index);
			//     sectionIdReferralIndexMap.put(dischargeReferralObj.Section__c,referralIndexList);
			//     index++;
			// }
			// Map<String,String> individualReferralPhoneMap = getReferralPhonesMap('individual',individualReferralIdList);
			// Map<String,String> institutionReferralPhoneMap = getReferralPhonesMap('institution',institutionReferralIdList);

			// Group medOfficeQueue=[SELECT Id,Name FROM GROUP WHERE type='Queue' AND developername='Med_Office' limit 1];
			// // Id medOfficeQueueId;
			// Set<Id> responsibleOwnerIdSet=new Set<Id>();
			// for(Discharge_Section__c dischargeSectionObj:dischargeSectionList)
			// {
			//     // if('medical care instructions'.equalsIgnoreCase(dischargeSectionObj.Role__c))
			//     // {
			//     //     medOfficeQueueId=dischargeSectionObj.OwnerId;
			//     // }
			//     // else
			//     // {
			//     responsibleOwnerIdSet.add(dischargeSectionObj.OwnerId);
			//     // }
			// }

			// Map<Id,User> responsibleOwnerMap=new Map<Id,User>([SELECT Id,Name,Contact_Professional_Name__c FROM User WHERE Id=:responsibleOwnerIdSet]);
			// for(Discharge_Section__c dischargeSectionObj:dischargeSectionList)
			// {
			//     DischargeSection dischargeSection=new DischargeSection();
			//     if('medical care instructions'.equalsIgnoreCase(dischargeSectionObj.Role__c))
			//     {
			//         dischargeSection.responsiblePerson=medOfficeQueue.Name;
			//     }
			//     else
			//     {
			//         User responsibleUser = responsibleOwnerMap.get(dischargeSectionObj.OwnerId);
			//         String responsibleUserName = responsibleUser.Name;
			//         if(String.isNotBlank(responsibleUser.Contact_Professional_Name__c)) {
			//             responsibleUserName = responsibleUser.Contact_Professional_Name__c;
			//         }
			//         dischargeSection.responsiblePerson=responsibleUserName;
			//     }
			//     dischargeSection.dischargeSectionObj=dischargeSectionObj;
			//     dischargeSection.completedByName=dischargeSectionObj.Completed_By__r.Professional_Name__c;
			//     dischargeSection.completedDateTime=dischargeSectionObj.Completed_Date_Time__c;
			//     dischargeSection.sectionDisplayIndex=sectionRowIndexMap.get(dischargeSectionObj.role__c);
			//     List<Integer> referralIndexList=sectionIdReferralIndexMap.get(dischargeSectionObj.Id);
			//     if(referralIndexList!=null)
			//     {
			//         List<DischargeReferral> sectionReferralList=new List<DischargeReferral>();
			//         for(Integer referralIndex:referralIndexList)
			//         {
			//             Discharge_Referral__c dischargeReferral=dischargeReferralList.get(referralIndex);
			//             DischargeReferral dischargeReferralObj=new DischargeReferral();
			//             dischargeReferralObj.dischargeReferralObj=dischargeReferral;
			//             if(String.isNotBlank(dischargeReferral.Clinician__c))
			//             {
			//                 dischargeReferralObj.referralPhone=individualReferralPhoneMap.get(dischargeReferral.Clinician__c);
			//                 dischargeReferralObj.referralName=dischargeReferral.Clinician__r.Name;
			//             }
			//             else if (String.isNotBlank(dischargeReferral.Institution__c))
			//             {
			//                 dischargeReferralObj.referralPhone=institutionReferralPhoneMap.get(dischargeReferral.Institution__c);
			//                 dischargeReferralObj.referralName=dischargeReferral.Institution__r.Name;
			//             }
			//             sectionReferralList.add(dischargeReferralObj);
			//         }
			//         dischargeSection.referralList=sectionReferralList;
			//     }
			//     dischargeDisposition.dischargeSectionList.add(dischargeSection);
			// }
			// dischargeDisposition.dischargeSectionList.sort();
		}

		return dischargeDisposition;
	}

	public static List<DischargeSection> getDischargeSectionWrappers(Id dischargeDispositionId, String specifiedSectionRole) {
		List<DischargeSection> sectionWrapperList = new List<DischargeSection>();

		List<Discharge_Section__c> dischargeSectionList = queryDischargeSections(dischargeDispositionId, specifiedSectionRole);
		List<Discharge_Referral__c> dischargeReferralList = queryDischargeReferrals(dischargeDispositionId, new Map<Id, Discharge_Section__c>(dischargeSectionList).keySet());

		Map<Id, List<Integer>> sectionIdReferralIndexMap = new Map<Id, List<Integer>>();
		Integer index = 0;

		// Setup Referral Phone number
		List<String> individualReferralIdList = new List<String>();
		List<String> institutionReferralIdList = new List<String>();
		for (Discharge_Referral__c dischargeReferralObj : dischargeReferralList) {
			if (dischargeReferralObj.Clinician__c != null) {
				individualReferralIdList.add(dischargeReferralObj.Clinician__c);
			}
			if (dischargeReferralObj.Institution__c != null) {
				institutionReferralIdList.add(dischargeReferralObj.Institution__c);
			}
			List<Integer> referralIndexList = sectionIdReferralIndexMap.get(dischargeReferralObj.Section__c);
			if (referralIndexList == null) {
				referralIndexList = new List<Integer>();
			}
			referralIndexList.add(index);
			sectionIdReferralIndexMap.put(dischargeReferralObj.Section__c, referralIndexList);
			index++;
		}

		Map<String, String> individualReferralPhoneMap = getReferralPhonesMap('individual', individualReferralIdList);
		Map<String, String> institutionReferralPhoneMap = getReferralPhonesMap('institution', institutionReferralIdList);

		Group medOfficeQueue = [SELECT Id, Name FROM GROUP WHERE type = 'Queue' AND developername = 'Med_Office' LIMIT 1];

		Set<Id> responsibleOwnerIdSet = new Set<Id>();
		for (Discharge_Section__c dischargeSectionObj : dischargeSectionList) {
			responsibleOwnerIdSet.add(dischargeSectionObj.OwnerId);
		}

		Map<Id, User> responsibleOwnerMap = new Map<Id, User>([SELECT Id, Name, Professional_Name__c FROM User WHERE Id IN :responsibleOwnerIdSet]);
		for (Discharge_Section__c dischargeSectionObj : dischargeSectionList) {
			DischargeSection dischargeSection = new DischargeSection();
			if ('medical care instructions'.equalsIgnoreCase(dischargeSectionObj.Role__c)) {
				dischargeSection.responsiblePerson = medOfficeQueue.Name;
			} else {
				User responsibleUser = responsibleOwnerMap.get(dischargeSectionObj.OwnerId);
				String responsibleUserName = responsibleUser.Name;
				if (String.isNotBlank(responsibleUser.Professional_Name__c)) {
					responsibleUserName = responsibleUser.Professional_Name__c;
				}
				dischargeSection.responsiblePerson = responsibleUserName;
			}
			dischargeSection.dischargeSectionObj = dischargeSectionObj;
			// dischargeSection.completedByName = dischargeSectionObj.Completed_By__r?.Professional_Name__c;
			dischargeSection.completedByName = dischargeSectionObj.Completed_By_Professional_Name__c;

			dischargeSection.completedDateTime = dischargeSectionObj.Completed_Date_Time__c;
			dischargeSection.sectionDisplayIndex = sectionRowIndexMap.get(dischargeSectionObj.role__c);

			List<Integer> referralIndexList = sectionIdReferralIndexMap.get(dischargeSectionObj.Id);
			if (referralIndexList != null) {
				List<DischargeReferral> sectionReferralList = new List<DischargeReferral>();
				for (Integer referralIndex : referralIndexList) {
					Discharge_Referral__c dischargeReferral = dischargeReferralList.get(referralIndex);
					DischargeReferral dischargeReferralObj = new DischargeReferral();
					dischargeReferralObj.dischargeReferralObj = dischargeReferral;
					if (String.isNotBlank(dischargeReferral.Clinician__c)) {
						dischargeReferralObj.referralPhone = individualReferralPhoneMap.get(dischargeReferral.Clinician__c);
						dischargeReferralObj.referralName = dischargeReferral.Clinician__r.Name;
					} else if (String.isNotBlank(dischargeReferral.Institution__c)) {
						dischargeReferralObj.referralPhone = institutionReferralPhoneMap.get(dischargeReferral.Institution__c);
						dischargeReferralObj.referralName = dischargeReferral.Institution__r.Name;
					}
					sectionReferralList.add(dischargeReferralObj);
				}
				dischargeSection.referralList = sectionReferralList;
			}
			//dischargeDisposition.dischargeSectionList.add(dischargeSection);
			sectionWrapperList.add(dischargeSection);
		}
		sectionWrapperList.sort();
		return sectionWrapperList;
	}

	public static List<Discharge_Section__c> queryDischargeSections(Id dischargeDispositionId, String specifiedRole) {
		String dischargeSectionQuery = 'SELECT ';
		Set<String> dischargeSectionFieldNameSet = new Set<String>(Discharge_Section__c.getSobjectType().getDescribe().fields.getMap().keySet());
		Set<String> removeFields = new Set<String>{ 'LastModifiedDate', 'LastModifiedById', 'CreatedDate', 'CreatedById', 'IsDeleted', 'SysModStamp', 'LastViewedDate', 'LastViewedById' };
		dischargeSectionFieldNameSet.removeAll(removeFields);
		dischargeSectionFieldNameSet.add('Completed_By__r.Name');
		dischargeSectionFieldNameSet.add('Completed_By__r.Professional_Name__c');
		dischargeSectionFieldNameSet.add('Owner.Name');
		List<String> dischargeSectionFieldNameList = new List<String>(dischargeSectionFieldNameSet);
		dischargeSectionQuery += String.join(dischargeSectionFieldNameList, ',') + ' FROM Discharge_Section__c' + ' WHERE Discharge_Disposition__c = :dischargeDispositionId';
		if (specifiedRole != null) {
			dischargeSectionQuery += ' AND Role__c = :specifiedRole';
		}
		return (List<Discharge_Section__c>) Database.query(dischargeSectionQuery);
	}

	public static List<Discharge_Referral__c> queryDischargeReferrals(Id dischargeDispositionId, Set<Id> dischargeSectionIds) {
		String disRefQuery = 'SELECT Id, Clinician__c, Clinician__r.Name, Discharge_Disposition__c, Name, Institution__c, Institution__r.Name,' + ' Is_Primary__c, Referral_Notes__c, Referred_By__c, Role__c, Section__c, Grouping__c, Phone__c, Referral_To__c' + ' FROM Discharge_Referral__c' + ' WHERE Discharge_Disposition__c = :dischargeDispositionId' + ' AND Section__c IN :dischargeSectionIds';
		return (List<Discharge_Referral__c>) Database.query(disRefQuery);
	}

	@AuraEnabled
	public static Account getPatientById(String patientId) {
		Account patient = [SELECT Id, Name FROM Account WHERE Id = :patientId];
		return patient;
	}

	@AuraEnabled
	public static String cancelDischargeDisposition(String dischargeDispositionId) {
		String retval = 'SUCCESS';
		Savepoint sp = Database.setSavepoint();
		try {
			Discharge_Disposition__c dischargeDispositionObj = [SELECT Id, Status__c, (SELECT Id, Status__c FROM Discharge_Sections__r) FROM Discharge_Disposition__c WHERE Id = :dischargeDispositionId];

			dischargeDispositionObj.Status__c = 'Cancelled';
			for (Discharge_Section__c ds : dischargeDispositionObj.Discharge_Sections__r) {
				ds.Status__c = 'Cancelled';
			}
			update dischargeDispositionObj;
			update dischargeDispositionObj.Discharge_Sections__r;
		} catch (Exception e) {
			Database.rollback(sp);
			retval = 'ERROR: ' + e.getMessage();
		}

		return retval;
	}

	@AuraEnabled
	public static String saveDischargeDisposition(Discharge_Disposition__c dischargeDispositionObj) {
		String retval = 'ERROR saving Discharge Disposition';
		Savepoint sp = Database.setSavepoint();
		try {
			if (dischargeDispositionObj.Status__c.equalsIgnoreCase('finalized')) {
				Discharge_Disposition__c dd = [SELECT Id, Finalized_Date_Time__c FROM Discharge_Disposition__c WHERE Id = :dischargeDispositionObj.Id];
				if (dd.Finalized_Date_Time__c == null) {
					User currentUser = [SELECT Id, Requires_Co_Signature__c, Professional_Name__c FROM USER WHERE Id = :UserInfo.getUserId()];
					dischargeDispositionObj.Finalized_By__c = UserInfo.getUserId();
					dischargeDispositionObj.Finalized_Date_Time__c = System.now();
					dischargeDispositionObj.Finalized_By_Professional_Name__c = currentUser.Professional_Name__c;
				}
			}

			update dischargeDispositionObj;

			if (dischargeDispositionObj.Status__c.equalsIgnoreCase('finalized')) {
				new DischargeDispositionSnapshot(dischargeDispositionObj.Id).generateSnapshots();
			}
			retval = 'SUCCESS';
		} catch (Exception e) {
			Database.rollBack(sp);
			retval += ': ' + e.getMessage() + ' STACKTRACE: ' + e.getStackTraceString();
			system.debug('message:' + e.getmessage() + ', stack:' + e.getStackTraceString());
		}
		return retval;
	}

	@InvocableMethod(label='Create Discharge Disposition' description='Create Discharge Disposition')
	public static List<String> createDischargeDisposition(List<DischargeDispositionRequest> request) {
		//parse input parameters
		String patientId = request.get(0).patientId;
		Boolean isEmergencyTransfer = request.get(0).dischargeDispositionOption == 'Emergency Transfer' ? true : false;
		DischargeDisposition dd = DischargeDispositionCtl.createDischargeDisposition(patientId, isEmergencyTransfer);
		Discharge_Disposition__c ddObj = dd?.dischargeDispositionObj;
		return new List<String>{ ddObj.Id };
	}

	public class DischargeDispositionRequest {
		@InvocableVariable
		public String patientId;

		@InvocableVariable
		public String dischargeDispositionOption;
	}
}