/**
 * Created By: Synaptic - Fernando Ortiz
 */
public class PhysicalMonitorController {
	public PhysicalMonitorController() {
	}

	public class PhysicalMonitorWrapper {
		public Physical_Monitor__c PhysicalMonitor { get; set; }
		public Boolean IsUpdate { get; set; }
	}

	@AuraEnabled
	public static List<Physical_Monitor__c> getPhysicalMonitorByAccountId(Id accountId) {
		try {
			return [SELECT Id FROM Physical_Monitor__c WHERE Account__c = :accountId];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static Physical_Monitor__c getPhysicalMonitorByNursingShiftItemId(Id nursingShiftItemId) {
		try {
			// return [SELECT Account__c, Age__c, Blood_Glucose_mg_dL__c, Blood_Pressure__c, BMI__c, BMI_Status__c, BP_Cuff_Size__c,
			// BP_Diastolic_mmHg__c, BP_Patient_Refused__c, BP_Systolic_mmHg__c, CreatedById, CreatedDate, Current_Admission_Stage__c,
			// Current_Admitted_Program__c, Date_Time__c, Finalized_By__c, Finalized_By_Name__c, Finalized_By_User__c, Finalized_Date_Time__c,
			// Gender_Identifies_As__c, Glucose_Action_Taken__c, Height_cm__c, Height_in__c, Height_Patient_Refused__c, Id, IsDeleted,
			// LastActivityDate, LastModifiedById, LastModifiedDate, LastReferencedDate, LastViewedDate, Lying_BP_Diastolic_mmHg__c,
			// Lying_BP_Systolic_mmHg__c, Lying_Plus_per_min__c, Name, Other_Observations__c, Oxygen_Saturation__c, Patient_Age__c,
			// Patient_Distinguished_Name__c, Performed_Date_Time__c, Phone__c, Preferred_Pronouns__c, Pregnancy_Urine_Test__c,
			// Previous_ARC_Admissions__c, Procedure_Order__c, Psychotherapist__c, Pulse_per_min__c, RecordTypeId, Respiration_per_min__c,
			// Sex_Assigned_at_Birth__c, Sitting_BP_Systolic_mmHg__c, Sitting_Plus_per_min__c, Standing_BP_Systolic_mmHg__c,
			// Standing_Plus_per_min__c, Status__c, SystemModstamp, Temperature_C__c, Temperature_F__c, Urinalysis_Notes__c,
			// View_Blood_Glucose_Info__c, View_Blood_Pressure_Info__c, View_Height_Weight__c, View_Orthostatic_Blood_Pressure_Info__c,
			// View_Temperature_Info__c, Weight_kg__c, Weight_lbs__c, Weight_Patient_Refused__c
			// FROM Physical_Monitor__c
			// WHERE Id IN (SELECT Physical_Monitor__c FROM Nursing_Shift_Item__c WHERE Id = :nursingShiftItemId)
			// LIMIT 1];

			return ((List<Physical_Monitor__c>) Database.query(QueryUtils.getQueryAll('Physical_Monitor__c', new List<String>()) + ' WHERE Id IN (SELECT Physical_Monitor__c FROM Nursing_Shift_Item__c WHERE Id = :nursingShiftItemId)' + ' LIMIT 1'))[0];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string createUpdatePhysicalMonitor(string strJson) {
		try {
			PhysicalMonitorWrapper physicalMonitor = (PhysicalMonitorWrapper) JSON.deserialize(strJson, PhysicalMonitorWrapper.class);

			if (physicalMonitor == null) {
				throw new AuraHandledException('physicalMonitor is Null');
			}

			if (physicalMonitor.PhysicalMonitor == null) {
				throw new AuraHandledException('physicalMonitor is Null');
			}

			if (physicalMonitor.PhysicalMonitor.Account__c == null) {
				throw new AuraHandledException('Account is missing');
			}

			if (physicalMonitor.isUpdate) {
				update physicalMonitor.PhysicalMonitor;
			} else {
				insert physicalMonitor.PhysicalMonitor;
			}

			return 'Success';
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}