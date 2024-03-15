public with sharing abstract class PrintedMedicalRecordBase {
	public static final Integer MULTIPLIER = 100;
	private static Map<String, Med_Records_Document_Type__mdt> docTypeDevName2DocTypeMap = null;
	private static Map<String, Med_Records_Document_Type__mdt> docTypeName2DocTypeMap = null;
	public abstract String getSObjectName();
	public static MAP<String, String> noteDefinitionRecTypeMap = new Map<String, String>();
	static {
		for (Note_Definition__mdt noteDefinition : [SELECT Id, DeveloperName, Active__c, Note_Label__c, Med_Records_Document_Type__r.DeveloperName FROM Note_Definition__mdt WITH SECURITY_ENFORCED]) {
			noteDefinitionRecTypeMap.put(noteDefinition.Med_Records_Document_Type__r.DeveloperName, noteDefinition.Note_Label__c);
		}
	}

	public String patientId { get; set; }
	public String requestId { get; set; }
	public String selectedAdmissions { get; set; }
	public List<String> admissionIdList { get; set; }
	public Date dateFrom { get; set; }
	public Date dateTo { get; set; }
	public Map<String, List<TreeGridNode>> availableMedicalRecords { get; set; }
	public List<String> selectedMedicalRecords { get; set; }
	public List<String> selectedMedicalRecordsInDateRange { get; set; }

	//String serializedSelectedRecords {get; set;}
	public Boolean searchFinalizedDate { get; set; }
	public PrintedMedicalRecordBase() {
		this.patientId = null;
		this.requestId = null;
		this.dateFrom = null;
		this.dateTo = null;
		this.selectedAdmissions = null;
		this.admissionIdList = null;
		//this.serializedSelectedRecords=null;
		this.searchFinalizedDate = false;
	}
	public abstract String getSDocJunctionLookupField();
	public virtual void initialize(String patientId, String requestId, String admissionIds) {
		this.patientId = patientId;
		this.requestId = requestId;
		this.selectedAdmissions = admissionIds;
		if (String.isBlank(admissionIds)) {
			String admissionId = [SELECT Id, Name, current_admission__c FROM Account WHERE Id = :patientId WITH SECURITY_ENFORCED].current_admission__c;
			admissionIdList = new List<String>{ admissionId };
			this.selectedAdmissions = JSON.serialize(admissionIdList);
		} else {
			admissionIdList = (List<String>) JSON.deserialize(admissionIds, List<String>.class);
		}
	}
	public virtual TreeGridNode assignDocumentRecord(TreeGridNode node) {
		if (availableMedicalRecords.containsKey(node.developerName)) {
			node.children = availableMedicalRecords.get(node.developerName);
			node.sObjectName = this.getSObjectName();
			node.name = formatLevel2Name(node);
		}
		return node;
	}

	public abstract Map<String, List<TreeGridNode>> collectAvailableMedicalRecords();
	public abstract List<String> collectSelectedMedicalRecords();
	public abstract List<String> collectSelectedMedicalRecordsInDateRange();
	public abstract List<TreeGridNode> findMedicalRecordsForDocumentType(String docName);
	public abstract List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs();
	public abstract String formatLevel2Name(TreeGridNode level2);
	public abstract String formatLevel3Name(SObject form);
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
			sequence = Integer.valueOf(dt.Category__r.Sort_Order__c * MULTIPLIER + (dt.Sort_Order__c != null ? dt.Sort_Order__c : 0));
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
}