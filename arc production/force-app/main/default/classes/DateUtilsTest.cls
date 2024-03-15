@isTest
private class DateUtilsTest
{
	@isTest
	static void getAllDatesInRangeTest()
	{
		Date today = System.today();
		Date threeDaysFromToday = today.addDays(3);

		List<Date> daysInRange = DateUtils.getAllDaysInRange(today, threeDaysFromToday);
		System.assertEquals(3, daysInRange.size());
	}

	@isTest
	static void getDayOfWeekTest()
	{
		/*
		Date mondayDate = Date.newInstance(2018, 1, 1);
		String monday = DateUtils.getDayOfWeek(mondayDate);
		System.assertEquals('Monday', monday);
		*/
		Date today = Date.newInstance(2019, 7, 10);
		String wednesday = DateUtils.getDayOfWeek(today);
		System.assertEquals('Wednesday', wednesday);
	}
	
	@isTest
	static void getDateToDayOfWeekTest()
	{
		List<Date> daysInRange = new List<Date>();
		Date mondayDate = Date.newInstance(2018, 1, 1);
		Date wednesdayDate = Date.newInstance(2018, 1, 3);
		daysInRange.add(mondayDate);
		daysInRange.add(wednesdayDate);

		Map<Date, String> dateToDayOfWeek = DateUtils.getDateToDayOfWeek(daysInRange);

		System.assertEquals('Monday', dateToDayOfWeek.get(mondayDate));
		System.assertEquals('Wednesday', dateToDayOfWeek.get(wednesdayDate));
	}
	
}