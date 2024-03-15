public with sharing class PicklistValues 
{
	/*
			Provide dependent picklist values for use in UI components

			180813		JN 		Created with code from StackExchange
	*/	


    private static final String BASE_64_CHARS = ''
            + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            + 'abcdefghijklmnopqrstuvwxyz'
            + '0123456789+/';


    private static Map<String, Set<Integer>> cache;

    //overload for default return
    public static List<Choice> controllingToDependentValues(SObjectField controlling, SObjectField dependent) 
    {
        return controllingToDependentValues(controlling, dependent, false);
    }
    public static List<Choice> controllingToDependentValues(SObjectField controlling, SObjectField dependent, Boolean returnLabelsAsValues) 
    {

        //Map<String, List<String>> results = new Map<String, List<String>>();
        List<Choice> results = new List<Choice>();
        Map<String, Choice> code2ChoiceMap = new Map<String, Choice>();

        if (controlling != null && dependent != null) {
	        cache = new Map<String, Set<Integer>>();

            List<String> controllingValues = new List<String>();

            for (PicklistEntry pe : controlling.getDescribe().getPicklistValues()) {
                if (pe.isActive()) {
                    //results.put(pe.getValue(), new String[] {});
                    Choice controllingChoice = new Choice(pe, returnLabelsAsValues);
                    String key = returnLabelsAsValues ? pe.getLabel() : pe.getValue();
                    results.add(controllingChoice);
                    controllingValues.add(key);
                    code2ChoiceMap.put(key, controllingChoice);
                }
            }

            for (PicklistEntryBean pe : picklistEntryBeans(dependent.getDescribe().getPicklistValues())) {
                if (pe.active) {
                    for (Integer index : validForToIndices(pe.validFor)) {
                        //results.get(controllingValues.get(index)).add(pe.value);
                        Choice controllingChoice = code2ChoiceMap.get(controllingValues[index]);
                        controllingChoice.dependentFieldChoices.add(new Choice(pe, returnLabelsAsValues));
                    }
                }
            }

        }

        return results;
    }

    private static Set<Integer> validForToIndices(String validFor) {

        Set<Integer> indices = cache.get(validFor);
        if (indices == null) {
            indices = new Set<Integer>();

            String validForBits = base64ToBits(validFor);
            for (Integer i = validForBits.indexOf('1'); i >= 0; i = validForBits.indexOf('1', i + 1)) {
                indices.add(i);
            }

            cache.put(validFor, indices);
        }

        return indices;
    }

    private static String decimalToBinary(Integer val) {

        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    private static String base64ToBits(String validFor) {

        if (String.isEmpty(validFor)) return '';

        String validForBits = '';
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = BASE_64_CHARS.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        return validForBits;
    }

    private static PicklistEntryBean[] picklistEntryBeans(List<PicklistEntry> pes) {

        return (List<PicklistEntryBean>) JSON.deserialize(JSON.serialize(pes), List<PicklistEntryBean>.class);
    }
    
    private class PicklistEntryBean {
        public Boolean active {get; set;}
        public String value {get; set;}
        public String label;
    	public Boolean isDefaultValue;
        public String validFor {get; set;}
    }

    public class Choice 
    {
        public String label;
    	public String value;
        public Boolean defaultValue;

        public List<Choice> dependentFieldChoices = new List<Choice>();

    	public Choice(PicklistEntry pe, Boolean returnLabelsAsValues)
    	{
    		this.label = pe.getLabel();
    		//this.value = pe.getValue();
    		//changed to save the label in the field rather than the value
    		this.value = returnLabelsAsValues ? pe.getLabel() : pe.getValue();
    		this.defaultValue = pe.isDefaultValue();
        	
   		}
    	public Choice(PicklistEntryBean pe, Boolean returnLabelsAsValues)
    	{
    		this.label = pe.label;
    		this.value = returnLabelsAsValues ? pe.label : pe.value;
    		this.defaultValue = pe.isDefaultValue;
        	
   		}
    }
}