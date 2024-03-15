@isTest
private with sharing class BHS_HL7_ParserBaseTest {
	@isTest
	private static void testFetchControlId() {
		String hl7LabResult =
			'MSH|^~\\&|LAB|SITE|||200612051358||ORU^R01|7453.1|D|2.4\n' +
			'PID|1|^^^AB|MG00001234^^^^MR~999-99-9999^^^^SS~232^^^^PI||LastName^FirstName^Middle^^^||19340711|F||||||||||MT0001234/10|\n' +
			'PV1|1|O|CLRH 3F LAB^^||||AttendingDocId^AttendingDocLast^AttendingDocFirst^^^^|||||||||||REF||AHC|||||||||||||||||||MEDH^MediTech General Hospital||REG|||200607111417||||||\n' +
			'OBR|1|18562^LAB|18562^LAB|UA^URINALYSIS^L|||200612051300|||||||200612051343||OrderingDocId^OrderingDocLast^OrderingDocFirst^^^^||||0512:U00004U||200612051358||LAB|COMP||^^^^^U||\n' +
			'OBX|1|ST|COLUR^COLOR,URINE^L|1|YELLOW||YELLOW||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|2|ST|CLAUR^CLARITY,URINE^L|1|CLEAR||CLEAR/HAZY||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|3|ST|GLUUR^GLUCOSE,URINE^L|1|NEGATIVE|mmol/L|NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|4|ST|BILUR^BILIRUBIN,URINE^L|1|NEGATIVE||NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|5|ST|KETUR^KETONES,URINE^L|1|NEGATIVE|mmol/L|NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|6|ST|SGUR^SPECIFIC GRAVITY,URINE^L|1|>=1.030||||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|7|ST|BLDUR^BLOOD,URINE^L|1|NEGATIVE||NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|8|NM|PHUR^PH,URINE^L|1|5.5||5.0 - 7.5||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|9|ST|PROUR^PROTEIN,URINE^L|1|NEGATIVE|g/L|NEG/TRACE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|10|NM|UROUR^UROBILINOGEN,URINE^L|1|3.2|umol/L|<18||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|11|ST|NITUR^NITRITE,URINE^L|1|NEGATIVE||NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n' +
			'OBX|12|ST|LEUR^LEUKOCYTES,URINE^L|1|NEGATIVE||NEGATIVE||||F|||200612051300|ML^MAIN LAB^L\n';
		string[] segments = hl7LabResult.split('\\n');

		BHS_HL7_ParserFactory.BHS_MSHParser parser = (BHS_HL7_ParserFactory.BHS_MSHParser) BHS_HL7_ParserFactory.createParser(segments[0].left(3));
		parser.parse(segments, 0);
		System.assertEquals('7453.1', parser.getControlId(), 'Control ID should be 7453.1');
		Integer index = 0;
		for (string segment : segments) {
			BHS_HL7_ParserBase parser2 = BHS_HL7_ParserFactory.createParser(BHS_HL7_ParserBase.getMessageName(segment));
			parser2.parse(segments, index++);
			system.assert(parser2.values != null, 'parser2.values should contain parsed values');
		}
	}
}