public class CaseAbstractPresentation 
{
    //passed in to constructor
    public String documentId;
    
    //queried within this class
    public String versionId;
    public ContentVersion version;

    //set within this class
    public String previewUrl;
    public String downloadUrl;
    public String fileSize;
    public String latestCaseAbstractVerion;
    //set externally
    public String generatedBy {get; set;}
    public Datetime generatedDatetime {get; set;}
    public String generatedDateTimeString {
        get {
            return generatedDatetime.format('EEEE MMMM d, y K:mm a z');
        }
    }

    public CaseAbstractPresentation(String contentDocumentId)
    {
        this.documentId = contentDocumentId;
        queryLatestContentVersion();
    }

    public void queryLatestContentVersion()
    {
        List<ContentVersion> versions = [
            SELECT Id, Title, Description, CreatedDate, ContentSize, IsLatest
            FROM ContentVersion 
            WHERE ContentDocumentId = :this.documentId AND IsLatest = true
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC];
        if(versions.size() > 0) {
            this.version = versions[0];
            this.versionId = version.Id;
            previewUrl = '/sfc/servlet.shepherd/version/download/' + this.versionId;
            latestCaseAbstractVerion = '/apex/PrintLatestCaseAbstractPresentation?documentId='+this.documentId;
            fileSize = String.valueOf(this.version.ContentSize / 1000) + ' KB';
        }
        
    }
}