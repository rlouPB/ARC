@isTest(SeeAllData=true)
public with sharing class LightningForgotPasswordControllerTest {
	/* Verifies that ForgotPasswordController handles invalid usernames appropriately */
	@isTest
	static void testLightningForgotPasswordControllerInvalidUserName() {
		System.assertEquals(LightningForgotPasswordController.forgotPassword('fakeUser', 'http://a.com'), Label.Site.invalid_email);
		System.assertEquals(LightningForgotPasswordController.forgotPassword(null, 'http://a.com'), Label.Site.invalid_email);
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a', '/home/home.jsp'), Label.Site.invalid_email);
	}

	/* Verifies that null checkEmailRef url throws proper exception. */
	@isTest
	static void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a', null), 'Argument 1 cannot be null');
		System.assertEquals(LightningForgotPasswordController.forgotPassword('a@salesforce.com', null), 'Argument 1 cannot be null');
	}

	/* Verifies that LightningForgotPasswordController object is instantiated correctly. */
	@isTest
	static void LightningForgotPasswordControllerInstantiation() {
		LightningForgotPasswordController controller = new LightningForgotPasswordController();
		System.assertNotEquals(controller, null);
	}

	@isTest
	static void testSetExperienceId() {
		String expid = ApexPages.currentPage().getParameters().get('expid');
		LightningForgotPasswordController.setExperienceId(expid);
		LightningForgotPasswordController.setExperienceId('');
	}
}