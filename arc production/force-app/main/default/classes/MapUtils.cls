public class MapUtils
{
    public static Map<String, List<SObject>> addItemToStringToObjectsMap(Map<String, List<SObject>> objectToObjectsMap, String key, SObject objectToAdd)
    {
        if(objectToObjectsMap.containsKey(key))
        {
            objectToObjectsMap.get(key).add(objectToAdd);
        }
        else
        {
            objectToObjectsMap.put(key, new List<SObject>{objectToAdd});
        }
        return objectToObjectsMap;
    }

    public static Map<Id, List<SObject>> addItemToStringToObjectsMap(Map<Id, List<SObject>> objectToObjectsMap, Id key, SObject objectToAdd)
    {
        if(objectToObjectsMap.containsKey(key))
        {
            objectToObjectsMap.get(key).add(objectToAdd);
        }
        else
        {
            objectToObjectsMap.put(key, new List<SObject>{objectToAdd});
        }
        return objectToObjectsMap;
    }
}