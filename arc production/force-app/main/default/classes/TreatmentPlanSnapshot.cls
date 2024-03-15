public without sharing class TreatmentPlanSnapshot {
	public static boolean runOnce;
	static map<id, Goal__c[]> goalsByTreatmentPlanId = new Map<id, Goal__c[]>();
	static map<ID, Goal__c[]> goalsByDomainId = new Map<ID, Goal__c[]>();
	static map<Id, Account> accountMap = new Map<Id, Account>();

	public static void process(Id[] treatmentplanIds) {
		if (runOnce != true && treatmentplanIds != null && !treatmentplanIds.isEmpty()) {
			runOnce = true;
			accountMap = new Map<id, account>([SELECT id, Name, current_case__c, Current_Admission__r.Psychotherapist__r.Professional_Name__c FROM account WHERE id IN (SELECT AccountId FROM Case WHERE id IN :treatmentplanIds)]);

			set<Id> tpToProcessIds = new Set<id>(treatmentplanIds);

			if (tpToProcessIds.size() > 0) {
				fillData(new List<id>(tpToProcessIds));
				Snapshot__c[] snapshots = new List<Snapshot__c>{};
				map<Id, Case> tpToProcessMap = new Map<id, Case>([SELECT Id, AccountId, Finalized_By__c, Finalized_Date_Time__c, Goal__c, team_commentary__c, Admission__r.Medical_Care_Plan__c FROM Case WHERE Id IN :tpToProcessIds]);

				for (id tpId : tpToProcessIds) {
					Case tp = tpToProcessMap.get(tpId);
					string html = getHtml(tp);
					string mobileHtml = getMobileHtml(tp);

					string psychiatrist = SnapshotHelper.getTeamMembersByRole(tp.AccountId, 'Psychiatrist');
					string psychotherapist = SnapshotHelper.getTeamMembersByRole(tp.AccountId, 'Psychotherapist');

					string patientName = accountMap.containsKey(tp.AccountId) ? ParserHelper.toString(accountMap.get(tp.AccountId), 'Name') : '';
					snapshots.add(new Snapshot__c(Patient_Name__c = patientName, Treatment_Plan__c = tp.id, html__c = html, Mobile_Html__c = mobileHtml, Psychiatrist__c = psychiatrist, Psychotherapist__c = psychotherapist, Team_Members__c = null, Finalized_By__c = tp.Finalized_By__c, Finalized_Date_Time__c = tp.Finalized_Date_Time__c));
				}

				if (snapshots.size() > 0) {
					insert snapshots;

					case[] toUpdate = new List<case>{};
					for (Snapshot__c ss : snapshots) {
						toUpdate.add(new Case(Id = ss.treatment_plan__c, Snapshot__c = ss.Id));
					}
					update toUpdate;
				}
			}
		}
	}

	static void fillData(id[] treatmentPlanIds) {
		SnapshotHelper.fillMaps(accountMap.keySet());

		string goalQuery = QueryUtils.getQueryAll('Goal__c', new List<string>{ 'Continued_From_Goal__r.Date_Added__c', 'Continued_From_Goal__r.Target_Date__c', QueryUtils.getSubQueryAll('Objective__c', 'Objectives__r', new List<string>{ 'Continued_From_Objective__r.Date_Added__c', 'Continued_From_Objective__r.Target_Date__c' }, ' Order By Order__c'), QueryUtils.getSubQueryAll('EGO_Rating__c', 'EGO_Ratings__r', new List<string>{}, '') }) + ' WHERE Draft_Treatment_Plan__c in :treatmentPlanIds order by Draft_Treatment_Plan__c, Domain_Name__c,Domain_Number__c,Order__c';
		Goal__c[] goals = (Goal__c[]) database.query(goalQuery);
		for (Goal__c g : goals) {
			if (!goalsByTreatmentPlanId.containsKey(g.Draft_Treatment_Plan__c)) {
				goalsByTreatmentPlanId.put(g.Draft_Treatment_Plan__c, new List<Goal__c>{});
			}
			goalsByTreatmentPlanId.get(g.Draft_Treatment_Plan__c).add(g);

			if (string.isNotBlank(g.Domain_Metadata_ID__c)) {
				if (!goalsByDomainId.containsKey(g.Domain_Metadata_ID__c)) {
					goalsByDomainId.put(g.Domain_Metadata_ID__c, new List<Goal__c>{});
				}
				goalsByDomainId.get(g.Domain_Metadata_ID__c).add(g);
			}
		}
	}

	public static string getHtml(Case treatmentPlan) {
		string html = '';
		html = SnapshotHelper.getHtmlHeader('Treatment Plan');
		html += '<br>';
		html += SnapshotHelper.getHtmlTeamCommentary(ParserHelper.toString(treatmentPlan, 'Team_Commentary__c'));
		html += '<br>';
		html += SnapshotHelper.getHtmlOverallGoal(ParserHelper.toString(treatmentPlan, 'Goal__c'));
		html += '<br>';
		for (Domain__mdt domain : SnapshotHelper.domains) {
			html += '<div class="slds-box">';
			html += string.format('<div class="slds-text-heading_medium"><b>Domain: {0}&nbsp;{1}</b></div>', new List<string>{ string.valueof(domain.Domain_Number__c).replace('.0', ''), domain.Label__c });
			if (domain.Domain_Number__c == 6 && String.isNotBlank(treatmentPlan.Admission__r.Medical_Care_Plan__c)) {
				html += '<p>' + treatmentPlan.Admission__r.Medical_Care_Plan__c + '</p>';
			} else if (goalsByDomainId != null && goalsByDomainId.containsKey(domain.Id)) {
				html += string.format('<p><h1><b>{0} Goals</b></h1></p>', new List<string>{ domain.Label__c });
				for (Goal__c goal : goalsByDomainId.get(domain.Id)) {
					html += SnapshotHelper.getHtmlGoal(goal, null, null, true);
				}
			}
			html += '</div>';
		}
		html += '<br>';

		Account patient = accountMap.get(treatmentPlan.AccountId);

		html += '<div class="slds-p-around_small">';
		html += SnapshotHelper.getHtmlFooter(patient, new List<SnapshotHelper.HtmlFooterMapping>{ new SnapshotHelper.HtmlFooterMapping('Finalized By', ParserHelper.ToString(treatmentPlan, 'Finalized_By__c')), new SnapshotHelper.HtmlFooterMapping('Finalized Date/Time', ParserHelper.ToDateTimeFormat(treatmentPlan, 'Finalized_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)) });

		html += '</div>';
		return html;
	}

	// Added by Sols 2022-07-28 to accommodate readability on small screens
	// Related to ARC-1735: Modify Flow: 'Create New Form' for Treatment Plan lookup
	public static string getMobileHtml(Case treatmentPlan) {
		string html = '';
		html = SnapshotHelper.getHtmlHeader('Treatment Plan');
		html += '<br>';
		html += SnapshotHelper.getHtmlTeamCommentary(ParserHelper.toString(treatmentPlan, 'Team_Commentary__c'));
		html += '<br>';
		html += SnapshotHelper.getHtmlOverallGoal(ParserHelper.toString(treatmentPlan, 'Goal__c'));
		html += '<br>';
		for (Domain__mdt domain : SnapshotHelper.domains) {
			html += '<div class="slds-box slds-box_xx-small slds-m-bottom_x-small">';
			html += string.format('<div class="slds-text-heading_medium"><b>Domain: {0}&nbsp;{1}</b></div>', new List<string>{ string.valueof(domain.Domain_Number__c).replace('.0', ''), domain.Label__c });

			if (goalsByDomainId != null && goalsByDomainId.containsKey(domain.Id)) {
				html += string.format('<p><h1><b>{0} Goals</b></h1></p>', new List<string>{ domain.Label__c });
				for (Goal__c goal : goalsByDomainId.get(domain.Id)) {
					html += SnapshotHelper.getHtmlGoalMobile(goal, null, null, true);
				}
			}
			html += '</div>';
		}
		// html += '<br>';

		Account patient = accountMap.get(treatmentPlan.AccountId);

		html += '<div class="slds-p-around_small">';
		html += SnapshotHelper.getHtmlFooter(patient, new List<SnapshotHelper.HtmlFooterMapping>{ new SnapshotHelper.HtmlFooterMapping('Finalized By', ParserHelper.ToString(treatmentPlan, 'Finalized_By__c')), new SnapshotHelper.HtmlFooterMapping('Finalized Date/Time', ParserHelper.ToDateTimeFormat(treatmentPlan, 'Finalized_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)) });

		html += '</div>';
		return html;
	}
}