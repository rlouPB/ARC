@IsTest
public class discoAnswerTriggerHandlerTest {
    @TestSetup
    static void setup(){
        Account patient = new Account(Name='Test');
        insert patient;

        disco__Question__c[] questions = new disco__Question__c[]{
            new disco__Question__c(disco__Label__c='This application is ready for Team Review'),
            new disco__Question__c(disco__Label__c='Send to Medical Records to complete this process'),
            new disco__Question__c(disco__Label__c='Finalize and lock this application'),
            new disco__Question__c(disco__Label__c='This application is ready for Team Review and the Director of Patient Care'),
            new disco__Question__c(disco__Label__c='Send to Director of Patient Care')
        };
        insert questions;
    }
    @IsTest
    public static void test(){
        insert new disco__Answer__c();
    }
}