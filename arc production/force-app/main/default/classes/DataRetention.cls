/*
  Purpose:  DataRetention class is a Basic utility class for Data Retention called by a batch Batch_DataRetention.


  Original Author:  Synaptic AP - KRISHNA OMMI created on 06/19/2019

 */
public class DataRetention {
	private Retention_Setting__mdt retSetting;
	public String queryString = '';

	public DataRetention(Retention_Setting__mdt retSetting) {
		buildQueryString(retSetting);
	}

	public void buildQueryString(Retention_Setting__mdt retSetting) {
		queryString = 'SELECT Id';
		String settingId = retSetting.Id;
		Map<String, String> settingFieldsValues = new Map<String, String>();
		String objectName = retSetting.Object__c;
		String dateField = retSetting.Date_Field__c;
		Integer allowedAge = (Integer) retSetting.Allowed_Age__c;
		String additionalFilter = retSetting.Additional_Filter__c;

		queryString = queryString + ' FROM ' + objectName + ' WHERE ' + dateField + ' < LAST_N_DAYS:' + allowedAge;
		// If there are no Additional filters to the metadata please type 'null' on the metadata record
		if (additionalFilter != 'null' && additionalFilter != null) {
			queryString = queryString + ' AND ' + additionalFilter;
		}
	}
}