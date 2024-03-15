({
	// initialLoad : function(component, event, helper) {
        
    //       //var action = component.get("c.buildAllCharts");
          
    //     var action = component.get("c.getAllCategories");
    //     action.setCallback(this, function(response){
    //         var state = response.getState();
    //         if(state === "SUCCESS"){
    //             component.set("v.medRecHierarchy",response.getReturnValue());
    //             //console.log('object',response.getReturnValue());
    //             var objResult = JSON.parse(response.getReturnValue());
    //             console.log(objResult);
                
                 
    //                 var categories = [];
    //                 for(var j = 0; j < objResult.length; j++ ){
    //                     var cat = {};
    //                     cat.label = objResult[j].obj.Name__c;
    //                     cat.expanded = true;
    //                     var allDocTypes = [];
    //                     var docTypes = objResult[j].docTypes;
    //                     for(var k = 0; k < docTypes.length; k++ ){
    //                         var docType = {};
    //                         docType.label = docTypes[k].obj.Name__c;
    //                         docType.expanded = true;
    //                         allDocTypes.push(docType);
    //                     }
    //                     cat.items = allDocTypes;
    //                     categories.push(cat);
    //                 }
                   
                
    //                 console.log('======================CATEGORIES init load======================', categories);
    //              component.set('v.categories', categories);
    //              component.set('v.categoriesForSearch', categories);
                 
    //         }
    //     });
    //     $A.enqueueAction(action);
		
    // },
    getAdmissionList : function(component, event, helper) {
        var patientId = component.get("v.patientId");
        var action = component.get("c.getAdmissions");
        action.setParams({ 
            patientId : patientId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let result = response.getReturnValue();
                var admissionOptions = JSON.parse(result);
                component.set('v.admissionOptions', admissionOptions);
          }
        });
        $A.enqueueAction(action);
	},
    savePrintedMedicalRecordPDF: function(component, requestId, pdfUrl) {
        var action = component.get("c.savePDFUrl");
        action.setParams({ 
            requestId : requestId,
            pdfUrl : pdfUrl
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let result = response.getReturnValue();
                console.log(result);
          }
        });
        $A.enqueueAction(action);
    },
    walkTheTree : function(row, component){
        var that=this;
        var clonedRow = Object.assign({}, row);
        if(clonedRow._children && clonedRow._children.length != 0) {
            clonedRow._children = [];
        }
        if(row._children != null) {
            for(var i=0; i < row._children.length; i++ ) {
                var childRow = row._children[i];
                // does this row have a properly formatted _children key with content?
                var obj = that.walkTheTree(childRow, component);
                if(obj) {
                    console.log('tree obj->'+ JSON.stringify(obj)); 
                    clonedRow._children.push(obj);
                }
            }
        } else {
            var selectedData = component.get( 'v.originalGridSelectedRows');
            if(selectedData.indexOf(row.name) != -1) {
                return Object.assign({}, row);
            } else {
                return null;
            }
            
        }
        return clonedRow;
    },
    loadTreeNodes : function(component, event, helper) {
        var requestId = component.get("v.requestId");
        var patientId = component.get("v.patientId");
        var admissionId = component.get("v.selectedAdmissionValue");
        console.log('admissionId=' + admissionId);
        
        // var startDateString = component.get("v.startDate") ? new Date(component.get("v.startDate")).toISOString().slice(0, 10) : null;
        // var endDateString = component.get("v.endDate") ? new Date(component.get("v.endDate")).toISOString().slice(0, 10) : null;
        // console.log('startDate Date =' + startDateString);
        // console.log('endDate Date =' + endDateString);
        
        console.log('request Id =' + component.get("v.requestId"));
        console.log('patient Id =' + component.get("v.patientId"));
        //String patientId, String requestId, String fromDateString, String toDateString
        var action = component.get("c.getAllTreeWithLeafNodes");
        action.setParams({ 
            patientId : patientId,
            requestId : requestId,
            admissionId : admissionId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let result = response.getReturnValue();
                var allTreeNodes = result.allTreeNodes.replace(/\bchildren\b/g, '_children');
                var selectedRows = result.selectedRows;
                var objResult = JSON.parse(allTreeNodes);
                var expandedRows=[];
                selectedRows = JSON.parse(selectedRows);

                var newData = objResult.map(function(row) {
                    if(row._children) {
                        row._children = row._children.map(function(subrow) {
                            if(!subrow._children || !subrow._children.length) {
                                delete subrow._children;
                            } else {
                                subrow._children = subrow._children.map(function(leaf) {
                                    delete leaf._children;
                                    for(var i=0; i < selectedRows.length; i++) {
                                        if(selectedRows[i] == leaf.name) {
                                            expandedRows.push(subrow.name);
                                            expandedRows.push(row.name);
                                        }
                                    }
                                    return leaf;
                                });
                            }
                            return subrow;
                        });
                    }
                    return row;
                });
                expandedRows = expandedRows.filter((item, index)=> expandedRows.indexOf(item) === index);
                component.set('v.gridData', newData);
                component.set('v.medicalRecords', JSON.parse(JSON.stringify(newData)));
                component.set('v.originalGridData', newData);
                //component.find("treegrid_async").expandAll();
                component.set("v.gridExpandedRows", expandedRows);
                component.set('v.gridSelectedRows', selectedRows);
                component.set('v.originalGridSelectedRows', selectedRows);
                component.set('v.oldGridSelectedRows', selectedRows);
                component.set('v.selectedRowsStored', selectedRows);
                //component.set('v.expandedRowsCount', expandedRows.length);
                //var admissionId = component.get("v.selectedAdmissionValue");
                if(result.selectedAdmissions != admissionId) {
                    component.set("v.selectedAdmissionValue", result.selectedAdmissions);
                }
                //selectedAdmissions
                //helper.mergeSelection(component);
                //var admissionOptions = JSON.parse(result.admissionOptions);
                //component.set('v.admissionOptions', admissionOptions);
                console.log(newData);
                }
        });
        $A.enqueueAction(action);
    },
    mergeSelection : function(component) {
        var originalSelectedRows = component.get('v.originalGridSelectedRows');
        var oldSelectedRows =  component.get('v.gridSelectedRows');
        var selectedRows = component.find("treegrid_async").getSelectedRows();
        selectedRows = selectedRows.map(item=>item.name);
        //selectedRows = originalSelectedRows.concat(selectedRows.filter((item) => originalSelectedRows.indexOf(item) < 0));
        component.set('v.gridSelectedRows', selectedRows);
        component.set('v.originalGridSelectedRows', selectedRows);
        var expandedRows = component.get("v.gridExpandedRows");
        expandedRows = expandedRows.concat(selectedRows.filter((item) => expandedRows.indexOf(item) < 0));
        component.set("v.gridExpandedRows", expandedRows);
        console.log(selectedRows);
    },
    expandCollapseTree : function(component, event, helper, expended){
        var objResult = component.get('v.categories');
        console.log('objresult',objResult);
        var categories = [];
        for(var j = 0; j < objResult.length; j++ )
        {
           var cat = {};
           cat.label = objResult[j].label;
           cat.expanded = expended;
           var allDocTypes = [];
                      
           var docTypes = objResult[j].items;
           
            for(var k = 0; k < docTypes.length; k++ )
            {
             	var docType = {};
              	docType.label = docTypes[k].label;
              	docType.expanded = expended;
              	allDocTypes.push(docType);
             }
                        
            cat.items = allDocTypes;
            categories.push(cat);
          }

          console.log(categories);
          component.set('v.categories', categories);   
    },
    addChildrenToRow: function(data, rowName, children) {
        var that = this;
        // step through the array using recursion until we find the correct row to update
        var newData = data.map(function(row) {
            // does this row have a properly formatted _children key with content?
            var hasChildrenContent = false;
            if (row.hasOwnProperty('_children') && Array.isArray(row._children) && row._children.length > 0) {
                hasChildrenContent = true;
            }
            const params = row.name.split(';');
            if ((params.length > 1) && (params[0] === rowName)) {
                row._children = children;
            } else if (hasChildrenContent) {
                that.addChildrenToRow(row._children, rowName, children);
            }
            return row;
        });

        return newData;
    },
    retrieveUpdatedData: function(component, rowName, sObjName, patientId) {
        var that = this;
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.retrieveRecordsToPrint");
            action.setParams({ docName : rowName, sObjName : sObjName, patientId : patientId });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    debugger;
                    //console.log('object',response.getReturnValue());
                    let allTreeNodes = response.getReturnValue();
                    allTreeNodes = allTreeNodes.replace(/\bchildren\b/g, '_children');
                    var objResult = JSON.parse(allTreeNodes);
                    var newData = objResult.map(function(row) {
                        delete row._children;
                        return row;
                    });
                    var oldGridData = component.get('v.gridData');
                    var updatedData = that.addChildrenToRow(oldGridData, rowName, newData);
                    resolve(updatedData);
                }
            });
            $A.enqueueAction(action);
        }));
    },
    toggleStepOne : function(component) {
		var stepOne = component.find("stepOne");
        $A.util.toggleClass(stepOne, 'slds-hide');
	},
    toggleStepTwo : function(component){
        var stepTwo = component.find("stepTwo");
        $A.util.toggleClass(stepTwo, 'slds-hide');
    },
    searchRecordsInDateRange : function(component, patientId, fromDate, toDate, searchFinalizedDate, admissionId) {
        var that = this;
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.retrieveRecordsInDateRange");
            action.setParams({   
                patientId : patientId, 
                fromDate : fromDate, 
                toDate : toDate, 
                searchFinalizedDate: searchFinalizedDate,
                admissionId : admissionId
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    //console.log('object',response.getReturnValue());
                    let allTreeNodes = response.getReturnValue();
                    resolve(allTreeNodes);
                }
            });
            $A.enqueueAction(action);
        }));   
    },
    createPrintJob : function(component, patientId, items, requestId) {
        //String patientId, List<String> documentObjs
        return new Promise($A.getCallback(function(resolve){
            var action = component.get("c.savePrintedMedicalRecord");
            action.setParams({ patientId : patientId, documentObjsTxt : JSON.stringify(items), requestId: requestId });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    //console.log('object',response.getReturnValue());
                    let result = response.getReturnValue();
                    resolve(result);
                }
            });
            $A.enqueueAction(action);
        }));   
    },
    closeMenu: function (component) {
        var forclose = component.find("search-look-ahead");
        $A.util.addClass(forclose, "slds-is-close");
        $A.util.removeClass(forclose, "slds-is-open");
    },
    collectExpandedRows: function(component, gridData, selectedRows) {
        var expandedRows=[];
        var newData = gridData.map(function(row) {
            if(row._children) {
                row._children = row._children.map(function(subrow) {
                    if(!subrow._children || !subrow._children.length) {
                        delete subrow._children;
                    } else {
                        subrow._children = subrow._children.map(function(leaf) {
                            delete leaf._children;
                            for(var i=0; i < selectedRows.length; i++) {
                                if(selectedRows[i] == leaf.name) {
                                    expandedRows.push(subrow.name);
                                    expandedRows.push(row.name);
                                }
                            }
                            return leaf;
                        });
                    }
                    return subrow;
                });
            }
            return row;
        });
        expandedRows = expandedRows.filter((item, index)=> expandedRows.indexOf(item) === index);
        return expandedRows;
    },
    
    selectChildren: function(component, item, selectedItemNames) {
        //console.log("-----------"+item.name + '-----------=' + item.nodeName);
        //console.log("===========selectedItemNames ="+selectedItemNames);
        if(selectedItemNames.indexOf(item.nodeName) == -1 && !item._children) {
            return [];
        } else {
            if(!item._children){
                for(var level=0; level < item._children.length; level++) { 
                    selectedCollection = selectedCollection.concat(this.collectSelectedNodes(component, item._children[level], selectedItemNames));
                }
            }
            if(selectedItemNames.indexOf(item.nodeName) != -1) {
                selectedCollection.push(item);
            }
            return selectedCollection;
        }
    },
    arrayUnique: function(component, array) {
        var a = array.concat();
        for(var i=0; i<a.length; ++i) {
            for(var j=i+1; j<a.length; ++j) {
                if(a[i] === a[j])
                    a.splice(j--, 1);
            }
        }
    
        return a;
    },
    showPill: function(component) {
        // console.log("LookupComponentHelper showPill...");
        var pillTarget = component.find("lookup-pill");
        $A.util.addClass(pillTarget, "slds-show");
        $A.util.removeClass(pillTarget, "slds-hide");
    },
})