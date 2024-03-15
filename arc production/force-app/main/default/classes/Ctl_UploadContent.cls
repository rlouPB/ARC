public with sharing class Ctl_UploadContent 
{

    @AuraEnabled
    public static String createDocLinks(List<String> contentDocumentIds, List<String> additionalRelatedIds)
    {
    	String result = 'Success';

    	try
    	{
    		List<ContentDocumentLink> cdlsToInsert = new List<ContentDocumentLink>();
    		for (String cdId : contentDocumentIds)
    		{
    			for (String relatedId : additionalRelatedIds)
    			{
	    			ContentDocumentLink newCdl = new ContentDocumentLink(
	    				LinkedEntityId = relatedId,
	    				ContentDocumentId = cdId,
	    				ShareType = 'V',
	    				Visibility = 'AllUsers'
	    				);
	    			cdlsToInsert.add(newCdl);
    			}
    		}
    		insert cdlsToInsert;
		} catch (Exception e)
		{
			result = 'There was a problem connecting the uploaded file' + (additionalRelatedIds.size() > 1 ? 's' : '') 
					+ ' to the correct records within Salesforce. Please contact a system administrator for assistance and include this message. '
					+ '\nMessage: ' + e.getMessage()
					+ '\nStack Trace: ' + e.getStackTraceString();
		}


    	return result;
    }


}