public class DefinedFilters {
	public List<Expression> expressionList;

	public DefinedFilters(Filter_Expression__mdt filter) {
		List<Filter_Expression__mdt> filters = new List<Filter_Expression__mdt>();
		filters.add(filter);
		buildExpressions(filters);
	}

	public DefinedFilters(List<Filter_Expression__mdt> filters) {
		buildExpressions(filters);
	}

	private void buildExpressions(List<Filter_Expression__mdt> filters) {
		expressionList = new List<Expression>();

		for (Filter_Expression__mdt filter : filters) {
			expressionList.add(new Expression(filter));
		}
	}

	public class Expression {
		public String function; //and, or, compare

		public String fieldName;
		public String operator;
		public String value;

		public List<Expression> expressions = new List<Expression>();

		public Expression() {
		}

		public Expression(Filter_Expression__mdt filterMetadata) {
			if (filterMetadata != null && filterMetadata.Expression__c != null) {
				Expression tempExp = (Expression) JSON.deserialize(filterMetadata.Expression__c, DefinedFilters.Expression.class);
				function = tempExp.function;
				fieldName = tempExp.fieldName;
				operator = tempExp.operator;
				value = tempExp.value;
				expressions = tempExp.expressions;
			}
		}

		// return true if obj passes the filters on this expression
		public Boolean includes(sObject obj) {
			Boolean result = false;

			switch on function {
				when 'compare' {
					// String fieldValue = String.valueOf(obj.get(fieldName));
					String fieldValue = String.valueOf(SObjectUtils.getFieldValue(obj, fieldName));
					String stringVal = value;
					switch on operator {
						when '=' {
							result = (fieldValue == stringVal);
						}
						when '==' {
							result = (fieldValue == stringVal);
						}
						when '!=' {
							result = (fieldValue != stringVal);
						}
						when '<' {
							result = (fieldValue < stringVal);
						}
						when '>' {
							result = (fieldValue > stringVal);
						}
						when '<=' {
							result = (fieldValue <= stringVal);
						}
						when '>=' {
							result = (fieldValue >= stringVal);
						}
						when 'contains' {
							result = (fieldValue.contains(stringVal));
						}
						when '!contains' {
							result = (!fieldValue.contains(stringVal));
						}
						when 'startsWith' {
							result = (fieldValue.startsWith(stringVal));
						}
						when 'endsWith' {
							result = (fieldValue.endsWith(stringVal));
						}
					}
				}
				when 'and' {
					result = true;
					for (Expression exp : expressions) {
						if (!exp.includes(obj)) {
							return false;
						}
					}
				}
				when 'or' {
					for (Expression exp : expressions) {
						if (exp.includes(obj)) {
							return true;
						}
					}
				}
			}

			return result;
		}
	}
}