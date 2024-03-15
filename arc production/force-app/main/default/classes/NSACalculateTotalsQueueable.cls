public with sharing class NSACalculateTotalsQueueable implements Queueable {
    Id[] nsaIds;

    public NSACalculateTotalsQueueable( Id[] nsaIds ){
        this.nsaIds = nsaIds;
    }

    public void execute(QueueableContext context) {
        Nursing_Shift_Assignment__c[] toUpdate = new Nursing_Shift_Assignment__c[]{};
        Nursing_Shift_Assignment__c[] nsaList = [
            Select Id, Open_Shift_Items__c,Total_Shift_Items__c,
            ( Select Status__c from Nursing_Shift_Items__r )
            from Nursing_Shift_Assignment__c where id in :nsaIds
        ];
        for( Nursing_Shift_Assignment__c nsa : nsaList ){
            Nursing_Shift_Assignment__c n = new Nursing_Shift_Assignment__c();
            decimal totals = nsa.Nursing_Shift_Items__r != null? nsa.Nursing_Shift_Items__r.size() : 0;
            decimal open = getOpenNursingShiftItems(nsa.Nursing_Shift_Items__r);
            if(totals != nsa.Total_Shift_Items__c){
                n.Id = nsa.Id;
                n.Total_Shift_Items__c = totals;
            }
            if( open != nsa.Open_Shift_Items__c ){
                n.Id = nsa.Id;
                n.Open_Shift_Items__c = open;
            }
            if( n.Id != null ){
                toUpdate.add(n);
            }
        }
        if(toUpdate.size() > 0){
            update toUpdate;
        }
    }

    public static decimal getOpenNursingShiftItems(Nursing_Shift_Item__c[] items){
        decimal openItems = 0;
        if(items != null){
            for(Nursing_Shift_Item__c item : items){
                if(Item.Status__c == 'Open'){
                    openItems++;
                }
            }
        }
        return openItems;
    }
}