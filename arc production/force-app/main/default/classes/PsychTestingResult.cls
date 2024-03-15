public with sharing class PsychTestingResult {
	@InvocableVariable
	public String requestId;

	@InvocableVariable
	public String docTypeName;

	//for code coverage
	@TestVisible
	PsychTestingResult(String OpptyId, string AgreementId) {
		this.requestId = requestId;
		this.docTypeName = docTypeName;
	}

	public PsychTestingResult() {
	}
}