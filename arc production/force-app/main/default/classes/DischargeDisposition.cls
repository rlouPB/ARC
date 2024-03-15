public class DischargeDisposition {
    @AuraEnabled
    public User currentUser{get;set;}

    @AuraEnabled
    public User responsibleSocialWorker{get;set;}
    
    @AuraEnabled
    public Boolean isMedOfficeUser{get;set;}
    
    @AuraEnabled
    public Boolean isMedRecords{get;set;}
    
    @AuraEnabled
    public Boolean isSystemAdmin{get;set;}
    
    @AuraEnabled
	public Assigned_Clinician__c assignedClinician {get;set;}
    
    @AuraEnabled
    public Account patient{get;set;}
    
    @AuraEnabled
    public Discharge_Disposition__c dischargeDispositionObj{get;set;}
        
    @AuraEnabled
    public List<DischargeSection> dischargeSectionList{get;set;}
    
    public DischargeDisposition()
    {
        this.isMedRecords = PermissionSets.hasPermissionSet(Userinfo.getUserId(), 'MedicalRecords');
        this.isSystemAdmin = ([SELECT Profile.Name FROM User WHERE Id = :Userinfo.getUserId()].Profile.Name == 'System Administrator');
    }
}