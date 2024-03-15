public without sharing class SnapshotHelper {

    public static final String FIELD_TEMPLATE = '<td><strong>{0}:</strong></td><td>{1}</td>';
    public static final String DATETIMEFORMAT = 'MM/dd/yyyy h:mm a z';
    public static final String DATEFORMAT = 'MM/dd/yyyy';
    public static final String TIMEZONE =  'America/New_York';
    public static Map<Id,Account> accountMap = new Map<Id,Account>();
    private static Map<Id, Assigned_Clinician__c[]> assignedClinitiansByPatientIdMap = new Map<Id, Assigned_Clinician__c[]>();
    private static Map<String,String> getTeamMembersByRoleCache = new Map<String,String>();

    @TestVisible
    public static User currentUser{
        get{
            if( currentUser == null ){
                currentUser = [Select Name,Professional_Name__c from User where Id=:userinfo.getUserId()];
            }
            return currentUser;
        }
        private set;
    }

    public static Domain__mdt[] domains {
        get{
            if (domains == null){
                domains = [SELECT Id,Label,DeveloperName,Domain_Number__c,Active__c,Label__c FROM Domain__mdt WHERE Active__c=true order by Domain_Number__c];
            }
            return domains;
        }
        private set;
    }

    public static Map<Id,Domain__mdt> domainsMap {
        get{
            if( domainsMap == null ){
                domainsMap = new Map<Id,Domain__mdt>( domains );
            }
            return domainsMap;
        }
        private set;
    }

    public static String getTeamMembersByRole(Id patientId, String roleName){
        String key = ''+patientId+'-'+roleName;
        if ( !getTeamMembersByRoleCache.containsKey(key)){
            String[] members = new String[]{};
            Assigned_Clinician__c[] clinitians = assignedClinitiansByPatientIdMap.get(patientId);
            if(clinitians != null && !clinitians.isEmpty()){
                for(Assigned_Clinician__c ac : clinitians){
                    if(ac.Role__c == roleName && String.isNotEmpty(ac.Professional_Name__c)){
                        members.add(ac.Professional_Name__c);
                    }
                }
            }
            getTeamMembersByRoleCache.put(key,String.join(members,', '));
        }
        return getTeamMembersByRoleCache.containsKey(key)? getTeamMembersByRoleCache.get(key) : '';
    }

    public static String getAllTeamMembersByRole(id patientId){
        String[] members = new String[]{};
        return String.join(members,', ');
    }

    public static void fillMaps(set<id> patientIds){
        getTeamMembersByRoleCache.clear();

        //Assigned Clinitians
        for (Assigned_Clinician__c ac : [Select Id, Patient_Account__c, Professional_Name__c,Role__c FROM Assigned_Clinician__c where Patient_Account__c in :patientIds]){
            if( !assignedClinitiansByPatientIdMap.containsKey(ac.Patient_Account__c) ){
                assignedClinitiansByPatientIdMap.put(ac.Patient_Account__c, new List<Assigned_Clinician__c>());
            }
            assignedClinitiansByPatientIdMap.get(ac.Patient_Account__c).add(ac);
        }

        accountMap = new Map<id,account>([Select Id,Name,Current_Admission__r.Team__c from Account where id in :patientIds]);
    }

    public class HtmlFooterMapping{
        public String fieldLabel;
        public String fieldValue;
        public HtmlFooterMapping(){}
        public HtmlFooterMapping(String fieldLabel, String fieldValue){
            this.fieldValue = fieldValue;
            this.fieldLabel = fieldLabel;
        }
    }
    
    public static String getHtmlFooter(List<HtmlFooterMapping> mappings ) 
    {
        return getHtmlFooter(new Account(), mappings);
    }
    public static String getHtmlFooter(Account patient, HtmlFooterMapping[] mappings ) {
        String html = '<table>';
        if(mappings != null){
            for(HtmlFooterMapping m : mappings){
                if( m.fieldLabel == 'SEPARATOR' ){
                    html += '<tr>';
                    html += String.format('<td>{0}</td><td>{1}</td>', new object[]{'&nbsp;', '&nbsp;'});
                    html += '</tr>';
                }else if( String.isNotBlank(m.fieldValue) ){
                    html += '<tr>';
                    html += String.format(SnapshotHelper.FIELD_TEMPLATE, new object[]{m.fieldLabel, m.fieldValue});
                    html += '</tr>';
                }
            }
        }
        html += '</table>';
        html += '<br />';
        return html;
    }

    static map<set<id>, set<String>> AllowedDisplinesCache = new Map<set<id>, set<String>> ();

    public static set<String> getAllowedDisplines(set<id> patientIds){
        if(!AllowedDisplinesCache.containsKey(patientIds)){
            AllowedDisplinesCache.put(patientIds,new set<String>());
            set<String> roles = new set<String>();
            for(Assigned_Clinician__c ac : [
                select Role__c
                from Assigned_Clinician__c where
                Patient_Account__c in :patientIds and
                User__c=:userinfo.getuserid() and Role__c != null
            ]){
                roles.add(ac.Role__c);
            }
            if(roles.size() > 0){
                for(Discipline_Intervention__mdt dt: [
                    Select
                    Discipline__c, Assigned_Clinician_Role__c,Intervention__c,Must_Specify__c
                    from Discipline_Intervention__mdt where
                    Assigned_Clinician_Role__c in :roles
                ]){
                    AllowedDisplinesCache.get(patientIds).add( dt.Discipline__c );
                }
            }
        }
        return AllowedDisplinesCache.containsKey(patientIds)? AllowedDisplinesCache.get(patientIds) : new set<String>();
    }

    public static String getHtmlElement(String label, String value){
        String html = '';
        html += '<div class="slds-form-element">';
            html += String.format('<label class="slds-form-element__label" ><b>{0}</b></label>', new String[]{ label });
            html += String.format('<div class="slds-form-element__control" >{0}</div>',new String[]{ value });
        html += '</div>';
        return html;
    }

    public static String getHtmlGoalTable(Goal__c goal, Map<Id,EGO_Rating__c> ratingByGoalIdMap, boolean showComments){
        String html = '';
        String targetDate = ParserHelper.ToDateTimeFormat(goal, 'Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
        String metDiscontinued = ParserHelper.ToDateTimeFormat(goal, 'Met_Discontinued_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
        String dateToShow = String.isNotBlank(metDiscontinued)? metDiscontinued : targetDate;
        String dateLabel = String.isNotBlank(metDiscontinued)? 'Met/Discontinued Date' : 'Target Date';
        html = '<table>';
            html += '<tr>';
                html += '<th class="slds-col slds-size_2-of-6">Goal</th>';
                html += '<th class="slds-col slds-size_1-of-6">Date Added</th>';
                html += '<th class="slds-col slds-size_1-of-6">Previous Target Date</th>';
                html += String.format('<th class="slds-col slds-size_1-of-6">{0}</th>', new String[]{ dateLabel });
                html += '<th class="slds-col slds-size_1-of-6">Status</th>';
            html += '</tr>';
            html += '<tr>';
                html += String.format('<td>{0}</td>',new String[]{ParserHelper.ToString(goal, 'Label__c')});
                html += String.format('<td>{0}</td>',new String[]{ParserHelper.ToDateTimeFormat(goal, 'Date_Added__c', SnapshotHelper.DATEFORMAT, 'UTC')});
                html += String.format('<td>{0}</td>',new String[]{ParserHelper.ToDateTimeFormat(goal, 'Continued_From_Goal__r.Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC')});
                html += String.format('<td>{0}</td>',new String[]{ dateToShow });
                html += String.format('<td>{0}</td>',new String[]{ParserHelper.ToString(goal, 'Status__c')});
            html += '</tr>';
            if(showComments == true){
                html += '<tr>';
                    html += '<td colspan="5">';
                        html += '<div class="slds-p-top_medium">';
                            html += '<div class="slds-grid">';
                                html += '<div class="slds-size_6-of-12 slds-p-left_medium">';
                                if((goal.EGO_Ratings__r != null && goal.EGO_Ratings__r.size() > 0) && String.isNotBlank(goal.EGO_Ratings__r[0].Comments__c)) {
                                    html += getHtmlElement( 'Patient Goal Comments', ParserHelper.ToString(goal, 'EGO_Ratings__r[0].Comments__c') );
                                }
                                html += '</div>';
                                html += '<div class="slds-size_6-of-12 slds-p-left_medium">';
                                if(String.isNotBlank(goal.Team_Goal_Comments__c)) {
                                    html += getHtmlElement( 'Team Goal Comments', ParserHelper.ToString(goal, 'Team_Goal_Comments__c') );
                                }
                                html += '</div>';
                            html += '</div>';
                        html += '</div>';
                    html += '</td>';
                html += '</tr>';
            }
            if( ratingByGoalIdMap != null && ratingByGoalIdMap.containsKey(goal.Id)){
                EGO_Rating__c rating = ratingByGoalIdMap.get(goal.Id);
                html += getHtmlRatingSection(rating, integer.valueof(rating.Rating__c) , 'Goal Rating');
            }
        html += '</table>';

        return html;
    }

    public static String getHtmlGoalTableMobile(Goal__c goal, Map<Id,EGO_Rating__c> ratingByGoalIdMap, boolean showComments){
        String html = '';
        String targetDate = ParserHelper.ToDateTimeFormat(goal, 'Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
        String metDiscontinued = ParserHelper.ToDateTimeFormat(goal, 'Met_Discontinued_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
        String dateToShow = String.isNotBlank(metDiscontinued)? metDiscontinued : targetDate;
        String dateLabel = String.isNotBlank(metDiscontinued)? 'Met/Discontinued Date' : 'Target Date';

    	html = '<table>';
    	html += '<tr>';
    	html += String.format('<td><span><b>Goal:</b></span>&nbsp;<span>{0}</span></td>',new String[]{ParserHelper.ToString(goal, 'Label__c')});
    	html += '</tr>';

    	html += '<tr>';
    	html += String.format('<td><span><b>Date Added:</b></span>&nbsp;<span>{0}</span></td>',new String[]{ParserHelper.ToDateTimeFormat(goal, 'Date_Added__c', SnapshotHelper.DATEFORMAT, 'UTC')});
    	html += '</tr>';

    	html += '<tr>';
    	html += String.format('<td><span><b>Previous Target Date:</b></span>&nbsp;<span>{0}</span></td>',new String[]{ParserHelper.ToDateTimeFormat(goal, 'Continued_From_Goal__r.Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC')});
    	html += '</tr>';

    	html += '<tr>';
        String thisLabel = String.format('<span><b>{0}:</b></span>&nbsp;', new String[]{ dateLabel });
        String thisDate = String.format('<td><span>{0}</span></td>', new String[]{ dateToShow });
        String thisHtml = thisDate.replace('<td>', '<td>' + thisLabel);

    	html += thisHtml;
    	html += '</tr>';

    	html += '<tr>';
    	html += String.format('<td><span><b>Status:</b></span>&nbsp;<span>{0}</span></td>',new String[]{ParserHelper.ToString(goal, 'Status__c')});
    	html += '</tr>';

        if(showComments == true){
            if((goal.EGO_Ratings__r != null && goal.EGO_Ratings__r.size() > 0) && String.isNotBlank(goal.EGO_Ratings__r[0].Comments__c)) {
                html += '<tr>';
                html += '<td>';
                html += '<div>';
                html += '<div class="slds-form-element">';
                html += getHtmlElement( 'Patient Goal Comments', ParserHelper.ToString(goal, 'EGO_Ratings__r[0].Comments__c') );
                html += '</div>';
                html += '</div>';
                html += '</td>';
                html += '</tr>';
            }

            if((goal.EGO_Ratings__r != null && goal.EGO_Ratings__r.size() > 0) && String.isNotBlank(goal.EGO_Ratings__r[0].Comments__c)) {
                html += '<tr>';
                html += '<td>';
                html += '<div>';
                html += '<div class="slds-form-element">';
                html += getHtmlElement( 'Patient Goal Comments', ParserHelper.ToString(goal, 'EGO_Ratings__r[0].Comments__c') );
                html += '</div>';
                html += '</div>';
                html += '</td>';
                html += '</tr>';
            }

            if(String.isNotBlank(goal.Team_Goal_Comments__c)) {
                html += '<tr>';
                html += '<td>';
                html += '<div>';
                    html += getHtmlElement( 'Team Goal Comments', ParserHelper.ToString(goal, 'Team_Goal_Comments__c') );
                html += '</div>';
                html += '</td>';
                html += '</tr>';
            }
        }

        html += '</table>';
        return html;
    }

    public static String getHtmlObjectivesTable(Goal__c goal, map<id,EGO_Rating__c> ratingByObjectiveIdMap){
        String html = '';
        html += '<div class="slds-p-top_medium">';
        html += '<table>';
        Integer i = 1;
        for( Objective__c obj :  goal.Objectives__r ){
            String targetDate = ParserHelper.ToDateTimeFormat(obj, 'Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
            String metDiscontinued = ParserHelper.ToDateTimeFormat(obj, 'Met_Discontinued_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
            String dateToShow = String.isNotBlank(metDiscontinued)? metDiscontinued : targetDate;
            String dateLabel = String.isNotBlank(metDiscontinued)? 'Met/Discontinued Date' : 'Target Date';
            html += '<tr>';
                html += '<th class="slds-col slds-size_2-of-6">Objective</th>';
                html += '<th class="slds-col slds-size_1-of-6">Date Added</th>';
                html += '<th class="slds-col slds-size_1-of-6">Previous Target Date</th>';
                html += String.format('<th class="slds-col slds-size_1-of-6">{0}</th>',new String[]{dateLabel});
                html += '<th class="slds-col slds-size_1-of-6">Status</th>';
            html += '</tr>';
            html += '<tr>';
                html += String.format('<td {0}>{1}</td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToString(obj, 'Label__c')});
                html += String.format('<td {0}>{1}</td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToDateTimeFormat(obj, 'Date_Added__c', SnapshotHelper.DATEFORMAT, 'UTC')});
                html += String.format('<td {0}>{1}</td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToDateTimeFormat(obj, 'Continued_From_Objective__r.Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC')});
                html += String.format('<td {0}>{1}</td>',new String[]{i<goal.Objectives__r.size() ? '' : '', dateToShow });
                html += String.format('<td {0}>{1}</td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToString(obj, 'Status__c')});
            html += '</tr>';
            if(ratingByObjectiveIdMap != null && ratingByObjectiveIdMap.containsKey(obj.Id)){
                html += '<tr>';
                    html += '<td colspan="5" class="slds-p-bottom_medium">';
                    html += getHtmlElement( 'Objective Rating', getHtmlRatingItem( integer.valueof(ratingByObjectiveIdMap.get(obj.Id).Rating__c) ) );
                    html += '</td>';
                html += '</tr>';
            }
            i++;
        }
        html += '</table>';
        html += '</div>';
        return html;
    }

    public static String getHtmlObjectivesTableMobile(Goal__c goal, map<id,EGO_Rating__c> ratingByObjectiveIdMap){
        String html = '';
        html += '<div class="slds-p-top_medium">';
        html += '<table>';
        Integer i = 1;

        for( Objective__c obj :  goal.Objectives__r ){
            String targetDate = ParserHelper.ToDateTimeFormat(obj, 'Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
            String metDiscontinued = ParserHelper.ToDateTimeFormat(obj, 'Met_Discontinued_Date__c', SnapshotHelper.DATEFORMAT, 'UTC');
            String dateToShow = String.isNotBlank(metDiscontinued)? metDiscontinued : targetDate;
            String dateLabel = String.isNotBlank(metDiscontinued)? 'Met/Discontinued Date' : 'Target Date';

            html += '<tr>';
            html += String.format('<td {0}><span><b>Objective:</b></span>&nbsp;<span>{1}</span></td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToString(obj, 'Label__c')});
            html += '</tr>';

            html += '<tr>';
            html += String.format('<td {0}><span><b>Date Added:</b></span>&nbsp;<span>{1}</span></td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToDateTimeFormat(obj, 'Date_Added__c', SnapshotHelper.DATEFORMAT, 'UTC')});
            html += '</tr>';

            html += '<tr>';
            html += String.format('<td {0}><span><b>Previous Target Date:</b></span>&nbsp;<span>{1}</span></td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToDateTimeFormat(obj, 'Continued_From_Objective__r.Target_Date__c', SnapshotHelper.DATEFORMAT, 'UTC')});
            html += '</tr>';

            html += '<tr>';
            String thisLabel = String.format('<span><b>{0}:</b></span>&nbsp;', new String[]{ dateLabel });
            String thisDate = String.format('<td><span>{0}</span></td>', new String[]{i<goal.Objectives__r.size() ? '' : '', dateToShow });
            String thisHtml = thisDate.replace('<td>', '<td>' + thisLabel);
            html += thisHtml;
            html += '</tr>';

            html += '<tr>';
            html += String.format('<td {0}><span><b>Status:</b></span>&nbsp;<span>{1}</span></td>',new String[]{i<goal.Objectives__r.size() ? '' : '',ParserHelper.ToString(obj, 'Status__c')});
            html += '</tr>';
        }

        html = '</table>';

        return html;
    }

    public static String getHtmlGoal(Goal__c goal, map<id,EGO_Rating__c> ratingByGoalIdMap, map<id,EGO_Rating__c> ratingByObjectiveIdMap, boolean showComments){
        String html = '';
        html += '<div class="slds-p-left_large">';
            html += '<div class="slds-box">';
                html += getHtmlGoalTable(goal, ratingByGoalIdMap, showComments);
                if( goal.Objectives__r != null && goal.Objectives__r.size() > 0){
                    html += '<div class="slds-p-left_large">';
                        html += getHtmlObjectivesTable(goal, ratingByObjectiveIdMap);
                    html += '</div>';
                }
            html += '</div>';
        html += '</div>';
        return html;
    }

    public static String getHtmlGoalMobile(Goal__c goal, map<id,EGO_Rating__c> ratingByGoalIdMap, map<id,EGO_Rating__c> ratingByObjectiveIdMap, boolean showComments){
        String html = '';
        html += '<div>';
        // html += '<div>';
        html += getHtmlGoalTableMobile(goal, ratingByGoalIdMap, showComments);
        if( goal.Objectives__r != null && goal.Objectives__r.size() > 0){
            html += '<div>';
            html += getHtmlObjectivesTableMobile(goal, ratingByObjectiveIdMap);
            html += '</div>';
        }
        // html += '</div>';
        html += '</div>';

        return html;
    }

    public static String getHtmlRatingSection(EGO_Rating__c rating, integer rate, String label){
        String html = '';
        html += '<tr>';
        html += String.format('<td colspan="2">{0}</td>', new String[]{ getHtmlElement( label, getHtmlRatingItem(rate) ) });
        String tempGoalComment = ParserHelper.toString(rating,'Comments__c') ;
        if(String.isNotBlank(tempGoalComment)) {
            html += String.format('<td colspan="2">{0}</td>', new String[]{ getHtmlElement( 'Patient Goal Comments', tempGoalComment ) });
        } else {
            html += '<td colspan="2">&nbsp;</td>';
        }
        html += '</tr>';
        return html;
    }

    public static String getHtmlRatingItem(integer rate){
        String html = '';
        html += '<div class="slds-button-group" role="group" style="display: inline-block;">';
        for(integer i =1; i<= 6; i++){
            html += String.format('<div class="{0}" style="width:1rem;"><b>{1}</b></div>', new String[]{
                (i==rate || rate > 6 )? 'slds-button slds-button_brand': 'slds-button slds-button_neutral',
                ''+i
            });
        }
        html += '</div>';
        return html;
    }

    public static String getHtmlHeader(String header){
        return String.format('<div class="slds-text-heading_medium" style="text-align:center;"><center><b>{0}</b></center></div>',new String[]{ header });
    }

    public static String getHtmlOverallGoal(String overallGoalValue){
        String html = '';
        html += '<div style="text-align:center;">';
        html += '<div class="slds-form-element">';
        html += String.format('<label class="slds-form-element__label" ><b class="slds-text-heading_medium">{0}</b></label>', new String[]{ 'Overall Goal for Treatment' });
        html += String.format('<div class="slds-form-element__control" >{0}</div>',new String[]{ overallGoalValue  });
        html += '</div>';
        html += '</div>';
        return html;
    }

    public static String getHtmlTeamCommentary(String overallGoalValue){
        String html = '';
        if(String.isNotBlank(overallGoalValue)) {
            html += '<div style="text-align:center;">';
            html += '<div class="slds-form-element">';
            html += String.format('<label class="slds-form-element__label" ><b class="slds-text-heading_medium">{0}</b></label>', new String[]{ 'Team Commentary' });
            html += String.format('<div class="slds-form-element__control" >{0}</div>',new String[]{ overallGoalValue  });
            html += '</div>';
            html += '</div>';
        }
        return html;
    }
}