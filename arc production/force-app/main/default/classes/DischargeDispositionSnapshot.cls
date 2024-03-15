public without sharing class DischargeDispositionSnapshot {
	public DischargeDisposition dischargeDispositionWrapper;

	private List<Snapshot__c> snapshotsToInsert = new List<Snapshot__c>();

	public static Map<String, Schema.DescribeFieldResult> dischargeDispositionFieldMap {
		get {
			if (dischargeDispositionFieldMap == null) {
				dischargeDispositionFieldMap = getFieldResultMap('Discharge_Disposition__c');
			}
			return dischargeDispositionFieldMap;
		}
		private set;
	}

	public static Map<String, Schema.DescribeFieldResult> dischargeSectionFieldMap {
		get {
			if (dischargeSectionFieldMap == null) {
				dischargeSectionFieldMap = getFieldResultMap('Discharge_Section__c');
			}
			return dischargeSectionFieldMap;
		}
		private set;
	}

	public static Map<String, Schema.DescribeFieldResult> dischargeReferralFieldMap {
		get {
			if (dischargeReferralFieldMap == null) {
				dischargeReferralFieldMap = getFieldResultMap('Discharge_Referral__c');
			}
			return dischargeReferralFieldMap;
		}
		private set;
	}

	static Map<String, Schema.DescribeFieldResult> getFieldResultMap(String sObjectType) {
		Map<String, Schema.DescribeFieldResult> returnMap = new Map<String, Schema.DescribeFieldResult>();
		for (Schema.SObjectField field : Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap().values()) {
			Schema.DescribeFieldResult dfr = field.getDescribe();
			returnMap.put(dfr.getName(), dfr);
		}
		return returnMap;
	}

	public Map<String, List<FieldDefinition>> dischargeDispositionTypeToFieldsMap = new Map<String, List<FieldDefinition>>{
		'Planned Discharge' => new List<FieldDefinition>{ new FieldDefinition('Anticipated_Discharge_Date__c', 'Anticipated Discharge Date'), new FieldDefinition('[SECTIONS]', '[SECTIONS]'), new FieldDefinition('Date_Delivered_to_Patient__c', 'Date Delivered to Patient'), new FieldDefinition('Method__c', 'Method'), new FieldDefinition('Post_Discharge_Address_Summary__c', 'Post-Discharge Address') },
		'Emergency Transfer' => new List<FieldDefinition>{ new FieldDefinition('Transfer_Details__c', 'Transfer Details'), new FieldDefinition('Anticipated_Discharge_Date__c', 'Anticipated Discharge Date') }
	};

	public Map<String, List<FieldDefinition>> dischargeSectionRoleToFieldsMap = new Map<String, List<FieldDefinition>>{
		'Psychotherapy' => new List<FieldDefinition>{ new FieldDefinition('[REFERRALS.Psychotherapy]', ''), new FieldDefinition('No_Separate_Referral_Required__c', 'No separate referral required for this discipline'), new FieldDefinition('No_Separate_Referral_Required_Comments__c', 'Comments') },
		'Psychopharmacology' => new List<FieldDefinition>{ new FieldDefinition('[REFERRALS.Psychopharmacology]', ''), new FieldDefinition('No_Separate_Referral_Required__c', 'No separate referral required for this discipline'), new FieldDefinition('No_Separate_Referral_Required_Comments__c', 'Comments'), new FieldDefinition('Drug_Allergies__c', 'Drug Allergies'), new FieldDefinition('Blood_Levels__c', 'Blood Levels'), new FieldDefinition('Additional_Instructions__c', 'Additional Instructions') },
		'Medical Care Instructions' => new List<FieldDefinition>{
			new FieldDefinition('[REFERRALS.MedicalCareInstructions]', ''),
			new FieldDefinition('No_Separate_Referral_Required__c', 'No separate referral required for this discipline'),
			new FieldDefinition('No_Separate_Referral_Required_Comments__c', 'Comments'),
			new FieldDefinition('X1st_Appointment_Frequency__c', '1st Appointment / Frequency'),
			new FieldDefinition('Pending_Tests_Follow_Up__c', 'Pending Tests / Follow Up'),
			new FieldDefinition('Latest_Tests__c', 'Latest Tests'),
			new FieldDefinition('Special_Precautions_Instructions__c', 'Special Precautions / Instructions'),
			new FieldDefinition('Restrictions_in_Diet_Activity__c', 'Restrictions in Diet / Activity')
		},
		'Nursing' => new List<FieldDefinition>{ new FieldDefinition('Nursing_Education_Information__c', 'Nursing Education Information') },
		'Substance Use Services' => new List<FieldDefinition>{ new FieldDefinition('[REFERRALS.IndividualCounselingReferrals]', 'Individual Counseling Referrals'), new FieldDefinition('[REFERRALS.GroupCounselingReferrals]', 'Group Counseling Referrals'), new FieldDefinition('No_Separate_Referral_Required__c', 'No separate referral required for this discipline'), new FieldDefinition('Self_help_Organizations__c', 'Self-help organizations'), new FieldDefinition('Not_Applicable__c', 'Not Applicable') },
		'Social Work' => new List<FieldDefinition>{
			new FieldDefinition('[REFERRALS.ResidentialDayTreatmentProgramReferrals]', 'Residential / Day Treatment Program Referrals'),
			new FieldDefinition('[REFERRALS.CouplesFamilyTherapyReferrals]', 'Couples / Family Therapy Referrals'),
			new FieldDefinition('[REFERRALS.GroupTherapySelfHelpReferrals]', 'Group Therapy / Self-Help Referrals'),
			new FieldDefinition('[HEADER]', 'Additional Referral Notes'),
			new FieldDefinition('Volunteer_Academic_Vocational_Plan__c', 'Volunteer / Academic / Vocational Plan'),
			new FieldDefinition('Living_Arrangements_Social_Support__c', 'Living Arrangements / Social Support'),
			new FieldDefinition('Financial_Plan__c', 'Financial Plan'),
			new FieldDefinition('Local_Community_Involvement__c', 'Local Community Involvement'),
			new FieldDefinition('Other__c', 'Others'),
			new FieldDefinition('Emergency_Psychiatric_Contact__c', 'Emergency Psychiatric Contact', 'National Suicide & Crisis Lifeline: Call or Text 988', false)
		},
		'Team Leader' => new List<FieldDefinition>{ new FieldDefinition('Patient_Discharge_Meeting_with_Team__c', 'Patient Discharge Meeting with Team'), new FieldDefinition('Discharge_Meeting_Date__c', 'Discharge Meeting Date'), new FieldDefinition('Discharge_Comments__c', 'Discharge Comments') }
	};

	public DischargeDispositionSnapshot(Id dischargeId) {
		dischargeDispositionWrapper = DischargeDispositionCtl.getDischargeDisposition(dischargeId);
	}

	public void generateSnapshots() {
		this.generateSnapshots(false, null);
	}
	public void generateSnapshots(Boolean isDraft, String purpose) {
		Discharge_Disposition__c dischargeDisposition = dischargeDispositionWrapper.dischargeDispositionObj;
		Account patient = dischargeDispositionWrapper.patient;
		if (dischargeDisposition != null) {
			String title = (dischargeDisposition.Emergency_Transfer__c ? 'Emergency Transfer Discharge Disposition' : 'Planned Discharge Disposition and Referrals');

			String html = getRenderedHtml(dischargeDispositionWrapper);

			SnapshotHelper.HtmlFooterMapping[] footer = new List<SnapshotHelper.HtmlFooterMapping>{};
			if (dischargeDisposition.Finalized_Date_Time__c != null && !isDraft) {
				footer.add(new SnapshotHelper.HtmlFooterMapping('Finalized By', ParserHelper.ToString(dischargeDisposition, 'Finalized_By_Professional_Name__c')));
				footer.add(new SnapshotHelper.HtmlFooterMapping('Finalized Date/Time', ParserHelper.ToDateTimeFormat(dischargeDisposition, 'Finalized_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)));
			}
			String decoratedFooter = SnapshotHelper.getHtmlFooter(patient, footer);
			html += decoratedFooter;

			Snapshot__c newSnapshot = new Snapshot__c(Html__c = html, Patient_Name__c = ParserHelper.toString(patient, 'Name'), Discharge_Disposition__c = dischargeDisposition.Id, Title__c = title, Finalized_By__c = dischargeDisposition.Finalized_By_Professional_Name__c, Finalized_Date_Time__c = dischargeDisposition.Finalized_Date_Time__c);
			if (isDraft) {
				newSnapshot.Purpose__c = purpose;
				newSnapshot.Is_Draft__c = isDraft;
			}
			this.snapshotsToInsert.add(newSnapshot);
		}

		insert this.snapshotsToInsert;
		List<Discharge_Disposition__c> dispositionsToUpdate = new List<Discharge_Disposition__c>();
		for (Snapshot__c snap : snapshotsToInsert) {
			dispositionsToUpdate.add(new Discharge_Disposition__c(Id = snap.Discharge_Disposition__c, Snapshot__c = snap.Id));
		}
		update dispositionsToUpdate;
	}

	public String getRenderedHtml(DischargeDisposition wrapper) {
		String html = '';
		List<FieldDefinition> fieldDefs = dischargeDispositionTypeToFieldsMap.get(wrapper.dischargeDispositionObj.DDR_Type__c);
		for (FieldDefinition fieldDef : fieldDefs) {
			if (fieldDef.isField) {
				html += getRenderedDispositionField(dischargeDispositionWrapper.dischargeDispositionObj, fieldDef);
			} else if (fieldDef.fieldName == '[SECTIONS]') {
				for (DischargeSection dsWrapper : dischargeDispositionWrapper.dischargeSectionList) {
					String sectionHtml = '<div class="slds-card">';
					sectionHtml += getHtmlSectionHeader(dsWrapper.dischargeSectionObj.Role__c);
					sectionHtml += '<div class="slds-m-left_small">';
					List<FieldDefinition> sectionFieldDefs = dischargeSectionRoleToFieldsMap.get(dswrapper.dischargeSectionObj.Role__c);

					for (FieldDefinition sectionFieldDef : sectionFieldDefs) {
						if (sectionFieldDef.isField) {
							sectionHtml += getRenderedDischargeSectionField(dsWrapper.dischargeSectionObj, sectionFieldDef);
						} else if (sectionFieldDef.fieldName.startsWith('[HEADER')) {
							sectionHtml += getHtmlSectionHeader(sectionFieldDef.label);
						} else if (sectionFieldDef.fieldName.startsWith('[REFERRALS.')) {
							String groupingName = sectionFieldDef.fieldName.split('\\.')[1];
							groupingName = groupingName.left(groupingName.length() - 1);

							//Referrals Header
							String referralsHtml = getHtmlFieldHeader(sectionFieldDef.label, '');
							Boolean hasReferrals = false;
							for (DischargeReferral referral : dsWrapper.referralList) {
								if (referral.dischargeReferralObj.Grouping__c == groupingName) {
									referralsHtml += getRenderedReferral(referral, wrapper);
									hasReferrals = true;
								}
							}
							if (hasReferrals) {
								sectionHtml += referralsHtml;
							}
						}
					}
					sectionHtml += getHtmlSectionFooter(dsWrapper.dischargeSectionObj);
					sectionHtml += '</div>';
					sectionHtml += '</div>';

					html += sectionHtml;
				}
			}
		}

		return html;
	}

	private String getRenderedDispositionField(Discharge_Disposition__c dischargeDisposition, FieldDefinition fieldDef) {
		String html = '';
		if (!fieldDef.hideOnBlankValue || (String.isNotBlank(fieldDef.fieldName) && string.isNotBlank(ParserHelper.ToString(dischargeDisposition, fieldDef.fieldName)))) {
			Schema.DescribeFieldResult dfr = dischargeDispositionFieldMap.get(fieldDef.fieldName);
			if (dfr.getType() == Schema.DisplayType.BOOLEAN) {
				if (Boolean.valueOf(dischargeDisposition.get(fieldDef.fieldName))) {
					html += getHtmlFieldHeader(fieldDef.label, fieldDef.subTitle);
					html += getHtmlDischargeField(dischargeDisposition, fieldDef);
				}
			} else {
				html += getHtmlFieldHeader(fieldDef.label, fieldDef.subTitle);
				html += getHtmlDischargeField(dischargeDisposition, fieldDef);
			}
		}
		return html;
	}

	private String getRenderedDischargeSectionField(Discharge_Section__c dischargeSection, FieldDefinition fieldDef) {
		String html = '';
		if (!fieldDef.hideOnBlankValue || (String.isNotBlank(fieldDef.fieldName) && string.isNotBlank(ParserHelper.ToString(dischargeSection, fieldDef.fieldName)))) {
			Schema.DescribeFieldResult dfr = dischargeSectionFieldMap.get(fieldDef.fieldName);
			if (dfr.getType() == Schema.DisplayType.BOOLEAN) {
				if (Boolean.valueOf(dischargeSection.get(fieldDef.fieldName))) {
					html += getHtmlFieldHeader(fieldDef.label, fieldDef.subTitle);
				}
			} else {
				html += getHtmlFieldHeader(fieldDef.label, fieldDef.subTitle);
				html += getHtmlDischargeSectionField(dischargeSection, fieldDef);
			}
		}
		return html;
	}

	private String getRenderedReferral(DischargeReferral refWrapper, DischargeDisposition dischargeWrapper) {
		String html = '';

		html +=
			'<div class="slds-form-element slds-m-left_small slds-grid slds-wrap">' +
			'<div class="slds-size_4-of-12">' +
			'<h1 class="slds-text-heading_small title" style="font-weight:bold;">Referral To</h1>' +
			String.format('<div class="slds-form-element__control">{0}</div>', new List<String>{ refWrapper.dischargeReferralObj.Referral_To__c }) +
			'</div>' +
			'<div class="slds-size_4-of-12">' +
			'<h1 class="slds-text-heading_small  title" style="font-weight:bold;">Phone</h1>' +
			(refWrapper.dischargeReferralObj.Phone__c != null ? String.format('<div class="slds-form-element__control">{0}</div>', new List<String>{ refWrapper.dischargeReferralObj.Phone__c }) : '') +
			'</div>';
		if (refWrapper.dischargeReferralObj.Is_Primary__c) {
			html += '<div class="slds-form-element__control slds-size_4-of-12 slds-m-top_medium" style="font-weight: bold;">Primary</div>';
		}
		if (refWrapper.dischargeReferralObj.Referral_Notes__c != null) {
			html +=
				'<div class="slds-size_10-of-12">' +
				'<h1 class="slds-text-heading_small title" style="font-weight:bold;">Referral Notes</h1>' +
				//+ String.format('<div class="slds-form-element__control">{0}</div>', new string[]{ refWrapper.dischargeReferralObj.Referral_Notes__c } );
				'<div class="slds-form-element__control">' +
				refWrapper.dischargeReferralObj.Referral_Notes__c +
				'</div>' +
				'</div>';
		}
		html += '</div>' + '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		return html;
	}

	public String getHtmlSectionHeader(String headerString) {
		String html = '';
		if (String.isNotBlank(headerString)) {
			html += string.format('<h1 class="slds-text-heading_medium slds-m-bottom_small title" style="font-weight:bold;">{0}</h1>', new List<String>{ headerString });
		}
		return html;
	}

	public String getHtmlSectionFooter(Discharge_Section__c dischargeSection) {
		String html = '';
		List<SnapshotHelper.HtmlFooterMapping> footerMappings = new List<SnapshotHelper.HtmlFooterMapping>();
		if (dischargeSection.Completed_Date_Time__c != null) {
			footerMappings.add(new SnapshotHelper.HtmlFooterMapping('Completed By', ParserHelper.ToString(dischargeSection, 'Completed_By_Professional_Name__c')));
			footerMappings.add(new SnapshotHelper.HtmlFooterMapping('Completed Date/Time', ParserHelper.ToDateTimeFormat(dischargeSection, 'Completed_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)));
		}
		String decoratedFooter = SnapshotHelper.getHtmlFooter(footerMappings);
		html += decoratedFooter;
		return html;
	}

	public String getHtmlFieldHeader(String title, String subTitle) {
		String html = '';
		if (String.isNotBlank(title)) {
			html += String.format('<h1 class="slds-text-heading_small title" style="font-weight:bold;">{0}</h1>', new List<String>{ title });
		}
		if (string.isNotBlank(subTitle)) {
			html += String.format('<div class="slds-text-title">{0}</div>', new List<string>{ subTitle });
		}
		return html;
	}

	public string getHtmlDischargeField(Discharge_Disposition__c dischargeDisposition, FieldDefinition fieldDef) {
		Schema.DescribeFieldResult dfr = dischargeDispositionFieldMap.get(fieldDef.fieldName);
		String html = formatHtmlField((sObject) dischargeDisposition, fieldDef.fieldName, dfr, fieldDef.hideOnBlankValue);
		return html;
	}

	public string getHtmlDischargeSectionField(Discharge_Section__c dischargeSection, FieldDefinition fieldDef) {
		Schema.DescribeFieldResult dfr = dischargeSectionFieldMap.get(fieldDef.fieldName);
		String html = formatHtmlField((sObject) dischargeSection, fieldDef.fieldName, dfr, fieldDef.hideOnBlankValue);
		return html;
	}

	String formatHtmlField(sObject obj, String fieldName, Schema.DescribeFieldResult dfr, Boolean hideOnBlankValue) {
		String html = '';
		String value = '';
		if (!hideOnBlankValue || obj.get(fieldName) != null) {
			if (dfr.getType() == Schema.DisplayType.DATETIME) {
				value = ParserHelper.ToDateTimeFormat(obj, fieldName, SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE);
			} else if (dfr.getType() == Schema.DisplayType.DATE) {
				value = ParserHelper.ToDateFormat(obj, fieldName);
			} else if (dfr.getType() == Schema.DisplayType.PICKLIST || dfr.getType() == Schema.DisplayType.MULTIPICKLIST) {
				value = ParserHelper.ToString(obj, fieldName).replaceAll(';', '; ');
			} else {
				value = ParserHelper.ToString(obj, fieldName);
			}
			if (dfr.getType() == Schema.DisplayType.BOOLEAN) {
				value = ((Boolean) obj.get(fieldName) ? 'Yes' : 'No');
			}
			if (value == 'null' || value == null)
				value = '';
			html += '<div class="slds-form-element c">' + String.format('<div class="slds-form-element__control">{0}</div>', new List<string>{ value }) + '</div>';
			html += '<hr class="slds-m-top_x-small slds-m-bottom_x-small">';
		}
		return html;
	}

	public class FieldDefinition {
		String fieldName = '';
		String label = '';
		String subTitle = '';
		String fieldValue = '';
		Boolean isField = true;
		Boolean hideOnBlankValue = true;

		public FieldDefinition(String fieldName, String label, String subTitle, Boolean hideOnBlankValue) {
			this(fieldName, label);
			this.subTitle = subTitle;
			this.hideOnBlankValue = hideOnBlankValue;
		}
		public FieldDefinition(String fieldName, String label) {
			this.fieldName = fieldName;
			this.label = label;
			if (fieldName.startsWith('[')) {
				isField = false;
			}
		}
	}
}