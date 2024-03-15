/**
 * @author Synaptic Advisors
 * @date 2021
 *
 * @group BHS
 * @group-content ../../ApexDocContent/BHS.htm
 *
 * @description
 *   Utility class to support HL7 parsing such as transform a sub-field, a field, and a segment
 *
 */
public with sharing class BHS_ORU_ObjectsUtils {
	/**
	 *
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description
	 *   Inner class used as a wrapper class to seriralize/deserialize field mapping
	 * @example
	 *   {"field":"processingID","type":"str","index":"0"} for a single field
	 *   [{"field":"messageType","type":"str","index":"0"},{"field":"triggerEvent","type":"str","index":"1"}] for multiple fields
	 * @example
	 * Example:
	 * The following sample HL7 data fragment
	 *   |orderingDocId^orderingDocLast^orderingDocFirst^G.^^^|
	 * is parsed with following configuration
	 *   [{"field":"orderingDoctorId","type":"str","index":"0"},
	 *   {"field":"orderingDoctorLastName","type":"str","index":"1"},
	 *   {"field":"orderingDoctorFirstName","type":"str","index":"2"},
	 *   {"field":"orderingDoctorMiddleName","type":"str","index":"3"}]
	 */
	public class FieldMapping {
		/*******************************************************************************************************
		 * @description Specifies the index of a component in a component list separated by '^'
		 */
		public integer index { get; set; }
		/*******************************************************************************************************
		 * @description Specifies the field type of data to be converted. The field type could be one of int(integer), str(string), dt(datetime) and date
		 */
		public String type { get; set; }
		/*******************************************************************************************************
		 * @description Specifies the field name the data to be set in the target object
		 */
		public String field { get; set; }
	}
	/*******************************************************************************************************
	 * @description Convert the HL7 Datetime, in YYYYMMDDHHmmss format, to SFDC datetime format
	 * @param datetimeString the HL7 datetime in YYYYMMDDHHmmss string format
	 * @return the Datetime
	 * @example
	 *   Datetime receivedDatetime = BHS_ORU_ObjectsUtils.convertDatetimeString('200612131756');
	 */
	public static Datetime convertDatetimeString(final String datetimeString) {
		if (String.isNotBlank(datetimeString)) {
			string dtString = datetimeString.rightPad(14, '0');
			return Datetime.newInstance(Integer.valueOf(dtString.left(4)), Integer.valueOf(dtString.mid(4, 2)), Integer.valueOf(dtString.mid(6, 2)), Integer.valueOf(dtString.mid(8, 2)), Integer.valueOf(dtString.mid(10, 2)), Integer.valueOf(dtString.mid(12, 2)));
		} else {
			return null;
		}
	}
	/*******************************************************************************************************
	 * @description Retrieves the field name(ID) that is embedded as the last component in a field
	 *   For example, the MR in the component MG00001234^^^^MR is an End Name
	 * @param oru:BHS_ORU_Mapping__mdt a specific field mapping
	 * @param components:string[]
	 * @return the End Name
	 */
	private static string getEndName(BHS_ORU_Mapping__mdt oru, string[] components) {
		string endName = null;
		if (oru.Has_End_Name__c) {
			endName = components[components.size() - 1];
		}
		return endName;
	}
	/*******************************************************************************************************
	 * @description Transforms the segments to the target fields defined in BHS_ORU_Mapping__mdt
	 * @param oru:BHS_ORU_Mapping__mdt a specific field mapping
	 * @param items:list<string> list of repeatable sub-segment(sub-field)
	 * @return transformed data stored in a map<string, object>
	 */
	public static map<string, object> transformFieldRepeatItems(BHS_ORU_Mapping__mdt oru, list<string> items) {
		map<string, object> retValues = new Map<string, object>();
		map<string, object> newValue = new Map<string, object>();
		String mappings = oru.mappings__c;
		for (String item : items) {
			if (!oru.Is_Complex_Type__c) {
				//transform a single component
				FieldMapping m = (FieldMapping) JSON.deserialize(mappings, FieldMapping.class);
				try {
					newValue = transform(m, item, null);
					retValues.putAll(newValue);
				} catch (Exception e) {
					system.debug(logginglevel.warn, e.getMessage());
				}
			} else {
				//transform a list of components separated by '^'
				list<FieldMapping> fms = (list<FieldMapping>) JSON.deserialize(mappings, list<FieldMapping>.class);
				string[] components = item.split('\\^');
				string endName = getEndName(oru, components);
				for (FieldMapping m : fms) {
					integer idx = m.index;
					try {
						newValue = transform(m, components[idx], endName);
						retValues.putAll(newValue);
					} catch (Exception e) {
						system.debug(logginglevel.warn, 'index = ' + idx + ' ' + e.getMessage());
					}
				}
			}
		}
		return retValues;
	}
	public static map<String, list<BHS_ORU_Mapping__mdt>> segment2ORUMapping = new Map<String, list<BHS_ORU_Mapping__mdt>>();
	static {
		list<BHS_ORU_Mapping__mdt> orus = [SELECT Message_Type__c, Sequence__c, Mappings__c, Repeatable__c, Is_Complex_Type__c, Has_End_Name__c FROM BHS_ORU_Mapping__mdt WITH SECURITY_ENFORCED ORDER BY Sequence__c];
		for (BHS_ORU_Mapping__mdt oru : orus) {
			if (!segment2ORUMapping.containsKey(oru.Message_Type__c)) {
				segment2ORUMapping.put(oru.Message_Type__c, new List<BHS_ORU_Mapping__mdt>());
			}
			list<BHS_ORU_Mapping__mdt> mappings = segment2ORUMapping.get(oru.Message_Type__c);
			mappings.add(oru);
		}
	}
	/*******************************************************************************************************
	 * @description Transforms all the fields in a segment to the target fields defined in BHS_ORU_Mapping__mdt
	 * @param payload:string a segment
	 * @param segmentName:string segment name such as 'MSH'
	 * @return transformed data stored in a map<string, object>
	 */
	public static map<string, object> transformSegment(string payload, string segmentName) {
		map<string, object> values = new Map<string, object>();
		string[] fields = payload.split('\\|');
		map<string, object> newValue = new Map<string, object>();
		// list<BHS_ORU_Mapping__mdt> orus = [SELECT Message_Type__c, Sequence__c, Mappings__c, Repeatable__c, Is_Complex_Type__c, Has_End_Name__c
		//                                     FROM BHS_ORU_Mapping__mdt where Message_Type__c = :segmentName WITH SECURITY_ENFORCED order by Sequence__c ];

		list<BHS_ORU_Mapping__mdt> orus = segment2ORUMapping.get(segmentName);
		if (orus != null) {
			for (BHS_ORU_Mapping__mdt oru : orus) {
				String mappings = oru.mappings__c;
				//make sure oru.Sequence__c is not out of bound in string array fields
				if ((fields.size() >= (oru.Sequence__c + 1)) && string.isNotBlank(fields[Integer.valueOf(oru.Sequence__c)])) {
					list<string> items = new List<string>();
					if (oru.Repeatable__c) {
						//if this component is repeatable, split it with '~' into a component list
						items = fields[Integer.valueOf(oru.Sequence__c)].split('\\~');
					} else {
						//add the single item to the component list
						items.add(fields[Integer.valueOf(oru.Sequence__c)]);
					}
					values.putAll(transformFieldRepeatItems(oru, items));
				}
			}
		}

		return values;
	}
	/*******************************************************************************************************
	 * @description Transforms a component/sub-component to a target field defined in BHS_ORU_Mapping__mdt
	 * @param m:FieldMapping field mapping
	 * @param val:string a data value from HL7 component/sub-component
	 * @param endName:string the end name will be concatenated to field name as field name + ':' + endName
	 * @return transformed data stored in a map<string, object>
	 */
	public static map<string, object> transform(FieldMapping m, string val, string endName) {
		map<string, object> newValue = new Map<string, object>();
		string fieldName = m.field;
		//concatenate endName to fieldName if endName is not blank
		if (string.isNotBlank(endName)) {
			fieldName += ':' + endName;
		}
		switch on m.type {
			when 'int' {
				newValue.put(fieldName, Integer.valueOf(val));
			}
			when 'dt' {
				newValue.put(fieldName, convertDatetimeString(val));
			}
			when 'date' {
				newValue.put(fieldName, convertDatetimeString(val).Date());
			}
			when else {
				newValue.put(fieldName, val);
			}
		}
		return newValue;
	}
}