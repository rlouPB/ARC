public without sharing class DispensingService {
	// public static disco__Form_Template__c MED_PACKAGE_RETURN_INFO_FORM_TEMPLATE = [SELECT Id from disco__Form_Template__c WHERE Name = 'Medication Package Return Information' AND disco__Status__c = 'In Use'];
	public static disco__Form_Template__c MED_PACKAGE_RETURN_INFO_FORM_TEMPLATE = [SELECT Id FROM disco__Form_Template__c WHERE DocType_Name__c = 'Medication_Package_Contents' AND disco__Status__c = 'In Use'];
	public static disco__Form_Template__c MED_CONTROLLED_SUBSTANCE_FORM_TEMPLATE = [SELECT Id FROM disco__Form_Template__c WHERE DocType_Name__c = 'Patient_Certification_of_Dispensed' AND disco__Status__c = 'In Use'];

	public static disco__Form_Template__c PSAT_FORM_TEMPLATE = [SELECT Id FROM disco__Form_Template__c WHERE DocType_Name__c = 'Patient_Safety_Assessment_Tool' AND disco__Status__c = 'In Use'];

	public static Id PHARMACIST_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'RiggsPharmacist' LIMIT 1][0].Id;
	public static Boolean isPharmacist = UserInfo.getProfileId() == PHARMACIST_PROFILE_ID ? true : false;

	@AuraEnabled
	public static Account[] getPatients() {
		return [SELECT Id, Name, Patient_LastName__c, Photo__c, Date_of_Birth__c, Current_Admission__r.Dispensing_Status__c, Current_Admission__r.MSA_Schedule__c, Current_Admission__r.MSA_Pickup_Location__c FROM Account WHERE Current_Admission__r.Stage__c = 'Admitted'];
	}

	// JN 220930 These two methods moved to CreateNewCtl
	// @AuraEnabled
	// public static Patient_Note__c[] getDraftAwayOrdersForPatient(Id accountId) {
	// 	return [
	// 		SELECT Id, Type__c, Status__c, Account__c
	// 		FROM Patient_Note__c
	// 		WHERE Account__c = :accountId AND Status__c = 'Draft' AND Type__c = 'Away Medication Order'
	// 	];
	// }

	// @AuraEnabled
	// public static Patient_Note__c[] getDraftMSAOrdersForPatient(Id accountId) {
	// 	return [
	// 		SELECT Id, Type__c, Status__c, Account__c
	// 		FROM Patient_Note__c
	// 		WHERE Account__c = :accountId AND Status__c = 'Draft' AND Type__c = 'Medication Self Administration (MSA) Order'
	// 	];
	// }

	@AuraEnabled
	public static Prescription__c[] getPrescriptions(Id accountId) {
		return [SELECT Id, Medication_Finalize_Display__c, IRIS_Fill_Datetime__c, Name, Status__c, Drug_Name__c, Drug_Format__c, Dispensing_Comment__c, As_Needed__c, Last_Dispensed__c, Last_Dispensed_By__c, Medication_Filled_with__c, Medication_Format__c, Indication_Text__c, Control_Group__c, Dispensed__c, Location__c, Max_Daily__c, Dosage_Quantity__c, Written_Date__c, Fill_Date__c, Start_Date__c, End_Date__c, Pharmacist_Discontinued__c, Pharmacist_Canceled__c, Parent__c, Times_Of_Day__c, Presciber__c, Prescriber_Professional_Name__c, Times_Of_Day_Sort__c, Pharmacy_Note__c FROM Prescription__c WHERE Account__c = :accountId];
	}

	@AuraEnabled
	public static Patient_Note__c[] getOrders(Id accountId) {
		return [SELECT Id, Contact_Date__c, Finalized_Date_Time__c, Discontinue_Date_Time__c, Type__c, New_Medication_Program__c, New_Medication_Program_Location__c, Comments__c FROM Patient_Note__c WHERE Type__c IN ('Away Medication Order', 'Medication Self Administration (MSA) Order', 'Away Medication Order', 'Discharge Medication Order') AND Account__c = :accountId AND Finalized_Date_Time__c = LAST_N_DAYS:30 AND Status__c = 'Finalized'];
	}

	public static Map<Id, Patient_Note__c[]> getOrdersByAccountId(Set<Id> accountIds) {
		Patient_Note__c[] orders = [SELECT Id, Account__c, Contact_Date__c, Finalized_Date_Time__c, Type__c, New_Medication_Program__c, New_Medication_Program_Location__c, Comments__c FROM Patient_Note__c WHERE Type__c IN ('Away Medication Order', 'Medication Self Administration (MSA) Order') AND Account__c IN :accountIds AND Finalized_Date_Time__c = LAST_N_DAYS:30 AND Status__c = 'Finalized'];

		Map<Id, Patient_Note__c[]> dispensingOrdersByAccountId = new Map<Id, Patient_Note__c[]>();
		for (Patient_Note__c pn : orders) {
			if (dispensingOrdersByAccountId.containsKey(pn.Account__c)) {
				Patient_Note__c[] ordersForPatient = dispensingOrdersByAccountId.get(pn.Account__c);
				ordersForPatient.add(pn);
			} else {
				Patient_Note__c[] pns = new List<Patient_Note__c>{ pn };
				dispensingOrdersByAccountId.put(pn.Account__c, pns);
			}
		}
		return dispensingOrdersByAccountId;
	}

	@AuraEnabled
	public static Prescription__c getPrescription(Id prescriptionId) {
		return [
			SELECT Id, Medication_Finalize_Display__c, Name, Status__c, Drug_Name__c, Drug_Format__c, Dispensing_Comment__c, As_Needed__c, Last_Dispensed__c, Last_Dispensed_By__c, Medication_Filled_with__c, Medication_Format__c, Indication_Text__c, Control_Group__c, Dispensed__c, Location__c, Max_Daily__c, Written_Date__c, Fill_Date__c, Start_Date__c, End_Date__c, Pharmacist_Discontinued__c, Pharmacist_Canceled__c, Daily_Dosage_Quantity__c, Duration__c, Account__c, Parent__c, Times_Of_Day__c, Presciber__c, Prescriber_Professional_Name__c, Times_Of_Day_Sort__c, Pharmacy_Note__c
			FROM Prescription__c
			WHERE Id = :prescriptionId
			LIMIT 1
		];
	}

	@AuraEnabled
	public static disco__Form__c[] getControlledSubstanceFormsToAttach() {
		return [SELECT Id, Name, disco__Status__c, disco__Form_Contact__r.Name, CreatedById, CreatedBy.Name, CreatedDate, disco__File_Count__c, Signature_Attached_Later__c, MAR_Medication_Administration_Record__c FROM disco__Form__c WHERE Signature_Attached_Later__c = TRUE AND disco__Status__c != 'LOCKED' AND Template_Doc_Name__c = 'Patient_Certification_of_Dispensed'];
	}

	@AuraEnabled
	public static Prescription__c[] getPrescriptionsToProcess() {
		return [
			SELECT Id, Medication_Finalize_Display__c, Name,IRIS_Fill_Datetime__c, Account__c, Account__r.Name, Status__c, Drug_Name__c, Drug_Format__c, Dispensing_Comment__c, As_Needed__c, Last_Dispensed__c, Last_Dispensed_By__c, Medication_Filled_with__c, Medication_Format__c, Indication_Text__c, Control_Group__c, Dispensed__c, Location__c, Max_Daily__c, Dosage_Quantity__c, Written_Date__c, Fill_Date__c, Start_Date__c, End_Date__c, Pharmacist_Discontinued__c, Pharmacist_Canceled__c, Parent__c, Times_Of_Day__c, Presciber__c, Prescriber_Professional_Name__c, Times_Of_Day_Sort__c, Pharmacy_Note__c
			FROM Prescription__c
			WHERE Status__c IN ('Active Pending Fill', 'Discontinued', 'Canceled', 'Source Script') AND Pharmacist_Discontinued__c = FALSE AND Pharmacist_Canceled__c = FALSE
		];
	}

	public static Prescription__c[] getDispensedPrescriptions(Id accountId) {
		return [SELECT Id, Medication_Finalize_Display__c, Name, Status__c, Drug_Name__c, Drug_Format__c, Dispensing_Comment__c, Last_Dispensed__c, Last_Dispensed_By__c, Medication_Filled_with__c, Medication_Format__c, Indication_Text__c, Control_Group__c, Dispensed__c, Location__c, Max_Daily__c, Written_Date__c, Fill_Date__c, Start_Date__c, End_Date__c FROM Prescription__c WHERE Account__c = :accountId AND Dispensed__c = TRUE];
	}

	@AuraEnabled
	public static Patient_Note__c[] getPatientNoteOrdersToProcess() {
		return [SELECT Id, Name, Type__c, Account__r.Name, Contact_Date__c, Discontinue_Date_Time__c, Account__r.Current_Admission__r.MSA_Schedule__c, Account__r.Current_Admission__r.MSA_Pickup_Location__c, Pharmacy_Complete__c, Away_First_Date__c FROM Patient_Note__c WHERE Pharmacy_Complete__c = FALSE AND Type__c IN ('Medication Self Administration (MSA) Order', 'Away Medication Order', 'Discharge Medication Order') AND Status__c = 'Finalized'];
	}

	@AuraEnabled
	public static Package__c[] getPackages(Id accountId) {
		return [SELECT Dispensed__c, Dispensed_Datetime__c, End_Date__c, Form__c, Form__r.Name, Form_Status__c, Id, Name, OwnerId, Package_Delivery_ETA__c, Package_Name_Fml__c, Patient__c, Start_Date__c, Order__c, Order__r.Name, Medications__c, Control_Group__c, Status__c FROM Package__c WHERE Patient__c = :accountId];
	}

	@AuraEnabled
	public static Package__c getPackage(Id packageId) {
		return [SELECT Dispensed__c, End_Date__c, Form__c, Form__r.Name, Form_Status__c, Id, Name, OwnerId, Package_Delivery_ETA__c, Package_Name_Fml__c, Patient__c, Start_Date__c, Order__c, Order__r.Name, Medications__c, Control_Group__c, Status__c FROM Package__c WHERE Id = :packageId LIMIT 1];
	}

	@AuraEnabled
	public static Package_Line__c[] getPackageLines(Id packageId) {
		System.debug('DispensingService getPackageLines packageId: ' + packageId);
		return [SELECT Id, Name, Amount_Returned__c, Pharmacy_Amount_Returned_Variance__c, Amount_Taken__c, Efficacy__c, Medication_and_Format__c, Prescription__c, Prescription__r.Name, Prescription__r.Medication_Filled_with__c, Prescription_Quantity__c FROM Package_Line__c WHERE Package__c = :packageId ORDER BY Prescription__r.Medication_Filled_with__c, Prescription__r.Name];
	}

	public static Package__c[] getDispensedPackages(Id accountId) {
		return [SELECT Dispensed__c, End_Date__c, Form__c, Form__r.Name, Form_Status__c, Id, Name, OwnerId, Package_Delivery_ETA__c, Package_Name_Fml__c, Patient__c, Start_Date__c, Order__c, Order__r.Name, Medications__c, Control_Group__c, Status__c FROM Package__c WHERE Patient__c = :accountId AND Dispensed__c = TRUE];
	}

	@AuraEnabled
	public static void cleardDispensedPrescriptions(Id accountId) {
		Prescription__c[] prescriptions = getDispensedPrescriptions(accountId);
		Set<Id> prescriptionIds = new Set<Id>();
		for (Prescription__c p : prescriptions) {
			p.Dispensed__c = false;
			prescriptionIds.add(p.Id);
		}

		List<Medication_Administration_Line__c> marLines = [SELECT Id, MAR_Medication_Administration_Record__c, Controlled_Substance_Form__c FROM Medication_Administration_Line__c WHERE Prescription__c IN :prescriptionIds AND Status__c = 'Dispensed'];

		disco__Form__c[] controlledSubstanceFormsToDelete = new List<disco__Form__c>{};
		// Map<Id, Medication_Administration_Record__c> marsById = new Map<Id, Medication_Administration_Record__c>();
		for (Medication_Administration_Line__c marl : marLines) {
			if (null != marl.Controlled_Substance_Form__c) {
				controlledSubstanceFormsToDelete.add(new disco__Form__c(Id = marl.Controlled_Substance_Form__c));
			}
			// marsById.put(
			// 	marl.MAR_Medication_Administration_Record__c,
			// 	new Medication_Administration_Record__c(Id = marl.MAR_Medication_Administration_Record__c)
			// );
		}

		update prescriptions;
		// delete marsById.values();
		delete marLines;
		delete controlledSubstanceFormsToDelete;
	}

	@AuraEnabled
	public static void clearDispensedPrescriptionsForPrescriptions(SObject[] prescriptionIdsArr) {
		Set<Id> prescriptionIds = new Set<Id>();
		for (SObject so : prescriptionIdsArr) {
			prescriptionIds.add(so.Id);
		}

		Prescription__c[] prescriptions = [SELECT Id, Name, Status__c, Drug_Name__c, Drug_Format__c, Dispensing_Comment__c, Last_Dispensed__c, Last_Dispensed_By__c, Medication_Filled_with__c, Medication_Format__c, Indication_Text__c, Control_Group__c, Dispensed__c, Location__c, Max_Daily__c, Written_Date__c, Fill_Date__c, Start_Date__c, End_Date__c FROM Prescription__c WHERE Id IN :prescriptionIds AND Dispensed__c = TRUE];
		Set<Id> pIds = new Set<Id>();
		for (Prescription__c p : prescriptions) {
			p.Dispensed__c = false;
			pIds.add(p.Id);
		}

		List<Medication_Administration_Line__c> marLines = [SELECT Id, MAR_Medication_Administration_Record__c, Controlled_Substance_Form__c FROM Medication_Administration_Line__c WHERE Prescription__c IN :pIds AND Status__c = 'Dispensed'];
		disco__Form__c[] controlledSubstanceFormsToDelete = new List<disco__Form__c>{};
		Map<Id, Medication_Administration_Record__c> marsById = new Map<Id, Medication_Administration_Record__c>();
		for (Medication_Administration_Line__c marl : marLines) {
			if (null != marl.Controlled_Substance_Form__c) {
				controlledSubstanceFormsToDelete.add(new disco__Form__c(Id = marl.Controlled_Substance_Form__c));
			}
			// marsById.put(
			// 	marl.MAR_Medication_Administration_Record__c,
			// 	new Medication_Administration_Record__c(Id = marl.MAR_Medication_Administration_Record__c)
			// );
		}

		update prescriptions;
		// delete marsById.values();
		delete marLines;
		delete controlledSubstanceFormsToDelete;
	}

	@AuraEnabled
	public static void clearDispensedPackages(Id accountId) {
		Package__c[] packages = getDispensedPackages(accountId);
		Set<Id> packageIds = new Set<Id>();
		for (Package__c p : packages) {
			p.Dispensed__c = false;
			packageIds.add(p.Id);
		}

		List<Medication_Administration_Record__c> mars = [SELECT Id, Controlled_Substance_Form__c FROM Medication_Administration_Record__c WHERE Package__c IN :packageIds];
		disco__Form__c[] controlledSubstanceFormsToDelete = new List<disco__Form__c>{};
		for (Medication_Administration_Record__c mar : mars) {
			if (null != mar.Controlled_Substance_Form__c) {
				controlledSubstanceFormsToDelete.add(new disco__Form__c(Id = mar.Controlled_Substance_Form__c));
			}
		}
		update packages;
		delete mars;
		delete controlledSubstanceFormsToDelete;
	}

	@AuraEnabled
	public static string finalizePrescriptions(Id[] prescriptionIds, Id patientId) {
		try {
			Set<Id> dfIds = new Set<Id>();
			Map<Id, Medication_Administration_Line__c> marLinesByDFId = new Map<Id, Medication_Administration_Line__c>();
			for (Medication_Administration_Line__c marLine : [SELECT Id, Controlled_Substance_Form__c, Medication__c FROM Medication_Administration_Line__c WHERE Prescription__c IN :prescriptionIds AND Status__c = 'Dispensed']) {
				dfIds.add(marLine.Controlled_Substance_Form__c);
				marLinesByDFId.put(marLine.Controlled_Substance_Form__c, marLine);
			}

			disco__Form__c[] dfs = [SELECT Id, Name, Available_in_Community__c, disco__Status__c FROM disco__Form__c WHERE Id IN :dfIds];
			String validationMessage = 'The following medications need to have their controlled substance forms submitted: ';
			Boolean hasValidationError = false;
			for (disco__Form__c df : dfs) {
				if (!isPharmacist && !df.disco__Status__c.equals('LOCKED')) {
					validationMessage += marLinesByDFId.get(df.Id).Medication__c + ', ';
					hasValidationError = true;
				}
			}

			if (hasValidationError) {
				validationMessage = validationMessage.trim().removeEnd(',');
				validationMessage += '.';
				return validationMessage;
			}

			Medication_Administration_Record__c[] marsToUpdate = [SELECT Id FROM Medication_Administration_Record__c WHERE Id IN (SELECT MAR_Medication_Administration_Record__c FROM Medication_Administration_Line__c WHERE Prescription__c IN :prescriptionIds)];
			for (Medication_Administration_Record__c mar : marsToUpdate) {
				mar.Status__c = 'Finalized';
			}

			Prescription__c[] prescriptionsToUpdate = new List<Prescription__c>{};
			for (Id pId : prescriptionIds) {
				prescriptionsToUpdate.add(new Prescription__c(Id = pId, Dispensed__c = false, Last_Dispensed__c = System.NOW(), Last_Dispensed_By__c = UserInfo.getUserId()));
			}

			update marsToUpdate;
			update prescriptionsToUpdate;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static string dispensePrescriptions(Id[] prescriptionIds, Id patientId) {
		// String controlledSubstanceFormId = '';
		try {
			Account acc = [SELECT current_admission__c FROM account WHERE id = :patientId];
			Contact contact = [SELECT Id FROM Contact WHERE AccountId = :patientId];
			Prescription__c[] prescriptionsToUpdate = [SELECT ID, Control_Group__c, Dosage_Quantity__c FROM Prescription__c WHERE Id IN :prescriptionIds];
			Medication_Administration_Record__c[] marsToInsert = new List<Medication_Administration_Record__c>{};

			Medication_Administration_Record__c mar = new Medication_Administration_Record__c(Patient__c = patientId, Admission__c = acc.current_admission__c, Status__c = 'Dispensed');
			insert mar;

			Medication_Administration_Line__c[] marLinesToInsert = new List<Medication_Administration_Line__c>{};
			// disco__Form__c[] controlledSubstanceForms = new disco__Form__c[]{};
			Boolean hasControlledSubstanceForm = false;
			for (Prescription__c p : prescriptionsToUpdate) {
				p.Dispensed__c = true;

				marLinesToInsert.add(new Medication_Administration_Line__c(MAR_Medication_Administration_Record__c = mar.Id, Prescription__c = p.Id, Patient__c = patientId, Quantity__c = p.Dosage_Quantity__c));

				// if(!hasControlledSubstanceForm && ('2'.equals(p.Control_Group__c) || '4'.equals(p.Control_Group__c))) {
				//     disco__Form__c df = new disco__Form__c(
				//         MAR_Medication_Administration_Record__c = mar.Id,
				//         disco__Form_Account__c = patientId,
				//         disco__Form_Template__c = DispensingService.MED_CONTROLLED_SUBSTANCE_FORM_TEMPLATE.Id,
				//         disco__Form_Contact__c = contact.Id
				//     );
				//     hasControlledSubstanceForm = true;
				//     controlledSubstanceForms.add(df);
				// }
			}
			update prescriptionsToUpdate;
			insert marLinesToInsert;
			// insert controlledSubstanceForms;

			// Map<Id, disco__Form__c> dfByMarId = new Map<Id, disco__Form__c>();
			// for(disco__Form__c df : controlledSubstanceForms) {
			//     dfByMarId.put(df.MAR_Medication_Administration_Record__c, df);
			// }

			// Set<Id> marLineIds = new Set<Id>();
			// for(Medication_Administration_Line__c marl : marLinesToInsert) {
			//     marLineIds.add(marl.Id);
			// }
			// Medication_Administration_Line__c[] marLinesToUpdate = [SELECT Id, Controlled_Substance__c, MAR_Medication_Administration_Record__c FROM Medication_Administration_Line__c WHERE Id IN :marLineIds];
			// System.debug('marLinesToUpdate : ' + marLinesToUpdate);

			// Medication_Administration_Record__c[] marsToUpdate = new Medication_Administration_Record__c[]{};

			// for(Medication_Administration_Line__c marl : marLinesToUpdate) {
			//     if(marl.Controlled_Substance__c) {
			//         System.debug('dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id  : ' + dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id);
			//         marl.Controlled_Substance_Form__c = dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id;
			//         controlledSubstanceFormId = isPharmacist ? '' : marl.Controlled_Substance_Form__c;
			//         marsToUpdate.add(new Medication_Administration_Record__c(
			//             Id = marl.MAR_Medication_Administration_Record__c,
			//             Controlled_Substance_Form__c = marl.Controlled_Substance_Form__c
			//         ));
			//     }
			// }
			// update marLinesToUpdate;
			// update marsToUpdate;
		} catch (Exception e) {
			return e.getMessage();
		}
		return '';
	}

	@AuraEnabled
	public static string dispensePackages(Id[] packageIds, Id patientId) {
		String controlledSubstanceFormId = '';
		try {
			Account acc = [SELECT current_admission__c FROM account WHERE id = :patientId];
			Contact contact = [SELECT Id FROM Contact WHERE AccountId = :patientId];
			Package__c[] packagesToUpdate = [SELECT Id, (SELECT ID, Prescription__c, Prescription__r.Control_Group__c, Prescription_Quantity__c FROM Package_Lines__r) FROM Package__c WHERE Id IN :packageIds];
			Medication_Administration_Record__c[] marsToInsert = new List<Medication_Administration_Record__c>{};

			for (Package__c p : packagesToUpdate) {
				marsToInsert.add(new Medication_Administration_Record__c(Package__c = p.Id, Patient__c = patientId, Admission__c = acc.current_admission__c, Status__c = 'Dispensed'));
				p.Dispensed__c = true;
			}
			insert marsToInsert;
			update packagesToUpdate;

			Map<Id, Medication_Administration_Record__c> marsByPackageId = new Map<Id, Medication_Administration_Record__c>();
			Map<Id, Medication_Administration_Record__c> marsById = new Map<Id, Medication_Administration_Record__c>();
			for (Medication_Administration_Record__c mar : marsToInsert) {
				marsByPackageId.put(mar.Package__c, mar);
				marsById.put(mar.Id, mar);
			}

			Medication_Administration_Line__c[] marLinesToInsert = new List<Medication_Administration_Line__c>{};
			disco__Form__c[] controlledSubstanceForms = new List<disco__Form__c>{};
			for (Package__c p : packagesToUpdate) {
				Boolean hasControlledSubstanceForm = false;
				for (Package_Line__c pl : p.Package_Lines__r) {
					marLinesToInsert.add(new Medication_Administration_Line__c(MAR_Medication_Administration_Record__c = marsByPackageId.get(p.Id).Id, Package_Line__c = pl.Id, Prescription__c = pl.Prescription__c, Patient__c = patientId, Quantity__c = pl.Prescription_Quantity__c));

					if (!hasControlledSubstanceForm && ('2'.equals(pl.Prescription__r.Control_Group__c) || '4'.equals(pl.Prescription__r.Control_Group__c))) {
						disco__Form__c df = new disco__Form__c(MAR_Medication_Administration_Record__c = marsByPackageId.get(p.Id).Id, disco__Form_Account__c = patientId, disco__Form_Template__c = DispensingService.MED_CONTROLLED_SUBSTANCE_FORM_TEMPLATE.Id, disco__Form_Contact__c = contact.Id);
						hasControlledSubstanceForm = true;
						controlledSubstanceForms.add(df);
					}
				}
			}
			System.debug('marLinesToInsert : ' + marLinesToInsert);
			insert marLinesToInsert;
			System.debug('controlledSubstanceForms : ' + controlledSubstanceForms);
			insert controlledSubstanceForms;

			Map<Id, disco__Form__c> dfByMarId = new Map<Id, disco__Form__c>();
			for (disco__Form__c df : controlledSubstanceForms) {
				dfByMarId.put(df.MAR_Medication_Administration_Record__c, df);
			}

			Set<Id> marLineIds = new Set<Id>();
			for (Medication_Administration_Line__c marl : marLinesToInsert) {
				marLineIds.add(marl.Id);
			}
			Medication_Administration_Line__c[] marLinesToUpdate = [SELECT Id, Controlled_Substance__c, MAR_Medication_Administration_Record__c FROM Medication_Administration_Line__c WHERE Id IN :marLineIds];
			System.debug('marLinesToUpdate : ' + marLinesToUpdate);

			Medication_Administration_Record__c[] marsToUpdate = new List<Medication_Administration_Record__c>{};

			boolean controlledSubstanceFormAddedToMar = false;
			for (Medication_Administration_Line__c marl : marLinesToUpdate) {
				if (marl.Controlled_Substance__c) {
					System.debug('dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id  : ' + dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id);
					marl.Controlled_Substance_Form__c = dfByMarId.get(marl.MAR_Medication_Administration_Record__c).Id;
					controlledSubstanceFormId = isPharmacist ? '' : marl.Controlled_Substance_Form__c;
					if (!controlledSubstanceFormAddedToMar) {
						marsToUpdate.add(new Medication_Administration_Record__c(Id = marl.MAR_Medication_Administration_Record__c, Controlled_Substance_Form__c = marl.Controlled_Substance_Form__c, Signature_Attached_Later__c = isPharmacist));
						controlledSubstanceFormAddedToMar = true;
					}
				}
			}
			update marLinesToUpdate;
			System.debug('marsToUpdate : ' + marsToUpdate);
			update marsToUpdate;
		} catch (Exception e) {
			return e.getMessage();
		}
		return controlledSubstanceFormId;
	}

	@AuraEnabled
	public static string printPackages(Id[] packageIds) {
		SDocCallableParent__c sdocCallableParent = new SDocCallableParent__c();
		insert sdocCallableParent;

		List<Package__c> packagesToUpdate = new List<Package__c>();
		for (Id pId : packageIds) {
			packagesToUpdate.add(new Package__c(Id = pId, SDocCallableParent__c = sdocCallableParent.Id));
		}
		update packagesToUpdate;
		return sdocCallableParent.Id;
	}

	@AuraEnabled
	public static String packageAndPrintForPatients(Id[] patientIds, Date startDate, Date endDate, Datetime packageDeliveryETA) {
		Account[] patients = [SELECT Id, Patient_LastName__c FROM Account WHERE Id IN :patientIds ORDER BY Patient_LastName__c ASC];
		Map<Id, SDocCallableParent__c> sdocCallableParentsByAccountId = new Map<Id, SDocCallableParent__c>();
		for (Account p : patients) {
			SDocCallableParent__c sdocCallableParent = new SDocCallableParent__c();
			sdocCallableParentsByAccountId.put(p.Id, sdocCallableParent);
		}
		insert sdocCallableParentsByAccountId.values();

		Map<Id, Package__c> packagesByPatientId = new Map<Id, Package__c>();
		for (Id patientId : patientIds) {
			Package__c myPackage = new Package__c(Patient__c = patientId, SDocCallableParent__c = sdocCallableParentsByAccountId.get(patientId).Id, Start_Date__c = startDate, End_Date__c = endDate, Package_Delivery_ETA__c = packageDeliveryETA, Control_Group__c = null);
			packagesByPatientId.put(patientId, myPackage);
		}
		insert packagesByPatientId.values();

		String prescriptionsQuery = 'SELECT Id, Account__c, On_Going_Quantity__c, Start_Date__c, End_Date__c, Control_Group__c ' + 'FROM Prescription__c ' + ' WHERE Account__c IN :patientIds ' + 'AND Location__c = \'Package\' ' + 'AND Status__c = \'Active\' ' + 'AND Exclude_from_Regular_Package__c = false';

		String dbDateFormat = 'yyy-MM-dd';
		if (null != startDate) {
			String startDateStr = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format(dbDateFormat);
			if (null != endDate) {
				String endDateStr = DateTime.newInstance(endDate.year(), endDate.month(), endDate.day()).format(dbDateFormat);
				prescriptionsQuery += ' AND (End_Date__c >=' + startDateStr + ' OR End_Date__c = null)' + ' AND (Start_Date__c <= ' + endDateStr + ' OR Start_Date__c = null)';
			} else {
				prescriptionsQuery += ' AND (Start_Date__c <= ' + startDateStr + ' OR Start_Date__c = null)' + ' AND (End_Date__c >= ' + startDateStr + ' OR End_Date__c = null)';
			}
		}

		System.debug('prescriptionsQuery : ' + prescriptionsQuery);

		List<Prescription__c> prescriptions = Database.query(prescriptionsQuery);

		System.debug('prescriptions : ' + prescriptions);

		List<Package_Line__c> packageLines = new List<Package_Line__c>();
		for (Prescription__c p : prescriptions) {
			Package_Line__c pl = new Package_Line__c(Package__c = packagesByPatientId.get(p.Account__c).Id, Prescription__c = p.Id, Prescription_Quantity__c = p.On_Going_Quantity__c);
			packageLines.add(pl);

			if ('2'.equals(p.Control_Group__c)) {
				packagesByPatientId.get(p.Account__c).Control_Group__c = '2';
			} else if ('4'.equals(p.Control_Group__c) && null == packagesByPatientId.get(p.Account__c).Control_Group__c) {
				packagesByPatientId.get(p.Account__c).Control_Group__c = '4';
			}
		}
		insert packageLines;

		List<Contact> contacts = [SELECT Id, AccountId, Account.Current_Admission__c FROM Contact WHERE AccountId = :patientIds];
		Map<Id, Contact> contactsByAccountId = new Map<Id, Contact>();
		for (Contact c : contacts) {
			contactsByAccountId.put(c.AccountId, c);
		}

		Map<Id, disco__Form__c> returnInfoFormsByPackageId = new Map<Id, disco__Form__c>();
		for (Id patientId : patientIds) {
			disco__Form__c df = new disco__Form__c(Package__c = packagesByPatientId.get(patientId).Id, disco__Form_Account__c = patientId, disco__Form_Template__c = DispensingService.MED_PACKAGE_RETURN_INFO_FORM_TEMPLATE.Id, disco__Form_Contact__c = contactsByAccountId.get(patientId).Id, Admission__c = contactsByAccountId.get(patientId).Account.Current_Admission__c);
			returnInfoFormsByPackageId.put(packagesByPatientId.get(patientId).Id, df);
		}
		insert returnInfoFormsByPackageId.values();

		for (Package__c myPackage : packagesByPatientId.values()) {
			myPackage.Form__c = returnInfoFormsByPackageId.get(myPackage.Id).Id;
		}
		System.debug('packagesByPatientId.values() : ' + packagesByPatientId.values());
		update packagesByPatientId.values();

		String sdocCallableParentIdsStr = '';
		for (SDocCallableParent__c sDocP : sdocCallableParentsByAccountId.values()) {
			sdocCallableParentIdsStr += sDocP.Id + ',';
		}
		sdocCallableParentIdsStr = sdocCallableParentIdsStr.removeEnd(',');

		return sdocCallableParentIdsStr;
	}

	@AuraEnabled
	public static string finalizePackages(Id[] packageIds, Id patientId) {
		try {
			Set<Id> dfIds = new Set<Id>();
			Map<Id, Medication_Administration_Record__c> marsByDFId = new Map<Id, Medication_Administration_Record__c>();
			for (Medication_Administration_Record__c mar : [SELECT Id, Controlled_Substance_Form__c, Package__r.Package_Name_Fml__c, Package__r.Form__c FROM Medication_Administration_Record__c WHERE Package__c IN :packageIds]) {
				dfIds.add(mar.Controlled_Substance_Form__c);
				marsByDFId.put(mar.Controlled_Substance_Form__c, mar);
				dfIds.add(mar.Package__r.Form__c);
			}

			disco__Form__c[] dfs = [SELECT Id, Name, Available_in_Community__c, disco__Status__c FROM disco__Form__c WHERE Id IN :dfIds];
			String validationMessage = 'The following packages need to have their controlled substance forms submitted: ';
			Boolean hasValidationError = false;
			for (disco__Form__c df : dfs) {
				df.Available_in_Community__c = true;
				if (!isPharmacist && !df.disco__Status__c.equals('LOCKED') && marsByDFId.containsKey(df.Id)) {
					validationMessage += marsByDFId.get(df.Id).Package__r.Package_Name_Fml__c + ', ';
					hasValidationError = true;
				}
			}

			if (hasValidationError) {
				validationMessage = validationMessage.trim().removeEnd(',');
				validationMessage += '.';
				return validationMessage;
			}

			Package__c[] packagesToUpdate = new List<Package__c>{};
			Medication_Administration_Record__c[] marsToUpdate = [SELECT Id, Package__c FROM Medication_Administration_Record__c WHERE Package__c IN :packageIds];
			for (Medication_Administration_Record__c mar : marsToUpdate) {
				mar.Status__c = 'Finalized';
				packagesToUpdate.add(new Package__c(Id = mar.Package__c, Dispensed__c = false, Status__c = 'Finalized', Dispensed_Datetime__c = System.NOW()));
			}
			update marsToUpdate;
			update packagesToUpdate;
			update dfs;

			Package_Line__c[] pls = [SELECT Prescription__c FROM Package_Line__c WHERE Package__c IN :packageIds];
			Prescription__c[] prescriptionsToUpdate = new List<Prescription__c>();
			for (Package_Line__c pl : pls) {
				prescriptionsToUpdate.add(new Prescription__c(Id = pl.Prescription__c, Last_Dispensed__c = System.NOW(), Last_Dispensed_By__c = UserInfo.getUserId()));
			}
			update prescriptionsToUpdate;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static string cancelPackages(Id[] packageIds) {
		try {
			Package__c[] packagesToUpdate = new List<Package__c>{};
			for (Id pId : packageIds) {
				packagesToUpdate.add(new Package__c(Id = pId, Dispensed__c = false, Status__c = 'Canceled'));
			}
			update packagesToUpdate;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	@AuraEnabled
	public static FieldDefinition[] getFieldDefinitions(String sobjectType, String[] fieldNames) {
		try {
			return [SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = :sobjectType AND QualifiedApiName IN :fieldNames];
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage() + ' - ' + e.getStackTraceString());
		}
	}

	@AuraEnabled
	public static string insertPackage(Package__c record, SObject[] prescriptionIdsArr) {
		try {
			System.debug('prescriptionIdsArr : ' + prescriptionIdsArr);
			Set<Id> prescriptionIds = new Set<Id>();
			for (SObject so : prescriptionIdsArr) {
				prescriptionIds.add(so.Id);
			}
			System.debug('prescriptionIds : ' + prescriptionIds);

			List<Prescription__c> prescriptions = [SELECT Id, On_Going_Quantity__c, Exclude_from_Regular_Package__c, Control_Group__c FROM Prescription__c WHERE ID IN :prescriptionIds];
			System.debug('prescriptions : ' + prescriptions);

			Boolean allPrescriptionsAreSpecial = true;
			for (Prescription__c p : prescriptions) {
				if (!p.Exclude_from_Regular_Package__c) {
					allPrescriptionsAreSpecial = false;
				}

				if ('2'.equals(p.Control_Group__c)) {
					record.Control_Group__c = '2';
				} else if ('4'.equals(p.Control_Group__c) && null == record.Control_Group__c) {
					record.Control_Group__c = '4';
				}
			}
			record.Entire_Package_is_Special__c = allPrescriptionsAreSpecial;
			insert record;

			List<Package_Line__c> packageLines = new List<Package_Line__c>();
			for (Prescription__c p : prescriptions) {
				Package_Line__c pl = new Package_Line__c(Package__c = record.Id, Prescription__c = p.Id, Prescription_Quantity__c = p.On_Going_Quantity__c);
				packageLines.add(pl);
			}
			insert packageLines;

			Contact contact = [SELECT Id, Account.Current_Admission__c FROM Contact WHERE AccountId = :record.Patient__c];

			disco__Form__c df = new disco__Form__c(Package__c = record.Id, disco__Form_Account__c = record.Patient__c, disco__Form_Template__c = DispensingService.MED_PACKAGE_RETURN_INFO_FORM_TEMPLATE.Id, disco__Form_Contact__c = contact.Id, Admission__c = contact.Account.Current_Admission__c);

			if (record.Entire_Package_is_Special__c) {
				df.disco__save_complete__c = true;
				df.disco__locked__c = true;
				df.Finalized_By__c = userInfo.getUserId();
				df.Finalized_Date_Time__c = Datetime.now();
			}
			insert df;

			System.debug('df.Id : ' + df.Id);
			record.Form__c = df.Id;
			update record;
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}

	// Dave S, 23-Feb-2022:  This method is temporary, currently being used for retrieving prototype data for editable lightning table dispensingPackageLinesLwc
	@AuraEnabled(cacheable=true)
	public static List<Account> getAccounts() {
		List<Account> accList = [SELECT Id, Name, Phone__c, Gender_Identifies_As__c, Dispensing_Status__c, MSA_Schedule__c, MSA_Pickup_Location__c FROM Account WHERE RecordType.Name = 'Patient' AND Current_Admission_stage__c = 'Admitted' ORDER BY Patient_Contact__r.LastName, Patient_Contact__r.FirstName];
		return accList;
	}

	@AuraEnabled
	public static Medication_Administration_Line__c[] getMARLinesForMaxDosageValidationForPrescription(Id prescriptionId) {
		String startDt = string.valueOfGmt(System.Now().addHours(-20));
		startDt = startDt.replace(' ', 'T');
		startDt += 'Z';
		String endDt = string.valueOfGmt(System.Now());
		endDt = endDt.replace(' ', 'T');
		endDt += 'Z';
		String queryStr = 'SELECT CreatedDate, Id, Prescription__c, Quantity__c, Status__c ' + 'FROM Medication_Administration_Line__c ' + 'WHERE Prescription__c =\'' + prescriptionId + '\' AND CreatedDate >=' + startDt + ' AND CreatedDate <= ' + endDt + ' AND Status__c = \'Finalized\' Order By CreatedDate ASC';
		System.Debug('queryStr : ' + queryStr);
		return Database.query(queryStr);
	}

	@AuraEnabled
	public static Map<Id, List<Medication_Administration_Line__c>> getDispensingHistoryForPrescriptions(Id[] prescriptionIds, Date startDate, Date endDate) {
		System.Debug('prescriptionIds : ' + prescriptionIds);
		System.Debug('startDate : ' + startDate);
		System.Debug('endDate : ' + endDate);

		Map<Id, List<Medication_Administration_Line__c>> marLinesByPrescriptionId = new Map<Id, List<Medication_Administration_Line__c>>();

		Medication_Administration_Line__c[] marLines = [SELECT Id, CreatedDate, Medication__c, Prescription__c FROM Medication_Administration_Line__c WHERE CreatedDate >= :startDate AND CreatedDate <= :endDate AND Prescription__c IN :prescriptionIds];

		for (Medication_Administration_Line__c marLine : marLines) {
			if (marLinesByPrescriptionId.containsKey(marLine.Prescription__c)) {
				marLinesByPrescriptionId.get(marLine.Prescription__c).add(marLine);
			} else {
				marLinesByPrescriptionId.put(marLine.Prescription__c, new List<Medication_Administration_Line__c>{ marLine });
			}
		}

		return marLinesByPrescriptionId;
	}

	@AuraEnabled
	public static Prescription__c clonePrescription(Id prescriptionId) {
		Prescription__c prescription = DispensingService.getPrescription(prescriptionId);
		Prescription__c prescription2 = prescription.clone(false, false, false, false);
		prescription2.Parent__c = prescription.Id;
		prescription2.Status__c = 'Active Pending Fill';
		prescription2.Last_Dispensed_By__c = null;
		prescription2.Last_Dispensed__c = null;
		insert prescription2;
		prescription.Status__c = 'Source Script';
		update prescription;
		return prescription2;
	}
}