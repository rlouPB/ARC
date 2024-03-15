/**
 * @Description:
 * @Created By: Fernando Ortiz
 */

public class AllergyTrigger_Helper 
{

    public static void beforeDelete(List<Allergy__c> triggerOld)
    {
        AllergyTrigger_Handler.checkAllergyDelete(triggerOld);
    }


    public static void afterInsert(Map<Id, Allergy__c> mapNewAllergies) {
        AllergyTrigger_Handler.updatePatientContactAllergyFields(mapNewAllergies);
        AllergyTrigger_Handler.createScriptSurePatientAllergies(mapNewAllergies.values());
        // Dave Avery : 5-Sep-2022 : Commented out as per Alexcia Adams. They are changing directions
        // on the handling of the Med Reconciliation process.
        // AllergyTrigger_Handler.updateMedRecFormIfNeeded(mapNewAllergies.values());
    }


    public static void afterUpdate(Map<Id, Allergy__c> mapOldAllergies, Map<Id, Allergy__c> mapNewAllergies) {
        AllergyTrigger_Handler.updatePatientContactAllergyFields(mapNewAllergies);
        AllergyTrigger_Handler.updateScriptSurePatientAllergies(mapNewAllergies.values());
    }

}