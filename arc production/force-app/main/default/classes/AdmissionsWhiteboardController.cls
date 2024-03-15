public with sharing class AdmissionsWhiteboardController
{
    @AuraEnabled
    public static Whiteboard getWhiteboard(String[] requirements)
    {
        List<AccountRequirementRow> accReqRows = new List<AccountRequirementRow>();
        List<Account> doneAccts = new List<Account>();
        List<Account> waitlistAccounts = new List<Account>();
        // the list of Admission stages that should be queried
        Set<String> stages = new Set<String>
        { 
            'Active Inquiry', 'Waitlist', 'Consultation Pending'
        };
        // the list of Request Item statuses to query for Records
        Set<String> recordsStatuses = new Set<String>
        {
            'Open', 'Received'
        };
        Map<Id, Account> admissionIdToAccountMap = new Map<Id, Account>();
        List<Id> orderedListAdmissionId = new List<Id>();
        for (Account acc : [SELECT Id, Name, Patient_LastName__c, Current_Admission__c,
            Current_Admission__r.Waitlist_Order__c, Current_Admission__r.Waitlist_Notes__c, 
            Current_Admission__r.Consultation_Date__c, Current_Admission_Stage__c,
            Current_Admission__r.Days_in_Current_Stage__c,
            Current_Admission__r.Consultation_Only_Date__c,
            Current_Admission__r.Service_Type__c
            FROM Account WHERE Current_Admission_Stage__c IN :stages
            AND Current_Admission__r.Service_Type__c = 'Residential'
            ORDER BY Current_Admission__r.Waitlist_Order__c, 
            Current_Admission__r.Consultation_Date__c,
            Current_Admission__r.Days_in_Current_Stage__c DESC])
        {
            if(acc.Current_Admission_Stage__c == 'Active Inquiry')
            {
                orderedListAdmissionId.add(acc.Current_Admission__c);
                admissionIdToAccountMap.put(acc.Current_Admission__c, acc);
            }
            else if(acc.Current_Admission_Stage__c == 'Waitlist' || 
                acc.Current_Admission_Stage__c == 'Consultation Pending')
            {
                if (acc.Current_Admission__r.Service_Type__c == 'Residential'){
                    // only add if Current Admission Service Type is 'Residential'
                    waitlistAccounts.add(acc);
                }
            }
        }
        if(!admissionIdToAccountMap.isEmpty())
        {
            Set<Id> admissionIdSet = admissionIdToAccountMap.keySet();
            Map<Id, Set<String>> admissionIdToRequirements = 
                new Map<Id, Set<String>>();
            for(Admissions_Requirement__c admissionsRequirement : [SELECT Id, Name,
                Admission__c
                FROM Admissions_Requirement__c
                WHERE Admission__c IN :admissionIdSet AND Name IN :requirements
                AND Completed__c = false])
            {
                if(admissionIdToRequirements.containsKey(admissionsRequirement.Admission__c))
                {
                    admissionIdToRequirements.get(admissionsRequirement.Admission__c)
                        .add(admissionsRequirement.Name);
                }
                else
                {
                    admissionIdToRequirements.put(admissionsRequirement.Admission__c,
                        new Set<String> {admissionsRequirement.Name});
                }
            }

            
            for(Id admissionId : orderedListAdmissionId)
            {
                if(admissionIdToAccountMap.containsKey(admissionId))
                {
                    Account account = admissionIdToAccountMap.get(admissionId);
                    AccountRequirementRow accReqRow = new AccountRequirementRow(account);
                    Boolean isComplete = true;
                    for(String requirement : requirements)
                    {
                        if(admissionIdToRequirements.containsKey(admissionId))
                        {
                            if(admissionIdToRequirements.get(admissionId)
                                .contains(requirement))
                            {
                                accReqRow.Requirements.add(true);
                                isComplete = false;
                            }
                            else
                            {
                                accReqRow.Requirements.add(false);
                            }
                        }
                    }
                    if(isComplete)
                    {
                        doneAccts.add(account);
                    }
                    else
                    {
                        Integer numReqRecords = [SELECT COUNT()
                        FROM Request_Item__c
                        WHERE Admissions_Requirement__r.Admission__c = :admissionId 
                        AND Status__c IN :recordsStatuses];
                        accReqRow.numReqRecords = numReqRecords;
                        accReqRows.add(accReqRow);
                    }
                }
            }
        }
        Whiteboard whb = new Whiteboard(accReqRows, doneAccts, waitlistAccounts);
        return whb;
    }
    public class AccountRequirementRow{
        // this class represents a "row" of the whiteboard, each patient Account on its own row
        @AuraEnabled public Account Account { get; set; }
        @AuraEnabled public Boolean[] Requirements { get; set; }
        @AuraEnabled public Integer numReqRecords { get; set; }
        
        public AccountRequirementRow(Account account){
            this.Account = account;
            this.Requirements = new List<Boolean>();
            this.numReqRecords = 0;
        }
    }
    public class Whiteboard{
        // this class encapsulates all data on the whiteboard and is returned by one apex method
        @AuraEnabled public List<AccountRequirementRow> AccountRequirementRows { get; set; }
        @AuraEnabled public List<Account> WaitlistAccounts { get; set; }
        @AuraEnabled public List<Account> ActiveDoneAccounts { get; set; }
        
        public Whiteboard(List<AccountRequirementRow> accReqRows, List<Account> activeDoneAccounts, List<Account> waitlistAccounts){
            this.AccountRequirementRows = accReqRows;
            this.ActiveDoneAccounts = activeDoneAccounts;
            this.WaitlistAccounts = waitlistAccounts;
        }
    }
}