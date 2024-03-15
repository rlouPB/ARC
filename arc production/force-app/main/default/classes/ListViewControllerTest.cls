@isTest
public with sharing class ListViewControllerTest {
    Public Static testMethod void myUnitTest (){
        list<Object> oListViewWrapper = new list<Object>();
        oListViewWrapper = ListViewController.listValues('Variance__c');
        System.assertEquals(oListViewWrapper.size()>0, true);
    }
}