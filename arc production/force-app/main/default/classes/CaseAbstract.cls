public class CaseAbstract
{
    String mode; //'new' or 'existing'
    Id patientId;
    public Admission__c admission { get; set;}
    public static Id admissionId;

    public Case_Abstract__c record { get; set;}
    List<Case_Abstract_Section__c> sectionRecords = new List<Case_Abstract_Section__c>();
    Set<Id> sectionOwnerIds = new Set<Id>();

    User currentUser { get {
        if (currentUser == null) {
            currentUser = [SELECT Id, Professional_Name__c, profile.name
                            FROM User
                            WHERE Id = :Userinfo.getUserId()];
        }
        return currentUser;
    } set; }

    public Boolean canReopen {
        get {
            Boolean result = false;
            
            Boolean hasMedicalRecords = FeatureManagement.checkPermission('Medical_Records');
            if(currentUser.profile.Name == 'System Administrator' || hasMedicalRecords){
                result=true;
            }
            return result;
        }
        set;
    }

    public Boolean canGeneratePresentation {
        get {
            Boolean result = false;
            Map<String, Assigned_Clinician__c> assignedMap = CaseAbstract.assignedClinicianMap;
            Assigned_Clinician__c ac = assignedMap.get('Psychotherapist');
            Boolean hasClinicalAdmin = FeatureManagement.checkPermission('Clinical_Admin');
            if((userInfo.getUserId() == ac.User__c) || hasClinicalAdmin){
                result=true;
            }
            return result;
        }
        set;
    }
    //Info on Presentation PDF
    public CaseAbstractPresentation presentation {get; set;}
    public Boolean hasPresentation = false;
    public Map<String, String> assignedClinicianNameMap {
        get{
            Map<String, Assigned_Clinician__c> assignedMap = CaseAbstract.assignedClinicianMap;
            Map<String, String> result = new Map<String, String>();
            for(String key: assignedMap.keySet()) {
                result.put(key, assignedMap.get(key).Professional_Name__c);
            }
            return result;
        }
        set;
    }

    public static Map<String, Assigned_Clinician__c> assignedClinicianMap {
        get {
            if (assignedClinicianMap == null) {
                queryAssignedClinicians();
            }
            return assignedClinicianMap;
        } set;
    }
    public static void queryAssignedClinicians()
    {
        assignedClinicianMap = new Map<String, Assigned_Clinician__c>();
        String assClinQueryString = buildQueryString('Assigned_Clinician__c',
                                    'Admission__c = \'' + admissionId + '\''
                                    + ' AND Start_Date__c <= TODAY'
										+ ' AND (End_Date__c = null OR End_Date__c > TODAY)',
                                    'Start_Date__c ASC');
        List<Assigned_Clinician__c> assClinicians =(List<Assigned_Clinician__c>)Database.query(assClinQueryString);
        for (Assigned_Clinician__c assClin : assClinicians)
        {
            assignedClinicianMap.put(assClin.Role__c, assClin);
        }
    }
    static Map<String, Group> queueMap  {
        get {
            if (queueMap == null)
            {
                queueMap = new Map<String, Group>();
                for (Group g : [SELECT Id, Name FROM Group WHERE Type = 'Queue'])
                {
                    queueMap.put(g.Name, g);
                }
            }
            return queueMap;
        } private set; }


    public List<Section> sections {get; set;}

    CA_Type__mdt caTypeMdt;
    String shortCaTypeString;
    Set<Id> caSectionMdtIds = new Set<Id>();
    List<CA_Section__mdt> caSectionMdts;
    List<CA_Section_Item__mdt> caSectionItemMdts;
    Map<Id, List<CA_Section_Item__mdt>> sectionMdtId2sectionItemMdtsMap = new Map<Id, List<CA_Section_Item__mdt>>();
    //representationCATargetId is set to the latest CA associated with current admission when caTypeString == 'Re_Presentation_Case_Abstract'
    Id representationCATargetId = null;
    public CaseAbstract()
    {
        this.sections = new List<Section>();

    }
    public CaseAbstract(Id patientId, String caTypeString)
    {
        this();
        this.mode = 'new';
        this.patientId = patientId;
        system.debug('CaseAbstract constructor----');
        queryAdmission();
        if(caTypeString == 'Re_Presentation_Case_Abstract') {
            List<Case_Abstract__c> cas = [SELECT Id FROM Case_Abstract__c WHERE Admission__c = :this.admission.Id
                AND Status__c = 'Finalized' AND Finalized_Date_Time__c != null ORDER BY Finalized_Date_Time__c DESC];
            system.debug('re_Presentation_Case_Abstract size = ' + cas.size());
            if(cas.size() > 0) {
                //representationCATargetId is set to the latest CA associated with current admission when caTypeString == 'Re_Presentation_Case_Abstract'
                representationCATargetId = cas[0].Id;
            } else {
                //If there is no previous Case Abstract, change to the First in IRIS Re-Pre
                caTypeString += '_Initial';
            }
        }


        queryMdts(caTypeString);

        createCaseAbstract();
        createCaseAbstractSections();

        populateAllSections();
        setVisibilityOfSaveAndRefreshFromSourceButtons();
    }

    void createCaseAbstract()
    {
        record = new Case_Abstract__c(
            Admission__c = admission.Id,
            Name = admission.Patient_Contact__r.Abbreviated_Name__c + ' - ' + shortCaTypeString,
            Case_Abstract_Type__c = caTypeMdt.MasterLabel
        );
    }

    void createCaseAbstractSections()
    {
        Map<Id, Section> sectionMdtId2SectionWrapperMap = new Map<Id, Section>();
        System.debug('createCaseAbstractSections caSectionMdts.size()' + caSectionMdts.size());
        for (CA_Section__mdt sectionMdt : caSectionMdts)
        {
            Section newSection = new Section(sectionMdt, this);

            //Map by mdtId so we can find the section wrappers later
            sectionMdtId2SectionWrapperMap.put(sectionMdt.Id, newSection);

            sections.add(newSection);
            sectionRecords.add(newSection.record);
        }

        // section Items
        System.debug('createCaseAbstractSections caSectionItemMdts.size()' + caSectionItemMdts.size());
        for (CA_Section_Item__mdt sectionItemMdt : caSectionItemMdts)
        {
            SectionItem newSectionItemWrapper = new SectionItem(sectionItemMdt);
            //representationCATargetId is set to the latest CA associated with current admission when caTypeString == 'Re_Presentation_Case_Abstract'
            newSectionItemWrapper.representationCATargetId = this.representationCATargetId;
            sectionMdtId2SectionWrapperMap.get(sectionItemMdt.CA_Section_Mdt__c).items.add(newSectionItemWrapper);
        }
    }

    public CaseAbstract(Id recordId)
    {
        this();
        this.mode = 'existing';
        queryCaseAbstract(recordId);
        queryMdts(record.Case_Abstract_Type__c);

        //join Mdts to Sections
        populateSectionItemsFromMdt();

        queryAdmission();
        setVisibilityOfSaveAndRefreshFromSourceButtons();
    }

    void setVisibilityOfSaveAndRefreshFromSourceButtons() {
        List<Id> sectionIds = new List<Id> ();
        for (Section sectionWrapper : sections)
        {
            sectionIds.add(sectionWrapper.record.Id);
            //If there is one SectionItem is marked Allow_Editing__c in sectionItemMdt, set canSave to true
            for (SectionItem item : sectionWrapper.items){
                //system.debug('----> item.sectionItemMdt.Title__c='+ item.sectionItemMdt.Title__c + ' type= ' + item.sectionItemMdt.Source_Type__c);
                if(!sectionWrapper.canSave) {
                    if (item.sectionItemMdt.Allow_Editing__c){
                        sectionWrapper.canSave = true;
                    }
                }
                if(!sectionWrapper.canRefreshFromSource){
                    if(item.sectionItemMdt.Source_Type__c == 'Patient Note') {
                        sectionWrapper.canRefreshFromSource = true;
                    }
                }
                //system.debug('----> canSave='+ sectionWrapper.canSave);
                //system.debug('----> canRefreshFromSource='+ sectionWrapper.canRefreshFromSource);
            }
        }
        Map<String, Boolean> editAccessMap = new Map<String, Boolean> ();
        for(UserRecordAccess userAccess : [SELECT RecordId, HasEditAccess FROM UserRecordAccess
            WHERE UserId = :userInfo.getUserId() AND RecordId in :sectionIds WITH SECURITY_ENFORCED]) {
            editAccessMap.put(userAccess.RecordId, userAccess.HasEditAccess);
        }
        for(Section sectionWrapper : sections) {
            sectionWrapper.canEdit = editAccessMap.get(sectionWrapper.record.Id);
            if(sectionWrapper.canSave) {
                if(editAccessMap.containsKey(sectionWrapper?.record?.Id)) {
                    sectionWrapper.canSave = editAccessMap.get(sectionWrapper.record.Id);
                }
            }
            if(sectionWrapper.canRefreshFromSource) {
                if(editAccessMap.containsKey(sectionWrapper?.record?.Id)) {
                    sectionWrapper.canRefreshFromSource = editAccessMap.get(sectionWrapper.record.Id);
                }
            }
        }
    }
    //for existing case abstract
    void populateSectionItemsFromMdt()
    {
        Map<Id, CA_Section__mdt> sectionMdtMap = new Map<Id, CA_Section__mdt>(caSectionMdts);
        for (Section sectionWrapper : sections)
        {
            sectionWrapper.sectionMdt = sectionMdtMap.get(sectionWrapper.record.CA_Section_Mdt_Id__c);
            caSectionMdtIds.add(sectionWrapper.record.CA_Section_Mdt_Id__c);
            for (CA_Section_Item__mdt item : sectionMdtId2sectionItemMdtsMap.get(sectionWrapper.record.CA_Section_Mdt_Id__c) )
            {
                SectionItem newItem = new SectionItem(item);
                if ( item.Item_Type__c == 'Rich Text Area' || item.Item_Type__c == 'Digital File')
                {
                    //populate the section item field value from the section field
                    newItem.sectionFieldValue = (String)sectionWrapper.record.get(item.Section_Field_Name__c);
                }
                sectionWrapper.items.add(newItem);
            }
        }
    }

    //existing and new
    void queryMdts(String caTypeString)
    {
        System.debug('caTypeString ' + caTypeString);
        //DeveloperName has underscores(Initial_Case_Abstract), MasterLabel doesn't (Initial Case Abstract)
        String typeWhereClause = ' WHERE DeveloperName = \'' + caTypeString + '\'';
        if (caTypeString.contains(' ')) {
            typeWhereClause = ' WHERE MasterLabel = \'' + caTypeString + '\'';
        }
        String caTypeQueryString = 'SELECT ' + buildFieldList(objNameToQueryFieldsMap.get('CA_Type__mdt'))
                                + ' FROM CA_Type__mdt'
                                + typeWhereClause;

        caTypeMdt = (CA_Type__mdt)Database.query(caTypeQueryString);

        List<String> pieces = caTypeMdt.MasterLabel.split(' ');
        shortCaTypeString = pieces[0];

        String sectionWhereClause = ' WHERE Id in :caSectionMdtIds';
        if (caSectionMdtIds.isEmpty()) {
            sectionWhereClause = ' WHERE CA_Type__c = \'' + caTypeMdt.Id + '\'';
        }
        String caSectionQueryString = 'SELECT ' + buildFieldList(objNameToQueryFieldsMap.get('CA_Section__mdt'))
                                + ' FROM CA_Section__mdt'
                                + sectionWhereClause
                                + ' ORDER BY Order__c ASC NULLS LAST';
        caSectionMdts = (List<CA_Section__mdt>)Database.query(caSectionQueryString);
        caSectionMdtIds.addAll( new Map<Id, CA_Section__mdt>(caSectionMdts).keySet());
        for (CA_Section__mdt sectionMdt : caSectionMdts)
        {
            sectionMdtId2sectionItemMdtsMap.put(sectionMdt.Id, new List<CA_Section_Item__mdt>());
        }

        String caSectionItemQueryString = 'SELECT ' + buildFieldList(objNameToQueryFieldsMap.get('CA_Section_Item__mdt'))
                                        + ' FROM CA_Section_Item__mdt '
                                        + ' WHERE CA_Section_Mdt__c IN :caSectionMdtIds'
                                        + ' ORDER BY Order__c ASC NULLS LAST';
        caSectionItemMdts = (List<CA_Section_Item__mdt>)Database.query(caSectionItemQueryString);

        Set<String> sectionFieldsToQuery = objNameToQueryFieldsMap.get('Case_Abstract_Section__c');

        //TODO query for fields based on what subset names there are
        // Set<String> sourceFieldsToQuery = objNameToQueryFieldsMap.get('Case_Abstract_Section__c');

        for (CA_Section_Item__mdt itemMdt : caSectionItemMdts)
        {
            sectionMdtId2sectionItemMdtsMap.get(itemMdt.CA_Section_Mdt__c).add(itemMdt);
            sectionFieldsToQuery.add(itemMdt.Section_Field_Name__c);
        }
        sectionFieldsToQuery.remove(null);
        objNameToQueryFieldsMap.put('Case_Abstract_Section__c', sectionFieldsToQuery);
    }

    //existing
    void queryCaseAbstract(Id recordId)
    {
        //get Professional_Name__c from polymorphic Owner field
        String typeOfString = ', TYPEOF Owner'
						+ ' WHEN User'
						    + ' THEN Name, Professional_Name__c'
                        + ' WHEN Group'
                            + ' THEN Name, DeveloperName'
                		+ ' END';

        String caseAbstractQueryString = 'SELECT '
                + buildQueryFieldList('Case_Abstract__c')
                    + typeOfString
                + ' FROM Case_Abstract__c '
                + ' WHERE Id = :recordId'
                + ' LIMIT 1';
        List<Case_Abstract__c> caseAbstracts = (List<Case_Abstract__c>)Database.query(caseAbstractQueryString);
        this.record = caseAbstracts[0];
        this.patientId = this.record.Admission__r.Patient_Account__c;

        //Presentation: Find ContentVersion based on ContentDocumentId if there is one
        if (this.record.Presentation_Document_Id__c != null)
        {
            hasPresentation = true;
            presentation = new CaseAbstractPresentation(this.record.Presentation_Document_Id__c);
            presentation.generatedBy = this.record.Presentation_Generated_By__c;
            presentation.generatedDatetime = this.record.Presentation_Generated_Date_Time__c;

        }

        // String sectionQueryString = buildQueryString('Case_Abstract_Section__c',
        //                             'Case_Abstract__c = \'' + recordId + '\'',
        //                             'Order__c ASC');
        // typeOfString = ', TYPEOF Owner'
		// 				+ ' WHEN User'
		// 				    + ' THEN Name, Professional_Name__c'
        //                 + ' WHEN Queue'
        //                     + ' THEN Name'
        //         		+ ' END';
        String sectionQueryString =  'SELECT '
                + buildQueryFieldList('Case_Abstract_Section__c')
                    + typeOfString
                + ' FROM Case_Abstract_Section__c '
                + ' WHERE Case_Abstract__c = :recordId'
                + ' ORDER BY Order__c';
        List<Case_Abstract_Section__c> queriedSectionRecords = (List<Case_Abstract_Section__c>)Database.query(sectionQueryString);

        //put sections into custom apex class objects
        for (Case_Abstract_Section__c sectionRecord : queriedSectionRecords)
        {
            Section newSection = new Section(sectionRecord, this);
            sections.add(newSection);
        }
    }

    //existing and new
    void queryAdmission() {
        this.admission = queryAdmission(this.patientId);
        // if (this.mode == 'New') {
            //get assigned clinicians and Queues to do Section Assignment on creation
            // queryAssignedClinicians();
            // queryQueues();
        // }
    }
    static Admission__c queryAdmission(Id patientId)
    {
        String admissionQueryString = buildQueryString('Admission__c',
                                    'Patient_Account__c = \'' + patientId + '\''
                                        + ' AND Is_Current_Admission__c = true',
                                    'CreatedDate DESC');
        Admission__c returnAdmission = (Admission__c)Database.query(admissionQueryString);
        CaseAbstract.admissionId = returnAdmission.Id;

        return returnAdmission;
    }
    // static void queryAssignedClinicians()
    // {
    //     assignedClinicianMap = new Map<String, Assigned_Clinician__c>();
    //     String assClinQueryString = buildQueryString('Assigned_Clinician__c',
    //                                 'Admission__c = \'' + admissionId + '\''
    //                                 + ' AND Start_Date__c <= :Date.today()'
	// 									+ ' AND (End_Date__c = null OR End_Date__c > :Date.today())',
    //                                 'Start_Date__c ASC');
    //     List<Assigned_Clinician__c> assClinicians =(List<Assigned_Clinician__c>)Database.query(assClinQueryString);
    //     for (Assigned_Clinician__c assClin : assClinicians)
    //     {
    //         assignedClinicianMap.put(assClin.Role__c, assClin);
    //     }
    // }


    //new: populate all Sections
    void populateAllSections()
    {   system.debug('populateAllSections-----');
        for (Section section : sections )
        {
            section.populateSection();
        }
    }

    public static String buildQueryString(String objectName, String baseWhereClause, String orderByClause)
    {
        // Set<String> whereExpressions = objNameToWhereExpressionsMap.get(objectName);
        String queryString = 'SELECT ' + buildQueryFieldList(objectName)
                            + ' FROM ' + objectName
                            + ' WHERE ' + baseWhereClause
                            + ' ORDER BY ' + orderByClause;
        return queryString;
    }
    static String buildQueryFieldList(String sObjectType)
    {
        Set<String> fieldNameSet = new Set<String>();
        List<Schema.SObjectField> sObjfields = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap().values();
        for( Schema.SObjectField sObjField : sObjfields )
        {
            Schema.DescribeFieldResult desField = sObjField.getDescribe();
            if(desField.isAccessible()){
                fieldNameSet.add(desField.getName());
            }
        }
        if (objNameToQueryFieldsMap.containsKey(sObjectType)) {
            fieldNameSet.addAll(objNameToQueryFieldsMap.get(sObjectType));
        }

        if (sObjectType == 'Patient_Note__c' || sObjectType == 'Case') //for Patient Notes or Treatment Plans, add all fields from related Snapshot also
        {
            List<Schema.SObjectField> snapshotfields = Schema.getGlobalDescribe().get('Snapshot__c').getDescribe().fields.getMap().values();
            for( Schema.SObjectField sObjField : snapshotfields )
            {
                Schema.DescribeFieldResult desField = sObjField.getDescribe();
                String snapshotFieldName = desField.getName();
                if(desField.isAccessible()) {
                    fieldNameSet.add('Snapshot__r.' + desField.getName());
                }
            }
        }
        return buildFieldList(fieldNameSet);
    }
    public static String buildFieldList(Set<String> fieldNameSet)
    {
        List<String> fieldNameList = new List<String>(fieldNameSet);
        String returnString = String.join(fieldNameList, ', ');
        return returnString;
    }

    public static Map<String, Set<String>> objNameToQueryFieldsMap = new Map<String, Set<String>>
    {
        //Custom Metadata
            'CA_Type__mdt' => new Set<String>{
                'Id',
                'DeveloperName',
                'MasterLabel'
            },
            'CA_Section__mdt' => new Set<String>{
                'Id',
                'DeveloperName',
                'MasterLabel',
                'Assignment_Type__c',
                'Assign_Section_To__c',
                'CA_Type__c',
                'CA_Type__r.DeveloperName',
                'CA_Type__r.MasterLabel',
                'Section_Number__c',
                'Header_Size__c',
                'Title__c',
                'Order__c'
            },
            'CA_Section_Item__mdt' => new Set<String>{
                'Id',
                'DeveloperName',
                'MasterLabel',
                'Allow_Editing__c',
                'CA_Section_mdt__c',
                'CA_Section_mdt__r.DeveloperName',
                'CA_Section_mdt__r.MasterLabel',
                'Hide_Item_Title__c',
                'Item_Type__c',
                'Order__c',
                'Order__c',
                'Section_Field_Name__c',
                'Section_Item_Number__c',
                'Source_Type__c',
                'Source_Field_Name__c',
                'Title__c',
                'Source_Query_Expression__c'
            },

        //Case Abstract sObject records
            'Case_Abstract__c' => new Set<String>{
                'Id',
                'Name',
                'OwnerId',
                // 'Owner.Name',
                'Case_Abstract_Type__c',
                'Status__c',
                'Admission__c',
                'Admission__r.Patient_Account__c',
                'Admission__r.Patient_Account__r.Name',
                'Admission__r.Patient_Account__r.Medical_Record_Number__c',
                'Admission__r.Patient_Account__r.Date_of_Birth__c'
            },
            'Case_Abstract_Section__c' => new Set<String>{},

        //Patient and Source records
            'Admission__c' => new Set<String>{
                'Id',
                'Name',
                'Admit_Date__c',
                'Patient_Account__c',
                'Patient_Account__r.Name',
                'Patient_Contact__r.Abbreviated_Name__c',
                'Stage__c'
            },
            'Assigned_Clinician__c' => new Set<String> {
                'Id',
                'User__r.Professional_Name__c'
            },
            'Patient_Note__c' => new Set<String>{
                'Id',
                'Name',
                'Type__c',
                'Snapshot__c'
                // All Snapshot fields will be added dynamically during buildQueryFieldList()
                //'Snapshot__r.Html__c', 'Snapshot__r.Initial_Case_Abstract_Html__c', 'Snapshot__r.Re_Presentation_Case_Abstract_Html__c'
            },
            'disco__Form__c' => new Set<String>{
                'Id',
                'Name',
                'Admission__c',
                'disco__Form_Template__r.Name',
                'disco__Status__c'
            },
            'disco__Answer__c' => new Set<String>{
                'Id',
                'Name',
                'disco__Long_Text_Answer__c',
                'disco__Answer__c',
                'disco__Form__r.disco__Form_Template__r.Name',
                'disco__Question__r.disco__Label__c'
            },
            'Case' => new Set<String>{
                'Id',
                'Snapshot__c',
                'Status'
            }
    };
    public static Map<String, String> objectToBaseQueryStringMap = new Map<String, String>
    {
        'Form' => buildQueryString('disco__Form__c',
                    'Admission__c = {{admissionId}} AND disco__Status__c = \'LOCKED\'',
                    'Finalized_Date_Time__c DESC'),
        'Answer' => buildQueryString('disco__Answer__c',
                    'disco__Form__r.Admission__c = {{admissionId}} AND disco__Form__r.disco__Status__c = \'LOCKED\'',
                    'disco__Form__r.Finalized_Date_Time__c DESC'),
        'Patient Note' => buildQueryString('Patient_Note__c',
                    'Admission__c = {{admissionId}} AND Status__c = \'Finalized\'',
                    'Finalized_Date_Time__c DESC'),
        'Previous CA Section Item' => buildQueryString('Case_Abstract_Section__c',
                    'Case_Abstract__c = {{caseAbstractId}}',
                    'Case_Abstract__r.Finalized_Date_Time__c DESC'),
        'Finalized Treatment Plan' => buildQueryString('Case',
                    'Admission__c = {{admissionId}} AND Status = \'Finalized\'',
                    'Finalized_Date_Time__c DESC')
    };
    public static Map<String, String> objectToDefaultTagLabelMap = new Map<String, String>
    {
        'disco__Form__c' => '{{disco__Form_Template_Name__c}} ready for review',
        'Patient_Note__c' => '{{Type__c}} in Draft'
    };

    //Perform DML on new sObject records
    public void commitNewCaseAbstract()
    {
        insert record;
        for (Case_Abstract_Section__c sectionRecord : sectionRecords)
        {
            sectionRecord.Case_Abstract__c = record.Id;
            System.debug('commit section ' + sectionRecord.Title__c + ' owner ' + sectionRecord.OwnerId);
        }
        insert sectionRecords;
    }

    public class Section
    {
        public CA_Section__mdt sectionMdt {get; set;}
        public Case_Abstract_Section__c record{ get; set; }
        public String ownerType {get; set;}
        public String ownerName {get; set;}
        public List<SectionItem> items {get; set;}
        public Boolean canSave {get; set;}
        public Boolean canRefreshFromSource {get; set;}
        public Boolean canEdit {get; set;}
        public Boolean isCompleted {get; set;}
        public String completedDateTimeString {get; set;}
        public Section()
        {
            this.ownerType = '';
            this.ownerName = '';
            this.items = new List<SectionItem>();
            this.canSave = false;
            this.canRefreshFromSource = false;
            this.canEdit=false;
            this.isCompleted=false;
            this.completedDateTimeString = '';
        }
        //create new sectionrecord
        public Section(CA_Section__mdt sectionMdt, CaseAbstract caseAbstractWrapper)
        {
            this();
            this.sectionMdt = sectionMdt;

            buildNewSectionRecord(caseAbstractWrapper);
        }
        //use existing sectionrecord
        public Section(Case_Abstract_Section__c section, CaseAbstract caseAbstractWrapper)
        {
            this();
            this.record = section;
            caseAbstractWrapper.sectionOwnerIds.add(section.OwnerId);
            if (String.valueOf(section.OwnerId).startsWith('005')) {
                this.ownerType = 'Responsible User';
                this.ownerName = (String)section.Owner.get('Professional_Name__c');
            } else {
                this.ownerType = 'Responsible Queue';
                this.ownerName = section.Owner.Name;
            }
            this.isCompleted = this.record.Status__c == 'Completed';
            if(this.record.Completed_Date_Time__c != null) {
                this.completedDateTimeString = this.record.Completed_Date_Time__c.format('MM/dd/yyyy hh:mm a, z', 'America/New_York');
            }
        }

        //constructor to use for refreshing this section
        public Section(Case_Abstract_Section__c section)
        {
            this();
            this.record = section;
            this.isCompleted = this.record.Status__c == 'Completed';
            if(this.record.Completed_Date_Time__c != null) {
                this.completedDateTimeString = this.record.Completed_Date_Time__c.format('MM/dd/yyyy hh:mm a, z', 'America/New_York');
            }
            //query for section and section Item Mdts
            //build SectionItem objects
        }

        //create new section record
        void buildNewSectionRecord(CaseAbstract caseAbstractWrapper)
        {
            this.record = new Case_Abstract_Section__c(
                Name = sectionMdt.Section_Number__c,
                Title__c = sectionMdt.Title__c,
                Status__c = 'Draft',
                CA_Section_Mdt_Id__c = sectionMdt.Id,
                Order__c = sectionMdt.Order__c
            );
            System.debug('this.record ' + this.record.Title__c + ' asstype ' + sectionMdt.Assignment_Type__c + ' assto ' + sectionMdt.Assign_Section_To__c);
            System.debug('CaseAbstract.assignedClinicianMap ' + CaseAbstract.assignedClinicianMap);
            System.debug('CaseAbstract.assignedClinicianMap get user ' + CaseAbstract.assignedClinicianMap.get('Psychotherapist')?.User__c);

            System.debug('CaseAbstract.queueMap ' + CaseAbstract.queueMap);
            if (sectionMdt.Assignment_Type__c != 'N/A'
                    && sectionMdt.Assignment_Type__c != null
                    && sectionMdt.Assign_Section_To__c != null)
            {
                this.ownerName = caseAbstractWrapper.currentUser.Professional_Name__c;
                this.record.OwnerId = caseAbstractWrapper.currentUser.Id;
                switch on sectionMdt.Assignment_Type__c {
                    when 'Assigned Clinician' {
                        this.ownerType = 'Responsible User';
                        Assigned_Clinician__c assClin = CaseAbstract.assignedClinicianMap.get(sectionMdt.Assign_Section_To__c);
                        if (assClin != null) {
                            this.ownerName = assClin.User__r.Professional_Name__c;
                            this.record.OwnerId = assClin.User__c;
                        }
                    } when 'Specified Queue' {
                        this.ownerType = 'Responsible Queue';
                        Group queue = queueMap.get(sectionMdt.Assign_Section_To__c);
                        if (queue != null) {
                            this.ownerName = queue.Name;
                            this.record.OwnerId = queue.Id;
                        }
                    }
                }
            }
        }

        public void populateSection()
        {
            system.debug('PopulateSection--------');
            this.record.Error_Messages__c = '';
            String errorList = '<ul>';
            if (this.items.isEmpty()) {
                // this.record.Error_Messages__c = '<li>Configuration Error: No Section Items defined for this Section!</li>';
                errorList += '<li>'
                                // + '<li>Configuration Error</li>'
                                + 'Configuration Error'
                                + '<ul><li>No Section Items defined for this Section!</li>'
                            + '</ul></li>';
            }
            Boolean itemErrors = false;
            for (SectionItem item : this.items)
            {
                item.populateSectionItem();
                if (item.sectionItemMdt.Allow_Editing__c){
                    this.canSave = true;
                } else {
                    this.canRefreshFromSource = true;
                }
                this.record.put(item.sectionItemMdt.Section_Field_Name__c, item.sectionFieldValue);
                if (item.errorMessage != null)
                {
                    itemErrors = true;
                    errorList += '<li>Error on Item "' + item.sectionItemMdt.Title__c +'".'
                                    + '<ul><li>' + item.errorMessage + '</li>'
                                + '</ul></li>';
                }
            }
            // if (itemErrors)
            // {
            //     errorList += '<li><ul><li>Error on Item "' + item.sectionItemMdt.Title__c +'".</li>'
            //                 + '<li>' + item.errorMessage + '</li></ul></li>';
            // }
            if (errorList != '<ul>')
            {
                this.record.Error_Messages__c = errorList + '</ul>';
            }

            //if there is no error, then save the refreshed content
            if(!itemErrors) {
                //update this.record;
            }

        }

        public void queryItemMdts()
        {
            String caSectionItemQueryString = 'SELECT ' + buildFieldList(objNameToQueryFieldsMap.get('CA_Section_Item__mdt'))
                                        + ' FROM CA_Section_Item__mdt '
                                        //+ ' WHERE CA_Section_Mdt__c IN :caSectionMdtIds'
                                        + ' WHERE CA_Section_Mdt__c = :this.record.CA_Section_Mdt_Id__c'
                                        + ' ORDER BY Order__c ASC NULLS LAST';
            List<CA_Section_Item__mdt> caSectionItemMdts = (List<CA_Section_Item__mdt>)Database.query(caSectionItemQueryString);
        }
    }

    public class SectionItem
    {
        public CA_Section_Item__mdt sectionItemMdt {get; set;}
        //representationCATargetId is set to the latest CA associated with current admission when caTypeString == 'Re_Presentation_Case_Abstract'
        public Id representationCATargetId {get; set;}
        public String sectionFieldValue {get; set;}
        public String contentVersionId {get; set;}
        // String sourceLabel = '';
        String errorMessage;
        public SectionItem()
        {
            this.sectionFieldValue = null;
            this.contentVersionId = null;
            this.representationCATargetId = null;
        }
        public SectionItem(CA_Section_Item__mdt sectionItemMdt)
        {
            this();
            this.sectionItemMdt = sectionItemMdt;
        }

        public void populateSectionItem()
        {
            // String returnErrorListItem = '';
            //if (this.sectionItemMdt.Source_Type__c != 'None' && this.sectionItemMdt.Source_Query_Expression__c != null)
            if (this.sectionItemMdt.Source_Type__c != 'None')
            {
                System.debug('populateSectionItem Title__c ' + this.sectionItemMdt.Title__c + ' Source_Type__c ' + this.sectionItemMdt.Source_Type__c);
                // {{admissionId}}
                String baseQueryString = CaseAbstract.objectToBaseQueryStringMap.get(this.sectionItemMdt.Source_Type__c);

                sObject sourceObject = querySourceRecord(CaseAbstract.objectToBaseQueryStringMap.get(this.sectionItemMdt.Source_Type__c));
                if (sourceObject != null)
                {
                    populateSectionFieldValue(sourceObject);
                } else {
                    // this.errorMessage = 'IRIS was unable to find a source for this item'
                    //         + ' ( ' + this.sectionItemMdt.Item_Type__c + ' from ' + this.sectionItemMdt.Source_Type__c + ' record ). '
                    //         + ' Click "Refresh From Source" button to try again.';
                    this.errorMessage = 'This item is not yet finalized.  Once finalized, click "Refresh From Source" button';
                    // returnErrorListItem = '<li>IRIS was unable to find a source for <strong>' + this.sectionItemMdt.Title__c + '</strong>'
                    //         + ' ( ' + this.sectionItemMdt.Item_Type__c + ' from ' + this.sectionItemMdt.Source_Type__c + ' record ).'
                    //         + '<br/>Click "Refresh From Source" button to try again.</li>';
                }
            }
            // return returnErrorListItem;
        }

        sObject querySourceRecord(String baseQueryString)
        {
            sObject returnObject;

            System.debug('querySourceRecord baseQueryString ' + baseQueryString);
            System.debug('querySourceRecord this.sectionItemMdt.Source_Query_Expression__c ' + this.sectionItemMdt.Source_Query_Expression__c);
            System.debug('CaseAbstract.admissionId ' + CaseAbstract.admissionId);
            System.assertNotEquals(null, CaseAbstract.admissionId, 'CaseAbstract.admissionId ' + CaseAbstract.admissionId);
            String fixedAdmissionBaseQueryString = baseQueryString.replace('{{admissionId}}', '\'' + CaseAbstract.admissionId + '\'');
            System.debug('this.representationCATargetId =' + this.representationCATargetId);
            if(this.representationCATargetId != null) {
                fixedAdmissionBaseQueryString = fixedAdmissionBaseQueryString.replace('{{caseAbstractId}}', '\'' + this.representationCATargetId + '\'');
            }
            String queryString = fixedAdmissionBaseQueryString;
            //representationCATargetId is set to the latest CA associated with current admission when caTypeString == 'Re_Presentation_Case_Abstract'

            if (this.sectionItemMdt.Source_Query_Expression__c != null) {
                queryString = fixedAdmissionBaseQueryString.replace(' ORDER BY', ' AND ' + this.sectionItemMdt.Source_Query_Expression__c + ' ORDER BY');
            }
            queryString += ' LIMIT 1';
            system.debug('query string='+ queryString);
            //TODO remove troubleshooting process log and try/catch
            try {
                List<sObject> sourceObjectList = Database.query(queryString);
                system.debug('querySourceRecord this.sectionItemMdt.Source_Type__c=' + this.sectionItemMdt.Source_Type__c);
                system.debug('querySourceRecord this.sectionItemMdt.title__c=' + this.sectionItemMdt.title__c);
                system.debug('querySourceRecord this.sectionItemMdt.Source_Query_Expression__c=' + this.sectionItemMdt.Source_Query_Expression__c);
                system.debug('querySourceRecord sourceObjectList.isEmpty=' + sourceObjectList.isEmpty());

                if (!sourceObjectList.isEmpty())
                {
                    returnObject = sourceObjectList[0];

                    if (this.sectionItemMdt.Source_Type__c == 'Previous CA Section')
                    {
                        system.debug('querySourceRecord returnObject.title=' + returnObject.get('Title__c'));
                        returnObject = findPreviousCaSection(sourceObjectList);
                    }
                }
            } catch (Exception e) {
                ProcessLogging.quickProcessLog('Ignore (Jeremy Testing querySourceRecord)', e.getStackTraceString() , 'Title: ' + this.sectionItemMdt.Title__c + '\nobject: ' + this.sectionItemMdt.Source_Type__c + '\nmessage:\n' + e.getMessage() + '\n\nqueryString:\n' + queryString);
            }
            return returnObject;
        }

        Case_Abstract_Section__c findPreviousCaSection(List<sObject> queriedSections)
        {
            Case_Abstract_Section__c returnSection = new Case_Abstract_Section__c();
            String sourceFieldName = this.sectionItemMdt.Source_Field_Name__c;
            //String sourceFieldValue = (String)returnSection.get(sourceFieldName);
            if (sourceFieldName != null)
            {
                for (sObject section : queriedSections)
                {
                    if (section.get(sourceFieldName) != null)
                    {
                        returnSection = (Case_Abstract_Section__c)section;
                        break;
                    }
                }
            }
            return returnSection;
        }
        void populateSectionFieldValue(sObject sourceObject) //TODO this.sectionItemMdt.Source_Type__c
        {
            //TODO: If Previous Case Abstract Section Item
            //Search for previous CA, check for a Section that has that specific field populated
            Object fieldValue = getFieldValue(sourceObject, this.sectionItemMdt.Source_Field_Name__c);
            if (fieldValue != null && fieldValue != '')
            {
                if ( this.sectionItemMdt.Item_Type__c  == 'Rich Text Area')
                {
                    // section.record.put(item.sectionItemMdt.Section_Field_Name__c, (String)fieldValue);
                    this.sectionFieldValue = (String)fieldValue;
                } else if (this.sectionItemMdt.Item_Type__c  == 'Digital File')
                {
                    List<Map<String, String>> parsedAnswer = (List<Map<String, String>>)JSON.deserialize((String)fieldValue, List<Map<String, String>>.class);
                    String htmlLinkToFile = '<a href="/sfc/servlet.shepherd/version/download/'
                            + parsedAnswer[0].get('versionID') + '" style="font-size: 14px;">'
                            + parsedAnswer[0].get('docTitle') + '</a>';
                    // section.record.put(item.sectionItemMdt.Section_Field_Name__c,  htmlLinkToFile);
                    this.sectionFieldValue = htmlLinkToFile;
                }
            }
        }
// <img src="/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId={!attachment}"/>
        Object getFieldValue(sObject record, String fieldName) //recursive to use relationships
        {
            if (fieldName.contains('.'))
            {
                String objectName = fieldName.substringBefore('.');
                String newFieldName = fieldName.substringAfter('.');
                record = (sObject)record.getSobject(objectName);
                if (record == null) return '';

                return getFieldValue(record, newFieldName);
            }
            Object result = record.get(fieldName);
            if (result == null) result = '';

            return result;
        }
    }



    //return existing Case Abstract with sections and everything (used for record page)
    @AuraEnabled
    public static String getCaseAbstract(Id recordId)
    {
        Savepoint sp = Database.setSavepoint();
        String returnString = '';
        try
        {
            CaseAbstract existingCA = new CaseAbstract(recordId);
            returnString = JSON.serialize(existingCA);
        } catch (Exception e)
        {
            returnString = handleException('CaseAbstract.getCaseAbstract()', sp, e, 'Error getting Case Abstract!');
        }
        return returnString;
    }

    @AuraEnabled
    public static String finalizeCaseAbstract(Id recordId)
    {
        Savepoint sp = Database.setSavepoint();
        String returnString = 'Success';
        try
        {
            Case_Abstract__c caExisting = [SELECT Id, Finalized_By__c, Finalized_Date_Time__c FROM Case_Abstract__c WHERE Id = :recordId];
            Case_Abstract__c ca = new Case_Abstract__c(Id=recordId, Status__c='Finalized');
            if(caExisting.Finalized_Date_Time__c == null) {
                ca.Finalized_By__c=userInfo.getUserId();
                ca.Finalized_Date_Time__c=Datetime.now();
            }
            update ca;
            makeFinalizedPresentation(recordId);
        } catch (Exception e)
        {
            returnString = handleException('CaseAbstract.getCaseAbstract()', sp, e, 'Error getting Case Abstract!');
        }
        return returnString;
    }

    @AuraEnabled
    public static String reopenCaseAbstract(Id recordId)
    {
        Savepoint sp = Database.setSavepoint();
        String returnString = 'Success';
        try
        {
            Case_Abstract__c ca = new Case_Abstract__c(Id=recordId, Status__c='Draft');
            update ca;
        } catch (Exception e)
        {
            returnString = handleException('CaseAbstract.getCaseAbstract()', sp, e, 'Error getting Case Abstract!');
        }
        return returnString;
    }

    //@future
    public static void makeFinalizedPresentation(String caseAbstractId)
	{
        CaseAbstractPresentationController.generatePDF(caseAbstractId);
    }

    //called from caseAbstractSectionLwc
    @AuraEnabled
    public static String refreshSection(String sectionString)
    {
        Section refreshingSection = (Section)JSON.deserialize(sectionString, CaseAbstract.Section.class);
        String sectionId = refreshingSection.record.Id;
        CaseAbstract.admissionId = [SELECT Case_Abstract__r.Admission__c
                                    FROM Case_Abstract_Section__c
                                    WHERE Id = :sectionId
                                    LIMIT 1].Case_Abstract__r.Admission__c;

        String sectionQueryString = buildQueryString('Case_Abstract_Section__c',
                                    'Id = :sectionId', 'CreatedDate DESC');
        List<Case_Abstract_Section__c> sections =(List<Case_Abstract_Section__c>)Database.query(sectionQueryString);
        refreshingSection.record = sections[0];
        system.debug('itm_Summary_and_Recommendations_Org__c size = ' + sections.size());
        system.debug('itm_Summary_and_Recommendations_Org__c = ' + refreshingSection.record.itm_Summary_and_Recommendations_Org__c);
        refreshingSection.populateSection();
        Case_Abstract_Section__c sec = new Case_Abstract_Section__c(Id = refreshingSection.record.Id);
        for (SectionItem item : refreshingSection.items) {
            if (!item.sectionItemMdt.Allow_Editing__c){
                sec.put(item.sectionItemMdt.Section_Field_Name__c, item.sectionFieldValue);
            }
        }
        update sec;

        //TODO
        return JSON.serialize(refreshingSection);
    }

    //called from caseAbstractSectionLwc
    @AuraEnabled
    public static Case_Abstract_Section__c saveSection(String sectionString)
    {
        system.debug('saveSection payload =' + sectionString);
        Map<String, Object> saveSection = (Map<String, Object>)JSON.deserializeUntyped(sectionString);
        Case_Abstract_Section__c section = new Case_Abstract_Section__c();
        for(String key: saveSection.keyset()) {
            try{
                section.put(key, saveSection.get(key));
            } catch (Exception e) {
                system.debug(e.getMessage());
            }
        }
        if('Completed'.equalsIgnoreCase(section.Status__c)) {
            section.Completed_By__c = userInfo.getUserId();
            section.Completed_Date_Time__c = DateTime.now();
        }
        system.debug('saveSection section to update =' + section);
        try{
            update section;
        }catch(Exception e) {
            system.debug(e.getMessage());
        }

        //TODO
        return [SELECT Id, Title__c, Completed_Date_Time__c, Completed_By_Professional_Name__c, Status__c FROM Case_Abstract_Section__c WHERE Id = :section.Id];
    }

    //called from caseAbstractSectionLwc
    @AuraEnabled
    public static String setStatus(String sectionString)
    {
        Section refreshingSection = (Section)JSON.deserialize(sectionString, CaseAbstract.Section.class);
        //Map<String, Object> saveSection = (Map<String, Object>)JSON.deserializeUntyped(sectionString);
        Case_Abstract_Section__c section = refreshingSection.record;
        // for(String key: saveSection.keyset()) {
        //     try{
        //         section.put(key, saveSection.get(key));
        //     } catch (Exception e) {
        //         system.debug(e.getMessage());
        //     }
        // }
        if('Completed'.equalsIgnoreCase(refreshingSection.record.Status__c)) {
            refreshingSection.record.Completed_By__c = userInfo.getUserId();
            refreshingSection.record.Completed_Date_Time__c = DateTime.now();
        }

        system.debug('saveSection section to update =' + refreshingSection.record);
        try{
            update refreshingSection.record;
        }catch(Exception e) {
            system.debug(e.getMessage());
        }

        return refreshSection(sectionString);
    }

    //called from caseAbstractSectionLwc
    @AuraEnabled
    public static String setOwner(String sectionId, String ownerId)
    {
        system.debug('saveSection sectionId =' + sectionId);
        system.debug('saveSection ownerId =' + ownerId);
        Case_Abstract_Section__c section = new Case_Abstract_Section__c(Id = sectionId,
                                                    OwnerId=ownerId);
        update section;

        section = [SELECT Id, OwnerId, TYPEOF Owner
                                            WHEN User
                                                THEN Name, Professional_Name__c
                                            WHEN Group
                                                THEN Name, DeveloperName
                                            END
                                            FROM Case_Abstract_Section__c WHERE Id= :sectionId];
        return JSON.serialize(section);
    }


    @InvocableMethod(label='Create Case Abstract'
            category='Case Abstract'
            description='Generates a Case Abstract and Case Abstract Sections for specified Patient based on Mdts, can be Initial Case Conference or Re-Presentation Case Conference.')
    public static List<String> createNewCaseAbstractInvocable(List<CaseAbstractRequest> caRequests)
    {
        system.debug('list of CaseAbstractRequest=' + caRequests);
        CaseAbstractRequest caRequest = caRequests[0];
        system.debug('caRequest=' + caRequest);
        Id patientId = (Id)caRequest.patientId;
        system.debug('patientId=' + patientId);
        String caType = caRequest.caType;
        system.debug('caType=' + caType);

        String caseAbstractId = createNewCaseAbstract(patientId, caType, true);
        System.assert(caseAbstractId.length() <= 18, caseAbstractId);
        system.debug('caseAbstractId=' + caseAbstractId);
        return new List<String> { caseAbstractId };
    }

    public class CaseAbstractRequest //used for invocable method
    {
        @InvocableVariable(label='Patient Account Id' required=true)
        public String patientId;

        @InvocableVariable(label='Case Abstract Type' description='E.g. "Initial_Case_Abstract" or "Re_Presentation_Case_Abstract"' required=true)
        public String caType;
    }

    //called by invocable
    public static String createNewCaseAbstract(Id patientId, String caType, Boolean returnRecordIdOnly)
    {
        Savepoint sp = Database.setSavepoint();
        String returnString = '';
        try
        {
            CaseAbstract newCA = new CaseAbstract(patientId, caType);
            newCA.commitNewCaseAbstract();

            returnString = JSON.serialize(newCA);
            if (returnRecordIdOnly)
            {
                returnString = newCA.record.Id;
            }
        } catch (Exception e)
        {
            returnString = handleException('CaseAbstract.createNewCaseAbstract()', sp, e, 'Error creating Case Abstract!');

        }
        return returnString;
    }

    @testVisible
    static String handleException(String processName, System.Savepoint sp, Exception e, String messageIntro)
    {
        Database.rollBack(sp);
        ProcessLogging.quickProcessLog(processName, e.getStackTraceString(), e.getMessage());

        // Map<String, String> returnMap = new Map<String, String>
        // {
        //     'processName' => processName,
        //     'message' => messageIntro + ' \nException thrown in ' + processName + ': \n' + e.getMessage(),
        //     'stackTrace' => e.getStackTraceString()
        // };
        // return JSON.serialize(returnMap);
        return 'There was an error creating the Case Abstract: ' + e.getMessage();
    }




}