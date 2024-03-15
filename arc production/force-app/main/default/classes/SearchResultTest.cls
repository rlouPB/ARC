@IsTest
public with sharing class SearchResultTest {
    public static testmethod void test(){
        SearchResult sr = new SearchResult('test','test');
        SearchResult sr2 = new SearchResult('test','test',null);
    }
}