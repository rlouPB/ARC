public class ListFormsCtl {
	
	@AuraEnabled
	public static List<disco__Form__c> refreshFormList(String context, List<String> fieldList, String formId)
	{
		switch on context
		{
			when 'community'
			{
				List<User> currentUser =
				[
					SELECT ContactID
					FROM User
					WHERE ID = :UserInfo.getUserId()
				];

				if (currentUser[0].ContactID != null)
				{
					ID contactID = currentUser[0].ContactID;

					String query = 'SELECT ';
					for (String currentField: fieldList)
					{
						query += currentField + ', ';
					}
					query = query.removeEnd(', ');
					query += ' FROM disco__Form__c ';

					System.debug('formId: ' + formId);
					if (formId != null)
					{
						query += 'WHERE ID = \'' + formId + '\' ';
					} else
					{
						query += 'WHERE Available_in_Community__c = TRUE ';
                        query += 'AND disco__Form_Template__r.Forms_Allowed_in_Community__c = TRUE ';//
						query += 'AND disco__Form_Contact__c = \'' + contactID + '\' ';
					}
					
					query += 'ORDER BY disco__Locked__c ASC, CreatedDate DESC ';

					System.debug('query: ' + query);

					List<disco__Form__c> forms = Database.query(query);

                    System.debug('forms returned: ' + forms);

					return forms;
				} else
				{
					System.debug('No ContactID found on current user.');
					return new List<disco__Form__c>();
				}
			}
			when else
			{
				System.debug('No context match found.');
				return new List<disco__Form__c>();
			}
		}
	}

	@AuraEnabled
	public static String getLabelsByAPI(List<String> fieldList)
	{
		String objectType = 'disco__Form__c';
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(objectType);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

		Map<String, String> labelByAPI = new Map<String, String>();
		for (String currentField: fieldList)
		{
			labelByAPI.put(currentField, fieldMap.get(currentField).getDescribe().getLabel());
		}

		return JSON.serialize(labelByAPI);
	}

	@AuraEnabled
	public static DateTime getLastModifiedFormDateTime(String context)
	{
        DateTime dateTimeToReturn = DateTime.newInstance(1900, 1, 1);
		switch on context
		{
			when 'community'
			{
				List<User> currentUser =
				[
					SELECT ContactID
					FROM User
					WHERE ID = :UserInfo.getUserId()
				];

				if (currentUser[0].ContactID != null)
				{
					ID contactID = currentUser[0].ContactID;

					String query = 'SELECT LastModifiedDate ';
					query += ' FROM disco__Form__c ';
					query += 'WHERE Available_in_Community__c = TRUE ';
                    query += 'AND disco__Form_Template__r.Forms_Allowed_in_Community__c = TRUE ';
					query += 'AND disco__Form_Contact__c = \'' + contactID + '\' ';
					query += 'ORDER BY LastModifiedDate DESC LIMIT 1';

					System.debug('query: ' + query);

					List<disco__Form__c> forms = Database.query(query);
                    if (!forms.isEmpty())
                    {
                        // return forms[0].LastModifiedDate;
                        dateTimeToReturn = forms[0].LastModifiedDate;
                    }
				} else
				{
					System.debug('No ContactID found on current user.');
					// return DateTime.newInstance(1900, 1, 1);
				}
			}
			when else
			{
				System.debug('No context match found.');
				// return DateTime.newInstance(1900, 1, 1);
			}
		}
        return dateTimeToReturn;
	}

}