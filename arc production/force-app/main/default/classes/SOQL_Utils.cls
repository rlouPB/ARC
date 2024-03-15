public class SOQL_Utils
{
    public static String generateWhereQuery(List<SOQL_Objects.SOQL_Criterion> criteriaList)
    {
        List<String> and_conditions = new List<String>();
        for(SOQL_Objects.SOQL_Criterion criterion : criteriaList)
        {
            if (criterion.isValueGiven()) 
            {
                and_conditions.add(criterion.getSOQLCriteria());
            }
        }
        return String.join(and_conditions, ' AND ');
    }
    
    public static List<SOQL_Objects.SOQL_Criterion> getAccessibleCriteriaList(String objectName,
    	List<SOQL_Objects.SOQL_Criterion> criteriaList)
    {
        List<SOQL_Objects.SOQL_Criterion> accessibleCriteriaList = new List<SOQL_Objects.SOQL_Criterion>();
        
        if(SObjectUtils.isSObjectAccessible(objectName))
        {
            if(!criteriaList.isEmpty())
            {
                Set<String> fieldNameSet = new Set<String>();
                
                for(SOQL_Objects.SOQL_Criterion criterion : criteriaList)
                {
                    fieldNameSet.add(criterion.fieldName);
                }
                
                Set<String> validFieldNameSet = SObjectUtils.getAccessibleFieldNameSet(objectName, fieldNameSet);
                
                if(!validFieldNameSet.isEmpty())
                {
                    for(SOQL_Objects.SOQL_Criterion criterion : criteriaList)
                    {
                        if(validFieldNameSet.contains(criterion.fieldName))
                        {
                            accessibleCriteriaList.add(criterion);
                        }
                    }
                }
            }
        }
        
        return accessibleCriteriaList;
    }
}