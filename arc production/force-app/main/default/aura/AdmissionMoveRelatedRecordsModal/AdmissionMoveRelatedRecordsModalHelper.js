({
	displayModal : function(component) {
        console.log('called displayModal');
        component.set("v.showModal", true);
        /*
		var recordId = component.get("v.recordId");
		$A.createComponent(
            "c:AdmissionMoveRelatedRecords",{
                recordId: recordId
            },
            function(newcomponent){
                if (component.isValid()) {
                    var body = component.get("v.body");
                    body.push(newcomponent);
                    component.set("v.body", body);             
                }
            }            
        );
        */
	}
})