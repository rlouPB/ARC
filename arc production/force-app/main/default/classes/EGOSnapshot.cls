public without sharing class EGOSnapshot {
	static map<id, Goal__c[]> goalsByEgoIdMap = new Map<id, Goal__c[]>();

	static map<id, Goal__c[]> goalsByDomainId = new Map<id, Goal__c[]>();

	static Map<Id, EGO_Rating__c> ratingByGoalIdMap = new Map<Id, EGO_Rating__c>();

	static map<id, EGO_Rating__c> ratingByObjectiveIdMap = new Map<id, EGO_Rating__c>();

	static map<string, RatingWrapper[]> ratingsByDomainIdEgoMap = new Map<string, RatingWrapper[]>();

	static map<id, Eval_Item__mdt> evalItemsMap = new Map<Id, Eval_Item__mdt>();

	static Eval_Item__mdt[] evalItemsList = new List<Eval_Item__mdt>{};

	static map<id, account> accountMap = new Map<id, account>();

	static map<id, EGO__c> egoMap;

	public class RatingWrapper implements Comparable {
		public EGO_Rating__c rating;

		public Eval_Item__mdt evalItem;

		public RatingWrapper(EGO_Rating__c rating, Eval_Item__mdt evalItem) {
			this.rating = rating;
			this.evalItem = evalItem;
		}
		public Integer compareTo(Object compareTo) {
			RatingWrapper compareToWrapper = (RatingWrapper) compareTo;
			integer returnValue = 0;
			if (this.evalItem.Item_Number__c > compareToWrapper.evalItem.Item_Number__c) {
				returnValue = 1;
			} else if (this.evalItem.Item_Number__c < compareToWrapper.evalItem.Item_Number__c) {
				returnValue = -1;
			} else if (this.evalItem.Item_Number__c == null && compareToWrapper.evalItem.Item_Number__c != null) {
				returnValue = -1;
			} else if (this.evalItem.Item_Number__c != null && compareToWrapper.evalItem.Item_Number__c == null) {
				returnValue = 1;
			}
			return returnValue;
		}
	}

	public static void process(Id[] egoIds) {
		fillData(egoIds);

		egoMap = new Map<id, EGO__c>([SELECT id, Overall_Goal__c, Admission__r.Patient_Account__c, Current_Treatment_Plan__r.AccountId, Finalized_By__c, Finalized_Date_Time__c FROM EGO__C WHERE id IN :egoIds]);

		Snapshot__c[] snapshots = new List<Snapshot__c>{};
		for (EGO__c ego : egoMap.values()) {
			string html = getHtml(ego.Id);
			string patientId = ParserHelper.toString(ego, 'Admission__r.Patient_Account__c');
			string psychiatrist = string.isNotBlank(patientId) ? SnapshotHelper.getTeamMembersByRole(patientId, 'Psychiatrist') : '';
			string psychotherapist = string.isNotblank(patientId) ? SnapshotHelper.getTeamMembersByRole(patientId, 'Psychotherapist') : '';
			string patientName = ParserHelper.toString(accountMap.get(patientId), 'Name');
			snapshots.add(new Snapshot__c(Patient_Name__c = patientName, EGO__C = ego.id, html__c = html, Psychiatrist__c = psychiatrist, Psychotherapist__c = psychotherapist, Team_Members__c = null, Finalized_By__c = SnapshotHelper.currentUser?.Professional_Name__c, Finalized_Date_Time__c = system.now()));
		}

		if (snapshots.size() > 0) {
			insert snapshots;
			EGO__c[] egosToUpdate = new List<EGO__c>{};
			for (Snapshot__c snap : snapshots) {
				egosToUpdate.add(new EGO__C(Id = snap.EGO__C, Snapshot__C = snap.Id));
			}
			update egosToUpdate;
		}
	}

	static void fillData(id[] egoIds) {
		set<id> accountIds = new Set<id>();
		for (Ego__c ego : [SELECT Finalized_Date_Time__c, Current_Treatment_Plan__r.AccountId FROM EGO__c WHERE id IN :egoIds AND Current_Treatment_Plan__r.AccountId != NULL]) {
			accountIds.add(ego.Current_Treatment_Plan__r.AccountId);
		}
		accountMap = new Map<id, account>([SELECT id, Name, current_case__c, Current_Admission__r.Psychotherapist__r.Professional_Name__c FROM account WHERE id IN :accountIds]);

		SnapshotHelper.fillMaps(accountMap.keySet());

		evalItemsList = [SELECT Id, Label, Item_Number__c, Domain__c FROM Eval_Item__mdt ORDER BY Item_Number__c ASC];

		evalItemsMap = new Map<Id, Eval_Item__mdt>(evalItemsList);

		for (EGO_Rating__c rating : [SELECT Id, Rating__c, Label__c, EGO__c, Objective__c, Goal__c, Comments__c, Domain_Eval_Item_ID__c FROM EGO_Rating__c WHERE EGO__c IN :egoIds ORDER BY Print_Order__c]) {
			if (rating.Goal__c != null && !ratingByGoalIdMap.containsKey(rating.Goal__c)) {
				ratingByGoalIdMap.put(rating.Goal__c, rating);
			}
			if (rating.Objective__c != null && !ratingByObjectiveIdMap.containsKey(rating.Objective__c)) {
				ratingByObjectiveIdMap.put(rating.Objective__c, rating);
			}
			if (rating.EGO__c != null && evalItemsMap.containsKey(rating.Domain_Eval_Item_ID__c)) {
				Eval_Item__mdt evalItem = evalItemsMap.get(rating.Domain_Eval_Item_ID__c);
				Domain__mdt domain = SnapshotHelper.domainsMap.get(evalItem.Domain__c);
				string key = '' + domain.Id + rating.Ego__C;
				if (!ratingsByDomainIdEgoMap.containsKey(key)) {
					ratingsByDomainIdEgoMap.put(key, new List<RatingWrapper>{});
				}
				ratingsByDomainIdEgoMap.get(key).add(new RatingWrapper(rating, evalItem));
			}
		}

		//SortRatingsByItemNumber
		for (string key : ratingsByDomainIdEgoMap.keyset()) {
			ratingsByDomainIdEgoMap.get(key).sort();
		}

		string goalQuery = QueryUtils.getQueryAll('Goal__c', new List<string>{ 'Continued_From_Goal__r.Date_Added__c', 'Continued_From_Goal__r.Target_Date__c', QueryUtils.getSubQueryAll('Objective__c', 'Objectives__r', new List<string>{ 'Continued_From_Objective__r.Date_Added__c', 'Continued_From_Objective__r.Target_Date__c' }, ' Order By Order__c') }) + ' WHERE EGO__C in :egoIds order by EGO__C, Domain_Name__c,Domain_Number__c,Order__c'; // DA - Added order

		for (Goal__c g : (Goal__c[]) database.query(goalQuery)) {
			if (!goalsByEgoIdMap.containsKey(g.EGO__C)) {
				goalsByEgoIdMap.put(g.EGO__C, new List<Goal__c>{});
			}
			goalsByEgoIdMap.get(g.EGO__C).add(g);

			if (string.isNotBlank(g.Domain_Metadata_ID__c)) {
				if (!goalsByDomainId.containsKey(g.Domain_Metadata_ID__c)) {
					goalsByDomainId.put(g.Domain_Metadata_ID__c, new List<Goal__c>{});
				}
				goalsByDomainId.get(g.Domain_Metadata_ID__c).add(g);
			}
		}
	}

	public static string getHtml(Id egoId) {
		string html = '';
		html = SnapshotHelper.getHtmlHeader('Evaluation, Goals and Objectives (EGO)');
		html += '<br>';
		html += SnapshotHelper.getHtmlOverallGoal(ParserHelper.toString(egoMap.get(egoId), 'Overall_Goal__c'));
		html += '<br>';
		for (Domain__mdt domain : SnapshotHelper.domains) {
			html += '<div class="slds-box">';
			html += string.format('<div class="slds-text-heading_medium"><b>Domain: {0}&nbsp;{1}</b></div>', new List<string>{ string.valueof(domain.Domain_Number__c).replace('.0', ''), domain.Label__c });

			html += getHtmlDomainRatings(domain, egoId);

			if (goalsByDomainId != null && goalsByDomainId.containsKey(domain.Id)) {
				html += string.format('<p class="slds-p-top_small"><h1><b>{0} Goals</b></h1></p>', new List<string>{ domain.Label__c });
				html += '<p>Goal/Objective Rating Scale:</p>';
				html += '<p>1 = no progress, 2 = minor progress, 3 = moderate progress, 4 = significant progress, 5 = very significant progress, 6 = goal/objective met</p>';
				for (Goal__c goal : goalsByDomainId.get(domain.Id)) {
					html += SnapshotHelper.getHtmlGoal(goal, ratingByGoalIdMap, ratingByObjectiveIdMap, false);
				}
			}
			html += '</div>';
		}
		html += '<br>';
		EGO__c eg = egoMap.get(egoId);
		Account patient = accountMap.get(eg.Current_Treatment_Plan__r.AccountId);

		html += '<div class="slds-p-around_small">';
		html += SnapshotHelper.getHtmlFooter(patient, new List<SnapshotHelper.HtmlFooterMapping>{ new SnapshotHelper.HtmlFooterMapping('Finalized By', ParserHelper.ToString(eg, 'Finalized_By__c')), new SnapshotHelper.HtmlFooterMapping('Finalized Date/Time', ParserHelper.ToDateTimeFormat(eg, 'Finalized_Date_Time__c', SnapshotHelper.DATETIMEFORMAT, SnapshotHelper.TIMEZONE)) });
		html += '</div>';

		return html;
	}

	public static string getHtmlDomainRatings(Domain__mdt domain, id egoId) {
		string html = '';
		//{!domain.domainObj.Domain_Number__c}.{!domainRatingItem.itemNumber}
		if (ratingsByDomainIdEgoMap.containsKey('' + domain.Id + egoId)) {
			html += '<p>Domain Rating Scale:</p>';
			html += '<p>1 = significant weakness, 2 = moderate weakness, 3 = relative weakness, 4 = relative strength, 5 = moderate strength, 6 = significant strength</p>';
			html += '<div class="slds-grid">';
			html += '<div class="slds-size_3-of-12 slds-p-left_medium"><b>Item</b></div>';
			html += '<div class="slds-size_3-of-12 slds-p-left_medium"><b>Rating</b></div>';
			html += '<div class="slds-size_6-of-12 slds-p-left_medium"><b>Comments</b></div>';
			html += '</div>';
			for (RatingWrapper er : ratingsByDomainIdEgoMap.get('' + domain.Id + egoId)) {
				html += '<div class="slds-grid">';
				html += string.format('<div class="slds-size_3-of-12 slds-p-left_medium"><div style="overflow-wrap: break-word;">{0} {1}</div></div>', new List<string>{ parserhelper.toInteger(domain, 'Domain_Number__c') + '.' + parserhelper.toInteger(er.evalItem, 'Item_Number__c'), parserhelper.toString(er.rating, 'Label__c') });
				html += string.format('<div class="slds-size_3-of-12 slds-p-left_medium"><div style="overflow-wrap: break-word;">{0}</div></div>', new List<string>{ SnapshotHelper.getHtmlRatingItem(parserhelper.ToInteger(er.rating, 'Rating__c')) });
				html += string.format('<div class="slds-size_6-of-12 slds-p-left_medium"><div style="overflow-wrap: break-word;">{0}</div></div>', new List<string>{ parserhelper.toString(er.rating, 'Comments__c') });
				html += '</div>';
			}
		}
		return html;
	}
}