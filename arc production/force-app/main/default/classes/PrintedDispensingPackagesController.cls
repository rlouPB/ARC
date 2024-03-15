global with sharing class PrintedDispensingPackagesController {
	public String currentRecordIds { get; set; }
	public List<String> packageHTMLs { get; set; }
	public disco__Form__c currentRecord { get; set; }
	public Id logoContentVersionId { get; set; }
	public PrintedDispensingPackagesController() {
		currentRecordIds = ApexPages.CurrentPage().getparameters().get('ids');
		packageHTMLs = new List<String>();
	}
	public PageReference init() {
		if (null != currentRecordIds) {
			String[] currentRecordIdsArray = currentRecordIds.split(',');

			List<disco__Form__c> forms = [
				SELECT
					Id,
					Name,
					Package__r.Patient__r.Name,
					Package__r.Patient__r.Medical_Record_Number__c,
					Package__r.Patient__r.Current_Admission__r.Admit_Date__c,
					Package__r.Patient__r.Date_of_Birth__c,
					Package__r.Package_Name_Fml__c,
					Package__r.Start_Date__c,
					Package__r.End_Date__c,
					Package__r.MSA_Schedule__c,
					Package__r.MSA_Pickup_Location__c,
					Package__r.Control_Group__c,
					(SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c FROM disco__Answers__r ORDER BY Name)
				FROM disco__Form__c
				WHERE Id IN (SELECT Form__c FROM Package__c WHERE SDocCallableParent__c IN :currentRecordIdsArray)
				ORDER BY Package__r.Patient__r.Patient_LastName__c
			];

			String dateFormatString = 'MM/dd/yyyy';
			Integer i = 0;
			for (disco__Form__c form : forms) {
				String computedHtml = '';
				computedHtml += '<div class="header">';
				computedHtml += '<div class="red-border center-text">';
				computedHtml += '<p class="red slim-margin bold">' + Label.ARC_Medical_Record_Disclaimer + '</p>';
				computedHtml += '</div>';
				if (i > 0) {
					computedHtml += '<div id="spacerOnSubsequentPages" style="padding-top:18px;"></div>';
				}
				computedHtml += '<div class="float-left"><img alt="" class="logo-image" src="' + PageReference.forResource('Riggs_Logo_Medical_Records').getUrl() + '" /><br />';
				computedHtml += '<span style="font-size:16px;">' + Label.ARC_Address + '</span>';
				computedHtml += '</div>';
				computedHtml += '<div class="float-right text-align-right">';
				computedHtml += '<span class="bold">' + form.Package__r.Patient__r.Name + '</span><br />';
				computedHtml += '<span>File No.&nbsp;' + form.Package__r.Patient__r.Medical_Record_Number__c + '</span><br />';
				if (null != form.Package__r.Patient__r.Current_Admission__r.Admit_Date__c) {
					String admitDate = form.Package__r.Patient__r.Current_Admission__r.Admit_Date__c.format();
					computedHtml += '<span>Date Admitted&nbsp;' + admitDate + '</span><br />';
				}
				if (null != form.Package__r.Patient__r.Date_of_Birth__c) {
					String birthDate = form.Package__r.Patient__r.Date_of_Birth__c.format();
					computedHtml += '<span>Birthdate&nbsp;' + birthDate + '</span>';
				}
				computedHtml += '</div>';
				computedHtml += '</div>';
				computedHtml += '<div align="center" style="padding-top: 95px;">';
				computedHtml += '<table width="500" style="margin-left: auto;margin-right: auto;border: solid 1px;">';
				String schedule = null != form.Package__r.MSA_Schedule__c ? form.Package__r.MSA_Schedule__c : '';
				computedHtml += '<tr><td width="40%" style="text-align: left;">MSA Schedule</td><td style="text-align: left;">' + schedule + '</td></tr>';
				String location = null != form.Package__r.MSA_Pickup_Location__c ? form.Package__r.MSA_Pickup_Location__c : '';
				computedHtml += '<tr><td style="text-align: left;">MSA Pickup Location</td><td style="text-align: left;">' + location + '</td></tr>';
				computedHtml += '<tr><td style="text-align: left;">Package</td><td style="text-align: left;">' + form.Package__r.Package_Name_Fml__c + '</td></tr>';
				computedHtml += '<tr><td colspan="2"><h3>Package Details</h3></td></tr>';
				computedHtml += '<tr><td style="text-align: left;">Patient Name</td><td style="text-align: left;">' + form.Package__r.Patient__r.Name + '</td></tr>';
				computedHtml += '<tr><td style="text-align: left;">Start Date</td><td style="text-align: left;">';
				if (null != form.Package__r.Start_Date__c) {
					String startDate = form.Package__r.Start_Date__c.format();
					computedHtml += startDate;
				}
				computedHtml += '</td></tr>';
				computedHtml += '<tr><td style="text-align: left;">End Date</td><td style="text-align: left;">';
				if (null != form.Package__r.End_Date__c) {
					String endDate = form.Package__r.End_Date__c.format();
					computedHtml += endDate;
				}
				computedHtml += '</td></tr></table>';
				if (null != form.Package__r.Control_Group__c) {
					computedHtml += '<div style="font-size: 120px;color: red;float: right;margin-top:-150px;">C</div>';
				}
				computedHtml += '<div>';
				Integer debugCounter = 1;

				AnswerSorter ansSorter = new AnswerSorter(form.disco__Answers__r);
				disco__Answer__c[] formAnswers = ansSorter.getResortedAnswers();

				for (disco__Answer__c formAns : formAnswers) {
					if ('Package Details'.equals(formAns.disco__Question__r.disco__Section__r.Name) && 'Free Text'.equals(formAns.disco__Question__r.disco__Type__c)) {
						computedHtml += '<div style="text-align:left;">' + formAns.disco__Question__r.disco__Label__c + '</div>';
					} else {
						if ('Return'.equals(formAns.disco__Question__r.disco__Section__r.Name) && 'Field Link'.equals(formAns.disco__Question__r.disco__Type__c)) {
							computedHtml += '<div style="page-break-after: always"><span style="display: none;">&nbsp;</span></div>';
							computedHtml += '<div class="red-border center-text">';
							computedHtml += '<p class="red slim-margin">' + Label.ARC_Medical_Record_Disclaimer + '</p>';
							computedHtml += '</div>';
							computedHtml += '<div><h3>Medication</h3></div>';
							computedHtml += '<table width="100%" style="border-collapse:collapse; margin-left: 100;margin-right: 100;border: solid 1px;">';
							computedHtml += '<tr>';
							computedHtml += '<th width="300" style="border:solid 1px; padding:3px; text-align:left; vertical-align:middle;">Medication & Format</th>';
							computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Quantity Dispensed</th>';
							computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Amount Taken</th>';
							computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Amount Returned</th>';
							computedHtml += '</tr>';
						} else {
							if ('Medication & Format'.equals(formAns.disco__Question__r.disco__Label__c) && null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c)) {
								computedHtml += '<tr>';
								computedHtml += '<td width="300" style="border:solid 1px; min-height:25px; padding:3px; text-align:left; vertical-align:middle;">';
								computedHtml += null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '';
								computedHtml += '</td>';
							} else if ('Quantity Dispensed'.equals(formAns.disco__Question__r.disco__Label__c)) {
								computedHtml += '<td width="100" style="border:solid 1px; min-height:25px; padding:3px; text-align:center; vertical-align:middle;">';

								computedHtml += null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '';
								computedHtml += '</td>';
								computedHtml += '<td width="100" style="border:solid 1px; min-height:25px; padding:3px; text-align:center;"></td>';
								computedHtml += '<td width="100" style="border:solid 1px; min-height:25px; padding:3px; text-align:center;"></td>';
								computedHtml += '</tr>';
							}
						}
					}
					debugCounter++;
				}

				computedHtml += '<div style="padding-top:18px;font-size: 10px;">';
				computedHtml += '<span>Package Conclusion &bull ' + form.Package__r.Patient__r.Name + '</span> &bull ';
				computedHtml += '<span>File No.&nbsp;' + form.Package__r.Patient__r.Medical_Record_Number__c + '</span> &bull ';
				if (null != form.Package__r.Patient__r.Current_Admission__r.Admit_Date__c) {
					String admitDate = form.Package__r.Patient__r.Current_Admission__r.Admit_Date__c.format();
					computedHtml += '<span>Date Admitted&nbsp;' + admitDate + '</span> &bull ';
				}
				if (null != form.Package__r.Patient__r.Date_of_Birth__c) {
					String birthDate = form.Package__r.Patient__r.Date_of_Birth__c.format();
					computedHtml += '<span>Birthdate&nbsp;' + birthDate + '</span>';
				}
				computedHtml += '</div>';

				i++;
				if (i < forms.size()) {
					computedHtml += '<div style="page-break-after: always"><span style="display: none;">&nbsp;</span></div>';
				}
				computedHtml += '</div>';
				computedHtml += '</table>';
				computedHtml += '</div>';
				packageHTMLs.add(computedHtml);
			}

			List<ContentVersion> logoContentVersions = [SELECT Id, VersionData, FileType FROM ContentVersion WHERE ContentDocument.Title = 'Riggs_Logo_Medical_Records' AND IsLatest = TRUE WITH SECURITY_ENFORCED];
			if (logoContentVersions.size() != 0) {
				logoContentVersionId = logoContentVersions[0].Id;
			}
		}
		return null;
	}

	global class AnswerSorter {
		public disco__Answer__c[] answers;

		public AnswerSorter(disco__Answer__c[] tempAnswers) {
			answers = tempAnswers;
		}

		public disco__Answer__c[] getResortedAnswers() {
			disco__Answer__c[] resortedAnswers = new List<disco__Answer__c>();
			Map<String, disco__Answer__c> answersByKeyMap = new Map<String, disco__Answer__c>();
			String[] medsList = new List<String>();
			for (Integer i = 0; i < answers.size(); i++) {
				disco__Answer__c a = answers[i];
				if ('Medication & Format'.equals(a.disco__Question__r.disco__Label__c) && null != a.disco__Answer__c && !'null'.equals(a.disco__Answer__c)) {
					medsList.add(a.disco__Answer__c);
					answersByKeyMap.put(a.disco__Answer__c + 'ANS', a);
					i++;
					disco__Answer__c a2 = answers[i];
					answersByKeyMap.put(a.disco__Answer__c + 'QTY', a2);
				}
			}
			medsList.sort();

			Boolean medListProcessed = false;
			for (Integer i = 0; i < answers.size(); i++) {
				disco__Answer__c a = answers[i];
				if ('Medication & Format'.equals(a.disco__Question__r.disco__Label__c) && null != a.disco__Answer__c && !'null'.equals(a.disco__Answer__c)) {
					if (!medListProcessed) {
						for (String k : medsList) {
							disco__Answer__c aMed = answersByKeyMap.get(k + 'ANS');
							disco__Answer__c aQty = answersByKeyMap.get(k + 'QTY');
							// The form has the following questions/answers in this order
							// Medication & Format
							// Quantity Dispensed
							// Amount Taken
							// Amount Returned
							// How effective was it?
							// We need to increment i by 5
							i = i + 5;
							resortedAnswers.add(aMed);
							resortedAnswers.add(aQty);
						}
						medListProcessed = true;
						i = i + 2;
					}
				} else {
					resortedAnswers.add(a);
				}
			}
			return resortedAnswers;
		}
	}
}