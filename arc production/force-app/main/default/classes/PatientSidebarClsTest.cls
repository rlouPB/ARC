@IsTest
public class PatientSidebarClsTest {
    public static testmethod void test(){
        Account a = new account(Name='test');
        insert a;

        PatientSidebarCls.ResultWrapper result1 = PatientSidebarCls.loadRecordData(a.Id, 'Name,CreatedBy.Profile.Name'.split(','));

        system.assert( String.isEmpty(result1.errorMessage), JSON.serialize(result1));
    }

    public static testmethod void testErrors(){
        PatientSidebarCls.ResultWrapper result1 = PatientSidebarCls.loadRecordData(null, 'Name,CreatedBy.Profile.Name'.split(','));

        system.assert(String.isNotEmpty(result1.errorMessage), JSON.serialize(result1));
    }
}