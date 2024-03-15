public with sharing class AdmissionsWhiteboardIOPController
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
        List<String> admissionsRequirements = new List<String>
        {
            'Motivation', 'Abstinence', 'Clinical', 'Finances', 'Medications', 'Medical', 'Legal'
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
            AND Current_Admission__r.Service_Type__c = 'IOP'
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
                waitlistAccounts.add(acc);
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
                    AccountRequirementRow accReqRow = new AccountRequirementRow(account, requirements);
                    Boolean isComplete = true;
                    for(Integer i = 0; i < requirements.size(); i++)
                    {
                        AccountRequirement accReq = accReqRow.Requirements.get(i);
                        if(admissionIdToRequirements.containsKey(admissionId))
                        {
                            if(admissionIdToRequirements.get(admissionId)
                                .contains(requirements.get(i)))
                            {
                                accReq.isOpen = true;
                                isComplete = false;
                            }
                            else
                            {
                                accReq.isOpen = false;
                            }
                        }
                    }
                    if(isComplete)
                    {
                        doneAccts.add(account);
                    }
                    else
                    {
                        Request_Item__c[] req_items = [SELECT Admissions_Requirement__r.Name
                        FROM Request_Item__c
                        WHERE Admissions_Requirement__r.Admission__c = :admissionId 
                        AND Status__c IN :recordsStatuses];

                        for (Request_Item__c req_item : req_items)
                        {
                            for (Integer i = 0; i < accReqRow.Requirements.size(); i++)
                            {
                                if (admissionsRequirements.get(i) == req_item.Admissions_Requirement__r.Name)
                                {
                                    AccountRequirement accReq = accReqRow.Requirements.get(i);
                                    accReq.numRecords += 1;
                                }
                            }
                        }
                        accReqRows.add(accReqRow);
                    }
                }
            }
        }
        Whiteboard whb = new Whiteboard(accReqRows, doneAccts, waitlistAccounts);
        return whb;
    }
    public class AccountRequirement{
        // this class represents a cell of the whiteboard, basically a specific Requirement within an AccountRequirementRow
        @AuraEnabled public Boolean isOpen { get; set; }
        @AuraEnabled public Integer numRecords { get; set; }

        public AccountRequirement(){
            this.isOpen = true;
            this.numRecords = 0;
        }
    }
    public class AccountRequirementRow{
        // this class represents a "row" of the whiteboard, each patient Account on its own row
        @AuraEnabled public Account Account { get; set; }
        @AuraEnabled public List<AccountRequirement> Requirements { get; set; }
        
        public AccountRequirementRow(Account account, List<String> requirements){
            this.Account = account;
            this.Requirements = new List<AccountRequirement>();
            for (String str : requirements)
            {
                AccountRequirement accReq = new AccountRequirement();
                this.Requirements.add(accReq);
            }
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