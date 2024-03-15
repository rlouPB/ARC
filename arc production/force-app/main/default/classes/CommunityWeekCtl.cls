public with sharing class CommunityWeekCtl {
	public static List<String> dayNames = new List<String>{ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' };

	Scheduling.Options schedulingOptions;
	public Scheduling.Calendar calendar = new Scheduling.Calendar();

	public CommunityWeekCtl(Scheduling.Options schedulingOptions) {
		this.schedulingOptions = schedulingOptions;
		//start on Monday
		this.schedulingOptions.rangeStart = Datetime.newInstance(this.schedulingOptions.rangeStart.addHours(6).Date().toStartOfWeek().addDays(1), Time.newInstance(6, 0, 0, 0));
		this.calendar = Scheduling.getSchedule(schedulingOptions);
	}

	private Week buildWeek(
		Scheduling.Calendar calendar // private String buildWeek(Scheduling.Calendar calendar)
	) {
		Week newWeek = new Week(calendar.startDate);

		//build week grid structure from MDT
		Custom_Grid__mdt customGrid = [SELECT Id, MasterLabel, DeveloperName, Context__c FROM Custom_Grid__mdt LIMIT 1];
		for (Custom_Grid_Row__mdt gridRow : queryGridRows(customGrid.Id)) {
			TimeRow theRow = new TimeRow(gridRow);
			newWeek.timeRows.add(theRow);
		}
		//add events to grid
		if (calendar.events.size() > 0) {
			for (Integer i = 0; i < calendar.events.size(); i++) {
				if (calendar.events[i].meeting.All_Day_Meeting__c) {
					calendar.events.remove(i);
				}
			}

			Integer eventNumber = 0;

			Scheduling.Meeting thisMeeting = calendar.events[eventNumber];
			Date eventDate = (thisMeeting.meeting.All_Day_Meeting__c) ? thisMeeting.meeting.All_Day_Date__c : thisMeeting.meeting.Start_Date_Time__c.date();

			//loop through days
			for (Integer daynum = 0; daynum < dayNames.size(); daynum++) {
				Date thisDate = newWeek.startDate.addDays(daynum);
				Integer timeRowNum = 0;
				TimeRow thisTimeRow;
				TimeRow previousTimeRow;

				while (eventDate == thisDate) {
					thisTimeRow = newWeek.timeRows[timeRowNum];

					if (thisTimeRow.startTime <= thisMeeting.startDateTime.time()) {
						//this timeRow starts before, hold on to it until we know if this is the right one
						previousTimeRow = thisTimeRow;
						timeRowNum++;
						//last time row?
						if (timeRowNum >= newWeek.timeRows.size()) {
							timeRowNum--;
							thisTimeRow.days[daynum].meetings.add(thisMeeting);
							eventNumber++;
							previousTimeRow = null;
						}
					} else {
						if (previousTimeRow != null) {
							//thisTimeRow is too late, need to back up and add meeting to previous timeRow
							previousTimeRow.days[daynum].meetings.add(thisMeeting);

							timeRowNum--;
						}
						eventNumber++;
					}

					//quit if we ran out of events
					if (eventNumber >= calendar.events.size())
						break;

					thisMeeting = calendar.events[eventNumber];
					eventDate = (thisMeeting.meeting.All_Day_Meeting__c) ? thisMeeting.meeting.All_Day_Date__c : thisMeeting.meeting.Start_Date_Time__c.date();
				}
				previousTimeRow = null;
			}
		}

		return newWeek;
		// return '{}';
	}

	List<Custom_Grid_Row__mdt> queryGridRows(Id customGridId) {
		return [SELECT Id, Row_Label__c, Start_Time__c FROM Custom_Grid_Row__mdt WHERE Custom_Grid__c = :customGridId ORDER BY Start_Time__c ASC];
	}

	@AuraEnabled
	public static Week getWeek(
		String options // public static String getWeek(String options)
	) {
		Scheduling.Options schedulingOptions = (Scheduling.Options) JSON.deserialize(options, Scheduling.Options.class);
		return getWeek(schedulingOptions);
		// return '{}';
	}
	public static Week getWeek(
		Scheduling.Options schedulingOptions // public static String getWeek(Scheduling.Options schedulingOptions)
	) {
		CommunityWeekCtl ctl = new CommunityWeekCtl(schedulingOptions);
		Scheduling.Calendar newCalendar = ctl.calendar;
		// = Scheduling.getSchedule(options);
		//calendar

		return ctl.buildWeek(newCalendar);
	}

	public class Week {
		@AuraEnabled
		public List<String> dayNames = CommunityWeekCtl.dayNames;
		@AuraEnabled
		public List<Date> dates = new List<Date>();
		@AuraEnabled
		public List<TimeRow> timeRows = new List<TimeRow>();
		@AuraEnabled
		public Date startDate;

		public Week(Date startDate) {
			this.startDate = startDate;
			for (Integer i = 0; i < this.dayNames.size(); i++) {
				dates.add(startDate.addDays(i));
			}
		}
	}

	public class TimeRow { //one row within the displayed week, a nominal time period
		@AuraEnabled
		public List<TimeDay> days;
		@AuraEnabled
		public Time startTime;
		@AuraEnabled
		public Custom_Grid_Row__mdt customGridRow;

		public TimeRow(Custom_Grid_Row__mdt customGridRow) {
			days = new List<TimeDay>();
			Integer weekLength = CommunityWeekCtl.dayNames.size();
			for (Integer i = 0; i < weekLength; i++) {
				days.add(new TimeDay(CommunityWeekCtl.dayNames[i]));
			}
			this.customGridRow = customGridRow;
			this.startTime = Time.newInstance(Integer.valueOf(customGridRow.Start_Time__c.left(2)), Integer.valueOf(customGridRow.Start_Time__c.right(2)), 0, 0);
		}
	}

	public class TimeDay { //one day box within a timerow
		@AuraEnabled
		public String dayName;
		@AuraEnabled
		public List<Scheduling.Meeting> meetings = new List<Scheduling.Meeting>();

		public TimeDay(String dayName) {
			this.dayName = dayName;
		}
	}
}