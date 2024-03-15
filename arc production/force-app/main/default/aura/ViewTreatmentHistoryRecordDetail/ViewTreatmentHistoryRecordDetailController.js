({
    handleSelectedTreatmentHistoryRecord : function(component, event, helper) {
        let displayRecordId = component.get("v.displayRecordId");
        console.log("body:"+component.get("v.body"));
        if(!$A.util.isEmpty(displayRecordId)){
            console.log("displayRecordId is not empty");
            let body = component.get("v.body");
            body.pop();
            component.set("v.body", body);
            //selectedRecordFormCmp.destroy();
        }
        let selectedRecordId = event.getParam("selectedRecordId");
        let selectedRecordObjectName = event.getParam("selectedRecordObjectName");
        let componentName = event.getParam("componentName");
        let metadataParameters = event.getParam("componentParameters");
        let queryFields = event.getParam('queryFields');
        console.log('selected record id:'+selectedRecordId);
        if(!$A.util.isEmpty(selectedRecordId))
        {
            component.set("v.displayRecordId", selectedRecordId);

            let componentParameters = {
                "aura:id" : "selectedRecord",
                "recordId" : selectedRecordId
            };
            
            if (!componentName)
            {
                componentName = 'c:ViewTreatmentHistorySimpleDetail';
                var fields = [];
                if (queryFields)
                {
                    queryFields.split(',').forEach( function(rawField)
                    {
                        fields.push(rawField.trim());
                    });
                }
                componentParameters.fields = fields;
                componentParameters.objectApiName = selectedRecordObjectName;
            }
            //component.set("v.displayRecord", true);
            console.log("handleSelectedTreatmentHistoryRecord selected record ID:"+selectedRecordId+", name:"+selectedRecordObjectName);
            
            
            //let params = JSON.parse(metadataParameters);
            if (metadataParameters)
            {
                Object.keys(metadataParameters).forEach(function(key){
                    componentParameters[key] = metadataParameters[key];
                });
            }

            $A.createComponent(
                componentName,
                componentParameters,
                function(recordContent, status, errorMessage){
                    if(status === "SUCCESS"){
                        let body = component.get("v.body");
                        body = [];
                        body.push(recordContent);
                        component.set("v.body", body);
                    }else if(status === "INCOMPLETE"){
                        console.log("No response from server or client is offline.");
                    }else if(status === "ERROR"){
                        console.log("Error:"+errorMessage);
                    }
                }
            );

           
            /*
            let componentParameters = {
                "aura:id" : "selectedRecord",
                "recordId" : selectedRecordId
            };
            let params = JSON.parse(metadataParameters);
            Object.keys(params).forEach(function(key){
                componentParameters[key] = params[key];
            });

            $A.createComponent(
                componentName,
                componentParameters,
                function(recordContent, status, errorMessage){
                    if(status === "SUCCESS"){
                        let body = component.get("v.body");
                        body = [];
                        body.push(recordContent);
                        component.set("v.body", body);
                    }else if(status === "INCOMPLETE"){
                        console.log("No response from server or client is offline.");
                    }else if(status === "ERROR"){
                        console.log("Error:"+errorMessage);
                    }
                }
            )
            */
            /*$A.createComponent(
                "force:recordView",
                {
                    "aura:id" : "selectedRecord",
                    "recordId" : selectedRecordId
                },
                function(recordContent, status, errorMessage){
                    if(status === "SUCCESS"){
                        let body = component.get("v.body");
                        body = [];
                        body.push(recordContent);
                        component.set("v.body", body);
                    }else if(status === "INCOMPLETE"){
                        console.log("No response from server or client is offline.");
                    }else if(status === "ERROR"){
                        console.log("Error:"+errorMessage);
                    }
                }
            )
            if(selectedRecordObjectName == "EGO__c"){
                $A.createComponent(
                    "c:TreatmentPlan_EGO",
                    {
                        "aura:id" : "selectedRecord",
                        "parentRecordId" : selectedRecordId,
                        "isReadOnly" : true
                    },
                    function(recordContent, status, errorMessage){
                        if(status === "SUCCESS"){
                            let body = component.get("v.body");
                            body = [];
                            body.push(recordContent);
                            component.set("v.body", body);
                        }else if(status === "INCOMPLETE"){
                            console.log("No response from server or client is offline.");
                        }else if(status === "ERROR"){
                            console.log("Error:"+errorMessage);
                        }
                    }
                )
            }else{
                $A.createComponent(
                    "lightning:recordForm",
                    {
                        "aura:id" : "selectedRecord",
                        "recordId" : selectedRecordId,
                        "objectApiName" : selectedRecordObjectName,
                        "layoutType" : "Full",
                        "mode" : "readonly"
                    },
                    function(recordContent, status, errorMessage){
                        if(status === "SUCCESS"){
                            let body = component.get("v.body");
                            body = [];
                            body.push(recordContent);
                            component.set("v.body", body);
                        }else if(status === "INCOMPLETE"){
                            console.log("No response from server or client is offline.");
                        }else if(status === "ERROR"){
                            console.log("Error:"+errorMessage);
                        }
                    }
                )
            }*/
        }
    }
})