public with sharing class CompediumEntryWrapper {
    public CompediumEntryWrapper(String sfid, String code, String testName, String category) {
        this.sfid = sfid;
        this.code = code;
        this.testName = testName;
        this.category = category;
    }
    @AuraEnabled
    public String sfid { get; set; }
    @AuraEnabled
    public String code { get; set; }
    @AuraEnabled
    public String testName { get; set; }
    @AuraEnabled
    public String category { get; set; }
}