({
    closeModal: function(component, event, helper, result) {
        console.log('called closeModal');
        var closeEvent = component.getEvent('closeModalView');
        
        if(result) {
            var data = {
                "label" : result.Name,
                "value" : result.Id
            };

            closeEvent.setParams({
                "data" : data
            });
        }

		closeEvent.fire();
    }
})