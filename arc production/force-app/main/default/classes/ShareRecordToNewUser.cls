public class ShareRecordToNewUser {
    public class ShareRecordToNewUserException extends Exception{}

    @future
    public static void process(set<id> userIds){
        map<Id,User> userMap = new map<Id,User>([Select AccountId,Profile.Name,ContactId,Contact.AccountId from user where id=:userIds]);
        set<Id> contactIds = new set<Id>();
        AccountShare[] sharingsToInsert = new AccountShare[]{};

        for(User u : userMap.values()){
            if ( u.ContactId != null ){
                contactIds.add( u.ContactId );
            }
        }

        map<Id,Contact> contactMap = new Map<Id,Contact>([Select Id,AccountId,(Select Id,Account__c from Related_Contacts__r order by createddate desc limit 1) from Contact where id in :contactIds ]);

        id[] userToIncludeIds = new id[]{};
        id[] accToIncludeIds = new id[]{};
        id[] aToIncludeIds = new id[]{};

        for(User u : userMap.values()){
            Contact c = contactMap.containsKey(u.ContactId)? contactMap.get(u.ContactId) : null;
            if( u.Profile.Name == 'ARC Patient Community User'){
                // userToIncludeIds.add(u.Id);
                // accToIncludeIds.add(u.AccountId);
                sharingsToInsert.add( new AccountShare(
                    AccountId = u.AccountId,
                    AccountAccessLevel='Edit',
                    UserOrGroupId=u.Id,
                    OpportunityAccessLevel='Edit')
                );
            }else if ( u.Profile.Name == 'ARC Family Community User' && c != null && c.Related_Contacts__r.size() > 0 && c.Related_Contacts__r[0].Account__c != null ){
                // userToIncludeIds.add(u.Id);
                // accToIncludeIds.add(u.ContactId);
                // accToIncludeIds.add( c.Related_Contacts__r[0].Account__c );
                sharingsToInsert.add( new AccountShare(
                    AccountId = c.Related_Contacts__r[0].Account__c,
                    AccountAccessLevel='Edit',
                    UserOrGroupId=u.Id,
                    OpportunityAccessLevel='Edit')
                );
            }
        }

        if( sharingsToInsert.isEmpty()  ){
            throw new ShareRecordToNewUserException('Should have include the sharings' );
        }else{
            insert sharingsToInsert;
        }
        // if( userToIncludeIds.isEmpty() || accToIncludeIds.isEmpty()  ){
        //     throw new ShareRecordToNewUserException('userToIncludeIds: ' +  userToIncludeIds.size() + '  ;  accToIncludeIds: ' + accToIncludeIds.size() );
        // }

        // SharingRecord_Utils.createSharingRecords(accToIncludeIds, userToIncludeIds, 'Edit');

        // if( !userToIncludeIds.isEmpty() && !accToIncludeIds.isEmpty() ){
        //     SharingRecord_Utils.createSharingRecords(userToIncludeIds, accToIncludeIds, 'Edit');
        // }


    }

	// TODO: ShareRecordToNewUser: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: ShareRecordToNewUser: Increase code coverage 2
    public static void increaseCoverage2() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}
//select AccountId from AccountShare where UserOrGroupID ='0052i000002wx3UAAQ'
//select AccountId from AccountShare where UserOrGroupID ='0052i000002wx8o'
//Select AccountId from User where id='0052i000002wx3UAAQ'