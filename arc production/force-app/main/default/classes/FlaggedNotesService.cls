public without sharing class FlaggedNotesService {
    public static final String alertType = 'Clinical Alert';

    static DateTime getDateTime(Datetime dt){
        return DateTime.valueOfGmt(string.valueof(dt));
    }

    @AuraEnabled
    public static Patient_Note__c[] getFlaggedNotes(Id patientId, string timeRange, string dateFrom, string dateTo ){
        DateTime startDate = dateFrom != null? Datetime.newInstance(Date.valueOf(dateFrom), time.newInstance(0, 0, 0, 0)) : null;
        DateTime endDate = dateTo != null? Datetime.newInstance(Date.valueOf(dateTo), Time.newInstance(23, 59, 59, 59)) : null;

        String baseQuery = 'SELECT Id, Snapshot__r.Html__c, Finalized_Date_Time__c, Finalized_By__r.Id, Finalized_By__r.Name, Finalized_By__r.Contact_Professional_Name__c, ' +
                            ' Completed_By_Professional_Name__c, Completed_Date_Time__c, Completed_By__r.Id, Completed_By__r.Name, Status__c, ' +
                            ' Type__c, Name, Account__r.Id, Account__r.Name, Account__r.Team__c FROM Patient_Note__c';
        String[] wherePart = new String[]{
            'Flagged__c = true'          
        };
        
        if ( string.isEmpty(timeRange) || timeRange == 'Custom' ){
            system.debug('***** FlaggedNotesService.getFlaggedNotes - Custom - startDate : ' + startDate.format() + '; endDate: '+ endDate.format() +' *****');
            //roy lou -- possible time zone issue here need to surround date time value with AY_ONLY(convertTimezone()
            wherePart.add( '( Finalized_Date_Time__c >= :startDate AND Finalized_Date_Time__c <= :endDate )' );
        }else if ( timeRange == '1 Month') {
            wherePart.add( '( Finalized_Date_Time__c >= LAST_N_DAYS:30 )' );
        }else if ( timeRange == '7 Days') {
            wherePart.add( '( Finalized_Date_Time__c >= LAST_N_DAYS:7 )' );
        }else if ( timeRange == '24 Hours') {
            wherePart.add( '( Finalized_Date_Time__c >= LAST_N_DAYS:1 )' );
        }

        if( patientId != null ){
            wherePart.add('Account__c=:patientId');
        }
        // ARC-2452 - filter out discarded record 
        wherePart.add('Status__c != \'Cancelled\'');
        return (Patient_Note__c[])database.query(baseQuery + ' WHERE ' + string.join(wherePart, ' AND '));
    }

    @AuraEnabled
    public static Message__c[] getAlerts(Id patientId, string timeRange, string dateFrom, string dateTo){
        DateTime startDate = dateFrom != null? Datetime.newInstance(Date.valueOf(dateFrom), time.newInstance(0, 0, 0, 0)) : null;
        DateTime endDate = dateTo != null? Datetime.newInstance(Date.valueOf(dateTo), Time.newInstance(23, 59, 59, 59)) : null;


        String baseQuery = 'SELECT Id, Name, Subject__c, Body__c, CreatedDate,CreatedBy.Name,Patient_Note__r.Finalized_By__r.Id,Patient_Note__r.Finalized_By__r.Name, Patient_Note__r.Finalized_By__r.Contact_Professional_Name__c, ' + 
                            'Patient_Note__r.Completed_By_Professional_Name__c, Patient_Note__r.Completed_Date_Time__c, Patient_Note__r.Completed_By__r.Id, Patient_Note__r.Completed_By__r.Name, Patient_Note__r.Status__c, ' +
                            'Patient_Note__r.Type__c, Patient_Note__r.Snapshot__r.Html__c,Patient_Note__r.Finalized_Date_Time__c, Patient_Note__r.Account__r.Id, Patient_Note__r.Account__r.Name, Patient_Note__r.Account__r.Team__c FROM Message__c';
        String[] wherePart = new String[]{
            'Type__c =:alertType',
            'Patient_Note__r.Account__c != null'
        };

        if ( string.isEmpty(timeRange) || timeRange == 'Custom' ){
            system.debug('***** FlaggedNotesService.getAlerts - Custom - startDate startDate : ' + startDate.format() + '; endDate: '+ endDate.format() +' *****');
            wherePart.add( '( CreatedDate >= :startDate AND CreatedDate <= :endDate )' );
        }else if ( timeRange == '1 Month') {
            wherePart.add( '( CreatedDate >= LAST_N_DAYS:30 )' );
        }else if ( timeRange == '7 Days') {
            wherePart.add( '( CreatedDate >= LAST_N_DAYS:7 )' );
        }else if ( timeRange == '24 Hours') {
            wherePart.add( '( CreatedDate >= LAST_N_DAYS:1 )' );
        }
        
        if( patientId != null ){
            wherePart.add('Patient_Note__r.Account__c=:patientId');
        }
        return (Message__c[])database.query(baseQuery + ' WHERE ' + string.join(wherePart, ' AND '));
    }
}