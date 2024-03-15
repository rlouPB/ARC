@IsTest
public class RecordTypeHelperTest {
    public static testmethod void test(){
        RecordType rtype = [Select Id, Name, SobjectType from RecordType limit 1];

        for(integer i=0; i<1000; i++){
            system.assertEquals(rtype.Id, (id)RecordTypeHelper.getIdByName(rtype.SobjectType, rtype.Name));
        }
    }
}