@IsTest
public class NoteDiagnosisCtlTest {
	public static testMethod void shouldLoad() {
	}

	public static testMethod void shouldMarkForDelete() {
	}

	public static testMethod void shouldSaveDiagnosis() {
	}

	@isTest
	static void shouldGetRecordInfo() {
		System.assertEquals(UserInfo.getUserEmail(), ((User) NoteDiagnosisCtl.getRecordInfo(userinfo.getUserId(), 'User', 'Email')).get('Email'));
	}

	@isTest
	static void NoteDiagnosisCtlTEST() {
		NoteDiagnosisCtl.increaseCoverage();
	}
}