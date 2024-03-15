({
    init: function (cmp, event, helper) {        
        helper.fetchData(cmp, event, helper);
        helper.initColumnsWithActions(cmp, event, helper);
        helper.getCreateAccess(cmp, event, helper);
        helper.getAllFieldColumns(cmp, event, helper);
        helper.getJsonCustomColums(cmp, event, helper);
        
    },
    
    handleColumnsChange: function (cmp, event, helper) {
        helper.initColumnsWithActions(cmp, event, helper)
    },
    
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var onRowActionHandler = cmp.get('v.onRowActionHandler');

        if(onRowActionHandler){
            $A.enqueueAction(onRowActionHandler)                       
        }else{            
            switch (action.name) {
                case 'edit':
                    helper.editRecord(cmp, row)
                    break;
                case 'delete':
                    helper.removeRecord(cmp, row)
                    break;
            }
        }
    },
    
    handleGotoRelatedList : function (cmp, event, helper) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": cmp.get("v.parentRelationshipApiName"),
            "parentRecordId": cmp.get("v.recordId")
        });
        relatedListEvent.fire();
    },
       
	handleCreateRecord : function (cmp, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": cmp.get("v.sobjectApiName"),
            "defaultFieldValues": {
                [cmp.get("v.relatedFieldApiName")] : cmp.get("v.recordId")
            },
            "navigationLocation": "RELATED_LIST"
        });
        //cmp.find("overlayLib").notifyClose()
        createRecordEvent.fire();
	},   
        
	handleToastEvent  : function (cmp, event, helper) {
        var eventType = event.getParam('type');
        var eventMessage= event.getParam('message');
        if(eventType == 'SUCCESS' && eventMessage.includes(cmp.get('v.sobjectLabel'))){
            helper.fetchData(cmp, event, helper);
            helper.initColumnsWithActions(cmp, event, helper);
            helper.getCreateAccess(cmp, event, helper);
        	event.stopPropagation();            
        }        
	},

    showHideColumns : function (cmp, event, helper) {
        let isVisible = !cmp.get('v.showColumnsSelection');
        console.log('@@@@@ isVisible ---> ', isVisible);

        cmp.set('v.showColumnsSelection', isVisible);

    },

    handleColumnSelectionChange: function (cmp, event, helper) {
        var changeValue = event.getParam("value");
        console.log("***** value ---> ", JSON.parse(JSON.stringify(changeValue)));

        let selectedColums = [];
        let columnlinkName = cmp.get("v.columnLinkApiName");
        let fieldColumns = cmp.get('v.fieldColumns');
        
        let columnLink;

        for (let i = 0; i < changeValue.length; i++) {
            const value = changeValue[i];

            let column;

            for (let j = 0; j < fieldColumns.length; j++) {
                const field = fieldColumns[j];

                // if (field.ApiName == value || columnlink == value) {
                if (field.ApiName == value) {

                    if (field.ApiName == 'Date_Time__c') {
                        console.log(' ##### HERE #####');
                    }

                    //This is to specify the Column link in the table
                    if (columnlinkName == field.ApiName) {
                        columnLink = { 
                            "label": field.Label, 
                            "fieldName": "LinkName", 
                            "type": "url", 
                            "cellAttributes": { "alignment": "left" }, 
                            "typeAttributes": {"label": { "fieldName": field.ApiName }, "target": "_blank"}, 
                            "hideDefaultActions": true }
                    } else {
                        column = {
                            label: field.Label,
                            fieldName: field.ApiName,
                            //type: field.IsDecimal ? "currency" : field.Type
                            type: field.Type
                        }
                    }

                    break;
                }
            }

            if (column) {
                selectedColums.push(column);
            }
                     
        }

        // //Verify if the link column is within the selected columns
        // let columnlink = cmp.get("v.columnLinkApiName");

        // if (!selectedColums.includes(columnlink)) {
        //     selectedColums
        // }

        selectedColums.splice(0,0, columnLink);

        cmp.set('v.selectedColumns', selectedColums);

        //Push the columnlinkName in case was unselected.
        changeValue.push(columnlinkName);
        cmp.set('v.value', changeValue);


    },

    setCustomColumns : function (cmp, event, helper) {
        helper.sendCustomColumns(cmp, event, helper);
    },



    // forceRefreshViewHandler : function(cmp, event, helper){
    //     helper.fetchData(cmp, event, helper);
    //     helper.initColumnsWithActions(cmp, event, helper);
    //     helper.getCreateAccess(cmp, event, helper);
    // },
    
})