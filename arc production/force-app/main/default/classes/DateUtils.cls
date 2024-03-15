public class DateUtils
{
	// endDate is EXCLUSIVE
	public static List<Date> getAllDaysInRange(Date startDate, Date endDate)
	{
		List<Date> days = new List<Date>();
		Date currentDate = startDate;

		while(currentDate < endDate)
		{
			days.add(currentDate);
			currentDate = currentDate.addDays(1);
		}
		
		return days;
	}

	public static Map<Date, String> getDateToDayOfWeek(List<Date> dates)
	{
		Map<Date, String> dateToDayOfWeek = new Map<Date, String>();
		for(Date currentDate : dates)
		{
			dateToDayOfWeek.put(currentDate, getDayOfWeek(currentDate));
		}
		return dateToDayOfWeek;
	}

	public static String getDayOfWeek(Date currentDate)
	{
		Datetime dayOfWeek = Datetime.newInstanceGmt(currentDate, Time.newInstance(0, 0, 0, 0));
		return dayOfWeek.formatGmt('EEEE');
	}

	public static Long timeDifferenceInMilliseconds(Datetime startDateTime, Datetime endDateTime)
	{
		return endDateTime.getTime() - startDateTime.getTime();
	}

	public static Long timeDifferenceInMinutes(Datetime startDateTime, Datetime endDateTime)
	{
		return timeDifferenceInMilliseconds(startDateTime, endDateTime) / 60000;
	}

	public static Long timeDifferenceInMinutes(Time startTime, Time endTime)
	{
		return (endTime.hour() * 60 + endTime.minute()) - (startTime.hour() * 60 + startTime.minute());
	}
}