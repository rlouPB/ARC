({
    sizeColumns: function(component, event, helper)
    {
        var columnClasses = component.get('v.columnClasses');
        var clientWidth = document.body.clientWidth;
		console.log('sizeColumns for ' + clientWidth);
		if (clientWidth >= 1700)
        {
            columnClasses = {
                'item': 'slds-size_3-of-12 slds-p-left_medium', 
                'rating': 'slds-size_3-of-12 slds-p-left_medium', 
                'comments': 'slds-size_6-of-12 slds-p-left_medium',
            };
        } else if (clientWidth >= 1000)
        {
            columnClasses = {
                'item': 'slds-size_12-of-12 slds-p-left_small', 
                'rating': 'slds-size_6-of-12 slds-p-left_small', 
                'comments': 'slds-size_6-of-12 slds-p-left_small',
            };
        } else
        {
            columnClasses = {
                'item': 'slds-size_12-of-12 slds-p-left_small', 
                'rating': 'slds-size_12-of-12 slds-p-left_small', 
                'comments': 'slds-size_12-of-12 slds-p-left_small',
            };
        }
        component.set('v.columnClasses', columnClasses);
    }
})