public class SearchResult{
    @AuraEnabled
    public string id;

    @AuraEnabled
    public string label;

    @AuraEnabled
    public object record;
    
    public SearchResult(string Id, string label){
        this.id = id;
        this.label = label;
    }
    public SearchResult(string Id, string label, object record){
        this.id = id;
        this.label = label;
        this.record = record;
    }
}