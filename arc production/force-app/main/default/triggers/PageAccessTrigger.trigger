trigger PageAccessTrigger on Page_Access__e (after insert) {

	PageAccess.handlePageAccess(Trigger.new); 
	
}