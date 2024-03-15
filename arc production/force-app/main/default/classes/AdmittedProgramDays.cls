public class AdmittedProgramDays 
{
    public static Boolean deleteExistingProgDays = false;
    public static String admittedProgramQueryString = 
            'SELECT Id, Admission__r.Current_Admitted_Program__c, Admission__r.Patient_Account__c, Admission__r.Last_Calculated_Program_Days__c,'
                    + ' Start_Date__c, End_Date__c, Admission__c,'
                + ' (SELECT Id, Start_Date_Time__c, End_Date_Time__c, Status__c'
                    + ' FROM Admitted_Program_Statuses__r)'
            + ' FROM Admitted_Program__c';

    @TestVisible
    private static datetime now{
        get {if(now==null){now = system.now();} return now;}
        set;
    }

    public static Integer NUM_FUTURE_DATES_FOR_APDS = 0; // may change
    public static Integer NUM_DAYS_TO_CHECK_LASTMODIFIED = 3; // will check this many days in the past to see what changed, to recalc

    List<Admitted_Program_Day__c> apdsToUpsert = new List<Admitted_Program_Day__c>();
    List<Admitted_Program_Day__c> apdsToDelete = new List<Admitted_Program_Day__c>();
    Map<Id, Admission__c> admsToUpdateMap = new Map<Id, Admission__c>();


    @TestVisible
    Set<Id> admissionIds = new Set<Id>{};

    Map<Id,Admitted_Program__c> admittedProgramsMap = new Map<Id,Admitted_Program__c>{};
    Map<Id,Id> admittedProgramIdToAdmissionId = new Map<Id,Id>{};
    Map<string,Set<string>> apDateStatusesMap = new Map<string,Set<string>>{};
    Map<Id,Set<Date>> calculatedDatesForAdmittedProgramsMap = new Map<Id,Set<date>>();


    Map<Id,Set<Date>> currentDatesForAdmittedProgramsMap = new Map<Id,Set<date>>();
    Map<Id,Admitted_Program_Day__c[]> apdsByApMap = new Map<Id,Admitted_Program_Day__c[]>();
    Map<Id,Admitted_Program_Day__c> currentAdmittedProgramDays = new Map<Id,Admitted_Program_Day__c>{};


    public AdmittedProgramDays(Set<Id> admissionIds)
    {
        this.admissionIds= admissionIds;

        queryAdmittedPrograms(this.admissionIds);

        calculateAPDS();

        getCurrentDates();

        compareAlt();
        
    }

    @TestVisible
    void queryAdmittedPrograms(Set<Id> admissionIds)
    {
        String qString = admittedProgramQueryString + ' WHERE Admission__c IN :admissionIds ORDER BY Start_Date__c ASC';
        admittedProgramsMap = new Map<Id,Admitted_Program__c>((List<Admitted_Program__c>)Database.query(qString));
    }

    /**
     * @description commit changes after calculations
     */
    public void commitChanges()
    {
        upsert apdsToUpsert;
        delete apdsToDelete;
        update admsToUpdateMap.values();
    }

    public CalculatedAdmittedProgramDay[] calculatedAdmittedProgramDayList = new CalculatedAdmittedProgramDay[]{};

    @TestVisible
    void calculateAPDS()
    {
        AdmittedProgram[] wrapperLst = new AdmittedProgram[]{};
        for(Admitted_Program__c ap : admittedProgramsMap.values())
        {
            AdmittedProgram apWrapper = new AdmittedProgram(ap);
            Date startDate = ap.Start_Date__c;
            Date endDate = (ap.End_Date__c != null)? ap.End_Date__c : System.today().addDays(NUM_FUTURE_DATES_FOR_APDS);

            calculatedDatesForAdmittedProgramsMap.put(ap.Id, new Set<Date>( DateUtils.getAllDaysInRange(startDate, endDate) ) );
            apWrapper.calculatedDates.addAll( calculatedDatesForAdmittedProgramsMap.get(ap.Id) );
            for(Admitted_Program_Status__c aps : ap.Admitted_Program_Statuses__r )
            {
                if(aps.Start_Date_Time__c != null && aps.Start_Date_Time__c <= system.now())
                {
                    calculatedDatesForAdmittedProgramsMap.get(ap.Id).addAll( DateUtils.getAllDaysInRange(
                        aps.Start_Date_Time__c.date(),
                        aps.End_Date_Time__c != null? aps.End_Date_Time__c.date() : endDate
                    ) );
                    apWrapper.calculatedDates.addAll( calculatedDatesForAdmittedProgramsMap.get(ap.Id) );
                }

                //calc status list by date
                for(Date d : calculatedDatesForAdmittedProgramsMap.get(ap.Id))
                {
                    if(d >= aps.Start_Date_Time__c.date() && ( aps.End_Date_Time__c==null || d <= aps.End_Date_Time__c.date() ) )
                    {
                        String key = AdmittedProgramDaysUtils.getKey(ap.Id,d);
                        if( !apDateStatusesMap.containsKey(key) ){
                            apDateStatusesMap.put(key, new Set<string>());
                        }
                        apDateStatusesMap.get(key).add(aps.Status__c);
                    }
                }
            }
            
            wrapperLst.add(apWrapper);
            for(Date d : apWrapper.calculatedDates )
            {
                CalculatedAdmittedProgramDay capd = new CalculatedAdmittedProgramDay();
                capd.admissionId = ap.Admission__c;
                capd.admittedProgramId = ap.Id;
                capd.patientId = ap.Admission__r.Patient_Account__c;
                capd.targetDate = d;
                if( d == ap.Start_Date__c ){
                    capd.type = 'Starting';
                }else if (d == ap.End_Date__c && ap.End_Date__c != null){
                    capd.type = 'Ending';
                }else{
                    capd.type = 'Full Day';
                }
                string key = AdmittedProgramDaysUtils.getKey(ap.Id,d);
                capd.status = string.join(new list<string>(apDateStatusesMap.get( key )), ',');
                CalculatedAdmittedProgramDayList.add(capd);
            }
            if (ap.Admission__r.Last_Calculated_Program_Days__c != System.today())
            {
                admsToUpdateMap.put(ap.Admission__c, new Admission__c(
                    Id = ap.Admission__c,
                    Last_Calculated_Program_Days__c = System.today()
                ));
            }
        }
    }


    /**
     * @description gets the current admitted program days to user later to compare
     */
    @TestVisible
    public void getCurrentDates(){
        currentAdmittedProgramDays = new Map<Id,Admitted_Program_Day__c>([
            SELECT Id, Admitted_Program__c, Admission__c, Date__c, Patient_Account__c, Type__c, Status__c,
                    Admitted_Program__r.Start_Date__c, Admitted_Program__r.End_Date__c
            FROM Admitted_Program_Day__c
            WHERE Admission__c IN :admissionIds
                AND Admitted_Program__c != null
        ]);
        if (deleteExistingProgDays)
        {
            apdsToDelete.addAll(currentAdmittedProgramDays.values());
        } else 
        {
            for(Admitted_Program_Day__c apd : currentAdmittedProgramDays.values()){
                if(!currentDatesForAdmittedProgramsMap.containsKey(apd.Admitted_Program__c)){
                    currentDatesForAdmittedProgramsMap.put(apd.Admitted_Program__c, new Set<Date>());
                }
                currentDatesForAdmittedProgramsMap.get(apd.Admitted_Program__c).add(apd.Date__c);

                if(!apdsByApMap.containsKey(apd.Admitted_Program__c)){
                    apdsByApMap.put(apd.Admitted_Program__c, new Admitted_Program_Day__c[]{});
                }
                apdsByApMap.get(apd.Admitted_Program__c).add(apd);
            }
        }
    }


     /**
     * @description comparing values to see which to update, which to insert and which to delete
     */
    @TestVisible
    void compareAlt()
    {
        Map<Id,Admitted_Program_Day__c> updateMap = new Map<Id,Admitted_Program_Day__c>();
        //comparing to calculate to upsert
        for(CalculatedAdmittedProgramDay capd : CalculatedAdmittedProgramDayList)
        {
            Boolean matched = false;
            if (!deleteExistingProgDays)
            {
                for( Admitted_Program_Day__c apd : currentAdmittedProgramDays.values()){
                    if(  capd.targetDate == apd.Date__c && capd.admissionId == apd.Admission__c && capd.admittedProgramId == apd.Admitted_Program__c ){
                        matched = true;
                        if( apd.Type__c != capd.type ){
                            if(!updateMap.containsKey(apd.Id)){ updateMap.put(apd.Id,new Admitted_Program_Day__c(Id=apd.Id)); }
                            updateMap.get(apd.Id).Type__c = capd.type;
                        }
                        break;
                    }
                }
            }
            if(matched != true){
                apdsToUpsert.add( capd.convert() );
            }
        }
        for(Admitted_Program_Day__c apd : updateMap.values()){
            apdsToUpsert.add( apd );
        }

        //comparing to calculate to delete
        if (!deleteExistingProgDays)
        {
            for(Admitted_Program_Day__c apd : currentAdmittedProgramDays.values())
            {
                Boolean found = false;
                for (CalculatedAdmittedProgramDay capd : CalculatedAdmittedProgramDayList){
                    if(  capd.targetDate == apd.Date__c && capd.admissionId == apd.Admission__c && capd.admittedProgramId == apd.Admitted_Program__c ){
                        found = true;
                        break;
                    }
                }
                if(!found ){
                    apdsToDelete.add(apd);
                }
            }
        }
    }


    /**
     * @description method that will be called by SIP_AdmittedProgramDays class
     */
    public static void syncAdmittedProgramDays()
    {
        Set<Id> nullIds;
        syncAdmittedProgramDays(nullIds);
    }
    public static void syncAdmittedProgramDays(Set<Id> admissionIds)
    {
        // Date startDate = now.date().addDays(-NUM_DAYS_TO_CHECK_LASTMODIFIED);

        Set<Id> admissionIdsFromAggregate = new Set<Id>();
        String aggregateQueryString = 'SELECT Admission__c admId'
                                    + ' FROM Admitted_Program__c'
                                    + ' WHERE Admission__r.Stage__c in (\'Admitted\', \'Discharged\')'
                                   		+ ' AND (Admission__r.Last_Calculated_Program_Days__c = null OR Admission__r.Last_Calculated_Program_Days__c <= TODAY)';
        if (admissionIds != null)
        {
            aggregateQueryString += ' AND Admission__c IN :admissionIds';
        }                                    
        aggregateQueryString += ' GROUP BY Admission__c';
        List<AggregateResult> ars = (List<AggregateResult>)Database.query(aggregateQueryString);
        for (AggregateResult ar : ars)
        {
            admissionIdsFromAggregate.add((Id)ar.get('admId'));
        }    

        List<Admission__c> adms = [SELECT Id, Stage__c, Last_Calculated_Program_Days__c, Discharge_Date__c, LastModifiedDate 
                                FROM Admission__c 
                                WHERE Id IN :admissionIdsFromAggregate];
		Set<Id> syncAdmIds = new Set<Id>();
		for (Admission__c a : adms)
        {
            if (a.Stage__c == 'Admitted'
            	|| a.Last_Calculated_Program_Days__c == null 
                || a.Discharge_Date__c == null
                || a.Last_Calculated_Program_Days__c <= a.Discharge_Date__c 
                || a.LastModifiedDate > a.Last_Calculated_Program_Days__c)
            {
            	syncAdmIds.add(a.Id);
            }
        }
        if (syncAdmIds.size() == 0) return;

        AdmittedProgramDays apd = new AdmittedProgramDays(syncAdmIds);

        apd.commitChanges();
    }

    //admitted program trigger
    // public static void updateProgramDays(List<Admitted_Program__c> triggerNew, Map<Id, Admitted_Program__c> triggerOldMap)
    // {
    //     Boolean isInsert = (triggerOldMap == null);
    //     List<Admitted_Program__c> apsTofixDates = new List<Admitted_Program__c>();
	// 	for(Admitted_Program__c ap: triggerNew)
    //     {
    //         if (isInsert )
    //         {
    //             //collect ap
    //         } else if (triggerNew != null)
    //         {
    //             //check for changes to important fields: Start_Date__c, End_Date__c, Current_Status__c
    //             //add to collection for processing

    //         } else //delete
    //         {
    //             //delete all program days and Statuses related to this admProg
    //         }
    //     }

        //insert
            // there are no statuses yet
            //collect dates
            //create prDay for each date
            //insert prDays

        //update
            //query for admProgs with sub of progDays and sub of Statuses
            //for each ap
                //collect admProg dates in set
                //for each status
                    //collect status dates
                //for each admProg date
                    //make program Day with admProg and status
                    //check for and compare to existing progDay for same date
                    //if different, copy Id to new prDay and add to upsert list
                    //if same, continue

    // }

    public class AdmittedProgram
    {
        public Admitted_Program__c obj;
        public Set<Date> existingDates;
        public Set<Date> calculatedDates;
        public AdmittedProgram(Admitted_Program__c ap){
            this.obj = ap;
            this.existingDates = new Set<Date>();
            this.calculatedDates = new Set<Date>();
        }
    }

    public class CalculatedAdmittedProgramDay
    {
        public Id admissionId;
        public Id admittedProgramId;
        public Id patientId;
        public string type;
        public Date targetDate;
        public string status;
        public Admitted_Program_Day__c convert(){
            return new Admitted_Program_Day__c(
                Admission__c = admissionId,
                Admitted_Program__c = admittedProgramId,
                type__c  = type,
                date__c = targetDate,
                status__c = status,
                Patient_Account__c = patientId
            );
        }
    }


}