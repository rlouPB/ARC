/**
 * @author Synaptic Advisors
 * @date 2021
 *
 * @group BHS
 * @group-content ../../ApexDocContent/BHS.htm
 *
 * @description A factory class to create a segment specific parser based on the segment name
 *   parse
 */
public with sharing class BHS_HL7_ParserFactory {
	public static final string CONTROL_ID = 'messageControlID';
	public static final string SEGMENT_OBX = 'OBX';
	public static final string SEGMENT_NTE = 'NTE';
	public static final string SEGMENT_OBR = 'OBR';
	/*******************************************************************************************************
	 * @description Naming convention of a HL7 Segment Parser
	 */
	static final string PARSER_NAMING_FORMATTER = 'BHS_HL7_ParserFactory.BHS_{0}Parser';

	/*******************************************************************************************************
	 * @description Dynamically creates a HL7 segment parser based on the segmentName passed in as a parameter.
	 *   The parser to be created dynamically should have the following naming convention 'BHS_'+SegmentName+'Parser'
	 *   such as BHS_MSHParser.
	 *
	 * @param segmentName:string a segment name
	 * @return an instance of BHS_HL7_ParserBase derived class
	 */
	public static BHS_HL7_ParserBase createParser(String segmentName) {
		//String className = 'BHS_HL7_ParserFactory.BHS_'+segmentName+'Parser';
		BHS_HL7_ParserBase instance = null;
		try {
			String className = String.format(PARSER_NAMING_FORMATTER, new List<string>{ segmentName });
			Type dynamicApexType = Type.forName(className);
			instance = (BHS_HL7_ParserBase) dynamicApexType.newInstance();
		} catch (Exception e) {
			instance = new BHS_DefaultParser();
		}
		return instance;
	}

	/**
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description Default HL7 ORU Message Parser
	 */
	public with sharing class BHS_DefaultParser extends BHS_HL7_ParserBase {
		public BHS_DefaultParser() {
			super();
		}
	}

	/**
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description Handle MSH related functionalities
	 */
	public with sharing class BHS_MSHParser extends BHS_HL7_ParserBase {
		public BHS_MSHParser() {
			super();
		}
		public String getControlId() {
			String controlId = null;
			if (values != null) {
				controlId = (string) values.get(BHS_HL7_ParserFactory.CONTROL_ID);
			}
			return controlId;
		}
	}
	/**
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description Responsible for parsing segment OBR and its child segments - NTE, OBX, ...
	 */
	public with sharing class BHS_OBRParser extends BHS_HL7_ParserBase {
		/*******************************************************************************************************
		 * @description default constructor
		 */
		public BHS_OBRParser() {
			super();
		}
		/*******************************************************************************************************
		 * @description Adds child segment to OBR map object
		 * @param segmentName:string Segment name such as 'MSH'
		 * @param childValues:map<string, object> The child segment
		 */
		public void addChildSegment(string segmentName, map<string, object> childValues) {
			if ((segmentName == BHS_HL7_ParserFactory.SEGMENT_OBX) || (segmentName == BHS_HL7_ParserFactory.SEGMENT_NTE)) {
				//The OBR has a list of "OBX" segments and a list of "NTE" segments.
				//If the segment is either an "OBX" or a "NTE" segment, add it to corresponding list.
				if (!this.values.containsKey(segmentName)) {
					this.values.put(segmentName, new List<map<string, object>>());
				}
				list<map<string, object>> objList = (list<map<string, object>>) this.values.get(segmentName);
				objList.add(childValues);
			} else {
				this.values.put(segmentName, childValues);
			}
		}
		/*******************************************************************************************************
		 * @description Overridden method to add child segments to OBR segment
		 * @param segments:List<String> a list of segments to be parsed
		 * @param currentIndex:integer the index of segment in the list of segments to be parsed
		 * @return the current index
		 */
		public override integer parse(List<String> segments, final integer currentIndex) {
			integer cIndex = super.parse(segments, currentIndex);

			for (Integer i = cIndex + 1; i < segments.size(); i++) {
				String segment = BHS_HL7_ParserBase.getMessageName(segments[i]);
				if (segment == BHS_HL7_ParserFactory.SEGMENT_OBR) {
					cIndex = i - 1;
					break;
				}
				BHS_HL7_ParserBase parser = BHS_HL7_ParserFactory.createParser(segment);
				cIndex = parser.parse(segments, i);
				i = cIndex;
				map<string, object> val = parser.values;
				addChildSegment(segment, val);
			}
			return cIndex;
		}
	}

	/**
	 * @author Synaptic Advisors
	 * @date 2021
	 *
	 * @group BHS
	 * @group-content ../../ApexDocContent/BHS.htm
	 *
	 * @description Responsible for parsing segment OBX and its child segments - NTE
	 */
	public with sharing class BHS_OBXParser extends BHS_HL7_ParserBase {
		public BHS_OBXParser() {
			super();
		}
		/*******************************************************************************************************
		 * @description Adds NTE segment to OBX map object
		 * @param segmentName:string Segment name such as 'MSH'
		 * @param childValues:map<string, object> The child segment
		 */
		public void addNTESegment(string segmentName, map<string, object> childValues) {
			if (segmentName == BHS_HL7_ParserFactory.SEGMENT_NTE) {
				//The OBX has a list of "NTE" segments.
				//If the segment is a "NTE" segment, add it to list.
				if (!this.values.containsKey(segmentName)) {
					this.values.put(segmentName, new List<map<string, object>>());
				}
				list<map<string, object>> objList = (list<map<string, object>>) this.values.get(segmentName);
				objList.add(childValues);
			}
		}

		/*******************************************************************************************************
		 * @description Overridden method to add child NTE segments to OBX segment
		 * @param segments:List<String> a list of segments to be parsed
		 * @param currentIndex:integer the index of segment in the list of segments to be parsed
		 * @return the current index
		 */
		public override integer parse(List<String> segments, final integer currentIndex) {
			integer cIndex = super.parse(segments, currentIndex);
			for (Integer i = cIndex + 1; i < segments.size(); i++) {
				String segment = BHS_HL7_ParserBase.getMessageName(segments[i]);
				if (segment != BHS_HL7_ParserFactory.SEGMENT_NTE) {
					cIndex = i - 1;
					break;
				}
				BHS_HL7_ParserBase parser = BHS_HL7_ParserFactory.createParser(segment);
				cIndex = parser.parse(segments, i);
				map<string, object> val = parser.values;
				addNTESegment(segment, val);
			}
			return cIndex;
		}
	}
}