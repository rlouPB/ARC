/**
 * @author Synaptic Advisors
 * @date 2021
 *
 * @group BHS
 * @group-content ../../ApexDocContent/BHS.htm
 *
 * @description Base class of HL7 parser that defines virtual functions of
 *   parse
 */
public with sharing abstract class BHS_HL7_ParserBase {
	/*******************************************************************************************************
	 * @description Returns the HL7 message name located in first three characters such as 'MSH'
	 * @param segment:string a segment
	 * @return HL7 message name
	 */
	public static string getMessageName(string segment) {
		return segment.left(3);
	}
	//public sObject values = null;
	/*******************************************************************************************************
	 * @description stores the transformed HL7 fields in a segment
	 */
	public map<string, object> values { get; set; }

	/*******************************************************************************************************
	 * @description default constructor
	 */
	public BHS_HL7_ParserBase() {
		values = new Map<string, object>();
	}

	/*******************************************************************************************************
	 * @description returns a specific message name in a corresponging derived parser class
	 * @param segments:List<String> a list of segments to be parsed
	 * @param currentIndex:integer the index of segment in the list of segments to be parsed
	 * @return the current index
	 */
	public virtual integer parse(List<String> segments, final integer currentIndex) {
		String segment = segments[currentIndex];
		values = BHS_ORU_ObjectsUtils.transformSegment(segment, getMessageName(segment));
		return currentIndex;
	}
}