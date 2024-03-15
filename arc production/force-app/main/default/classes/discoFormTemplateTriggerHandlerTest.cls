@IsTest
public class discoFormTemplateTriggerHandlerTest {
    @IsTest
    public static void test(){
         list<disco__Form_Template__c> dft = new disco__Form_Template__c[]{
            new disco__Form_Template__c()            
                };
       insert dft;             
                    delete [select id from disco__Form_Template__c ];
        
        discoForm_TemplateTriggerHandler dh = new discoForm_TemplateTriggerHandler();
        dh.afterUpdate(dft[0], dft[0]);
        dh.afterDelete(dft[0]);
    }
    
    @IsTest
    public static void testDocTypeValidationFail(){
        boolean errorThrown;
        try{
            insert new disco__Form_Template__c[]{
                new disco__Form_Template__c(DocType_Name__c='Test',disco__Status__c='In Use'),
                    new disco__Form_Template__c(DocType_Name__c='Test',disco__Status__c='In Use')
                    };
                        }catch(Exception ex){
                            errorThrown = true;
                            system.assert(ex.getMessage().contains( discoFormTemplateTriggerhandlerHelper.DUPLICATE_DOCTYPE_ERROR_BASE ),'Invalid Error: ' + ex.getMessage());
                        }
        system.assertEquals(true,errorThrown,'Should have thrown an error');
    }
    
    @IsTest
    public static void testDocTypeValidationFail2(){
        boolean errorThrown;
        try{
            insert new disco__Form_Template__c(DocType_Name__c='Test',disco__Status__c='In Use');
            
            TriggerFactory.Recursions.clear();
            
            insert new disco__Form_Template__c(DocType_Name__c='Test',disco__Status__c='In Use');
        }catch(Exception ex){
            errorThrown = true;
            system.assert(ex.getMessage().contains( discoFormTemplateTriggerhandlerHelper.DUPLICATE_DOCTYPE_ERROR_BASE ),'Invalid Error: ' + ex.getMessage());
        }
        system.assertEquals(true,errorThrown,'Should have thrown an error');
    }
}