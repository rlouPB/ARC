public without sharing class ViewOptionsCtl {
	/*
		Controller for ViewOptions Lightning Component. Retrieves View Options from Custom Metadata Types
		Created 181129 JN
	*/

	@AuraEnabled
	public static List<OptionSet> getViewOptionSets(String context) {
		List<OptionSet> optionSets = new List<OptionSet>();
		String userProfileName = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()].Name;
		Map<Id, OptionSet> optionSetMap = new Map<Id, OptionSet>();
		List<Id> sortedOptionSetList = new List<Id>();
		// OptionSet defaultSet;
		//query optionSets

		for (View_Option_Set__mdt obj : [SELECT Id, Is_Default__c, Specific_Name__c, Title__c, Available_to_Profiles__c, Parameters__c, Order__c, Role__c FROM View_Option_Set__mdt WHERE Context__c = :context AND Is_Active__c = TRUE AND Available_to_Profiles__c != NULL ORDER BY Is_Default__c DESC, Order__c ASC NULLS LAST]) {
			List<String> availableProfilesList = obj.Available_to_Profiles__c.split(',');

			for (String availableProfile : availableProfilesList) {
				if (availableProfile.trim() == userProfileName) {
					OptionSet theSet = new OptionSet(obj);
					sortedOptionSetList.add(obj.Id);
					optionSetMap.put(obj.Id, theSet);
					// if (obj.Is_Default__c)
					// {
					// 	defaultSet = theSet;
					// }
					break; //only do this once max
				}
			}
		}

		// List<View_Option_Item__mdt> selectOptionSetRadioButtonOptions = new List<View_Option_Item__mdt>();
		for (View_Option_Item__mdt obj : [SELECT Id, MasterLabel, DeveloperName, Label__c, Order__c, Radio_Button_Labels__c, Show_Label__c, Type__c, View_Option_Set__c, Default_Radio_Button__c, Default_Checkbox_Value__c, Select_Option_Set__c FROM View_Option_Item__mdt WHERE View_Option_Set__c IN :optionSetMap.keySet() ORDER BY View_Option_Set__c, Order__c ASC]) {
			OptionSet theSet = optionSetMap.get(obj.View_Option_Set__c);
			if (obj.Type__c == 'Checkbox') {
				theSet.checkboxItems.add(new OptionItem(obj, obj.Default_Checkbox_Value__c));
			} else if (obj.Type__c == 'Radio Button Group') {
				theSet.rbGroupItems.add(new OptionItem(obj, obj.Default_Radio_Button__c));
			} else if (obj.Type__c == 'Radio Button') {
				theSet.selectOptionSetRadioButtonOptions.add(obj);
			}
		}

		for (OptionSet theSet : optionSetMap.values()) {
			if (!theSet.selectOptionSetRadioButtonOptions.isEmpty()) {
				theSet.selectOptionSetRbGroupItem = new OptionItem(theSet.selectOptionSetRadioButtonOptions);
			}
		}

		// if (defaultSet != null)
		// {
		// 	optionSets.add(defaultSet);
		// 	optionSetMap.remove(defaultSet.optionSetObj.Id);
		// }
		// optionSets.addAll(optionSetMap.values());

		for (Id optionSetId : sortedOptionSetList) {
			OptionSet optSet = optionSetMap.get(optionSetId);
			if (optSet != null) {
				optionSets.add(optSet);
			}
		}

		if (optionSets.isEmpty()) {
			optionSets.add(new OptionSet(new View_Option_Set__mdt(Title__c = 'No options available')));
		}
		return optionSets;
	}

	public class OptionSet {
		@AuraEnabled
		public View_Option_Set__mdt optionSetObj;
		@AuraEnabled
		public Map<String, Object> parameters = new Map<String, Object>();
		@AuraEnabled
		public List<OptionItem> checkboxItems;
		@AuraEnabled
		public List<OptionItem> rbGroupItems;
		@AuraEnabled
		public OptionItem selectOptionSetRbGroupItem;

		public List<View_Option_Item__mdt> selectOptionSetRadioButtonOptions = new List<View_Option_Item__mdt>();

		@AuraEnabled
		public String orgDomainUrl;

		public OptionSet(View_Option_Set__mdt optSet) {
			this.orgDomainUrl = URL.getOrgDomainUrl().toExternalForm();
			this.optionSetObj = optSet;
			if (optSet.Parameters__c != null) {
				this.parameters = (Map<String, Object>) JSON.deserializeUntyped(optSet.Parameters__c);
			}

			this.checkboxItems = new List<OptionItem>();
			this.rbGroupItems = new List<OptionItem>();
		}
	}

	public class OptionItem {
		@AuraEnabled
		public View_Option_Item__mdt optionItemObj;
		@AuraEnabled
		public List<View_Option_Item__mdt> optionItemObjList;
		@AuraEnabled
		public Boolean checkboxValue;
		@AuraEnabled
		public String rbGroupValue;
		@AuraEnabled
		public List<String> rbGroupLabels = new List<String>();
		@AuraEnabled
		public List<Map<String, String>> rbOptions = new List<Map<String, String>>();
		public OptionItem() {
		}

		public OptionItem(View_Option_Item__mdt optItem, Boolean val) {
			this.optionItemObj = optItem;
			this.checkboxValue = val;
		}

		public OptionItem(View_Option_Item__mdt optItem, String val) {
			this.optionItemObj = optItem;
			this.rbGroupValue = val;
			buildRbOptions();
		}

		public OptionItem(List<View_Option_Item__mdt> optItems) {
			this.optionItemObjList = optItems;
			buildSelectOptionSetRbOptions();
		}

		void buildRbOptions() {
			this.rbGroupLabels = this.optionItemObj.Radio_Button_Labels__c.split(',');
			for (String label : rbGroupLabels) {
				rbOptions.add(new Map<String, String>{ 'label' => label, 'value' => label });
			}
		}

		//build rb options for radio button group to select another option set
		@TestVisible
		void buildSelectOptionSetRbOptions() {
			this.optionItemObj = new View_Option_Item__mdt();

			for (View_Option_Item__mdt item : this.optionItemObjList) {
				this.rbGroupLabels.add(item.Label__c);
				this.rbOptions.add(new Map<String, String>{ 'label' => item.Label__c, 'value' => item.Label__c, 'selectOptionSet' => item.Select_Option_Set__c });
				if (item.Default_Radio_Button__c != null) {
					this.optionItemObj.Default_Radio_Button__c = item.Default_Radio_Button__c;
				}
			}
		}
	}
}