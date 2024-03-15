/**
 * @author Synaptic Advisors
 * @date 2021
 *
 * @group BHS
 * @group-content ../../ApexDocContent/BHS.htm
 *
 * @description
 *   BHS HL7 ORM Message Writer Utility Class. Provides transformation methods to transform segments,
 *   fields with a specific data type to HL7 format
 *
 */
public with sharing class BHS_HL7_WriterUtils {
	public static String mnemonics = 'AUSTENRIGGS';
	// static {
	//     User user = [SELECT Id, BHS_User_Mnemonic__c FROM User WHERE Id = :userInfo.getUserId()];
	//     if(String.isNotBlank(user.BHS_User_Mnemonic__c)) {
	//         mnemonics = user.BHS_User_Mnemonic__c;
	//     }
	// }
	/**
	 *
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description
	 *   Inner class used as a wrapper class to seriralize/deserialize field mapping
	 * @example
	 *   {"field":"processingID","type":"str","index":"0", "asValue":false} for a single field
	 *   [{"field":"messageType","type":"str","index":"0", "asValue":false},{"field":"triggerEvent","type":"str","index":"1","asValue":false}] for multiple fields
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
		/*******************************************************************************************************
		 * @description Specifies if the field stores an expression or a value
		 */
		public boolean asValue { get; set; }
		/*******************************************************************************************************
		 * @description Specifies the length of converted data
		 */
		public integer len { get; set; }
	}
	/*******************************************************************************************************
	 * @description Transforms a SObject to a HL7 Segment
	 *
	 * @param segmentName:string segment name
	 * @param sObj:SObject an snstance of procedure_order__c
	 * @return The transformed HL7 message
	 */
	public static string transformASegment(string segmentName, SObject sObj, Integer sequence) {
		string formatter = null;
		list<BHS_ORM_Mapping__mdt> mappings = [SELECT Id, Message_Type__c, Sequence__c, Is_Complex_Type__c, Mapping__c, Formatter__c, Required__c, MapToSeq__c FROM BHS_ORM_Mapping__mdt WHERE Message_Type__c = :segmentName WITH SECURITY_ENFORCED ORDER BY Sequence__c];
		//The segment formatter is stored in sequence 0's formatter;
		string segmentFormatter = mappings[0].Formatter__c;
		//Initialize the string formatter parameters
		list<string> parameters = new List<string>(mappings.size() - 1);
		for (integer idx = 0; idx < parameters.size(); idx++) {
			//Initialize the parameters to empty
			parameters[idx] = '';
		}

		for (integer i = 1; i < mappings.size(); i++) {
			string hl7Field = transformAField(mappings[i], sObj, sequence);
			parameters[Integer.valueOf(mappings[i].MapToSeq__c)] = hl7Field;
		}

		return string.format(segmentFormatter, parameters);
	}

	/*******************************************************************************************************
	 * @description Transforms an integer to its correspomnding HL7 message
	 *
	 * @param m:BHS_HL7_WriterUtils.FieldMapping Field Mapping wrapper class
	 * @param sObj:SObject an instance of procedure_order__c
	 * @param value:Object a value object to be written to a HL7 message
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string handleIntegerValue(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = null;
		try {
			if (!m.asValue) {
				if (m.field == 'index') {
					ret = string.valueOf(value);
				}
			} else {
				ret = m.field;
			}
		} catch (Exception me) {
			System.debug(logginglevel.warn, 'Message: ' + me.getMessage());
			System.debug(logginglevel.warn, 'Stack trace: ' + me.getStackTraceString());
			ret = '';
		}
		return ret;
	}

	/*******************************************************************************************************
	 * @description Transforms a Datetime to its correspomnding HL7 message
	 *
	 * @param m:BHS_HL7_WriterUtils.FieldMapping Field Mapping wrapper class
	 * @param sObj:SObject an instance of procedure_order__c
	 * @param value:Object a value object to be written to a HL7 message
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string handleDatetimeValue(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = '';
		try {
			if (!m.asValue) {
				Datetime dt = null;
				if (m.field == 'now') {
					dt = Datetime.now();
				} else {
					dt = (Datetime) extractFieldValues(sObj, m.field);
				}
				if (dt != null) {
					ret = string.valueOf(dt.year()) + string.valueOf(dt.month()).leftPad(2, '0') + string.valueOf(dt.day()).leftPad(2, '0') + string.valueOf(dt.hour()).leftPad(2, '0') + string.valueOf(dt.minute()).leftPad(2, '0') + string.valueOf(dt.second()).leftPad(2, '0');
				}
			}
		} catch (Exception me) {
			System.debug(logginglevel.warn, 'Message: ' + me.getMessage());
			System.debug(logginglevel.warn, 'Stack trace: ' + me.getStackTraceString());
			ret = '';
		}
		return ret;
	}

	/*******************************************************************************************************
	 * @description Transforms a Date to its correspomnding HL7 message
	 *
	 * @param m:BHS_HL7_WriterUtils.FieldMapping Field Mapping wrapper class
	 * @param sObj:SObject an instance of procedure_order__c
	 * @param value:Object a value object to be written to a HL7 message
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string handleDateValue(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = '';
		try {
			if (!m.asValue) {
				Date lDate = (Date) extractFieldValues(sObj, m.field);
				ret = string.valueOf(lDate.year()) + string.valueOf(lDate.month()).leftPad(2, '0') + string.valueOf(lDate.day()).leftPad(2, '0');
			}
		} catch (Exception me) {
			System.debug(logginglevel.warn, 'Message: ' + me.getMessage());
			System.debug(logginglevel.warn, 'Stack trace: ' + me.getStackTraceString());
			ret = '';
		}
		return ret;
	}

	/*******************************************************************************************************
	 * @description Transforms a String to its correspomnding HL7 message
	 *
	 * @param m:BHS_HL7_WriterUtils.FieldMapping Field Mapping wrapper class
	 * @param sObj:SObject an instance of procedure_order__c
	 * @param value:Object a value object to be written to a HL7 message
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string handleStringValue(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = '';
		try {
			if (m.asValue) {
				ret = m.field;
			} else {
				if ('mnemonics'.equalsIgnoreCase(m.field)) {
					ret = BHS_HL7_WriterUtils.mnemonics;
				} else {
					ret = (String) extractFieldValues(sObj, m.field);
				}
			}
			if (string.isEmpty(ret) || ret == 'null') {
				ret = '';
			}
		} catch (Exception me) {
			System.debug(logginglevel.warn, 'Message: ' + me.getMessage());
			System.debug(logginglevel.warn, 'Stack trace: ' + me.getStackTraceString());
			ret = '';
		}
		return ret;
	}

	@TestVisible
	private static string handleBooleanValue(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = '';
		try {
			if (m.asValue) {
				ret = m.field;
			} else {
				ret = String.valueOf(extractFieldValues(sObj, m.field));
			}
			if ('true'.equalsIgnoreCase(ret)) {
				ret = '1';
			} else {
				ret = '0';
			}
		} catch (Exception me) {
			System.debug(logginglevel.warn, 'Message: ' + me.getMessage());
			System.debug(logginglevel.warn, 'Stack trace: ' + me.getStackTraceString());
			ret = '';
		}
		return ret;
	}

	/*******************************************************************************************************
	 * @description Transforms a value to its correspomnding HL7 message
	 *
	 * @param m:BHS_HL7_WriterUtils.FieldMapping Field Mapping wrapper class
	 * @param sObj:SObject an instance of procedure_order__c
	 * @param value:Object a value object to be written to a HL7 message
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string transform(BHS_HL7_WriterUtils.FieldMapping m, SObject sObj, Object value) {
		string ret = '';

		switch on m.type {
			when 'int' {
				ret = handleIntegerValue(m, sObj, value);
			}
			when 'dt' {
				ret = handleDatetimeValue(m, sObj, value);
			}
			when 'date' {
				ret = handleDateValue(m, sObj, value);
			}
			when 'boolean' {
				ret = handleBooleanValue(m, sObj, value);
			}
			when else {
				ret = handleStringValue(m, sObj, value);
			}
		}
		//if the attribute "len" is defined in the Field Mapping configuration, trim the
		//result string "ret" to the smaller length of m.len and ret.length()
		if (m.len != null) {
			ret = ret.left(math.min(m.len, ret.length()));
		}

		return ret;
	}

	/*******************************************************************************************************
	 * @description Transforms a field to its correspomnding HL7 message
	 *
	 * @param mapping:BBHS_ORM_Mapping__mdt Field Mapping Custom Metadata Type
	 * @param sObj:SObject an instance of procedure_order__c
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static string transformAField(BHS_ORM_Mapping__mdt mapping, SObject sObj, Integer sequence) {
		string ret = '';
		if (!mapping.Is_Complex_Type__c) {
			//transform a single component
			BHS_HL7_WriterUtils.FieldMapping m = (BHS_HL7_WriterUtils.FieldMapping) JSON.deserialize(mapping.Mapping__c, BHS_HL7_WriterUtils.FieldMapping.class);
			ret = transform(m, sObj, sequence);
		} else {
			//transform a list of components separated by '^'
			list<BHS_HL7_WriterUtils.FieldMapping> fms = (list<BHS_HL7_WriterUtils.FieldMapping>) JSON.deserialize(mapping.Mapping__c, list<BHS_HL7_WriterUtils.FieldMapping>.class);
			// string[] components = item.split('\\^');
			// string endName = getEndName(oru, components);
			string simpleRet = '';
			string formatter = mapping.formatter__c;
			list<string> parameters = new List<string>();

			for (BHS_HL7_WriterUtils.FieldMapping m : fms) {
				integer idx = m.index;
				parameters.add(transform(m, sObj, mapping.Sequence__c));
				// newValue = transform(m, components[idx], endName);
				// retValues.putAll(newValue);
			}
			ret = string.format(formatter, parameters);
		}
		return ret;
	}

	/*******************************************************************************************************
	 * @description Extracts a value from Procedure_Order__c via a path. Such as Admission__r.Patient_Contact__r.Birthdate
	 *
	 * @param sb:sObject an instance of procedure_order__c
	 * @param fieldAPIName:string a path to acces a value such as Admission__r.Patient_Contact__r.Birthdate
	 * @return The transformed HL7 message
	 */
	@TestVisible
	private static object extractFieldValues(sObject sb, string fieldAPIName) {
		object fvalue = null;
		if (fieldAPIName.contains('.')) {
			List<string> splitedFields = fieldAPIName.split('\\.');
			try {
				for (integer i = 0; i < splitedFields.size() - 1; i++) {
					sb = sb.getSobject(splitedFields[i]);
				}

				fvalue = sb.get(splitedFields[splitedFields.size() - 1]);
			} catch (exception ex) {
				system.debug(logginglevel.warn, '******exception while fetching fieldValues as relationship ' + fieldAPIName + '  value is blank.' + ex.getmessage());
				system.debug(logginglevel.warn, 'Stack trace: ' + ex.getStackTraceString());
				fvalue = null;
			}
		} else if (sb.get(fieldAPIName) != null) {
			fvalue = sb.get(fieldAPIName);
		}
		return fvalue;
	}
}