public with sharing class SDocsYourekaUtils {
	public static final string FORMAT_SECTION_HEADER = '<div class="section-header">{0}</div>';
	public static final string FORMAT_QUESTION = '<div class="question">{0}</div><br/>';
	public static final string FORMAT_ANSWER = '<div class="answer"><i>{0}</i></div><br/><br/>';
	public static final string FORMAT_SIGNATURE = '<img class="signature" src = {0} /><br/>';
	public static final Integer MULTIPLIER = 100;
	private static Map<String, Med_Records_Document_Type__mdt> docTypeDevName2DocTypeMap = null;
	private static Map<String, Med_Records_Document_Type__mdt> docTypeName2DocTypeMap = null;
	public static Integer calculateSortingSequenceWithDevName(String documentType) {
		Integer sequence = 0;
		if (docTypeDevName2DocTypeMap == null) {
			docTypeDevName2DocTypeMap = new Map<String, Med_Records_Document_Type__mdt>();
			for (Med_Records_Document_Type__mdt docType : [SELECT DeveloperName, Name__c, Sort_Order__c, Category__r.Sort_Order__c, SObject_Name__c FROM Med_Records_Document_Type__mdt WITH SECURITY_ENFORCED]) {
				docTypeDevName2DocTypeMap.put(docType.DeveloperName, docType);
			}
		}
		Med_Records_Document_Type__mdt dt = docTypeDevName2DocTypeMap.get(documentType);
		if (dt != null) {
			sequence = Integer.valueOf(dt.Category__r.Sort_Order__c * MULTIPLIER + dt.Sort_Order__c);
		}
		return sequence;
	}
	public static Integer calculateSortingSequence(String documentType) {
		Integer sequence = 0;
		if (docTypeName2DocTypeMap == null) {
			docTypeName2DocTypeMap = new Map<String, Med_Records_Document_Type__mdt>();
			for (Med_Records_Document_Type__mdt docType : [SELECT DeveloperName, Name__c, Sort_Order__c, Category__r.Sort_Order__c, SObject_Name__c FROM Med_Records_Document_Type__mdt WITH SECURITY_ENFORCED]) {
				docTypeName2DocTypeMap.put(docType.Name__c, docType);
			}
		}
		Med_Records_Document_Type__mdt dt = docTypeName2DocTypeMap.get(documentType);
		if (dt != null) {
			sequence = Integer.valueOf(dt.Category__r.Sort_Order__c * MULTIPLIER + dt.Sort_Order__c);
		}
		return sequence;
	}
	public static List<PrintedIncludedObject> generateYourekaHTMLs(String printedMRId) {
		Set<String> formIds = new Set<String>();
		Map<String, PrintedIncludedObject> formNameToIncludedObjectMap = new Map<String, PrintedIncludedObject>();
		for (Printed_Medical_Included_Record__c pmir : [SELECT SDoc_Junction__r.Youreka_Form__c, SDoc_Junction__r.Youreka_Form__r.Name, Sort_Order__c, SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c FROM Printed_Medical_Included_Record__c WHERE Printed_Medical_Record_Request__c = :printedMRId AND SDoc_Junction__r.Youreka_Form__c != NULL WITH SECURITY_ENFORCED ORDER BY Sort_Order__c]) {
			formIds.add(pmir.SDoc_Junction__r.Youreka_Form__c);
			Integer sortSequence = calculateSortingSequenceWithDevName(pmir.SDoc_Junction__r.Youreka_Form__r.disco__Form_Template__r.DocType_Name__c);
			formNameToIncludedObjectMap.put(pmir.SDoc_Junction__r.Youreka_Form__r.Name, new PrintedIncludedObject(pmir.SDoc_Junction__r.Youreka_Form__r.Name, sortSequence));
		}
		List<disco__Answer__c> answers = [
			SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c, disco__Form__c, disco__Form__r.name
			FROM disco__Answer__c
			WHERE disco__Form__c IN :formIds
			WITH SECURITY_ENFORCED
			ORDER BY disco__Form__c, disco__Question__r.disco__Order__c ASC
		];
		Map<String, List<disco__Answer__c>> formAnswerMap = new Map<String, List<disco__Answer__c>>();
		for (disco__Answer__c ans : answers) {
			if (!formAnswerMap.containsKey(ans.disco__Form__r.name)) {
				formAnswerMap.put(ans.disco__Form__r.name, new List<disco__Answer__c>());
			}
			formAnswerMap.get(ans.disco__Form__r.name).add(ans);
		}
		String htmlString = '';
		for (String key : formAnswerMap.keySet()) {
			formNameToIncludedObjectMap.get(key).htmlText = generateYourekaHTML(formAnswerMap.get(key));
		}
		return formNameToIncludedObjectMap.values();
	}
	public static String generateYourekaHTML(List<disco__Answer__c> answers) {
		//a0x2i000001xm1yAAA
		String htmlString = '';
		// List<disco__Answer__c> answers = [SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c,
		//     disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name,
		//     disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c,
		//     disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c,
		//     disco__Number_Answer__c, disco__Text_Answer__c FROM disco__Answer__c
		// WHERE disco__Form__c= :formId
		// WITH SECURITY_ENFORCED
		// ORDER BY disco__Question__r.disco__Order__c asc];
		for (disco__Answer__c ans : answers) {
			if ('logoy.jpg'.equalsIgnoreCase(ans.disco__Question__r.disco__Label__c)) {
				//ignore the logo
				continue;
			}
			String htmlAnswer = '';
			if (ans.disco__Question__r.First_in_Section__c) {
				htmlAnswer += String.format(FORMAT_SECTION_HEADER, new List<string>{ ans.disco__Question__r.disco__Section__r.Name });
			}

			htmlAnswer += String.format(FORMAT_QUESTION, new List<string>{ ans.disco__Question__r.disco__Label__c });

			if (!'signed'.equalsIgnoreCase(ans.disco__Answer__c)) {
				htmlAnswer += String.format(FORMAT_ANSWER, new List<string>{ ans.disco__Answer__c });
			}
			if ('E-Signature'.equalsIgnoreCase(ans.disco__Question__r.disco__Type__c)) {
				htmlAnswer += String.format(FORMAT_SIGNATURE, new List<string>{ ans.disco__Long_Text_Answer__c });
			}
			htmlString += htmlAnswer;
		}

		return htmlString;
	}
	public class PrintedIncludedObject implements Comparable {
		public string name { get; set; }
		public string htmlText { get; set; }
		public Integer sequence { get; set; }
		public Datetime finalizedTime { get; set; }
		public PrintedIncludedObject(String name, Integer sequence) {
			this.name = name;
			this.sequence = sequence;
		}
		public PrintedIncludedObject(String name, String htmlText, Integer sequence) {
			this.name = name;
			this.sequence = sequence;
			this.htmlText = htmlText;
		}
		public Integer compareTo(Object compareTo) {
			PrintedIncludedObject obj = (PrintedIncludedObject) compareTo;
			if (this.sequence != obj.sequence) {
				return this.sequence - obj.sequence;
			} else {
				Long thisTime = this.finalizedTime == null ? 0 : this.finalizedTime.getTime();
				Long cmpareToTime = obj.finalizedTime == null ? 0 : obj.finalizedTime.getTime();
				return Integer.valueOf(thisTime - cmpareToTime);
			}
		}
	}
}