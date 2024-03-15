public class UserHomeApexController
{
	//Used for
	//	UserHome.cmp (Clinical User Home)
	//	ClinicalPatientFile.cmp (Clinical Patient File)

	public static Id specifiedUserId = Userinfo.getUserId();
	public static Id specifiedPatientId;
	public static Date todaysDate = Date.today();

	public static String openTagQueryString = 'SELECT Id, Target_Date__c, Overdue_Days__c'
													+ ' FROM Outstanding_Tag__c';
	// public static final String openTagWhereTargetDate = ' Target_Date__c != null';
	public static final String openTagWhereUserId = ' OwnerId = :specifiedUserId';
	public static final String openTagWherePatientId = ' Patient__c = :specifiedPatientId';

	public static final String ADMISSION_STAGE_DISCHARGED = 'Discharged';
	public static final String HEADER_SETTING_ADMITTED = 'Admitted';
	public static final String HEADER_SETTING_DISCHARGED = 'Discharged';
	public static final String HEADER_SETTING_DECEASED = 'Deceased';
	public static final String RESULT_CONFIG = 'config';
	public static final String RESULT_PROGRAM_STATUS = 'programStatus';
	public static final String RESULT_CURRENT_APP_NAME = 'CurrentAppName';
	public static final String RESULT_PERSONA_VIEW_CONFIG = 'ViewConfig';
	public static final String RESULT_HIDE_TABS ='HideTabs';
	public static final String RESULT_HIDE_COMPONENTS ='HideComponents';
	public static final String RESULT_SHOW_TABS ='ShowTabs';
	public static final String RESULT_SHOW_COMPONENTS ='ShowComponents';

	@AuraEnabled
	public static SummaryInfoWrapper getSummaryInfoByPatient(Id patientId)
	{
		System.debug('UserHomeApexController getSummaryInfoByPatient...');
		if (patientId == null) {
			return null;
		}

		specifiedPatientId = patientId;
		return getSummaryInfo();
	}

	/*******************************************************************************************************
    * @description Returns ClinicalFileHeader UI fields configurations and Admitted Statuses
    * @param patientId the SFDC Id of the patient
    * @return A map containing ClinicalFileHeader UI fields configuration and Admitted Statuses
    */
	@AuraEnabled
	public static Map<string,string> getPatientFileHeaderSetting(Id patientId)
	{
			System.debug('UserHomeApexController getPatientFileHeaderSetting...');
	Map<string,string> ret= new Map<string,string>();
		String settingName = HEADER_SETTING_ADMITTED;
		Account curPatient = null;
		if (patientId != null) {
			List<Account> patients = [	SELECT Id, Current_Admission__r.Stage__c,
												Patient_Contact__r.Deceased__c
										FROM Account
										WHERE Id = :patientId
										WITH SECURITY_ENFORCED];
			if(patients.size() != 0) {
				curPatient=patients[0];
				if(curPatient.Patient_Contact__r.Deceased__c) {
					settingName = HEADER_SETTING_DECEASED;
				} else if(curPatient.Current_Admission__r.Stage__c == ADMISSION_STAGE_DISCHARGED) {
					settingName = HEADER_SETTING_DISCHARGED;
				}
				Clinical_Patient_File_Header_Setting__mdt setting = [SELECT Id, DeveloperName, Configuration__c
																			FROM Clinical_Patient_File_Header_Setting__mdt
																			WHERE DeveloperName = :settingName
																			WITH SECURITY_ENFORCED limit 1];
				String config = setting.Configuration__c;
				config = config.replaceAll('\r\n|\n|\r','');
				ret.put(RESULT_CONFIG, config);
				/*
				ChangeAdmittedProgramController.PatientAccount pInfo = ChangeAdmittedProgramController.getAccountInfo(patientId);
				if(pInfo.currentAdmittedProgram != null){
					ret.put(RESULT_PROGRAM_STATUS, pInfo.currentAdmittedProgram.Current_Status__c);
				}
				*/
			}
		}
		return ret;
	}

	@AuraEnabled
	public static SummaryInfoWrapper getSummaryInfo()
	{
		System.debug('UserHomeApexController getSummaryInfo...');
		// Get number of Overdue tags and Due Next 7 Days tags for Outstanding Items tab.
		return new SummaryInfoWrapper(queryTags());
	}

	@AuraEnabled
    public static String getCurrentAppName()
    {
			System.debug('UserHomeApexController getCurrentAppName...');
        return SObjectUtils.getCurrentAppName();
    }

	private static List<Outstanding_Tag__c> queryTags()
	{
			System.debug('UserHomeApexController queryTags...');
		String queryString = openTagQueryString + ' WHERE' + openTagWhereUserId;
		if (specifiedPatientId != null)
		{
			queryString += ' AND' + openTagWherePatientId;
		}

		List<Outstanding_Tag__c> currentTags = (List<Outstanding_Tag__c>)Database.query(queryString);
		return currentTags;
	}

	public static void convertCommaSeparatedToSet(String commaSeparated, Set<String> collection) {
			System.debug('UserHomeApexController convertCommaSeparatedToSet...');
		if(String.isNotBlank(commaSeparated)) {
			String[] parts = commaSeparated.split(',');
			for(String c : parts) {
				collection.add(c.trim());
			}
		}
	}
	/*******************************************************************************************************
    * @description Returns show/hide permissions for rendering ClinicalPatientFile Lightning Component
    * @param userId the SFDC Id of the user
    * @return A map containing current app name and view configuration
    */
	@AuraEnabled
	public static Map<string,object> getViewConfiguration(String userId) {
			System.debug('UserHomeApexController getViewConfiguration...');
		Persona_View_Configuration__mdt retConfig = null;
		//devNames.add(PERSONA_DEFAULT);
		PermissionSets.queryUserPermSets(userId);
		Map<Id, Set<String>> userId2PermSetAssignmentIdsMap = PermissionSets.userId2PermSetAssignmentIdsMap;
		Set<String> permissionSet = userId2PermSetAssignmentIdsMap.get(userId);
		list<Simplified_View_Configuration__mdt> simplified =
						[SELECT Id, Hide_Components__c, Hide_Tabs__c,
								Show_Components__c, Show_Tabs__c
						FROM Simplified_View_Configuration__mdt
						WHERE DeveloperName in :permissionSet
						WITH SECURITY_ENFORCED];

		Set<String> hideComponents = new Set<String>();
		Set<String> hideTabs = new Set<String>();
		Set<String> showComponents = new Set<String>();
		Set<String> showTabs = new Set<String>();

		for(Simplified_View_Configuration__mdt pvc : simplified) {
			UserHomeApexController.convertCommaSeparatedToSet(pvc.Hide_Components__c, hideComponents);
			UserHomeApexController.convertCommaSeparatedToSet(pvc.Hide_Tabs__c, hideTabs);
			UserHomeApexController.convertCommaSeparatedToSet(pvc.Show_Components__c, showComponents);
			UserHomeApexController.convertCommaSeparatedToSet(pvc.Show_Tabs__c, showTabs);
		}

		Map<string,object> retObj = new Map<string,object>{
			RESULT_HIDE_TABS => new List<String>(hideTabs),
			RESULT_HIDE_COMPONENTS => new List<String>(hideComponents),
			RESULT_SHOW_TABS => new List<String>(showTabs),
			RESULT_SHOW_COMPONENTS => new List<String>(showComponents)
		};
		System.debug('retObj =' + retObj);
		return retObj;
	}
	// private static SummaryInfoWrapper calculateSummaryValues(List<Outstanding_Tag__c> currentTags)
	// {
	// 	SummaryInfoWrapper result = new SummaryInfoWrapper(currentTags);

		// Integer overdue = 0;
		// Integer due7days = 0;
		// for (Outstanding_Tag__c currentTag: currentTags)
		// {
		// 	if (currentTag.Target_Date__c == null)
		// 	{
		// 		continue; //null target date will be counted in totalOpen only
		// 	} else if (currentTag.Overdue_Days__c > 0)
		// 	{
		// 		overdue++;
		// 	} else if (currentTag.Target_Date__c.daysBetween(todaysDate) <= 0 //today is target date or previous to target date
		// 			&& currentTag.Target_Date__c.daysBetween(todaysDate) >= -7) //today is 7 days previous to target date or less than 7 days previous
		// 	{
		// 		due7days++;
		// 	}
		// }
		// result.overdueTags = String.valueOf(overdue);
		// result.dueNext7Days = String.valueOf(due7days);
		// result.totalOpen = String.valueOf(currentTags.size());
	// 	return result;
	// }



	public class SummaryInfoWrapper
	{
		@AuraEnabled public String unreadAlerts = '-';
		@AuraEnabled public String unreadMessages = '-';
		@AuraEnabled public String overdueTags = '-';
		@AuraEnabled public String dueNext7Days = '-';
		@AuraEnabled public String totalOpen = '-';
		@AuraEnabled public String meetingsToday = '-';

		public SummaryInfoWrapper(List<Outstanding_Tag__c> currentTags)
		{
			calculateTotals(currentTags);
		}

		private void calculateTotals(List<Outstanding_Tag__c> currentTags)
		{
			System.debug('UserHomeApexController SummaryInfoWrapper calculateTotals...');
			Integer overdue = 0;
			Integer due7days = 0;
			for (Outstanding_Tag__c currentTag: currentTags)
			{
				if (currentTag.Target_Date__c == null)
				{
					continue; //null target date will be counted in totalOpen only
				} else if (currentTag.Overdue_Days__c > 0)
				{
					overdue++;
				} else if (currentTag.Target_Date__c.daysBetween(todaysDate) <= 0 //today is target date or previous to target date
						&& currentTag.Target_Date__c.daysBetween(todaysDate) >= -7) //today is 7 days previous to target date or less than 7 days previous
				{
					due7days++;
				}
			}
			this.overdueTags = String.valueOf(overdue);
			this.dueNext7Days = String.valueOf(due7days);
			this.totalOpen = String.valueOf(currentTags.size());
		}
	}

	@AuraEnabled
    public static Map<String,object> initializeComponentData(){
		System.debug('UserHomeApexController initializeComponentData...');

		Boolean isBilling = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'Billing');
		//MedOffice
		//MedicalRecords

		Boolean hasMedOfficePermission = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'MedOffice');
		//Boolean hasMedicalRecordsPermission = PermissionSets.hasPermissionSet(UserInfo.getUserId(), 'MedicalRecords');
		Boolean userInViewConsultPendingGroup = false;
		List<GroupMember> groupMemberships = [SELECT GroupId, Id, UserOrGroupId 
											FROM GroupMember 
											WHERE (group.DeveloperName = 'View_Consult_Pending' OR group.DeveloperName = 'Clinical') 
												AND UserOrGroupId =:UserInfo.getUserId()];
		if(!groupMemberships.isEmpty()) {
			userInViewConsultPendingGroup = true;
		}

		Map<String,object> resultData = new Map<String,object>();

		if (isBilling) {
			resultData.put('hasSwapPatientPictureBookForStaff', !isBilling);
			resultData.put('userInViewConsultPendingGroup', userInViewConsultPendingGroup);
			
			//return new Map<String,object>{ 'hasSwapPatientPictureBookForStaff' => !isBilling, 'userInViewConsultPendingGroup' => userInViewConsultPendingGroup };
		} else {
			resultData.put('hasSwapPatientPictureBookForStaff', PermissionUtils.checkPerms('SwapPatientPictureBookForStaff'));
			resultData.put('userInViewConsultPendingGroup', userInViewConsultPendingGroup);
			//return new Map<String,object>{ 'hasSwapPatientPictureBookForStaff' => PermissionUtils.checkPerms('SwapPatientPictureBookForStaff'), 'userInViewConsultPendingGroup' => userInViewConsultPendingGroup };
		}
		if(hasMedOfficePermission) {
			resultData.put('hasMedOfficePermission', hasMedOfficePermission);
		}
		// if(hasMedicalRecordsPermission) {
		// 	resultData.put('hasMedicalRecordsPermission', hasMedicalRecordsPermission);
		// }
		return resultData;
    }

	@AuraEnabled
	public static Boolean shouldShowClinicalPatientFile(Id accountId)
	{
		return UserHomeApexControllerHelper.shouldShowClinicalPatientFile(accountId);
	}

	@AuraEnabled
	public static Map<String, String> getPostRenderConfig(Id accountId)
	{
		return UserHomeApexControllerHelper.getPostRenderConfig(accountId);
	}
}