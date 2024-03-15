public without sharing class ParserUtils {
	public static object getValue(sobject record, string path) {
		try {
			string[] parts = path.split('\\.');
			if (parts.size() == 1) {
				return record.get(parts[0]);
			} else {
				sobject ref = record;
				for (integer i = 0; i < parts.size(); i++) {
					string part = parts[i];
					if (i != (parts.size() - 1)) {
						ref = (sobject) ref.get(part);
					}
				}
				return ref.get(parts[parts.size() - 1]);
			}
		} catch (Exception ex) {
			system.debug('ERRORS ON ParserUtils.getValue: ' + ex.getMessage() + '-' + ex.getStackTraceString());
		}
		return null;
	}
}