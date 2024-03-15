public with sharing class AdmissionScreeningController {
	//Overload: If only passed parentId (account Id), use Current Admission as admissionId
	@AuraEnabled
	public static QuestionSetWrapper getQuestionsForAccount(String parentId) {
		Account patientAccount = [SELECT Id, Current_Admission__c, Service_Type__c FROM Account WHERE Id = :parentId];

		return getQuestions(parentId, String.valueOf(patientAccount.Current_Admission__c), patientAccount.Service_Type__c);
	}

	@AuraEnabled
	public static QuestionSetWrapper getQuestions(String parentId, String admissionId, String serviceType) {
		//if admissionId is null, return all questions for this account,
		//Id queryparentId = (String.isBlank(admissionId)) ? Id.valueOf(parentId) : null;

		List<QuestionWrapper> selectedQuestionWithAnswerProperties = new List<QuestionWrapper>();
		List<QuestionWrapper> allQuestionWithAnswerProperties = new List<QuestionWrapper>();

		List<Related_Contact__c> relatedContactsList = [
			SELECT
				Id,
				Name,
				Contact__r.Name,
				Role__c,
				Long_Role__c,
				RecordType.DeveloperName,
				(
					SELECT Id
					FROM Forms__r
					WHERE
						Admission__c = :admissionId // OR Admission__r.Patient_Account__c = :queryParentId)
						AND disco__Form_Template__r.Name LIKE '%checklist%'
					ORDER BY LastModifiedDate DESC
					LIMIT 1
				)
			FROM Related_Contact__c
			WHERE Account__c = :parentId
		];

		List<Related_Contact__c> relatedContacts = new List<Related_Contact__c>();
		Map<Id, Id> relatedContactForm = new Map<Id, Id>();
		Map<String, List<Related_Contact__c>> relatedContactOrderMap = new Map<String, List<Related_Contact__c>>{
			'Patient' => new List<Related_Contact__c>(),
			'Professional' => new List<Related_Contact__c>(),
			'Personal' => new List<Related_Contact__c>()
		};

		List<Related_Contact__c> relatedContactsSortByRecordType = new List<Related_Contact__c>();

		if (relatedContactsList.size() == 1) {
			relatedContactsSortByRecordType.addAll(relatedContactsList);
		} else {
			for (Integer i = 0; i < relatedContactsList.size(); i++) {
				if (relatedContactOrderMap.containsKey(relatedContactsList[i].RecordType.DeveloperName)) {
					relatedContactOrderMap.get(relatedContactsList[i].RecordType.DeveloperName).add(relatedContactsList[i]);
				}
			}
		}

		for (String rc : relatedContactOrderMap.keySet()) {
			if (relatedContactOrderMap.get(rc).size() > 0) {
				relatedContactsSortByRecordType.addAll(relatedContactOrderMap.get(rc));
			}
		}

		for (Related_Contact__c rc : relatedContactsSortByRecordType) {
			for (disco__Form__c df : rc.Forms__r) {
				relatedContacts.add(rc);
				relatedContactForm.put(rc.Id, df.Id);
			}
		}

		if (!relatedContactForm.isEmpty()) {
			selectedQuestionWithAnswerProperties = getQuestionWrapper(relatedContacts, relatedContactForm, true, serviceType);

			allQuestionWithAnswerProperties = getQuestionWrapper(relatedContacts, relatedContactForm, false, serviceType);

			return new QuestionSetWrapper(
				relatedContacts,
				selectedQuestionWithAnswerProperties,
				allQuestionWithAnswerProperties,
				serviceType
			);
		}

		return new QuestionSetWrapper(relatedContacts, selectedQuestionWithAnswerProperties, allQuestionWithAnswerProperties, serviceType);
	}

	public static List<QuestionWrapper> getQuestionWrapper(
		List<Related_Contact__c> relatedContacts,
		Map<Id, Id> relatedContactForm,
		Boolean isSelectedQuestions,
		String serviceType
	) {
		List<String> IgnoreHighlight = new List<String>{ 'Who is completing the Pre-Admissions Checklist?', 'Contact Name' };

		List<QuestionWrapper> questionWithAnswerProperties = new List<QuestionWrapper>();
		List<Id> formIds = relatedContactForm.values();

		String qryStr = 'SELECT Id,disco__Question__r.disco__Label__c, disco__Answer__c , disco__Question__r.disco__RandomId__c, ';
		qryStr =
			qryStr +
			'disco__Form__r.Related_Contact__r.Contact_Name__c,disco__Question__r.disco__Type__c, disco__Question__r.disco__Filter_Logic__c, ';
		qryStr =
			qryStr +
			'disco__Question__r.disco__Dependent_Question_Values__c, disco__Question__r.Selected_Question_Order__c, disco__Question__r.Alternate_Question_Order__c FROM disco__Answer__c WHERE (disco__Form__c  IN :formIds) ';

		if (isSelectedQuestions == true) {
			qryStr =
				qryStr +
				'AND disco__Question__r.Selected_Question_Order__c != NULL ORDER BY disco__Question__r.Selected_Question_Order__c ASC ';
		} else {
			qryStr =
				qryStr +
				'AND disco__Question__r.Alternate_Question_Order__c != NULL ORDER BY disco__Question__r.Alternate_Question_Order__c ASC ';
		}

		List<disco__Answer__c> discoAnswers = database.query(qryStr);

		Map<String, QuestionWrapper> randomId2quesWrapperMap = new Map<String, QuestionWrapper>();
		Map<Id, String> answerMap;
		Boolean isValid = true;
		String dropMe = 'IOP';

		if (serviceType == 'IOP') {
			dropMe = 'Residential';
		}

		for (disco__Answer__c da : discoAnswers) {
			if (da.disco__Question__r.disco__Filter_Logic__c != null) {
				if (da.disco__Question__r.disco__Filter_Logic__c.contains(dropMe)) {
					isValid = false;
				} else {
					isValid = true;
				}
			} else {
				isValid = true;
			}

			//  here is where the non-current service type is filtered out ot the
			//  screening matrix
			if (isValid) {
				// hands off to legacy process from this point forward
				if (!randomId2quesWrapperMap.containsKey(da.disco__Question__r.disco__RandomId__c)) {
					answerMap = new Map<Id, String>();

					for (Id rc : relatedContactForm.Keyset()) {
						answerMap.put(rc, '');
					}

					if (da.disco__Answer__c != null) {
						answerMap.put(da.disco__Form__r.Related_Contact__c, da.disco__Answer__c);
					}

					randomId2quesWrapperMap.put(
						da.disco__Question__r.disco__RandomId__c,
						new QuestionWrapper(
							da.disco__Question__r.disco__Label__c,
							answerMap,
							null,
							da.disco__Question__r.disco__Type__c,
							serviceType
						)
					);
				} else {
					if (da.disco__Answer__c != null)
						answerMap.put(da.disco__Form__r.Related_Contact__c, da.disco__Answer__c);

					QuestionWrapper qwrp = randomId2quesWrapperMap.get(da.disco__Question__r.disco__RandomId__c);

					qwrp.answerMap = answerMap;

					randomId2quesWrapperMap.put(da.disco__Question__r.disco__RandomId__c, qwrp);
				}
			}
		}

		for (QuestionWrapper qw : randomId2quesWrapperMap.values()) {
			qw.answers = qw.answerMap.values();
			qw.isAnswersDifferent = false;

			if (!IgnoreHighlight.contains(qw.label) && qw.type != 'Text') {
				qw.isAnswersDifferent = isAllAnswersDifferent(qw.answerMap.values());
			}

			questionWithAnswerProperties.add(qw);
		}

		return questionWithAnswerProperties;
	}

	public static Boolean isAllAnswersDifferent(List<String> answers) {
		Boolean isDifferent = false;

		if (answers.size() > 0) {
			for (Integer i = 0; i < answers.size(); i++) {
				for (Integer j = i + 1; j < answers.size(); j++) {
					if (answers[i] == '') {
						break;
					}
					if (answers[j] != '' && answers[i] != answers[j]) {
						isDifferent = true;
						break;
					}
				}

				if (isDifferent) {
					break;
				}
			}
		}
		return isDifferent;
	}

	public class QuestionWrapper {
		@AuraEnabled
		public String label { get; set; }

		public Map<Id, String> answerMap { get; set; }

		@AuraEnabled
		public Boolean isAnswersDifferent { get; set; }

		@AuraEnabled
		public List<String> answers { get; set; }

		@AuraEnabled
		public String type { get; set; }

		@AuraEnabled
		public String serviceType { get; set; }

		public QuestionWrapper(String label, Map<Id, String> answerMap, List<String> answers, String type, String serviceType) {
			this.label = label;
			this.answerMap = answerMap;
			this.answers = answers;
			this.type = type;
			this.serviceType = serviceType;
		}
	}

	public class QuestionSetWrapper {
		@AuraEnabled
		public List<Related_Contact__c> relatedContacts;

		@AuraEnabled
		public List<QuestionWrapper> selectedQuestions;

		@AuraEnabled
		public List<QuestionWrapper> allQuestions;

		@AuraEnabled
		public String serviceType;

		public QuestionSetWrapper(
			List<Related_Contact__c> relatedContacts,
			List<QuestionWrapper> selectedquestionWithAnswer,
			List<QuestionWrapper> allSelectedquestionWithAnswer,
			String serviceType
		) {
			this.relatedContacts = relatedContacts;
			this.selectedQuestions = selectedquestionWithAnswer;
			this.allQuestions = allSelectedquestionWithAnswer;
			this.serviceType = serviceType;
		}
	}
}