public with sharing class TreeGridNode implements Comparable {
	public String name;
	public String nodeName { get; set; }
	public String developerName { get; set; }
	public String sfId { get; set; }
	public String url { get; set; }
	public String finalizedBy { get; set; }
	public String sObjectName { get; set; }
	public Datetime finalizedDatetime { get; set; }
	public Datetime contactDate { get; set; }
	public Integer sequence { get; set; }
	public Integer childrenCount { get; set; }
	public Boolean isDisplayed { get; set; }
	public List<TreeGridNode> children { get; set; }

	public Integer compareTo(Object compareTo) {
		TreeGridNode obj = (TreeGridNode) compareTo;
		this.sequence = this.sequence != null ? this.sequence : 0;
		obj.sequence = obj.sequence != null ? obj.sequence : 0;
		if (this.sequence != obj.sequence) {
			return this.sequence - obj.sequence;
		} else {
			Long thisTime = this.contactDate == null ? 0 : this.contactDate.getTime();
			Long cmpareToTime = obj.contactDate == null ? 0 : obj.contactDate.getTime();
			return Integer.valueOf(cmpareToTime - thisTime);
		}
	}
	public class TreeGridWrapper {
		public Map<String, List<TreeGridNode>> docTypeMedicalRecordsMap { get; set; }
		public List<String> selectedMedicalRecords { get; set; }
	}
	public class Option {
		public Option(String label, String value) {
			this.label = label;
			this.value = value;
		}
		public String label { get; set; }
		public String value { get; set; }
	}
	public class TreeNodeResult {
		@AuraEnabled
		public String allTreeNodes;
		@AuraEnabled
		public String selectedRows;
		@AuraEnabled
		public String admissionOptions;
		@AuraEnabled
		public String selectedAdmissions;
	}
	public class PrintedIncludedObject implements Comparable {
		public string name { get; set; }
		public string sfdcName { get; set; }
		public string htmlText { get; set; }
		public list<string> attachments { get; set; }
		public Integer sequence { get; set; }
		public Datetime finalizedTime { get; set; }
		public PrintedIncludedObject(String name, Integer sequence) {
			this.name = name;
			this.sequence = sequence;
			this.attachments = new List<string>();
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