public class PatientNoteCtl
{
    public static set<String> patientNoteTypeWithDiagnosisComponent = new set<String>();
    static {
        List<Note_Item__mdt> noteItems = [ SELECT Id, Embedded_Component_Name__c,
                Note_Definition__r.MasterLabel, Note_Definition__r.DeveloperName 
                FROM Note_Item__mdt where Embedded_Component_Name__c = 'c:NoteDiagnosis'];
        for(Note_Item__mdt item : noteItems) {
            patientNoteTypeWithDiagnosisComponent.add(item.Note_Definition__r.MasterLabel);
        }
    }
    @AuraEnabled
    public static LookupComponentController.RecordWrapper groupWrap {get; set;}

    @AuraEnabled
    public static User getUser(Id userId)
    {
        return [SELECT Id, Name, Requires_Co_Signature__c FROM User WHERE Id =: userId];
    }

    @AuraEnabled
    public static NoteDefinition.Note getNote(Id patientNoteId)
    {
        System.debug('begin PatientNoteCtl.getNote()');
        NoteDefinition.Note note = NoteDefinition.getNote(patientNoteId);
        System.debug('begin PatientNoteCtl.getNote() note: ' + note);
        note.isAuthSigner = AuthorizedSigners.getSignersByPatientNoteId(patientNoteId).contains(System.UserInfo.getUserId());
        System.debug('begin PatientNoteCtl.getNote() note.isAuthSigner: ' + note.isAuthSigner);
        note.canReOpenNote =  FeatureManagement.checkPermission('Can_Re_Open_Note');
        System.debug('begin PatientNoteCtl.getNote() note.canReOpenNote: ' + note.canReOpenNote);
        note.numOfSnapshots = getNumberOfSnapshots(patientNoteId);
        note.canSeeCompleteButton = canSeeCompleteButton(patientNoteId);
        System.debug('getNote note =' +  note);
        return note;
    }

    public static Boolean canSeeCompleteButton(Id patientNoteId) {
        Boolean canSeeCompleteButton = false;
        Patient_Note__c note = [SELECT Id, Status__c, OwnerId, Admission__c, type__c,
                                    Psych_Testing_Request__r.Report_Writer__c,
                                    Psych_Testing_Request__r.Report_Writer__r.Requires_Co_Signature__c,
                                    Psych_Testing_Request__r.Independent_Testing__c,
                                    Psych_Testing_Request__r.Testing_Supervisor__c,
                                    Psych_Testing_Request__r.RecordType.DeveloperName
                                FROM Patient_Note__c
                                WHERE Id = :patientNoteId
                                LIMIT 1];
        //User us = [SELECT Id, Requires_Co_Signature__c FROM User WHERE Id =: System.UserInfo.getUserId() LIMIT 1];
        User us = AuthorizedSigners.getAuthorizedSigner(System.UserInfo.getUserId());
        if (note.Status__c == 'Draft')
        {
            canSeeCompleteButton = us.Requires_Co_Signature__c || us.Requires_Social_Work_Co_Signature__c;
            // System.debug('getNote Psychological_Testing_Request RT =' +  note.Psych_Testing_Request__r.RecordType.DeveloperName);
            // System.debug('getNote Independent_Testing__c =' +  note.Psych_Testing_Request__r.Independent_Testing__c);
            // System.debug('getNote Report_Writer__c =' +  note.Psych_Testing_Request__r.Report_Writer__c);
            // System.debug('getNote current user =' +  us.Id);
            // System.debug('getNote current user = Report_Writer__c' +  (us.Id == note.Psych_Testing_Request__r.Report_Writer__c));

            if(note.Psych_Testing_Request__c != null && 'Psychological_Testing_Request'.EqualsIgnoreCase(note.Psych_Testing_Request__r.RecordType.DeveloperName)) {
                if(!note.Psych_Testing_Request__r.Independent_Testing__c 
                        && note.Psych_Testing_Request__r.Report_Writer__c == us.Id)
                {
                    // System.debug('getNote current canSeeCompleteButton =' +  canSeeCompleteButton);
                    canSeeCompleteButton = true;
                }
            } else if(note.Type__c == 'Summation of Hospitalization' ) 
            {
                Id admissionId = note.Admission__c;
                List<Assigned_Clinician__c> assignedClinicians = [SELECT Id , Name , Role__c , Admission__c , User__c
                                                    FROM Assigned_Clinician__c 
                                                    WHERE Admission__c = :admissionId
                                                        AND Role__c = 'Psychotherapist'
                                                        AND Start_Date__c <= TODAY
                                                        AND (End_Date__c = null OR End_Date__c > TODAY)
                                                    LIMIT 1];

                // system.debug('Case_AbstractTriggerHandler assignedClinicians =' + assignedClinicians);
                if(assignedClinicians.size() > 0) 
                {
                    // Assigned_Clinician__c ac = assignedClinicians[0];
                    if(assignedClinicians[0].User__c == us.Id) 
                    {
                        canSeeCompleteButton = true;
                    }
                }
            }
        }
        return canSeeCompleteButton;
    }

    public static Integer getNumberOfSnapshots(Id patientNoteId) {
        List<Snapshot__c> snapshots = [SELECT Id FROM Snapshot__c WHERE patient_note__c = :patientNoteId and patient_note__r.status__c='Finalized'];
        return snapshots.size();
    }

    @AuraEnabled
    public static String getGroup()
    {
        try {
            List<Group__c> gp = [SELECT Id, Name FROM Group__c WHERE Name = 'Current Clinical Staff' LIMIT 1];

            if (!gp.isEmpty()) 
            {
                groupWrap = new LookupComponentController.RecordWrapper();
                groupWrap.isRecord = true;
                groupWrap.label = gp[0].Name;
                groupWrap.value = gp[0].Id;
            } else {
                throw new AuraHandledException('Current Clinical Staff is missing.');
            }

            return JSON.serialize(groupWrap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



    @AuraEnabled
    public static Boolean getCanFinalize(String noteId)
    {
        Boolean canFinalize = false;
        try {
            if (noteId == null || noteId == '') {
                return false;
            }
            //Get the patient Note
            Patient_Note__c note = [SELECT Id, Status__c, OwnerId, Type__c,
                                        Psych_Testing_Request__c, Psych_Testing_Request__r.Report_Writer__c,
                                        Psych_Testing_Request__r.Report_Writer__r.Requires_Co_Signature__c,
                                        Psych_Testing_Request__r.Independent_Testing__c,
                                        Psych_Testing_Request__r.Testing_Supervisor__c,
                                        Psych_Testing_Request__r.RecordType.DeveloperName,
                                        TYPEOF Owner WHEN User THEN Requires_Social_Work_Co_Signature__c END
                                    FROM Patient_Note__c
                                    WHERE Id =: noteId
                                    LIMIT 1];
            //Get the User
            //User us = [SELECT Id, Requires_Co_Signature__c FROM User WHERE Id =: System.UserInfo.getUserId() LIMIT 1];
            User us =  AuthorizedSigners.getAuthorizedSigner(System.UserInfo.getUserId());

            if(note.Status__c != 'Cancelled' && note.Status__c != 'Finalized')
            {
                //canFinalize = FeatureManagement.checkPermission('Medical_Records');

                if (((String)note.OwnerId).startsWith('00G'))
                {
                    List<GroupMember> gms = [SELECT UserOrGroupId
                                            FROM GroupMember
                                            WHERE GroupId = :note.OwnerId AND UserOrGroupId = :us.Id];
                    canFinalize = (gms.size() > 0 && !us.Requires_Co_Signature__c);
                } 
                // else if (note.Psych_Testing_Request__c == null)
                // {
                //     canFinalize = (note.OwnerId == us.Id && !us.Requires_Co_Signature__c);
                // }
                          
                if (!canFinalize || Test.isRunningTest())
                {
                    if(note.Psych_Testing_Request__c != null) // && 'Psychological_Testing_Request'.EqualsIgnoreCase(note.Psych_Testing_Request__r.RecordType.DeveloperName)) 
                    {
                        if(note.Psych_Testing_Request__r.Independent_Testing__c && us.Requires_Co_Signature__c == false 
                                && note.Psych_Testing_Request__r.Report_Writer__c == us.Id) 
                        {
                            canFinalize = true;
                        } else if(note.Psych_Testing_Request__r.Testing_Supervisor__c == us.Id) 
                        {
                            canFinalize = true;
                        }
                    } else if('Summation of Hospitalization'.equalsIgnoreCase(note.Type__c)) 
                    {
                        List<GroupMember> members = [SELECT UserOrGroupId 
                                                    FROM GroupMember 
                                                    WHERE GroupId IN (SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Patient Care')
                                                        AND UserOrGroupId = :us.Id
                                                    LIMIT 1];
                        if (members.size() > 0)
                        {
                            canFinalize = true;
                        }
                    //} else if(note.Status__c == 'Completed' && AuthorizedSigners.getSignersByPatientNoteId(note.Id).contains(us.Id))
                    } else if(note.Status__c == 'Completed' && AuthorizedSigners.getTeamMemberSigners().contains(us.Id))
                        //(note.Status__c == 'Draft' && !us.Requires_Co_Signature__c && (note.OwnerId == us.Id || hasMedicalRecord || userIsQueueMember )) ||
                    {
                        canFinalize = true;
                    } else if (note.OwnerId == us.Id && !us.Requires_Co_Signature__c && !us.Requires_Social_Work_Co_Signature__c)
                    {
                        canFinalize = true;
                    } else if(note.Owner instanceof User) {
                        User anOwner = (User) note.Owner;
                        if(anOwner.Requires_Social_Work_Co_Signature__c) {
                            if(AuthorizedSigners.getSocialWorkTeamMemberSigners().contains(us.Id) && (note.OwnerId != us.Id)) {
                                canFinalize = true;
                            } else {
                                canFinalize = false;
                            }
                        }
                    }
                }
                //ARC-2342 medical records ability to finalize a re-opened note
                //Enable Medical_Records custom permission to Finalize a re-opened note
                canFinalize = canFinalize || FeatureManagement.checkPermission('Medical_Records');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return canFinalize;
    }

    @AuraEnabled
    public static String saveNote(String patientNoteJSON, String newStatus)
    {
        String retval = 'success';
        Savepoint sp = Database.setSavepoint();
        try
        {
            Boolean hasChange = false;
            // System.debug('patientNoteJSON ' + patientNoteJSON);
            // System.debug('newStatus ' + newStatus);
            Patient_Note__c patientNote = (Patient_Note__c)JSON.deserialize(patientNoteJSON, Patient_Note__c.class);
            NoteDefinition.Note theNote = NoteDefinition.getNote(patientNote.Id, true);
            Patient_Note__c loadedPatientNote = theNote.patientNote;
            // system.debug('loaded patient note status:'+loadedPatientNote.Status__c);
            /*
            if(String.isBlank(loadedPatientNote.Status__c) || !loadedPatientNote.Status__c.containsIgnoreCase('finalize')){
                User currentUser = [SELECT Id, Requires_Co_Signature__c FROM USER WHERE Id =: UserInfo.getUserId()];
                */
            // system.debug('loaded:'+loadedPatientNote.LastModifiedDate +', patiente note:'+patientNote.LastModifiedDate);
            if(loadedPatientNote.LastModifiedDate != patientNote.LastModifiedDate && !patientNote.Type__c.equals('Away Medication Order')){
                hasChange = true;
            }else{
                User currentUser = [SELECT Id, Requires_Co_Signature__c, Professional_Name__c
                                    FROM USER 
                                    WHERE Id = :UserInfo.getUserId()];
                
                if('Complete'.equalsIgnoreCase(newStatus))
                {
                    patientNote.Status__c = 'Completed';
                    if(String.isBlank(patientNote.Completed_By__c)) 
                    {
                        patientNote.Completed_By__c = UserInfo.getUserId();
                        patientNote.Completed_Date_Time__c = System.now();
                        patientNote.Completed_By_Professional_Name__c = currentUser.Professional_Name__c;
                    }
                    // Admission__c adm = [SELECT Id, Team__c 
                    //                     FROM Admission__c 
                    //                     WHERE Id = :patientNote.Admission__c 
                    //                     LIMIT 1];

                    Patient_Note__c note = [SELECT Id, Status__c, OwnerId, Psych_Testing_Request__c, Type__c,
                                                Psych_Testing_Request__r.Report_Writer__c,
                                                Psych_Testing_Request__r.Report_Writer__r.Requires_Co_Signature__c,
                                                Psych_Testing_Request__r.Independent_Testing__c,
                                                Psych_Testing_Request__r.Testing_Supervisor__c,
                                                Psych_Testing_Request__r.RecordType.DeveloperName 
                                            FROM Patient_Note__c 
                                            WHERE Id =: patientNote.Id 
                                            LIMIT 1];
                    if(note.Psych_Testing_Request__c != null 
                        && 'Psychological_Testing_Request'.EqualsIgnoreCase(note.Psych_Testing_Request__r.RecordType.DeveloperName)
                        && !note.Psych_Testing_Request__r.Independent_Testing__c
                        && note.Psych_Testing_Request__r.Testing_Supervisor__c != null)
                    {
                        patientNote.OwnerId = note.Psych_Testing_Request__r.Testing_Supervisor__c;
                    } else if('Summation of Hospitalization'.equalsIgnoreCase(note.Type__c)) 
                    {
                        patientNote.OwnerId = AuthorizedSigners.getAuthSignersQueueIdByQueueName('Patient Care');
                    }
                } else if('Finalize'.equalsIgnoreCase(newStatus))
                {
                    patientNote.Status__c = 'Finalized';
                    if(theNote.noteDefinition.DeveloperName.indexOf('History_and_Physical') != -1) 
                    {
                        Admission__c admUpdate = new Admission__c(
                            Id = patientNote.Admission__c, 
                            Medical_Care_Plan__c = patientNote.Medical_Care_Plan__c);
                        update admUpdate;
                    }
                    // Populate the Finalized__BY__c and Finalized_Date_Time__c only when it is the first time change.
                    if(String.isBlank(patientNote.Finalized_By__c)) 
                    {
                        patientNote.Finalized_By__c = currentUser.Id;//UserInfo.getUserId();
                        patientNote.Finalized_Date_Time__c = System.now();
                        patientNote.Finalized_By_Professional_Name__c = currentUser.Professional_Name__c;
                    }

                    //arc-2444 decouple the finalized meetings with series meeting.
                    List<Meeting__c> meetings = [SELECT Id, Recurrence__c FROM Meeting__c WHERE Monthly_Note__c = :patientNote.Id FOR UPDATE];
                    for(Meeting__c m : meetings) {
                        m.Recurrence__c = null;
                    }
                    if(meetings.size() != 0) {
                        update meetings;
                    }      

                } else if('Draft'.equalsIgnoreCase(newStatus)) {
                    patientNote.Status__c = 'Draft';
                } else if ('Cancelled'.equalsIgnoreCase(newStatus)) {
                    patientNote.Status__c = 'Cancelled';
                }
            }
            if(hasChange){
                retval = 'This Patient Note has been changed in a different session. To avoid overwriting changes, please edit the current version';
            }else{
                Map<String, Schema.SObjectField> patientFieldMap = patientNote.getSobjectType().getDescribe().fields.getMap();
                for(String fieldName : patientFieldMap.keySet())
                {
                    if(!fieldName.contains('__r'))
                    {
                        Schema.DescribeFieldResult fieldResult = patientFieldMap.get(fieldName).getDescribe();
                        if(fieldResult.isAccessible() &&
                            fieldResult.isCreateable() &&
                            fieldResult.isUpdateable() &&
                            !fieldResult.isCalculated() &&
                            !fieldResult.isAutoNumber() &&
                            !fieldResult.isDeprecatedAndHidden())
                        {
                                if(fieldResult.getType() == Schema.DisplayType.BOOLEAN)
                                {
                                    if(patientNote.get(fieldName) != NULL)
                                    {
                                        loadedPatientNote.put(fieldName, patientNote.get(fieldName));
                                    }
                                }else{
                                    loadedPatientNote.put(fieldName, patientNote.get(fieldName));
                                }
                        }
                    }
                }

                if('Finalize'.containsIgnoreCase(newStatus))
                {
                    // TODO: Only call NoteDiagnosisCtl.finalize if Patient Note contains
                    // Embedded component: c:NoteDiagnosis
                    String patientNoteType = patientNote.Type__c;
                    // System.debug('---------------patientNoteType=' + patientNoteType );
                    List<Note_Item__mdt> noteItems = [  SELECT Id, Embedded_Component_Parameters__c 
                                                        FROM Note_Item__mdt 
                                                        WHERE Embedded_Component_Name__c = 'c:NoteDiagnosis'
                                                            AND Note_Definition__r.Note_Label__c = :patientNoteType
                                                        LIMIT 1];
                    // System.debug('---------------noteItems=' + noteItems );
                    if(noteItems.size() > 0) 
                    {
                        Note_Item__mdt noteItem = noteItems[0];
                        Map<String, String> params = String.isNotBlank(noteItem.Embedded_Component_Parameters__c) 
                                    ? (Map<String, String>)JSON.deserialize(noteItem.Embedded_Component_Parameters__c, Map<String, String>.class) 
                                    : new Map<String, String>();
                        String source = params.get('source');   
                        NoteDiagnosisCtl.finalize(patientNote.Admission__c, patientNote, source);
                    }
                    
                    // system.debug('----- HERE IS DEBUGGER FOR FINALIZE');
                    // system.debug('----- update the location to location_temp on prescription');
                    // system.debug('----- patientNote.Admission__c ' + patientNote.Admission__c );
                    

                    // System.debug('PRESRIPTIONS TO UPDATE');
                    // System.debug(prescriptions);
                    // Updating prescription only when the patient note type is MSA
                    if (patientNote.Type__c == 'Medication Self Administration (MSA) Order') 
                    {
                        Prescription__c[] prescriptions = [SELECT Id, Location__c, Location_temp__c , Quantity_to_Package__c , Quantity_to_Package_Temp__c 
                                                        FROM Prescription__c 
                                                        WHERE Account__c = :patientNote.Account__c AND Status__c = 'Active' ];
                        for (Prescription__c presc : prescriptions) 
                        {
                            if( presc.location_temp__c != null)
                            {
                                presc.Location__c = presc.location_temp__c;
                                // presc.location_temp__c = '';
                            }
                            if( presc.Quantity_to_Package_Temp__c != null)
                            {
                                presc.Quantity_to_Package__c = presc.Quantity_to_Package_Temp__c;
                                presc.Quantity_to_Package_Temp__c = null;
                            }
                        }
                        update prescriptions;
                    }
                }

                update loadedPatientNote;
                // Patient_Note__c tpn = [SELECT Id, Status__c 
                //                         FROM Patient_Note__c 
                //                         WHERE Id = :loadedPatientNote.Id];
            }
        } catch (Exception e) { 
            Database.rollBack(sp); 
            throw new AuraHandledException(e.getMessage());
            //retVal = e.getMessage(); 
        }
        return retval;
    }

    @AuraEnabled
    public static void reopenNote(String patientNoteId, String patientStatus){
        List<Diagnosis__c> diagnoses = [SELECT Id, Status__c 
                                        FROM Diagnosis__c 
                                        WHERE Patient_note__c = :patientNoteId 
                                        FOR UPDATE];
        for(Diagnosis__c diag : diagnoses) {
            diag.Status__c = 'Draft';
        }
        // if(diagnoses.size() > 0) {
        update diagnoses;
        // }
    }

    @AuraEnabled
	public static Patient_Note__c getPatientNoteRecord(Id patientNoteId) {
		String queryStr =
			'SELECT CreatedDate, Id, Status__c, Contact_Date__c ' +
			'FROM Patient_Note__c ' +
			'WHERE Id =\'' + patientNoteId + '\'';
		// System.Debug('queryStr : ' + queryStr);
		return Database.query(queryStr);
	}

    public static void cloneDiagnosesWithPatientNote(List<Patient_Note__c> patientNotes) 
    {
        //only handle one patient note a time
        Id patientNoteId = patientNotes[0].Id;
        Patient_Note__c note = [SELECT Id, Admission__c, Type__c FROM Patient_Note__c WHERE Id = :patientNoteId];
        List<Note_Item__mdt> noteItems = [SELECT Id, Active__c, Embedded_Component_Parameters__c 
                                            FROM Note_Item__mdt 
                                            WHERE Embedded_Component_Name__c = 'c:NoteDiagnosis' 
                                                AND Note_Definition__r.masterlabel = :note.Type__c
                                            LIMIT 1];
        if(noteItems.size() > 0) 
        {
            Note_Item__mdt noteItem = noteItems[0];
            Map<string,string> params = String.isNotBlank(noteItem.Embedded_Component_Parameters__c)
                        ? (Map<String, String>)JSON.deserialize(noteItem.Embedded_Component_Parameters__c, Map<String, String>.class) 
                        : new Map<String, String>();
            String source = params.get('source');   
            
            List<Diagnosis__c> diagnoses = [SELECT Id, Name, Admission__c, Clinical_Code__c, 
                                                Type__c, Source__c, Additional_Specifiers__c, Marked_for_Delete__c, Clinical_Code_Name__c, 
                                                Clinical_Code_Description__c, Patient_Note__c 
                                            FROM Diagnosis__c 
                                            WHERE Admission__c = :note.Admission__c 
                                                AND Patient_Note__r.Status__c = 'Finalized' 
                                                AND Status__c = 'Finalized' 
                                                AND Source__c = :source];
            List<Diagnosis__c> clonedDiagnoses = new List<Diagnosis__c>();
            for(Diagnosis__c diag : diagnoses) 
            {
                // system.debug('******** diag =' +  diag);
                Diagnosis__c cloned = diag.clone(false, false, false, false);
                cloned.Admission__c = diag.Admission__c;
                cloned.Patient_Note__c = patientNoteId;
                cloned.Clinical_Code__c = diag.Clinical_Code__c;
                cloned.Status__c='Draft';
                // system.debug('******** cloned =' +  cloned);
                clonedDiagnoses.add(cloned);
            }
            insert clonedDiagnoses;
        }
    }

    @AuraEnabled
    public static String saveAwayMedOrderNoteDetails(Id pId, String firstDayAwayStr, String lastDayAwayStr, Boolean finalDischargeMedOrder, Integer daysToPackage) {
        
        Patient_Note__c pn = new Patient_Note__c(
            Id = pId,
            Away_First_Date__c = Date.valueOf(firstDayAwayStr)
        );
        
        if(null != lastDayAwayStr) {
            pn.Away_Last_Date__c = Date.valueOf(lastDayAwayStr);
        } else {
            pn.Away_Last_Date__c = null;
        }

        if(null != finalDischargeMedOrder){
            pn.Final_Discharge_Med_Order__c = finalDischargeMedOrder;
        } else {
            pn.Final_Discharge_Med_Order__c = false;
        }

        pn.Days_to_Package__c = daysToPackage;

        update pn;
        return 'Success';
    }

    @AuraEnabled
	public static Patient_Note__c getPatientNoteAwayOrderInfo(Id patientNoteId) {
		return [
			SELECT
				Id,
				Away_First_Date__c,
				Away_Last_Date__c,
                Away_Number_of_Days__c,
				Final_Discharge_Med_Order__c,
				Days_to_Package__c,
                Status__c,
                Type__c
			FROM Patient_Note__c
			WHERE Id = :patientNoteId
			LIMIT 1
		];
	}
}