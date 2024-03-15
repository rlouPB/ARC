global without sharing class RecursiveUtils {
	@TestVisible
	global static set<string> running {
		get {
			if (running == null) {
				running = new Set<string>();
			}
			return running;
		}
		private set;
	}
}