@isTest
public class TestFactory_Patient {
	/*Example of how to Call Test Methods
		// The TestFactory will pre-fill all the fields we typically need
		Account a = (Account)TestFactory_Patient.createSObject(new Account());
		insert a;

		// You can also set values to be used. Any values set in the constructor will override the defaults
		Opportunity o = (Opportunity)TestFactory_Patient.createSObject(new Opportunity(AccountId = a.Id));

		// You can also specify a specific set of overrides for different scenarios
		Account a = (Account)TestFactory_Patient.createSObject(new Account(), 'TestFactory_Patient.AccountDefaults');

		// Finally, get a bunch of records for testing bulk
		Account[] aList = (Account[])TestFactory_Patient.createSObjectList(new Account(), 200);

		// You can optionally insert records as created like this:
		// Note the final parameter of true.
		Account a = (Account)TestFactory_Patient.createSObject(new Account(), true);
		Contact c = (Contact)TestFactory_Patient.createSObject(new Contact(AccountID = a.Id), true);
	*/

	public static SObject createSObject(SObject sObj) {
		// Check what type of object we are creating and add any defaults that are needed.
		String objectName = String.valueOf(sObj.getSObjectType());
		// Construct the default values class. Salesforce doesn't allow '__' in class names
		String defaultClassName = 'TestFactory_Patient.' + objectName.replaceAll('__c|__', '') + 'Defaults';
		// If there is a class that exists for the default values, then use them
		if (Type.forName(defaultClassName) != null) {
			sObj = createSObject(sObj, defaultClassName);
		}
		return sObj;
	}

	public static SObject createSObject(SObject sObj, Boolean doInsert) {
		SObject retObject = createSObject(sObj);
		if (doInsert) {
			insert retObject;
		}
		return retObject;
	}

	public static SObject createSObject(SObject sObj, String defaultClassName) {
		// Create an instance of the defaults class so we can get the Map of field defaults
		Type t = Type.forName(defaultClassName);
		if (t == null) {
			throw new TestFactoryException('Invalid defaults class.');
		}
		FieldDefaults defaults = (FieldDefaults) t.newInstance();
		addFieldDefaults(sObj, defaults.getFieldDefaults());
		return sObj;
	}

	public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
		SObject retObject = createSObject(sObj, defaultClassName);
		if (doInsert) {
			insert retObject;
		}
		return retObject;
	}

	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects) {
		return createSObjectList(sObj, numberOfObjects, (String) null);
	}

	public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, Boolean doInsert) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, (String) null);
		if (doInsert) {
			insert retList;
		}
		return retList;
	}

	public static SObject[] createSObjectList(SObject sObj, Integer numberOfObjects, String defaultClassName, Boolean doInsert) {
		SObject[] retList = createSObjectList(sObj, numberOfObjects, defaultClassName);
		if (doInsert) {
			insert retList;
		}
		return retList;
	}

	public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, String defaultClassName) {
		SObject[] sObjs = new List<SObject>{};
		SObject newObj;

		// Get one copy of the object
		if (defaultClassName == null) {
			newObj = createSObject(sObj);
		} else {
			newObj = createSObject(sObj, defaultClassName);
		}

		// Get the name field for the object
		String nameField = nameFieldMap.get(String.valueOf(sObj.getSObjectType()));
		if (nameField == null) {
			nameField = 'Name';
		}

		// Clone the object the number of times requested. Increment the name field so each record is unique
		for (Integer i = 0; i < numberOfObjects; i++) {
			SObject clonedSObj = newObj.clone(false, true);
			if (String.valueOf(sObj.getSObjectType()) != 'Call__c')
				clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
			sObjs.add(clonedSObj);
		}
		return sObjs;
	}

	private static void addFieldDefaults(SObject sObj, Map<String, Object> defaults) {
		// Loop through the map of fields and if they are null on the object, fill them.
		for (String field : defaults.keySet()) {
			if (sObj.get(field) == null) {
				sObj.put(field, defaults.get(field));
			}
		}
	}

	// When we create a list of SObjects, we need to
	private static Map<String, String> nameFieldMap = new Map<String, String>{ 'Contact' => 'LastName', 'Case' => 'Subject' };

	public class TestFactoryException extends Exception {
	}

	// Use the FieldDefaults interface to set up values you want to default in for all objects.
	public interface FieldDefaults {
		Map<String, Object> getFieldDefaults();
	}

	public class PatientAccountDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object>{ 'Name' => 'Test Account', 'BillingStreet' => '123 Main Street', 'BillingCity' => 'Annapolis', 'BillingState' => 'Maryland', 'BillingPostalCode' => '21401', 'BillingCountry' => 'United States' };
		}
	}

	public class RelatedContactDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object>{ 'FirstName' => 'firstName', 'LastName' => 'Familyname', 'MailingStreet' => 'mailing', 'MailingCity' => 'city', 'MailingState' => 'Indiana', 'MailingCountry' => 'United States', 'MailingPostalCode' => 'zip', 'OtherStreet' => 'billing', 'OtherCity' => 'city', 'OtherState' => 'Ohio', 'OtherCountry' => 'United States', 'OtherPostalCode' => 'zip', 'BirthDate' => (System.today().addYears(-25)), 'Email' => 'test@test.com', 'Phone' => '555-888-7777' };
		}
	}

	public class FormDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object>{ 'disco__Archived__c' => 'false' };
		}
	}

	public class FormTemplateDefaults implements FieldDefaults {
		public Map<String, Object> getFieldDefaults() {
			return new Map<String, Object>{ 'Status__c' => 'Drafting' };
		}
	}
}