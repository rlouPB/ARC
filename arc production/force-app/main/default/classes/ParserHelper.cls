global class ParserHelper {
	static String[] currencyArgs = new List<String>{ '0', 'number', '###,###,###,##0.00' };
	static String[] numberArgs = new List<String>{ '0', 'number', '###,###,###,##0' };

	global static string ToDateTimeFormat(Sobject source, string path) {
		object res = parseSobject(source, path);
		return res != null ? ((DateTime) res).format() : '';
	}

	global static string ToDateTimeFormat(Sobject source, string path, string format) {
		object res = parseSobject(source, path);
		return res != null ? ((DateTime) res).format(format) : '';
	}

	global static string ToDateTimeFormat(Sobject source, string path, string format, string timezone) {
		object res = parseSobject(source, path);
		return res != null ? ((DateTime) res).format(format, timezone) : '';
	}

	global static string ToDateFormat(Sobject source, string path) {
		object res = parseSobject(source, path);
		return res != null ? ((Date) res).format() : '';
	}

	global static string ToCurrency(Sobject source, string path, integer positions) {
		Decimal res = ToDecimal(source, path, positions);
		return String.format(res.format(), currencyArgs);
	}

	global static string toNumber(Sobject source, string path, integer positions) {
		Decimal res = ToDecimal(source, path, positions);
		return String.format(res.format(), numberArgs);
	}

	global static Decimal ToDecimal(Sobject source, string path, integer positions) {
		object res = parseSobject(source, path);
		positions = positions != null ? positions : 2;
		decimal des = res != null ? (Decimal) res : 0.00;
		return des.setscale(positions);
	}

	global static integer ToInteger(Sobject source, string path) {
		object res = parseSobject(source, path);
		return res != null ? integer.valueof(res) : 0;
	}

	global static string ToString(Sobject source, string path) {
		object res = parseSobject(source, path);
		return res != null ? string.valueof(res) : '';
	}

	global static object parseSobject(Sobject source, string path) {
		if (source != null && path != null) {
			string[] parts = path.split('\\.');
			map<string, object> currentMap;
			sobject currentSource = source;
			for (integer i = 0; i < parts.size(); i++) {
				if (currentSource == null) {
					return null;
				}
				string p = parts[i];
				currentMap = currentSource.getPopulatedFieldsAsMap();
				if (i == (parts.size() - 1)) {
					return currentMap.containsKey(p) ? currentMap.get(p) : null;
				} else if (p.contains('[')) {
					string[] p2 = p.split('[\\[\\]]');
					if (p2.size() < 2) {
						return null;
					} else {
						integer idx = integer.valueof(p2[1]);
						list<sobject> arrSource = currentMap.containsKey(p2[0]) ? (sobject[]) currentMap.get(p2[0]) : null;
						if (arrSource != null && idx != null && idx >= 0 && arrSource.size() > 0 && idx < arrSource.size()) {
							currentSource = arrSource[idx];
						} else {
							return null;
						}
					}
				} else {
					currentSource = (Sobject) currentMap.get(p);
				}
			}
		}
		return null;
	}
}