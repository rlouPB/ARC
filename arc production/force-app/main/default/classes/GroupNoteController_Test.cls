@isTest
public class GroupNoteController_Test {
	@testSetup
	static void setupData() {
		Id patientConRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Patient').getRecordTypeId();
		Id patientAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId();

		Contact con = new Contact(Lastname = '0Sarine', recordtypeid = patientConRecTypeId);
		Contact con1 = new Contact(Lastname = '1Sarine11', recordtypeid = patientConRecTypeId);
		Contact con2 = new Contact(Lastname = '2Sarine2', recordtypeid = patientConRecTypeId);
		insert new List<Contact>{ con, con1, con2 };

		Group__c groupMem = new Group__c(Active__c = true, Name = 'test group', Attendance_Tracking__c = 'Track Attendance');
		insert groupMem;

		Patient_Group_Member__c pgm = new Patient_Group_Member__c(Patient__c = con.Id, Role__c = 'Student', Start_Date__c = system.today().addDays(-10), Group_Name__c = groupMem.Id);
		insert pgm;

		Account acc = new Account(Name = 'ARC account', Patient_Contact__c = con.Id, RecordtypeId = patientAccRecTypeId);
		Account acc1 = new Account(Name = 'ARC account1', Patient_Contact__c = con1.Id, RecordtypeId = patientAccRecTypeId);
		Account acc2 = new Account(Name = 'ARC account2', Patient_Contact__c = con2.Id, RecordtypeId = patientAccRecTypeId);
		insert new List<Account>{ acc, acc1, acc2 };

		Scheduling_Resource__c room = new Scheduling_Resource__c(Building__c = 'Union office Tower', Description__c = 'amazing place', Room__c = 'My Room', Seating_Capacity__c = 200);
		insert room;

		Meeting__c meeting = new Meeting__c(Start_Date_Time__c = system.now(), End_Date_Time__c = system.now().addDays(10), Subject__c = 'Patient Wellness', Patient_Group_Meeting_Type__c = 'Other', Group_Membership__c = groupMem.Id, Room_Resource__c = room.Id);
		insert meeting;

		Participant__c participant = new Participant__c(Contact__c = con.Id, Meeting__c = meeting.Id);
		Participant__c participant1 = new Participant__c(Contact__c = con1.Id, Meeting__c = meeting.Id);
		Participant__c grpParticipant = new Participant__c(Group__c = groupMem.Id, Meeting__c = meeting.Id);
		insert new List<Participant__c>{ participant, participant1, grpParticipant };

		// Group_Note__c gNote = new Group_Note__c(
		//     Meeting__c = meeting.Id,
		//     Name = meeting.Subject__c

		// );
		// insert gNote;

		// Group_Attendance__c gAtt = new Group_Attendance__c(Patient__c = acc.Id, Attended__c = true, Role__c = 'Student', Group_Note__c = gNote.Id);
		// insert gATt;
	}

	static testMethod void testGetUser() {
		Test.startTest();
		User testUser = GroupNoteController.getUser();
		Test.stopTest();
		System.assertEquals(Userinfo.getUserId(), testUser.Id);
	}

	static testMethod void testGetAttendanceTracking() {
		Group__c groupMem = [SELECT Id, Attendance_Tracking__c FROM Group__c LIMIT 1];

		Test.startTest();
		String trackingId = GroupNoteController.getAttendanceTracking(groupMem.Id);
		Test.stopTest();
		System.assertEquals(groupMem.Attendance_Tracking__c, trackingId);
	}

	static testMethod void testExistingGroupNoteFromMeeting() {
		Meeting__c meeting = [SELECT Id, Subject__c FROM Meeting__c LIMIT 1];
		Group_Note__c gNote = new Group_Note__c(Meeting__c = meeting.Id, Name = meeting.Subject__c, Did_Group_Meet__c = null);
		insert gNote;

		List<Account> accs = [SELECT Id, Patient_Contact__c FROM Account ORDER BY Name];
		Group_Attendance__c gAtt = new Group_Attendance__c(Patient__c = accs[1].Id, Attended__c = true, Role__c = 'Student', Group_Note__c = gNote.Id);
		insert gATt;

		Group_Note__c groupNote = [SELECT Id, Did_Group_Meet__c FROM Group_Note__c WHERE Meeting__c = :meeting.Id LIMIT 1];
		System.assertNotEquals('Yes', groupnote.Did_Group_Meet__c);
		test.startTest();

		GroupNoteController.GroupNoteWrapper testGroupNoteWrapper = GroupNoteController.getMeetingGroupNote(meeting.Id);

		GroupNoteController.GroupNoteWrapper testGroupNoteNoteWrapper = GroupNoteController.getGroupNote(testGroupNoteWrapper.theNote.Id);

		// Group_Note__c gn = new Group_Note__c(
		//     Did_Group_Meet__c = 'No',
		//     Reason_Group_Did_Not_Meet__c = 'No staff available',
		//     Status__c = 'Finalized',
		//     Finalized_By__c = UserInfo.getUserId(),
		//     Id = groupNoteId
		// );
		System.assertEquals(gNote.Id, testGroupNoteWrapper.theNote.Id);
		System.assertEquals(2, testGroupNoteWrapper.lstGroupAttendance.size());

		List<GroupNoteController.GroupAttendanceWrapper> gaList = testGroupNoteWrapper.lstGroupAttendance;

		// GroupNoteController.GroupAttendanceWrapper newGroupAttendanceWrapper = new GroupNoteController.GroupAttendanceWrapper();

		// gaList.add(newGroupAttendanceWrapper);
		testGroupNoteWrapper.theNote.Did_Group_Meet__c = 'Yes';
		String groupNoteWrapperString = JSON.serialize(testGroupNoteWrapper);
		String gaWrapperListString = JSON.serialize(gaList);

		Group_Note__c savedGroupNote = GroupNoteController.updateGroupNote(groupNoteWrapperString, JSON.serialize(new List<Group_Attendance__c>{ gAtt }));
		System.assertEquals('Yes', savedGroupNote.Did_Group_Meet__c);

		String savedGroupNoteString = JSON.serialize(savedGroupNote);
		Group_Note__c finalizedGroupNote = GroupNoteController.finalizeGroupNoteApex(savedGroupNoteString, '[]');
		system.assertEquals(Userinfo.getUserId(), finalizedGroupNote.Finalized_By__c);
		system.assertNotEquals(null, finalizedGroupNote.Finalized_Datetime__c);
		// GroupNoteController.getGroupAttendanceInstance(accId, gn.Id);

		test.stopTest();

		List<Group_Note__c> finalGroupNotes = [SELECT Id, Status__c, Finalized_By__c, Finalized_Datetime__c FROM Group_Note__c];
		// WHERE Meeting__c =: meeting.Id];
		System.assertEquals(1, finalGroupNotes.size());
		Id currentUserId = UserInfo.getUserId();

		system.assertNotEquals(null, finalGroupNotes[0].Finalized_Datetime__c);
		system.assertEquals('Finalized', finalGroupNotes[0].Status__c);
		system.assertEquals(currentUserId, finalGroupNotes[0].Finalized_By__c);
	}

	//  static testmethod void testGroupNoteFromGroupNote()
	// {
	//     // Id meetingId = [SELECT Id FROM Meeting__c LIMIT 1].Id;
	//     Group_Note__c testGroupNote = [SELECT Id, Meeting__c FROM Group_Note__c WHERE Meeting__c != null LIMIT 1];
	//     Id meetingId = testGroupNote.Meeting__c;
	//     Id groupNoteId = testGroupNote.Id;
	//     test.startTest();

	//     GroupNoteController.getGroupNote(groupNoteId);
	//     Group_Note__c gn = new Group_Note__c(
	//         Did_Group_Meet__c = 'No',
	//         Reason_Group_Did_Not_Meet__c = 'No staff available',
	//         Status__c = 'Finalized',
	//         Finalized_By__c = UserInfo.getUserId(),
	//         Id = groupNoteId
	//     );

	//     List<Group_Attendance__c> gaList = [SELECT Id FROM Group_Attendance__c WHERE Group_Note__c =: groupNoteId];
	//     Id accId = [SELECT Id FROM Account LIMIT 1].Id;
	//     GroupNoteController.updateGroupNote(JSON.serialize(gn), JSON.serialize(gaList));
	//     // GroupNoteController.finalizedGroupNote(gn);
	//     // GroupNoteController.getGroupAttendanceInstance(accId, gn.Id);

	//     test.stopTest();

	//     List<Group_Note__c> groupNote = [SELECT Id, Status__c, Finalized_By__c, Finalized_Datetime__c FROM Group_Note__c WHERE Meeting__c =: meetingId];
	//     Id currentUserId = UserInfo.getUserId();
	//     system.assertNotEquals(null, groupNote[0].Finalized_Datetime__c);
	//     system.assertEquals('Finalized', groupNote[0].Status__c);
	//     system.assertEquals(currentUserId,  groupNote[0].Finalized_By__c);

	// }
	// // returns null when meetingId is blank
	// static testmethod void testBlankMeetingId()
	// {
	//     test.startTest();
	//     Group_Note__c gn = GroupNoteController.getMeetingGroupNote('');
	//     test.stopTest();
	//     system.assertEquals(null, gn);
	// }
	// // returns null when meeting does not have a groupNote
	// static testmethod void testNoGroupNote()
	// {
	//     test.startTest();
	//     Id meetingId = [SELECT Id FROM Meeting__c LIMIT 1].Id;
	//     List<Group_Note__c> grpNote = [SELECT Id FROM Group_Note__c WHERE Meeting__c =: meetingId];

	//     delete grpNote[0];

	//     Group_Note__c gn =  GroupNoteController.getMeetingGroupNote(meetingId);

	//     test.stopTest();
	//     system.assertEquals(null, gn);
	// }
}