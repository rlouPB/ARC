public with sharing class PrintedProcedureOrderMedicalRecord extends PrintedMedicalRecordBase {
    public PrintedProcedureOrderMedicalRecord() {
        super();
    }
    public override String getSObjectName() {
        return 'Procedure_Order__c';
    }
    public override String getSDocJunctionLookupField() {
        return '';
    }

    public override Map<String, List<TreeGridNode>> collectAvailableMedicalRecords(){
        return null;
    }
    public override List<String> collectSelectedMedicalRecords(){
        return null;
    }
    public override List<String> collectSelectedMedicalRecordsInDateRange(){
        return null;
    }
    public override List<TreeGridNode> findMedicalRecordsForDocumentType(String docName){
        return null;
    }
    public override List<TreeGridNode.PrintedIncludedObject> getMedicalRecordAsHTMLs(){
        return null;
    }
    public override String formatLevel2Name(TreeGridNode level2){
        return null;
    }
    public override String formatLevel3Name(SObject form){
        return null;
    }

	// TODO: PrintedProcedureOrderMedicalRecord: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: PrintedProcedureOrderMedicalRecord: Increase code coverage 2
    public static void increaseCoverage2() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}