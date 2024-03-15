global with sharing class SDocsCallableDispensing implements Callable {
	public Object call(String action, Map<String, Object> args) {
		switch on action {
			when 'getPackagesAsSDocTable' {
				//return this.getPackagesAsSDocTable((String)args.get('recordId'));
				return this.getPackagesAsSDocTableMatrix((String) args.get('recordId'));
			}
			when else {
				throw new ExtensionMalformedCallException('Method not implemented');
			}
		}
	}
	public class ExtensionMalformedCallException extends Exception {
	}

	public SDOC.SDUtil.SDocTable getPackagesAsSDocTable(String recordId) {
		List<disco__Form__c> forms = [
			SELECT
				Id,
				Name,
				Package__r.Patient__r.Name,
				Package__r.Package_Name_Fml__c,
				Package__r.Start_Date__c,
				Package__r.End_Date__c,
				Package__r.MSA_Schedule__c,
				Package__r.MSA_Pickup_Location__c,
				(SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c FROM disco__Answers__r ORDER BY NAME)
			FROM disco__Form__c
			WHERE Id IN (SELECT Form__c FROM Package__c WHERE SDocCallableParent__c = :recordId)
		];

		SDOC.SDUtil.SDocTable table = new SDOC.SDUtil.SDocTable();
		String dateFormatString = 'MM/dd/yyyy';

		Integer i = 0;
		for (disco__Form__c form : forms) {
			String computedHtml = '<div align="center">';
			computedHtml += '<h2 style="padding:0px;">AUSTEN RIGGS CENTER</h2>';
			computedHtml += '<table width="500" style="margin-left: auto;margin-right: auto;border: solid 1px;">';
			computedHtml += '<tr><td width="40%" style="text-align: left;">MSA Schedule</td><td style="text-align: left;">' + form.Package__r.MSA_Schedule__c + '</td></tr>';
			computedHtml += '<tr><td style="text-align: left;">MSA Pickup Location</td><td style="text-align: left;">' + form.Package__r.MSA_Pickup_Location__c + '</td></tr>';
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

			for (disco__Answer__c formAns : form.disco__Answers__r) {
				if ('Package Details'.equals(formAns.disco__Question__r.disco__Section__r.Name) && 'Free Text'.equals(formAns.disco__Question__r.disco__Type__c)) {
					computedHtml += '<div style="text-align:left;">' + formAns.disco__Question__r.disco__Label__c + '</div>';
				}

				if ('Medication & Format'.equals(formAns.disco__Question__r.disco__Label__c)) {
					computedHtml += '<table width="600" style="margin-left: auto;margin-right: auto;border: solid 0px;">';
					computedHtml += '<tr><td colspan="2" align="center"><h3>Medication</h3></td></tr>';
					computedHtml += '<tr><td width="200" style="vertical-align:top;text-align: left;">' + formAns.disco__Question__r.disco__Label__c + '</td><td style="text-align: left;">';
					computedHtml += null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '';
					computedHtml += '</td></tr>';
				} else if ('Quantity Dispensed'.equals(formAns.disco__Question__r.disco__Label__c)) {
					computedHtml += '<tr><td style="text-align: left;">' + formAns.disco__Question__r.disco__Label__c + '</td><td style="text-decoration: underline;text-align:left;">';
					computedHtml += null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '';
					computedHtml += '</td></tr>';
					computedHtml += '<tr><td style="text-align: left;">Amount Taken</td><td style="text-decoration: underline;text-align:left;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>';
					computedHtml += '<tr><td style="text-align: left;">Amount Returned</td><td style="text-decoration: underline;text-align:left;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>';
					// computedHtml += '<tr><td style="vertical-align:top;text-align:left;">How effective was it?</td><td style="text-align: left;">__ Effective<br />__ Partially Effective<br />__ Not Effective</td></tr>';
					computedHtml += '</table></div>';
				}
			}

			i++;
			if (i < forms.size()) {
				computedHtml += '<div style="page-break-after: always"><span style="display: none;">&nbsp;</span></div>';
			}

			SDOC.SDUtil.SDocTableRow row = new SDOC.SDUtil.SDocTableRow();
			row.cells.add(new SDOC.SDUtil.SDocTableCell('computedHtml', computedHtml.escapeHtml4()));
			table.rows.add(row);
		}
		return table;
	}

	public SDOC.SDUtil.SDocTable getPackagesAsSDocTableMatrix(String recordId) {
		List<disco__Form__c> forms = [
			SELECT
				Id,
				Name,
				Package__r.Patient__r.Name,
				Package__r.Package_Name_Fml__c,
				Package__r.Start_Date__c,
				Package__r.End_Date__c,
				Package__r.MSA_Schedule__c,
				Package__r.MSA_Pickup_Location__c,
				(SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c FROM disco__Answers__r ORDER BY NAME)
			FROM disco__Form__c
			WHERE Id IN (SELECT Form__c FROM Package__c WHERE SDocCallableParent__c = :recordId)
		];

		SDOC.SDUtil.SDocTable table = new SDOC.SDUtil.SDocTable();
		String dateFormatString = 'MM/dd/yyyy';

		Integer i = 0;
		for (disco__Form__c form : forms) {
			String computedHtml = '<div align="center">';
			computedHtml += '<h2 style="padding:0px;">AUSTEN RIGGS CENTER</h2>';
			computedHtml += '<table width="500" style="margin-left: auto;margin-right: auto;border: solid 1px;">';
			computedHtml += '<tr><td width="40%" style="text-align: left;">MSA Schedule</td><td style="text-align: left;">' + form.Package__r.MSA_Schedule__c + '</td></tr>';
			computedHtml += '<tr><td style="text-align: left;">MSA Pickup Location</td><td style="text-align: left;">' + form.Package__r.MSA_Pickup_Location__c + '</td></tr>';
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

			// TODO: Dave S., Update this to use a matrix instead of divs for the medications.
			// You can just omit the "How effective was it questions"
			computedHtml += '<div>';
			Integer debugCounter = 1;

			for (disco__Answer__c formAns : form.disco__Answers__r) {
				if ('Package Details'.equals(formAns.disco__Question__r.disco__Section__r.Name) && 'Free Text'.equals(formAns.disco__Question__r.disco__Type__c)) {
					computedHtml += '<div style="text-align:left;">' + formAns.disco__Question__r.disco__Label__c + '</div>';
				} else {
					if ('Return'.equals(formAns.disco__Question__r.disco__Section__r.Name) && 'Field Link'.equals(formAns.disco__Question__r.disco__Type__c)) {
						computedHtml += '<tr><td colspan="2" align="center"><h3>Medication</h3></td></tr>';
						computedHtml += '<tr><td colspan="2">';
						computedHtml += '<table width="600" style="border-collapse:collapse; margin-left: 100;margin-right: 100;border: solid 1px;">';
						computedHtml += '<tr>';
						computedHtml += '<th width="300" style="border:solid 1px; padding:3px; text-align:left; vertical-align:middle;">Medication & Format</th>';
						computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Quantity Dispensed</th>';
						computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Amount Taken</th>';
						computedHtml += '<th width="100" style="border:solid 1px; padding:3px; text-align:center; vertical-align:middle;">Amount Returned</th>';
						computedHtml += '</tr>';
					} else {
						if ('Medication & Format'.equals(formAns.disco__Question__r.disco__Label__c)) {
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
							// computedHtml += '<tr><td style="vertical-align:top;text-align:left;">How effective was it?</td><td style="text-align: left;">__ Effective<br />__ Partially Effective<br />__ Not Effective</td></tr>';
						}
					}
				}

				debugCounter++;
			}

			i++;
			if (i < forms.size()) {
				computedHtml += '<div style="page-break-after: always"><span style="display: none;">&nbsp;</span></div>';
			}
			computedHtml += '</div>';
			computedHtml += '</table></td></tr>';
			computedHtml += '</table></div>';

			SDOC.SDUtil.SDocTableRow row = new SDOC.SDUtil.SDocTableRow();
			row.cells.add(new SDOC.SDUtil.SDocTableCell('computedHtml', computedHtml.escapeHtml4()));
			table.rows.add(row);
		}
		return table;
	}
}