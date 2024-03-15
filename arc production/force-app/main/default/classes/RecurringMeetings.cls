public class RecurringMeetings {
	// How far ahead in days to schedule meetings
	public static Integer daysInAdvanceToSchedule = 365;
	public static Date earliestDateToScheduleFrom = System.today().addMonths(-2);
	public static String recurrenceQueryString =
		'SELECT Id, Recurrence_Pattern__c, Recur_every__c, ' +
		'Weekdays__c, Start_Date__c, End_Type__c, End_By__c, Number_of_Occurrences__c, Excluded_Dates__c, ' +
		'Daily_Option__c, Monthly_Day_Number__c, Yearly_Month__c, Yearly_Day_Number__c, ' +
		'Original_Meeting__c, Original_Meeting__r.Subject__c, Original_Meeting__r.Start_Date_Time__c, ' +
		'Original_Meeting__r.End_Date_Time__c, Original_Meeting__r.All_Day_Date__c, Original_Meeting__r.All_Day_Meeting__c, ' +
		'Original_Meeting__r.Description__c, Original_Meeting__r.Patient_Account__c, ' +
		'Original_Meeting__r.Meeting_Focus__c, Original_Meeting__r.Other_Meeting_Type__c, ' +
		'Original_Meeting__r.Patient_Group_Meeting_Type__c, Original_Meeting__r.Patient_Meeting_Type__c, ' +
		'Original_Meeting__r.Group_Membership__c, Original_Meeting__r.Staff_Group_Meeting_Type__c, ' +
		'Original_Meeting__r.Room_Resource__c, Original_Meeting__r.OwnerId, Original_Meeting__r.Meeting_Type__c, OwnerId, Original_Meeting__r.Videoconference_Link__c, ' +
		'Month_Number__c, Monthly_Day_of_Week__c, Monthly_Day_of_Week_Ordinal__c, Monthly_Day_Type__c ' +
		'FROM Recurrence__c';
	public static String meetingQueryString = 'SELECT Id, Subject__c, Start_Date_Time__c, End_Date_Time__c, Description__c, Room_Resource__c, ' + 'Recurrence__c, Original_Start_Date_ID__c, Recurrence__r.Original_Meeting__c, OwnerId, Meeting_Type__c ' + 'FROM Meeting__c';
	// ORDER BY LastModifiedDate DESC) ' +
	@TestVisible
	private static Date today = System.today();
	@TestVisible
	private static Date endDateToScheduleInAdvance = today.addDays(daysInAdvanceToSchedule);
	@TestVisible
	private static List<Date> daysInRange = getAllDaysInRange();
	private static Map<Date, String> dateToDayOfWeek = DateUtils.getDateToDayOfWeek(daysInRange);
	private static Map<Id, Integer> recurrenceIdToLatestMeetingSequenceNumber = new Map<Id, Integer>();

	public static void createRecurringMeetings(RecurringMeetingOptions options) {
		if (options.recurrenceId != null) {
			String queryString = RecurringMeetings.recurrenceQueryString + ' WHERE Id = ' + '\'' + options.recurrenceId + '\'';
			List<Recurrence__c> recurrences = Database.query(queryString);
			RecurringMeetings.createRecurringMeetings(recurrences, options);
		}
	}

	public static void createRecurringMeetings(List<Recurrence__c> recurrences) {
		RecurringMeetingOptions options = new RecurringMeetingOptions();
		RecurringMeetings.createRecurringMeetings(recurrences, options);
	}

	public static void createRecurringMeetings(List<Recurrence__c> recurrences, RecurringMeetingOptions options) {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();
		Map<Id, Meeting__c> meetingsToUpdateMap = new Map<Id, Meeting__c>();
		Set<Id> oldMeetingIds = new Set<Id>();
		Map<Id, Id> recurrenceIdToOldMeetingId = new Map<Id, Id>();
		Map<String, List<Participant__c>> oldMeetingToParticipantsMap = new Map<String, List<Participant__c>>();
		Map<String, List<Participant__c>> clonedMeetingToParticipantsMap = new Map<String, List<Participant__c>>();

		List<Recurrence__c> dailyRecurrences = new List<Recurrence__c>();
		List<Recurrence__c> weeklyRecurrences = new List<Recurrence__c>();
		List<Recurrence__c> monthlyRecurrences = new List<Recurrence__c>();
		List<Recurrence__c> yearlyRecurrences = new List<Recurrence__c>();

		Set<Id> recurrenceIdSet = new Set<Id>();
		for (Recurrence__c recurrence : recurrences) {
			if (recurrence.Original_Meeting__c != null && recurrence.Recurrence_Pattern__c != null) {
				recurrenceIdSet.add(recurrence.Id);
			}
		}

		//If start or end date time on meeting was updated and modifying series
		if (!options.isMeetingUpdateOnly) {
			deleteOldMeetingsOnRecurrences(recurrenceIdSet);
			String queryString = recurrenceQueryString;
			if (queryString.endsWith('Recurrence__c')) {
				queryString += +' WHERE Id IN :recurrenceIdSet';
			}

			recurrences = Database.query(queryString);

			for (Recurrence__c recurrence : recurrences) {
				if (recurrence.Original_Meeting__c != null && recurrence.Recurrence_Pattern__c != null) {
					switch on recurrence.Recurrence_Pattern__c {
						when 'Daily' {
							dailyRecurrences.add(recurrence);
						}
						when 'Weekly' {
							weeklyRecurrences.add(recurrence);
						}
						when 'Monthly' {
							monthlyRecurrences.add(recurrence);
						}
						when 'Yearly' {
							yearlyRecurrences.add(recurrence);
						}
					}
				}
			}

			recurrenceIdToLatestMeetingSequenceNumber = getRecurrenceIdToLatestMeetingSequenceNumber(recurrences);

			if (!dailyRecurrences.isEmpty()) {
				List<Meeting__c> dailyMeetingsToInsert = createDailyMeetings(dailyRecurrences, oldMeetingIds, recurrenceIdToOldMeetingId, options);
				meetingsToInsert.addAll(dailyMeetingsToInsert);
				oldMeetingToParticipantsMap = getMeetingToParticipantsMap(oldMeetingIds);
			}

			if (!weeklyRecurrences.isEmpty()) {
				List<Meeting__c> weeklyMeetingsToInsert = createWeeklyMeetings(weeklyRecurrences, oldMeetingIds, recurrenceIdToOldMeetingId, options);
				meetingsToInsert.addAll(weeklyMeetingsToInsert);
				oldMeetingToParticipantsMap = getMeetingToParticipantsMap(oldMeetingIds);
			}

			if (!monthlyRecurrences.isEmpty()) {
				List<Meeting__c> monthlyMeetingsToInsert = createMonthlyMeetings(monthlyRecurrences, oldMeetingIds, recurrenceIdToOldMeetingId, options);
				meetingsToInsert.addAll(monthlyMeetingsToInsert);
				oldMeetingToParticipantsMap = getMeetingToParticipantsMap(oldMeetingIds);
			}

			if (!yearlyRecurrences.isEmpty()) {
				List<Meeting__c> yearlyMeetingsToInsert = createYearlyMeetings(yearlyRecurrences, oldMeetingIds, recurrenceIdToOldMeetingId, options);
				meetingsToInsert.addAll(yearlyMeetingsToInsert);
				oldMeetingToParticipantsMap = getMeetingToParticipantsMap(oldMeetingIds);
			}

			if (!meetingsToInsert.isEmpty()) {
				try {
					Database.insert(meetingsToInsert);
					List<Participant__c> participantsToInsert = new List<Participant__c>();
					for (Meeting__c meeting : meetingsToInsert) {
						String oldMeetingId = recurrenceIdToOldMeetingId.get(meeting.Recurrence__c);
						if (oldMeetingToParticipantsMap.containsKey(oldMeetingId)) {
							for (Participant__c participant : oldMeetingToParticipantsMap.get(oldMeetingId)) {
								Participant__c newParticipant = participant.clone(false, false, false, false);
								newParticipant.Meeting__c = meeting.Id;
								newParticipant.OwnerId = meeting.OwnerId;
								participantsToInsert.add(newParticipant);
							}
						}
					}

					if (!participantsToInsert.isEmpty()) {
						Database.insert(participantsToInsert);
					}
				} catch (Exception ex) {
					ProcessLogging.quickProcessLog('RecurringMeetings', ex.getStackTraceString(), ex.getMessage());
					System.debug('Exception occured! ' + ex.getMessage() + ' on line: ' + ex.getLineNumber());
				}
			}
		} else {
			String meetingQuery = RecurringMeetings.meetingQueryString + ' WHERE Recurrence__c in :recurrenceIdSet ORDER BY Start_Date_Time__c DESC';
			List<Meeting__c> meetingsFromRecurrences = Database.query(meetingQuery);
			Map<Id, List<Meeting__c>> recurrenceToMeetingsMap = getRecurrenceToMeetingsMap(recurrences, meetingsFromRecurrences);

			//TODO make it so you can update any meeting and have it apply to all of them, not just the Original
			for (Recurrence__c recurrence : recurrences) {
				if (recurrence.Original_Meeting__c != null) {
					Meeting__c meetingClone = recurrence.Original_Meeting__r.clone(false, false, false, false);
					List<Meeting__c> seriesMeetings = recurrenceToMeetingsMap.get(recurrence.Id);

					for (Meeting__c meeting : seriesMeetings) {
						if (meeting.Id != recurrence.Original_Meeting__c) {
							meeting.Subject__c = meetingClone.Subject__c;
							meeting.Description__c = meetingClone.Description__c;
							meeting.OwnerId = meetingClone.OwnerId;
							meeting.Room_Resource__c = meetingClone.Room_Resource__c;
							meeting.Videoconference_Link__c = meetingClone.Videoconference_Link__c;
							//meeting.Meeting_Type__c = meetingClone.Meeting_Type__c;
							meeting.Patient_Meeting_Type__c = meetingClone.Patient_Meeting_Type__c;
							meeting.Patient_Group_Meeting_Type__c = meetingClone.Patient_Group_Meeting_Type__c;
							meeting.Staff_Group_Meeting_Type__c = meetingClone.Staff_Group_Meeting_Type__c;
							meeting.Other_Meeting_Type__c = meetingClone.Other_Meeting_Type__c;
							meeting.Meeting_Focus__c = meetingClone.Meeting_Focus__c;
							meeting.Patient_Account__c = meetingClone.Patient_Account__c;
							meeting.Group_Membership__c = meetingClone.Group_Membership__c;
						}
					}
				}
			}
			List<Meeting__c> meetingsToUpdate = new List<Meeting__c>();
			if (!recurrenceToMeetingsMap.isEmpty()) {
				Set<Id> meetingIdsToUpdate = new Set<Id>();
				for (Id recurrenceId : recurrenceToMeetingsMap.keySet()) {
					for (Meeting__c meeting : recurrenceToMeetingsMap.get(recurrenceId)) {
						meetingIdsToUpdate.add(meeting.Id);
						meetingsToUpdate.add(meeting);
					}
				}
				clonedMeetingToParticipantsMap = getMeetingToParticipantsMap(meetingIdsToUpdate);

				List<Participant__c> participantsToDelete = new List<Participant__c>();
				List<Participant__c> participantsToInsert = new List<Participant__c>();

				Map<Id, List<Participant__c>> recurrenceOfOriginalMeetingToParticipantsMap = getRecurrenceOfOriginalMeetingToParticipantsMap(recurrences);
				for (Id recurrenceId : recurrenceToMeetingsMap.keySet()) {
					for (Meeting__c meeting : recurrenceToMeetingsMap.get(recurrenceId)) {
						if (clonedMeetingToParticipantsMap.containsKey(meeting.Id)) {
							for (Participant__c participant : clonedMeetingToParticipantsMap.get(meeting.Id)) {
								participantsToDelete.add(participant);
							}
						}

						if (recurrenceOfOriginalMeetingToParticipantsMap.containsKey(recurrenceId)) {
							for (Participant__c participant : recurrenceOfOriginalMeetingToParticipantsMap.get(recurrenceId)) {
								Participant__c newParticipant = participant.clone(false, false, false, false);
								newParticipant.Meeting__c = meeting.Id;
								newParticipant.OwnerId = meeting.OwnerId;
								participantsToInsert.add(newParticipant);
							}
						}
					}
				}

				Savepoint sp = Database.setSavePoint();
				try {
					Database.update(meetingsToUpdate);
					Database.delete(participantsToDelete);
					Database.insert(participantsToInsert);
				} catch (Exception ex) {
					Database.rollBack(sp);
					ProcessLogging.quickProcessLog('RecurringMeetings', ex.getStackTraceString(), ex.getMessage());
					throw ex;
				}
			}
		}
	}

	private static List<Meeting__c> createDailyMeetings(List<Recurrence__c> recurrences, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, RecurringMeetingOptions options) {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();

		for (Recurrence__c recurrence : recurrences) {
			dateToDayOfWeek = DateUtils.getDateToDayOfWeek(daysInRange);
			if (recurrence.Daily_Option__c != null) {
				// copy all days in range into new date list
				List<Date> filteredList = daysInRange;
				// get the latest meeting sequence number
				Integer meetingSequenceNumber = 0;
				if (recurrenceIdToLatestMeetingSequenceNumber.containsKey(recurrence.Id)) {
					meetingSequenceNumber = recurrenceIdToLatestMeetingSequenceNumber.get(recurrence.Id);
				}
				// if weekdays only, remove weekends
				if (recurrence.Daily_Option__c == 'Weekdays Only') {
					for (Integer i = filteredList.size() - 1; i >= 0; i--) {
						Date currentDate = filteredList[i];
						if (dateToDayOfWeek.containsKey(currentDate)) {
							if (dateToDayOfWeek.get(currentDate) == 'Saturday' || dateToDayOfWeek.get(currentDate) == 'Sunday') {
								filteredList.remove(i);
							}
						}
					}
				}

				// loop through date list
				for (Date currentDate : filteredList) {
					if (options.scheduleAfterToday && currentDate >= System.today() || !options.scheduleAfterToday) {
						meetingSequenceNumber = applyDailyFilterToDate(recurrence, currentDate, meetingsToInsert, oldMeetingIds, recurrenceIdToOldMeetingId, meetingSequenceNumber);
					}
				}
			}
		}

		return meetingsToInsert;
	}

	private static List<Meeting__c> createWeeklyMeetings(List<Recurrence__c> recurrences, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, RecurringMeetingOptions options) {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();

		// loop through recurrences
		for (Recurrence__c recurrence : recurrences) {
			if (recurrence.Weekdays__c != null) {
				// get the weekday filter
				Set<String> weekdays = splitStringToSet(recurrence.Weekdays__c);
				// copy all days in range into new date list
				List<Date> filteredList = daysInRange;
				// get the latest meeting sequence number
				Integer meetingSequenceNumber = 0;
				if (recurrenceIdToLatestMeetingSequenceNumber.containsKey(recurrence.Id)) {
					meetingSequenceNumber = recurrenceIdToLatestMeetingSequenceNumber.get(recurrence.Id);
				}

				// loop through date list
				for (Date currentDate : filteredList) {
					if (options.scheduleAfterToday && currentDate >= earliestDateToScheduleFrom || !options.scheduleAfterToday) {
						meetingSequenceNumber = applyWeeklyFilterToDate(recurrence, weekdays, currentDate, meetingsToInsert, oldMeetingIds, recurrenceIdToOldMeetingId, meetingSequenceNumber);
					}
				}
			}
		}

		return meetingsToInsert;
	}

	private static List<Meeting__c> createMonthlyMeetings(List<Recurrence__c> recurrences, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, RecurringMeetingOptions options) {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();

		for (Recurrence__c recurrence : recurrences) {
			if (recurrence.Monthly_Day_Type__c == 'Day Number') {
				if (recurrence.Monthly_Day_Number__c != null) {
					// copy all days in range into new date list
					List<Date> filteredList = daysInRange;
					// get the latest meeting sequence number
					Integer meetingSequenceNumber = 0;
					if (recurrenceIdToLatestMeetingSequenceNumber.containsKey(recurrence.Id)) {
						meetingSequenceNumber = recurrenceIdToLatestMeetingSequenceNumber.get(recurrence.Id);
					}

					// loop through date list
					for (Date currentDate : filteredList) {
						if (options.scheduleAfterToday && currentDate >= System.today() || !options.scheduleAfterToday) {
							Integer numberOfDaysInMonth = Date.daysInMonth(currentDate.year(), currentDate.month());

							if ((currentDate.day() == recurrence.Monthly_Day_Number__c) || (recurrence.Monthly_Day_Number__c > numberOfDaysInMonth && currentDate.day() == numberOfDaysInMonth)) {
								meetingSequenceNumber = applyMonthlyFilterToDate(recurrence, currentDate, meetingsToInsert, oldMeetingIds, recurrenceIdToOldMeetingId, meetingSequenceNumber);
							}
						}
					}
				}
			} else if (recurrence.Monthly_Day_Type__c == 'Day of Week') {
				// check for null fields: Monthly_Day_of_Week_Ordinal__c, Monthly Day of Week, Month Number
				if (recurrence.Monthly_Day_of_Week__c != null && recurrence.Monthly_Day_of_Week_Ordinal__c != null && recurrence.Month_Number__c != null) {
					//     loop over days of month (for each day)
					//          (run get ordinal day of week)
					//          if (ordinal day of week = recurrence options)
					//              applyMonthlyFilterToDate
					//
					if (recurrence.Monthly_Day_Number__c != null) {
						// copy all days in range into new date list
						List<Date> filteredList = daysInRange;
						// get the latest meeting sequence number
						Integer meetingSequenceNumber = 0;
						if (recurrenceIdToLatestMeetingSequenceNumber.containsKey(recurrence.Id)) {
							meetingSequenceNumber = recurrenceIdToLatestMeetingSequenceNumber.get(recurrence.Id);
						}

						// loop through date list
						for (Date currentDate : filteredList) {
							// declare Original Date here
							Date originalDate;
							// TO DO: if Original Meeting is All Day Meeting
							//
							if (recurrence.Original_Meeting__r.All_Day_Meeting__c == true) {
								originalDate = recurrence.Original_Meeting__r.All_Day_Date__c;
							} else {
								DateTime originalDateTime = recurrence.Original_Meeting__r.Start_Date_Time__c;
								originalDate = Date.newInstance(originalDateTime.year(), originalDateTime.month(), originalDateTime.day());
							}
							Integer monthsFromOriginal = originalDate.monthsBetween(currentDate);
							Boolean currentMonthNeedsMeeting = (Math.mod(monthsFromOriginal, recurrence.Month_Number__c.intValue()) == 0);
							if (currentMonthNeedsMeeting) {
								if (options.scheduleAfterToday && currentDate >= System.today() || !options.scheduleAfterToday) {
									String code1 = recurrence.Monthly_Day_of_Week__c + '-' + recurrence.Monthly_Day_of_Week_Ordinal__c;
									String code2 = getOrdinalDayOfWeek(currentDate);
									if (code1 == code2) {
										meetingSequenceNumber = applyMonthlyFilterToDate(recurrence, currentDate, meetingsToInsert, oldMeetingIds, recurrenceIdToOldMeetingId, meetingSequenceNumber);
									}
								}
							}
						}
					}
				}
			}
		}

		return meetingsToInsert;
	}

	private static List<Meeting__c> createYearlyMeetings(List<Recurrence__c> recurrences, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, RecurringMeetingOptions options) {
		List<Meeting__c> meetingsToInsert = new List<Meeting__c>();

		for (Recurrence__c recurrence : recurrences) {
			if (recurrence.Yearly_Month__c != null && recurrence.Yearly_Day_Number__c != null) {
				// copy all days in range into new date list
				List<Date> filteredList = daysInRange;
				// get the latest meeting sequence number
				Integer meetingSequenceNumber = 0;
				if (recurrenceIdToLatestMeetingSequenceNumber.containsKey(recurrence.Id)) {
					meetingSequenceNumber = recurrenceIdToLatestMeetingSequenceNumber.get(recurrence.Id);
				}

				// loop through date list
				for (Date currentDate : filteredList) {
					if (options.scheduleAfterToday && currentDate >= System.today() || !options.scheduleAfterToday) {
						Integer numberOfDaysInMonth = Date.daysInMonth(currentDate.year(), currentDate.month());

						if (((currentDate.day() == recurrence.Yearly_Day_Number__c) || (recurrence.Yearly_Day_Number__c > numberOfDaysInMonth && currentDate.day() == numberOfDaysInMonth)) && currentDate.month() == getMonthNumberFromString(recurrence.Yearly_Month__c)) {
							meetingSequenceNumber = applyMonthlyFilterToDate(recurrence, currentDate, meetingsToInsert, oldMeetingIds, recurrenceIdToOldMeetingId, meetingSequenceNumber);
						}
					}
				}
			}
		}

		return meetingsToInsert;
	}

	private static Integer applyDailyFilterToDate(Recurrence__c recurrence, Date currentDate, List<Meeting__c> meetingsToInsert, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, Integer meetingSequenceNumber) {
		if (currentDate >= recurrence.Start_Date__c && (isValidEndAfterOccurrences(recurrence, meetingSequenceNumber) || isValidEndByDate(recurrence, currentDate) || isNoEndDate(recurrence)) && !hasMeeting(recurrence, currentDate)) {
			Meeting__c meeting = recurrence.Original_Meeting__r.clone(false, false, false, false);
			meeting.Recurrence__c = recurrence.Id;
			// if meeting is All Day Meeting, do not run this block
			if (!meeting.All_Day_Meeting__c) {
				meeting.Start_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.Start_Date_Time__c);
				meeting.End_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.End_Date_Time__c);
			} else {
				meeting.All_Day_Date__c = currentDate;
			}
			meeting.OwnerId = recurrence.OwnerId;
			meeting.Meeting_Sequence_Number__c = ++meetingSequenceNumber;

			if (!meeting.All_Day_Meeting__c) {
				if (recurrence.Original_Meeting__r.Start_Date_Time__c != meeting.Start_Date_Time__c) {
					meetingsToInsert.add(meeting);
				}
			} else {
				if (recurrence.Original_Meeting__r.All_Day_Date__c != meeting.All_Day_Date__c) {
					meetingsToInsert.add(meeting);
				}
			}
			oldMeetingIds.add(recurrence.Original_Meeting__c);
			recurrenceIdToOldMeetingId.put(recurrence.Id, recurrence.Original_Meeting__c);
		}
		return meetingSequenceNumber;
	}

	private static Integer applyWeeklyFilterToDate(Recurrence__c recurrence, Set<String> weekdays, Date currentDate, List<Meeting__c> meetingsToInsert, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, Integer meetingSequenceNumber) {
		if (weekdays.contains(DateUtils.getDayOfWeek(currentDate)) && (currentDate >= recurrence.Start_Date__c) && (isValidEndAfterOccurrences(recurrence, meetingSequenceNumber) || isValidEndByDate(recurrence, currentDate) || isNoEndDate(recurrence)) && isCorrectRecurringWeek(recurrence, currentDate) && !hasMeeting(recurrence, currentDate)) {
			Meeting__c meeting = recurrence.Original_Meeting__r.clone(false, false, false, false);
			meeting.Recurrence__c = recurrence.Id;
			if (!meeting.All_Day_Meeting__c) {
				meeting.Start_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.Start_Date_Time__c);
				meeting.End_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.End_Date_Time__c);
			} else {
				meeting.All_Day_Date__c = currentDate;
			}

			meeting.OwnerId = recurrence.OwnerId;
			meeting.Meeting_Sequence_Number__c = ++meetingSequenceNumber;

			if (!meeting.All_Day_Meeting__c) {
				if (recurrence.Original_Meeting__r.Start_Date_Time__c != meeting.Start_Date_Time__c) {
					meetingsToInsert.add(meeting);
				}
			} else {
				if (recurrence.Original_Meeting__r.All_Day_Date__c != meeting.All_Day_Date__c) {
					meetingsToInsert.add(meeting);
				}
			}
			oldMeetingIds.add(recurrence.Original_Meeting__c);
			recurrenceIdToOldMeetingId.put(recurrence.Id, recurrence.Original_Meeting__c);
		}
		return meetingSequenceNumber;
	}

	private static Integer applyMonthlyFilterToDate(Recurrence__c recurrence, Date currentDate, List<Meeting__c> meetingsToInsert, Set<Id> oldMeetingIds, Map<Id, Id> recurrenceIdToOldMeetingId, Integer meetingSequenceNumber) {
		if (currentDate >= recurrence.Start_Date__c && (isValidEndAfterOccurrences(recurrence, meetingSequenceNumber) || isValidEndByDate(recurrence, currentDate) || isNoEndDate(recurrence)) && !hasMeeting(recurrence, currentDate)) {
			Meeting__c meeting = recurrence.Original_Meeting__r.clone(false, false, false, false);
			meeting.Recurrence__c = recurrence.Id;
			if (!meeting.All_Day_Meeting__c) {
				meeting.Start_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.Start_Date_Time__c);
				meeting.End_Date_Time__c = updateDatetimeFromOriginalTime(currentDate, recurrence.Original_Meeting__r.End_Date_Time__c);
			} else {
				meeting.All_Day_Date__c = currentDate;
			}

			meeting.OwnerId = recurrence.OwnerId;
			meeting.Meeting_Sequence_Number__c = ++meetingSequenceNumber;

			if (!meeting.All_Day_Meeting__c) {
				if (recurrence.Original_Meeting__r.Start_Date_Time__c != meeting.Start_Date_Time__c) {
					meetingsToInsert.add(meeting);
				}
			} else {
				if (recurrence.Original_Meeting__r.All_Day_Date__c != meeting.All_Day_Date__c) {
					meetingsToInsert.add(meeting);
				}
			}
			oldMeetingIds.add(recurrence.Original_Meeting__c);
			recurrenceIdToOldMeetingId.put(recurrence.Id, recurrence.Original_Meeting__c);
		}
		return meetingSequenceNumber;
	}

	@testVisible
	private static String getOrdinalDayOfWeek(Date dt) {
		String weekday = DateTime.newInstance(dt, Time.newInstance(0, 0, 0, 0)).format('EEEE');
		Integer calculatedNum = Integer.valueOf(1 + Math.floor((dt.day() - 1) / 7));
		return weekday + '-' + calculatedNum;
	}

	@TestVisible
	private static List<Date> getAllDaysInRange() {
		return DateUtils.getAllDaysInRange(earliestDateToScheduleFrom, endDateToScheduleInAdvance);
	}

	private static Set<String> splitStringToSet(String value) {
		Set<String> valueSet = new Set<String>();

		if (value != null) {
			valueSet.addAll(value.split(';'));
		}

		return valueSet;
	}

	private static Map<Id, Integer> getRecurrenceIdToLatestMeetingSequenceNumber(List<Recurrence__c> recurrences) {
		Map<Id, Integer> recurrenceIdToLatestMeetingSequenceNumber = new Map<Id, Integer>();
		Set<Id> recurrenceIdSet = new Set<Id>();
		for (Recurrence__c recurrence : recurrences) {
			if (recurrence.End_Type__c == 'End After Occurrences') {
				recurrenceIdSet.add(recurrence.Id);
			}
		}

		for (Recurrence__c recurrence : [SELECT Id, (SELECT Id, Meeting_Sequence_Number__c FROM Meetings__r ORDER BY Meeting_Sequence_Number__c DESC NULLS LAST) FROM Recurrence__c WHERE Id IN :recurrenceIdSet]) {
			if (!recurrence.Meetings__r.isEmpty()) {
				Integer meetingSequenceNumber = (Integer) recurrence.Meetings__r[0].Meeting_Sequence_Number__c;
				if (meetingSequenceNumber != null) {
					recurrenceIdToLatestMeetingSequenceNumber.put(recurrence.Id, meetingSequenceNumber);
				}
			}
		}

		for (Id key : recurrenceIdSet) {
			if (!recurrenceIdToLatestMeetingSequenceNumber.containsKey(key)) {
				recurrenceIdToLatestMeetingSequenceNumber.put(key, 0);
			}
		}

		return recurrenceIdToLatestMeetingSequenceNumber;
	}

	// If this is true, then create a new meeting based on the last meetingSequenceNumber
	private static Boolean isValidEndAfterOccurrences(Recurrence__c recurrence, Integer meetingSequenceNumber) {
		if (recurrence.End_Type__c == 'End After Occurrences' && recurrence.Number_of_Occurrences__c != null && meetingSequenceNumber < recurrence.Number_of_Occurrences__c) {
			return true;
		}
		return false;
	}

	private static Boolean isValidEndByDate(Recurrence__c recurrence, Date currentDate) {
		if (recurrence.End_Type__c == 'End By Date' && recurrence.End_By__c != null && currentDate <= recurrence.End_By__c) {
			return true;
		}
		return false;
	}

	private static Boolean isNoEndDate(Recurrence__c recurrence) {
		if (recurrence.End_Type__c == 'No End Date') {
			return true;
		}
		return false;
	}

	private static Boolean hasMeeting(Recurrence__c recurrence, Date currentDate) {
		for (Meeting__c meeting : recurrence.Meetings__r) {
			if (meeting.Start_Date_Time__c.dateGMT() == currentDate) {
				return true;
			}
		}
		return false;
	}

	@TestVisible
	private static Boolean isCorrectRecurringWeek(Recurrence__c recurrence, Date currentDate) {
		if (recurrence.Recur_every__c == 1) {
			return true;
		}
		Date startDate = recurrence.Start_Date__c;
		Integer daysBetween = startDate.daysBetween(currentDate);
		Integer weekNumber = (Integer) Math.floor(daysBetween / 7);
		return (Math.mod(weekNumber, (Integer) recurrence.Recur_every__c) == 0);
	}

	@TestVisible
	private static Integer getMonthNumberFromString(String month) {
		Integer numberMonth;
		switch on month {
			when 'January' {
				numberMonth = 1;
			}
			when 'February' {
				numberMonth = 2;
			}
			when 'March' {
				numberMonth = 3;
			}
			when 'April' {
				numberMonth = 4;
			}
			when 'May' {
				numberMonth = 5;
			}
			when 'June' {
				numberMonth = 6;
			}
			when 'July' {
				numberMonth = 7;
			}
			when 'August' {
				numberMonth = 8;
			}
			when 'September' {
				numberMonth = 9;
			}
			when 'October' {
				numberMonth = 10;
			}
			when 'November' {
				numberMonth = 11;
			}
			when 'December' {
				numberMonth = 12;
			}
		}
		return numberMonth;
	}

	private static Datetime updateDatetimeFromOriginalTime(Date newDate, Datetime oldDatetime) {
		// Datetime newDatetime = Datetime.newInstanceGmt(newDate, oldDatetime.timeGmt());
		Datetime newDatetime = Datetime.newInstance(newDate, oldDatetime.time());
		return newDatetime;
	}

	private static Map<String, List<Participant__c>> getMeetingToParticipantsMap(Set<Id> meetingIds) {
		Map<String, List<Participant__c>> oldMeetingToParticipantsMap = new Map<String, List<Participant__c>>();

		for (Participant__c participant : [SELECT Id, Meeting__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participant__c WHERE Meeting__c IN :meetingIds]) {
			oldMeetingToParticipantsMap = MapUtils.addItemToStringToObjectsMap(oldMeetingToParticipantsMap, participant.Meeting__c, participant);
		}

		return oldMeetingToParticipantsMap;
	}

	private static void deleteOldMeetingsOnRecurrences(Set<Id> recurrenceIdSet) {
		List<Meeting__c> meetingsToDelete = new List<Meeting__c>();
		List<Participant__c> participantsToDelete = new List<Participant__c>();
		for (
			Meeting__c meeting : [
				SELECT Id, Recurrence__c, Recurrence__r.Original_Meeting__c, Original_Start_Date_ID__c, (SELECT Id FROM Participants__r)
				FROM Meeting__c
				WHERE
					Recurrence__c IN :recurrenceIdSet
					//AND Start_Date_Time__c >= TODAY])
					AND Start_Date_Time__c >= :earliestDateToScheduleFrom
			]
		) {
			if (meeting.Recurrence__r.Original_Meeting__c != meeting.Id) {
				meetingsToDelete.add(meeting);
				// for(Participant__c participant : meeting.Participants__r)
				// {
				//     participantsToDelete.add(participant);
				// }
				participantsToDelete.addAll(meeting.Participants__r);
			}
		}

		// if(!participantsToDelete.isEmpty())
		// {
		Database.delete(participantsToDelete);
		// }

		// if(!meetingsToDelete.isEmpty())
		// {
		Database.delete(meetingsToDelete);
		// }
	}

	private static Map<Id, List<Meeting__c>> getRecurrenceToMeetingsMap(List<Recurrence__c> recurrences, List<Meeting__c> meetings) {
		Map<Id, List<Meeting__c>> recurrenceToMeetingsMap = new Map<Id, List<Meeting__c>>();
		for (Meeting__c meeting : meetings) {
			List<Meeting__c> recurrenceMeetings = (recurrenceToMeetingsMap.containsKey(meeting.Recurrence__c)) ? recurrenceToMeetingsMap.get(meeting.Recurrence__c) : new List<Meeting__c>();
			recurrenceMeetings.add(meeting);
			recurrenceToMeetingsMap.put(meeting.Recurrence__c, recurrenceMeetings);
		}

		return recurrenceToMeetingsMap;
	}

	private static Map<Id, List<Participant__c>> getRecurrenceOfOriginalMeetingToParticipantsMap(List<Recurrence__c> recurrences) {
		Map<Id, List<Participant__c>> recurrenceOfOriginalMeetingToParticipantsMap = new Map<Id, List<Participant__c>>();
		Set<Id> meetingIds = new Set<Id>();
		for (Recurrence__c recurrence : recurrences) {
			meetingIds.add(recurrence.Original_Meeting__c);
		}

		for (Participant__c participant : [SELECT Id, Meeting__r.Recurrence__c, User__c, Contact__c, Group__c, RecordTypeId, OwnerId FROM Participant__c WHERE Meeting__c IN :meetingIds]) {
			recurrenceOfOriginalMeetingToParticipantsMap = MapUtils.addItemToStringToObjectsMap(recurrenceOfOriginalMeetingToParticipantsMap, participant.Meeting__r.Recurrence__c, participant);
		}

		return recurrenceOfOriginalMeetingToParticipantsMap;
	}

	public class RecurringMeetingOptions {
		public Boolean scheduleAfterToday;
		public Boolean isMeetingUpdateOnly;
		public Id recurrenceId;

		public RecurringMeetingOptions() {
			scheduleAfterToday = false;
			isMeetingUpdateOnly = false;
		}
	}
}