@IsTest
public class CustomRecordDataController_Test {
    public static testmethod void shouldGetDataRegarless(){
        CustomRecordDataController.GetRecordDataResult resultWithoutSharing = CustomRecordDataController.GetRecordData(userinfo.getUserId(),'Name',false);
        CustomRecordDataController.GetRecordDataResult resultWithSharing = CustomRecordDataController.GetRecordData(userinfo.getUserId(),'Name',true);
        
        system.assertNotEquals(null,resultWithoutSharing.data);
        system.assertNotEquals(null,resultWithSharing.data);
    }
    
    public static testmethod void shouldThrowError(){
        CustomRecordDataController.GetRecordDataResult result = CustomRecordDataController.GetRecordData(null,null,null);   
        CustomRecordDataController.GetRecordDataResult resultInvalidType = CustomRecordDataController.GetRecordData('thisIsAnInvalidId','Name',false);
        
        system.assertNotEquals(null,result.error);
        system.assertNotEquals(null,resultInvalidType.error);
    }
}