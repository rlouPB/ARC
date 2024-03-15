public class SOQL_Objects {
	public class SOQL_Criterion {
		public String fieldName;
		public String operator;
		public String value;

		public SOQL_Criterion(String fieldName, String operator, String value) {
			this.fieldName = fieldName;
			this.operator = operator;
			this.value = value;
		}

		public Boolean isValueGiven() {
			return value != null && value != '';
		}

		public String getSOQLCriteria() {
			String soqlCriteria = fieldName + ' ' + operator + ' \'' + String.escapeSingleQuotes(value) + '\'';
			return soqlCriteria;
		}
	}
}