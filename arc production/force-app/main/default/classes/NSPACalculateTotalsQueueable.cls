public class NSPACalculateTotalsQueueable implements Queueable {
    Id[] recordIds;
    String ObjectName;
    public NSPACalculateTotalsQueueable( Id[] recordIds, String ObjectName ){
        this.recordIds = recordIds;
        this.ObjectName = ObjectName;
    }
    public void execute(QueueableContext context) {
        List<Id> patientIds = new List<Id>();
        List<Id> nsaIds = new List<Id>();
        Nursing_Shift_Assignment__c[] toUpdate = new Nursing_Shift_Assignment__c[]{};
        
        if (ObjectName == 'NSI') {
            for (Nursing_Shift_Item__c nsi : [Select Id, Patient__c,Nursing_Shift_Assignment__c, Status__c from Nursing_Shift_Item__c where id in :recordIds]) {
                patientIds.add(nsi.Patient__c);
                nsaIds.add(nsi.Nursing_Shift_Assignment__c);
            }
        } else if (ObjectName == 'NSPA') {
            for (Nursing_Shift_Patient_Assignment__c nsi : [Select Id, Patient__c,Nursing_Shift_Assignment__c, Status__c from Nursing_Shift_Patient_Assignment__c where id in :recordIds]) {
                patientIds.add(nsi.Patient__c);
                nsaIds.add(nsi.Nursing_Shift_Assignment__c);
            }
        }
        

        Map<Id,List<Nursing_Shift_Item__c>> nsiByNsaId = new Map<Id,List<Nursing_Shift_Item__c>>();
        Map<Id,List<Nursing_Shift_Item__c>> nsiByPatientId = new Map<Id,List<Nursing_Shift_Item__c>>();

        for (Nursing_Shift_Assignment__c nsa : [Select Id, (Select Status__c from Nursing_Shift_Items__r) from Nursing_Shift_Assignment__c where Id in :nsaIds]) {
            nsiByNsaId.put(nsa.Id, nsa.Nursing_Shift_Items__r);
        }

        for (Account acc : [Select Id, (Select Status__c from Nursing_Shift_Items__r) from Account where Id in :patientIds]) {
            nsiByPatientId.put(acc.Id, acc.Nursing_Shift_Items__r);
        }

        List<Nursing_Shift_Patient_Assignment__c> nspaList = new List<Nursing_Shift_Patient_Assignment__c>();
        for (Nursing_Shift_Patient_Assignment__c nspa: [Select id, Open_Patient_Shift_Items__c, Total_Patient_Shift_Items__c,
                                                        Patient__c, Nursing_Shift_Assignment__c
                                                        from Nursing_Shift_Patient_Assignment__c 
                                                        where Nursing_Shift_Assignment__c IN :nsaIds 
                                                        and 
                                                        Patient__c IN :patientIds]) {
            nspa.Total_Patient_Shift_Items__c = nsiByPatientId.get(nspa.Patient__c).size();

            decimal openItems = 0;
            for(Nursing_Shift_Item__c item : nsiByPatientId.get(nspa.Patient__c)){
                if(Item.Status__c == 'Open'){
                    openItems++;
                }
            }
            nspa.Open_Patient_Shift_Items__c = openItems;
            nspaList.add(nspa);
        }
        update nspaList;
    }
}