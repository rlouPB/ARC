({
    fetchData: function (cmp, event, helper) {
 		var action = cmp.get("c.initData")
 		var relatedFieldApiName = cmp.get("v.relatedFieldApiName")
        var numberOfRecords = cmp.get("v.numberOfRecords");

        var fields = cmp.get("{!v.canCustomizeColumns}") ? "all" : cmp.get("v.fields");

        // var jsonData = JSON.stringify({fields:cmp.get("v.fields"),
        var jsonData = JSON.stringify({fields:fields,
                                       relatedFieldApiName:cmp.get("v.relatedFieldApiName"),
                                       recordId:cmp.get("v.recordId"),
                                       numberOfRecords:numberOfRecords + 1,
                                       sobjectApiName: cmp.get("v.sobjectApiName"),
                                       sortedBy: cmp.get("v.sortedBy"),
                                       sortedDirection: cmp.get("v.sortedDirection")
        });
        action.setParams({jsonData : jsonData});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var jsonData = JSON.parse(response.getReturnValue())
                var records = jsonData.records
                if(records.length > numberOfRecords){
                    records.pop()
                    cmp.set('v.numberOfRecordsForTitle', numberOfRecords + "+")
                }else{
                    cmp.set('v.numberOfRecordsForTitle', Math.min(numberOfRecords,records.length))
                }
                records.forEach(record => {
                  record.LinkName = '/'+record.Id
                  for (const col in record) {
                    const curCol = record[col];
                    if (typeof curCol === 'object') {
                      const newVal = curCol.Id ? ('/' + curCol.Id) : null;
                      helper.flattenStructure(helper,record, col + '_', curCol);
                      if (newVal !== null) {
                        record[col+ '_LinkName'] = newVal;
                      }
                    }
                  }
                });                
                cmp.set('v.records', records)
                cmp.set('v.iconName', jsonData.iconName)
                cmp.set('v.sobjectLabel', jsonData.sobjectLabel)
                cmp.set('v.sobjectLabelPlural', jsonData.sobjectLabelPlural)
                cmp.set('v.parentRelationshipApiName', jsonData.parentRelationshipApiName)
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);        
    },
    getCreateAccess: function (cmp, event, helper) {
        var action = cmp.get("c.userCanCreate");

        action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            var hasCreateAccess = response.getReturnValue();            
            cmp.set('v.useHasCreateAccess', hasCreateAccess);
        }else if (state === "ERROR") {
            var errors = response.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log("Error message: " + errors[0].message);
                }
            } else {
                console.log("Unknown error");
            }
        }
        });

        $A.enqueueAction(action); 
    },
    getAllFieldColumns: function (cmp, event, helper) {
        var action = cmp.get("c.getFields");

        action.setParams({sObjectName: cmp.get("v.sobjectApiName")})
        action.setCallback(this, function(response) {
        var state = response.getState();

        if (state === "SUCCESS") {
            let listFieldColumns = response.getReturnValue();

            console.log('##### listFieldColumns ---> ', listFieldColumns);
            cmp.set('v.fieldColumns', listFieldColumns);

            let columnsOptions = [];

            for (let i = 0; i < listFieldColumns.length; i++) {
                const field = listFieldColumns[i];
                columnsOptions.push(
                    {'label': field.Label, 'value': field.ApiName}
                )
            }
            cmp.set('v.options', columnsOptions);

        }else if (state === "ERROR") {
            var errors = response.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log("Error message: " + errors[0].message);
                }
            } else {
                console.log("Unknown error");
            }
        }
        });

        $A.enqueueAction(action); 
    },
    flattenStructure : function (helper,topObject, prefix, toBeFlattened) {
      for (const prop in toBeFlattened) {
        const curVal = toBeFlattened[prop];
        if (typeof curVal === 'object') {
          helper.flattenStructure(helper, topObject, prefix + prop + '_', curVal);
        } else {
          topObject[prefix + prop] = curVal;
        }
      }
    },    
    
   initColumnsWithActions: function (cmp, event, helper) {
        var customActions = cmp.get('v.customActions')
        if( !customActions.length){
            customActions = [
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
	        ]         
        }
        
        var columns = cmp.get('v.columns')        
        var columnsWithActions = []
        columnsWithActions.push(...columns)
        columnsWithActions.push({ type: 'action', typeAttributes: { rowActions: customActions } })
        cmp.set('v.columnsWithActions',  columnsWithActions)
    },    
    
    removeRecord: function (cmp, row) {
        var modalBody;
        var modalFooter;
        var sobjectLabel = cmp.get('v.sobjectLabel')
        $A.createComponents([
            ["c:deleteRecordContent",{sobjectLabel:sobjectLabel}],
            ["c:deleteRecordFooter",{record: row, sobjectLabel:sobjectLabel}]
        ],
        function(components, status){
            if (status === "SUCCESS") {
                modalBody = components[0];
                modalFooter = components[1];
                cmp.find('overlayLib').showCustomModal({
                   header: "Delete " + sobjectLabel,
                   body: modalBody, 
                   footer: modalFooter,
                   showCloseButton: true
               })
            }
        }
       );
        
    },
    
	editRecord : function (cmp, row) {
        var createRecordEvent = $A.get("e.force:editRecord");
        createRecordEvent.setParams({
            "recordId": row.Id
        });
        createRecordEvent.fire();
	},

    getfieldsFromObject : function (cmp, event, helper) {
        var action = cmp.get("c.getFields");
        var sobjectApiName = cmp.get("v.sobjectApiName");

        action.setParams({sObjectName: sobjectApiName});
    },

    getJsonCustomColums: function (cmp, event, helper) {

        let containerRecordId = cmp.get("v.containerRecordId");

        console.log('##### getJsonCustomColums ---> ');
        console.log('##### canCustomizeColumns ---> ', cmp.get("v.canCustomizeColumns"));
        console.log('##### containerRecordId ---> ', containerRecordId);
        console.log('##### containerApiFieldName ---> ', cmp.get("v.containerApiFieldName"));

        if (cmp.get("v.canCustomizeColumns")) {
            var action = cmp.get("c.getPatientCustomColuomns");

            action.setParams({strContainerRecordId: containerRecordId, containerApiFieldName: cmp.get("v.containerApiFieldName")});
            action.setCallback(this, function(response) {
                var state = response.getState();

                console.log('##### state ---> ', state);
                
                if (state === "SUCCESS") {
                    let strJson = response.getReturnValue();
                
                    console.log('##### strJson ---> ', strJson);
                
                    if (strJson && strJson !== '') {
                        let columnsJson = JSON.parse(strJson);
                        console.log('##### columnsJson ---> ', columnsJson);
                        cmp.set('v.columns', columnsJson);
                        let columnlink = cmp.get("v.columnLinkApiName");

                        //Match the columns names with the options values in the multi select checkbox.
                        let optionValues = [];
                        for (let i = 0; i < columnsJson.length; i++) {
                            const column = columnsJson[i];
                            optionValues.push(column.fieldName == "LinkName" ? columnlink : column.fieldName);
                        }

                        cmp.set('v.value', optionValues);

                        console.log('##### Values ---> ', cmp.get('v.value'));
                        
                    }
                    
                
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
    
            $A.enqueueAction(action); 
        }

        
    },
    sendCustomColumns: function (cmp, event, helper) {

        let recordId = cmp.get("v.containerRecordId");

        console.log('##### getJsonCustomColums ---> ');

        console.log('##### selectedColumns ---> ', cmp.get("v.selectedColumns"));

        if (cmp.get("v.canCustomizeColumns")) {
            var action = cmp.get("c.saveCustomColumns");

            action.setParams({strJsonColumns: JSON.stringify(cmp.get("v.selectedColumns")),recordId: recordId, fieldName: cmp.get("v.containerApiFieldName")});
            action.setCallback(this, function(response) {
                var state = response.getState();

                console.log('##### state ---> ', state);
                
                if (state === "SUCCESS") {
                    let result = response.getReturnValue();
                
                    console.log('##### result ---> ', result);

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The record has been created successfully.",
                        "duration" : 2000
                    });
                    toastEvent.fire();
                        
                    cmp.set('v.showColumnsSelection', false);

                    //Refresh the table and data
                    helper.fetchData(cmp, event, helper);
                    helper.initColumnsWithActions(cmp, event, helper);
                    helper.getCreateAccess(cmp, event, helper);
                    helper.getAllFieldColumns(cmp, event, helper);
                    helper.getJsonCustomColums(cmp, event, helper);
                
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "message": errors[0].message,
                                "duration" : 2000
                            });
                            toastEvent.fire();
                            console.log("Error message: " + errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            });
    
            $A.enqueueAction(action); 
        }

        
    },
})