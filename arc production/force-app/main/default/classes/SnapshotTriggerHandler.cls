public  class SnapshotTriggerHandler implements ITrigger {
    /**
   * bulkBefore
   *
   * This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  private Map<String, Id> groupIdsByName;
   public void bulkBefore(){}

   /**
   * bulkAfter
   *
   * This method is called prior to execution of an AFTER trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
   public void bulkAfter(){
       if(Trigger.isAfter && Trigger.IsInsert){
           list<Patient_Note__c> patientNotes = new List<Patient_Note__c>();
           for(Snapshot__c ss : (Snapshot__c[])Trigger.New){
               if(ss.Patient_Note__c != null){
                   patientNotes.add(new Patient_Note__c(Id = ss.Patient_Note__c, Snapshot__c = ss.Id));
               }
           }
           if(patientNotes.size() > 0){
               update patientNotes;
           }
       }
       List<Group> allGroups = [
				SELECT Name
				FROM Group
			];
			groupIdsByName = new Map<String, Id>();
			for (Group currentGroup: allGroups)
			{
				groupIdsByName.put(currentGroup.Name, currentGroup.Id);
			}
   }

   /**
   * beforeInsert
   *
   * This method is called iteratively for each record to be inserted during a BEFORE
   * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
   */
   public void beforeInsert(SObject so){}

   /**
   * beforeUpdate
   *
   * This method is called iteratively for each record to be updated during a BEFORE
   * trigger.
   */
   public void beforeUpdate(SObject oldSo, SObject so){}

   /**
   * beforeDelete
   *
   * This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   */
   public void beforeDelete(SObject so){}

   /**
   * afterInsert
   *
   * This method is called iteratively for each record inserted during an AFTER
   * trigger. Always put field validation in the 'After' methods in case another trigger
   * has modified any values. The record is 'read only' by this point.
   */
   public void afterInsert(SObject so){
    Snapshot__c currentSnapshot = (Snapshot__c)so;
    Set<Admission__c> admissions = new Set<Admission__c>();
    Boolean hasAccount = false;
    if (currentSnapshot.EGO__c != null) {
        EGO__c ego = [SELECT Admission__r.Stage__c, Admission__r.Chart_Closed__c FROM EGO__c WHERE Id = :currentSnapshot.EGO__c];
        Admission__c adm = new Admission__c(Stage__c = ego.Admission__r.Stage__c, Chart_Closed__c = ego.Admission__r.Chart_Closed__c);
        admissions.add(adm);
    }
    if (currentSnapshot.Treatment_Plan__c != null) {
        Case tp = [SELECT Admission__r.Stage__c, Admission__r.Chart_Closed__c FROM Case WHERE Id = :currentSnapshot.Treatment_Plan__c];
        Admission__c adm = new Admission__c(Stage__c = tp.Admission__r.Stage__c, Chart_Closed__c = tp.Admission__r.Chart_Closed__c);
        admissions.add(adm);
    }
    if (currentSnapshot.Patient_Note__c != null) {
        Patient_Note__c pn = [SELECT Admission__r.Stage__c, Admission__r.Chart_Closed__c FROM Patient_Note__c WHERE Id = :currentSnapshot.Patient_Note__c];
        Admission__c adm = new Admission__c(Stage__c = pn.Admission__r.Stage__c, Chart_Closed__c = pn.Admission__r.Chart_Closed__c);
        admissions.add(adm);
    }
    if (currentSnapshot.Discharge_Disposition__c != null) {
        Discharge_Disposition__c ddr = [SELECT Admission__r.Stage__c, Admission__r.Chart_Closed__c FROM Discharge_Disposition__c WHERE Id = :currentSnapshot.Discharge_Disposition__c];
        Admission__c adm = new Admission__c(Stage__c = ddr.Admission__r.Stage__c, Chart_Closed__c = ddr.Admission__r.Chart_Closed__c);
        admissions.add(adm);
    }

    List<Id> groupsToShare = new List<Id>();
    //List<Id> groupsToShare = new List<Id>{groupIdsByName.get('Admissions')};
    List<String> stagesToShareWithClinical = new List<String>{
        'Consultation Pending',
        'Admitted',
        'Discharged'
    };
    for(Admission__c adm : admissions) {
        if (stagesToShareWithClinical.contains(adm.Stage__c)
            && adm.Chart_Closed__c == false)
        {
            groupsToShare.add(groupIdsByName.get('Clinical'));
            hasAccount = true;
        }
    }
     
    String shareResult = hasAccount ? SharingRecord_Utils.createSharingRecords(new List<Id>{currentSnapshot.Id}, groupsToShare, 'Read') : '';
   }

   /**
   * afterUpdate
   *
   * This method is called iteratively for each record updated during an AFTER
   * trigger.
   */
   public void afterUpdate(SObject oldSo, SObject so){}

   /**
   * afterDelete
   *
   * This method is called iteratively for each record deleted during an AFTER
   * trigger.
   */
   public void afterDelete(SObject so){}

   /**
   * andFinally
   *
   * This method is called once all records have been processed by the trigger. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
   public void andFinally(){}
}