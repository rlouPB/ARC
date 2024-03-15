({
    doInit : function(component, event, helper) 
    {
        helper.interpretParameters(component, event, helper);
        helper.populateFilters(component, event, helper);
        helper.populateSelectedRecord(component, event, helper);
    }, 
    handleChangeSelected : function(component, event, helper)
    {
        var recordLoaded = component.get('v.recordLoaded');
        console.log('changeSelected recordLoaded ' + recordLoaded);
        
        if (!component.get('v.recordLoaded')) return;
        helper.changeSelected(component, event, helper);
    }
})