public with sharing class ViewPatientPostsCtl 
{
    public static TimeZone riggsHomeTz = TimeZone.getTimeZone('America/New_York');

    public User currentUser { get; set; }
    public static Id currentUserContactId {get; set; }
    public Contact currentUserContact {get; set; }
    
    Boolean canSeeSharedPosts = false;
    String sharedPostsType = 'none';
    
    Map<String, List<PostWrapper>> sharedPostsMap
    { get 
        {
            if (sharedPostsMap == null)
            {
                sharedPostsMap = querySharedPosts();
            }
            return sharedPostsMap;
        } private set;
    }
    public List<PostWrapper> patientWidePosts 
    { get 
        {
            return sharedPostsMap.get('Patient-wide');
        } private set;
    }
    public List<PostWrapper> familyWidePosts 
    { get 
        {
            return sharedPostsMap.get('Family-wide');
        } private set;
    }

    public List<PostWrapper> individualPosts 
    { get 
        {
            if (individualPosts == null)
            {
                individualPosts = queryIndividualPosts();
            }
            return individualPosts;
        } private set;
    }

    String postQuery =      'SELECT Id, Type__c, Active__c, Info__c, Patient_Contact__c, Sort_Order__c, LastModifiedDate, LastModifiedBy.Name'
                            + ' FROM Post__c';
    String sharedWhere =        ' WHERE Active__c = TRUE AND Recordtype.DeveloperName = \'Shared\'';
    String individualWhere =    ' WHERE Active__c = TRUE AND Recordtype.DeveloperName = \'Individual\' AND Type__c = \'Individual\' AND Patient_Contact__c = :currentUserContactId';
    String orderBy =            ' ORDER BY Sort_Order__c ASC NULLS LAST, LastModifiedDate DESC';
   
   
    public ViewPatientPostsCtl() 
    {
        currentUser = [SELECT Id, Name, ContactId, Contact.Abbreviated_Name__c, Contact.Account.Current_Admission_Stage__c, 
                            Contact.RecordType.DeveloperName, Contact.Account.RecordType.DeveloperName
                    FROM User 
                    WHERE Id = :Userinfo.getUserId()];
        
        //use this user's contact unless another one was supplied in advance somehow (like testing)
        if (currentUserContactId == null && currentUser.ContactId != null)
        {
            currentUserContactId = currentUser.ContactId;
        }

        currentUserContact = new Contact();
        if (currentUserContactId != null)
        {
            currentUserContact = [SELECT Id, RecordType.DeveloperName, Abbreviated_Name__c, Distinguished_Name__c, 
                                        Account.Current_Admission_Stage__c, Account.RecordType.DeveloperName
                                FROM Contact 
                                WHERE Id = :currentUserContactId];
        }

        //internal user
        if (currentUser.ContactId == null)
        {
            canSeeSharedPosts = true;
        
        //internal user or  admitted patient or family member ('Personal')
        } else if(currentUser.ContactId == null
                || (currentUserContact != null
                    && (currentUserContact.RecordType.DeveloperName == 'Patient' && currentUserContact.Account.Current_Admission_Stage__c == 'Admitted'
                        || currentUserContact.Recordtype.DeveloperName == 'Personal')))
        {
            canSeeSharedPosts = true;
        }
        
        //limit shared posts depending on which community we're in
        String siteName = Site.getName();
        switch on siteName
        {
            when 'Community' 
            {
                sharedPostsType = 'Patient-wide';
            } when 'Family'
            {
                sharedPostsType = 'Family-wide';
            }    
        }

        System.debug('sitename ' + siteName  + ' sharedPostsType ' + sharedPostsType);
        
        
    }

    Map<String, List<PostWrapper>> querySharedPosts()
    {
        Map<String, List<PostWrapper>> type2PostsMap = new Map<String, List<PostWrapper>>
        {
            'Patient-wide' => new List<PostWrapper>(),
            'Family-wide' => new List<PostWrapper>()
        };
        if (Test.isRunningTest())
        {
            sharedPostsType = 'all';
        }

        if(canSeeSharedPosts)
        {
            List<PostWrapper> posts = queryPosts(sharedWhere);
            for (PostWrapper wrap : posts)
            {
                if (wrap.post.Type__c == sharedPostsType || sharedPostsType == 'all')
                {
                    List<PostWrapper> mappedPosts = type2PostsMap.get(wrap.post.Type__c);

                    mappedPosts.add(wrap);
                    type2PostsMap.put(wrap.post.Type__c, mappedPosts);
                }
            }

        }
        System.debug('type2PostsMap ' + type2PostsMap);
        return type2PostsMap;
    }

    List<PostWrapper> queryIndividualPosts()
    {
        return queryPosts(individualWhere);
    }
    
    List<PostWrapper> queryPosts(String whereClause)
    {
        List<PostWrapper> returnPostWrappers = new List<PostWrapper>();
        if(String.isBlank(whereClause)){
            return returnPostWrappers;
        }else{
            String queryString = postQuery + whereClause + orderBy;
            system.debug('Query:'+queryString);
            for (Post__c post : (List<Post__c>)Database.query(queryString))
            {
                returnPostWrappers.add(new PostWrapper(post));
            }
            system.debug('returnPostWrappers:'+returnPostWrappers.size());
            return returnPostWrappers;
        }
    }

    
    public static String formatUtcDateTime(Datetime utcDateTime)
    {
        Integer offsetHours = riggsHomeTz.getOffset(utcDateTime) / 3600 / 1000;
        Datetime riggsDateTime = utcDateTime.addHours(offsetHours);
        return riggsDateTime.formatGmt('MM/dd/yyyy hh:mm a');
    }



    public Class PostWrapper
    {
        public Post__c post { get; set; }
        public String formattedLastUpdated { get; set; }

        public PostWrapper(Post__c post)
        {
            this.post = post;
            this.formattedLastUpdated = ViewPatientPostsCtl.formatUtcDateTime(post.LastModifiedDate);
            System.debug('postwrapper datetime utc ' + this.post.LastModifiedDate + ' TO ' + this.formattedLastUpdated);
        }

    }

}