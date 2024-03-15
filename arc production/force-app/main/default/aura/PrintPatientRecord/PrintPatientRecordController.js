({ // eslint-disable-line
    init: function (component, event, helper) 
    {
        var columns = [
            {
                type: 'url',
                fieldName: 'url',
                label: '',
                initialWidth: 300,
                typeAttributes: {
                    label: { fieldName: 'nodeName' }
                }
            },
            {
                type: 'date-local',
                fieldName: 'contactDate',
                label: 'Date'
            },
            {
                type: 'text',
                fieldName: 'finalizedBy',
                label: 'Finalized By',
                initialWidth: 250
            },
            {
                type: 'date-local',
                fieldName: 'finalizedDatetime',
                label: 'Finalized Date'
            },
            
        ];
        //component.set("v.isOpen", false);
        component.set('v.gridColumns', columns);
        helper.getAdmissionList(component,event, helper);
        //helper.initialLoad(component,event, helper);
        helper.loadTreeNodes(component, event, helper);
        helper.toggleStepTwo(component);
        var matchedDocTypes = [{label: "Display All Types",
                                    value: "Clear"}];
        
        component.set('v.listOfSearchRecords', matchedDocTypes);
    },
    handleSubmit : function(component, event, helper) {
        component.set("v.isAdmissionOpen", false);
        helper.loadTreeNodes(component, event, helper);
        helper.toggleStepTwo(component);
    },
    goToStepTwo : function(component, event, helper) {
        var data = component.get( 'v.gridData' );
        var originalGridData = component.get( 'v.originalGridData' );
        var newData = [];
        for ( var l1 = 0; l1 < originalGridData.length; l1++ ){  
            //var level1Obj = Object.assign({}, data[l1]);
            //level1Obj._children=[];
            newData.push(helper.walkTheTree(originalGridData[l1], component));
        }
        console.log(newData);
        newData = newData.map(function(level1) {
            if(level1 && level1._children) {
                level1._children = level1._children.filter(function(level2) {
                    return (level2._children != null) && (level2._children.length > 0);
                })
                return level1;
            }
        });
        newData = newData.filter(function(level1) {
            return (level1 && level1._children != null) && (level1._children.length > 0);
        });
        
        component.set("v.reviewData", newData);
        component.find("treegrid_review").expandAll();
        helper.toggleStepOne(component);
        helper.toggleStepTwo(component);
    },
    goBackToStepOne : function(component, event, helper) {
        helper.toggleStepOne(component);
        helper.toggleStepTwo(component);
        
    },
    save : function(component, event, helper) {
        var requestId = component.get("v.requestId");
        var patientId = component.get("v.patientId");
        var admissionId = component.get("v.selectedAdmissionValue");
        var selectedRows = component.get("v.originalGridSelectedRows");
        console.log("Seleceted Rows=" + JSON.stringify(selectedRows));
        var action = component.get("c.savePrintedMedicalRecord");
        //String patientId, String documentObjsTxt, String requestId
        action.setParams({ patientId : patientId, documentObjsTxt : JSON.stringify(selectedRows), requestId : requestId, admissionId: admissionId });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let result = response.getReturnValue();
                console.log("result = " + result);
            }
        });
        $A.enqueueAction(action);

        // selectedRows = selectedRows.filter(item=>item.level == 3).map(level3=>({
        //     "url" : level3.url,
        //     "nodeName" : level3.nodeName,
        //     "name" : level3.name,
        //     "finalizedDatetime" : level3.finalizedDatetime,
        //     "finalizedBy" : level3.finalizedBy,
        //     "contactDate" : level3.contactDate
        // }));
        // console.log(selectedRows);
    },
    searchTree : function(component, event, helper)
    {
        var searchText = component.get("v.searchText");
       	console.log('text',searchText);
        var matchedDocTypes = [];
        if(searchText){
            console.log('searching',searchText);
            var orginalTree = component.get('v.medicalRecords');
            var objResult = JSON.parse(JSON.stringify(orginalTree));
            //var objResult = component.get('v.categoriesForSearch');
            console.log(objResult);
            var categories = [];
            
            for(var j = 0; j < objResult.length; j++ ){
                var cat = {};
                var showParent = false;
                cat.label = objResult[j].name;
                if(cat.label.toLowerCase().includes(searchText.toLowerCase())) { 
                    showParent = true;
                }
                cat.expanded = true;
                
                var docTypes = objResult[j]._children;
                if(docTypes) {
                    for(var k = 0; k < docTypes.length; k++ ) {
                        var docType = {};
                        docType.parent = objResult[j].name;
                        docType.label = docTypes[k].nodeName;
                        docType.value = docTypes[k].name;
                        docType.Name = k;
                        if(docType.label.toLowerCase().includes(searchText.toLowerCase())) {
                            cat.expanded = true;
                            matchedDocTypes.push(docType);
                            showParent = true;
                        
                        }

                    }
                }
                if(showParent){ 
                    //cat.items = matchedDocTypes;
                    categories.push(cat);  
                    cat.expanded = true;
                }

            }
            
            console.log('======================CATEGORIES======================', categories);
            component.set('v.categories', categories);
        }
        
        matchedDocTypes.push({label: "Display All Types",
                                value: "Clear"});
        if(matchedDocTypes.length) {
            var la = component.find("search-look-ahead");
            $A.util.removeClass(la, 'slds-hide');
            $A.util.addClass(la, 'slds-show');
        }
        component.set('v.listOfSearchRecords', matchedDocTypes);
    },
    handleSelectedItemEvent: function (component, event, helper) {
        debugger;
        var admissionId = component.get("v.selectedAdmissionValue");
        var parent = event.getParam("selectedObj").parent;
        //component.set('v.searchText', event.getParam("selectedObj").label);
        console.log("selectedItem " + JSON.stringify(parent));
        var la = component.find("search-look-ahead");
        $A.util.removeClass(la, 'slds-show');
        $A.util.addClass(la, 'slds-hide');
        //helper.showPill(component);
        event.stopPropagation();
        const params = event.getParam("selectedObj").value.split(';');
        if(params[0] == "Clear") {
            var originalData = component.get("v.originalGridData");
            component.set('v.gridData', originalData);
            var selectedRows = component.get('v.originalGridSelectedRows');
            var expandedRows = helper.collectExpandedRows(component, originalData, selectedRows);
            component.set('v.gridSelectedRows', selectedRows);
            component.set('v.gridExpandedRows', expandedRows);
            return true;
        }
        //component.find("treegrid_async").collapseAll();
       
        var orginalTree = component.get('v.medicalRecords');
        var curGridData = JSON.parse(JSON.stringify(orginalTree));
        var selectedGridData = curGridData.filter(item=>item.name == parent)[0];
        var level2 = selectedGridData._children.filter(item => {
            return item.name == event.getParam("selectedObj").value;
        })
        selectedGridData._children = level2;
        //var selectedGridData = curGridData.filter(item=>item.name == parent)[0]._children.filter(item=>item.name==curElm)
        var expandedRows = [parent,event.getParam("selectedObj").value];
        var selectedRows = [parent,event.getParam("selectedObj").value];
        curGridData = component.get('v.originalGridData');
        var action = component.get("c.retrieveRecordsToPrint");
        action.setParams({ docName : params[0], sObjName : params[1], patientId : params[2], admissionId : admissionId });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //console.log('object',response.getReturnValue());
                let allTreeNodes = response.getReturnValue();
                allTreeNodes = allTreeNodes.replace(/\bchildren\b/g, '_children');
                var objResult = JSON.parse(allTreeNodes);
                objResult.map(item=>{
                    if(selectedGridData._children[0]._children.map(item2=>item2.name).indexOf(item.name)== -1) {
                        selectedGridData._children[0]._children.push(item);
                    }
                    delete item._children;
                    selectedRows.push(item.name);
                })
                component.set('v.gridData', [selectedGridData]);
                component.set("v.gridExpandedRows", expandedRows);
                //component.set("v.gridSelectedRows", selectedRows);
                component.set('v.isLoading', false);
                curGridData = component.get('v.originalGridData');
                console.log(curGridData);
            }
        });
        $A.enqueueAction(action);
        
        //gridSelectedRows
        
    },
    handlePrintJob: function (component, event, helper) {
        var selectedRows = component.get("v.originalGridSelectedRows"); 
        var selectedAdmissionValue = component.get("v.selectedAdmissionValue"); 
        var filteredRows = selectedRows.filter(c=>c.split(';').length == 4)
        console.log(filteredRows);
        var patientId = component.get("v.patientId");
        var requestId = component.get("v.requestId");
        console.log('patient Id =' + patientId);
        helper.createPrintJob(component, patientId, filteredRows, requestId).then($A.getCallback(function (newData) {
            console.log(newData);
            if(newData.length == 15 || newData.length == 18) {
                //window.open('/apex/SDOC__SDCreate1?id=' + newData + '&Object=Printed_Medical_Record_Request__c&doclist=SDocsCallableTest&autoopen=0');
                var pdfUrl = "/apex/PrintedPatientRecordPDF?Id="+newData+"&admissions="+selectedAdmissionValue;
                window.open(pdfUrl);
                helper.savePrintedMedicalRecordPDF(component, requestId, pdfUrl);
            }
        }));
    },
    showSpinner: function(component, event, helper) {
       // make Spinner attribute true for display loading spinner 
        //component.set("v.Spinner", true); 
   	},
    
 	// this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
     // make Spinner attribute to false for hide loading spinner    
      //component.set("v.Spinner", false);
    },
    
    closeModal : function(component, event, helper){
        component.set("v.isOpen", false);
    },
    openModal  : function(component, event, helper){
        component.set("v.isOpen", true);
    },
    showAll : function(component, event, helper) {
        var allData = component.get('v.originalGridData');
        component.set('v.gridData', allData);
    }, 
    expand : function(component, event, helper){
        //component.set( 'v.bypassOnRowSelection', true);
        var orginalTree = component.get('v.medicalRecords');
        var allData = JSON.parse(JSON.stringify(orginalTree));

        component.set('v.gridData', allData);
        debugger;
        var selectedRows = component.get('v.originalGridSelectedRows');
        //var selectedRows = component.get('v.selectedRowsStored');
        
        component.set('v.gridSelectedRows', selectedRows);
        component.find("treegrid_async").expandAll();
        component.set('v.gridExpandedRows', component.find("treegrid_async").getCurrentExpandedRows());
    },
    collapse : function(component, event, helper){
        var t = component.find("treegrid_async").getSelectedRows();
        component.set('v.gridExpandedRows', []);
        var selectedRows = component.get('v.gridSelectedRows');
        debugger;
        component.set('v.originalGridSelectedRows', selectedRows);
        component.set('v.selectedRowsStored', selectedRows);
        
        //component.find("treegrid_async").collapseAll();
        //component.set( 'v.bypassOnRowSelection', true);
        //component.set('v.gridExpandedRows', component.find("treegrid_async").getCurrentExpandedRows());
    },   
    onSelected : function(component, event, helper){
        var bypassOnRowSelection = component.get( 'v.bypassOnRowSelection'); 
        
        if(bypassOnRowSelection) {
            console.log('---------- in process --------');
            window.setTimeout(
                $A.getCallback(function() {
                    component.set('v.bypassOnRowSelection', false);
                }), 100
            );

             return false;
        }
        console.log('onSelection');
        var selectedRows = event.getParam( 'selectedRows' );
        var currentSelectedRows = component.find("treegrid_async").getSelectedRows();
        var selectedRows2 = component.get( 'v.gridSelectedRows' );
        var data = component.get( 'v.gridData' );
        
        var oldSelections = component.get( 'v.oldGridSelectedRows' );
        var currentGridExpandedRows = component.find("treegrid_async").getCurrentExpandedRows();
        console.log('---currentGridExpandedRows='+currentGridExpandedRows.length);
        console.log('selectedRows='+selectedRows.length);
        console.log('oldSelections='+oldSelections.length);
        // if(selectedRows.length == oldSelections.length) {
        //     return false;
        // }
        if(oldSelections) {
            var newSelections = selectedRows.filter(function(x) {
                let test = oldSelections.includes(x.name);
                return !test;
            });
            console.log("----newSelection =" + JSON.stringify(newSelections));
        }
        let isDeselection = false;
        let deselections = [];
        if(oldSelections && (oldSelections.length > selectedRows.length)) {
            isDeselection = true;
            // console.log('before oldSelections=');
            // console.log('oldSelections='+JSON.stringify(oldSelections));
            // console.log('after oldSelections=');
            deselections = oldSelections.filter(function(x) {
                let test = selectedRows.map(b=>b.name).includes(x);
                return !test;
            });
        }
        console.log('deselections='+JSON.stringify(deselections));
        var originalSelectedData = selectedRows.map(x=>x.name);
        originalSelectedData = originalSelectedData.concat(component.get( 'v.gridSelectedRows' ));
        originalSelectedData = helper.arrayUnique(component, originalSelectedData.concat());
        var selectedData = newSelections.map(x=>x.name); 
        for ( var i = 0; i < newSelections.length; i++ ) {      
            for ( var l1 = 0; l1 < data.length; l1++ ){  
                if((newSelections[ i ].name == data[ l1 ].name) && data[ l1 ]._children) {
                    currentGridExpandedRows.push(data[ l1 ].name);
                    var children = data[ l1 ]._children;
                    for(var l2=0; l2 < children.length; l2++) {  
                        if((selectedData.indexOf(children[ l2 ].name) == -1) && (children[ l2 ]._children)) {
                            selectedData.push( children[ l2 ].name );  
                        }        
                        var childrenRecs = children[l2][ '_children' ];
                        //selectedData.push( children[l2].name );       
                        if(childrenRecs){
                            currentGridExpandedRows.push(children[l2].name);
                            for ( var k = 0; k < childrenRecs.length; k++ ) {
                                if(selectedData.indexOf(childrenRecs[ k ].name) == -1) {
                                    selectedData.push( childrenRecs[ k ].name );  
                                }
                            }    
                        }  
                    }
                }
                else if(data[ l1 ]._children) {
                    var children = data[ l1 ]._children;
                    for(var l2=0; l2 < children.length; l2++) {  
                        if ( (newSelections[ i ].name == children[l2].name) ) {             
                            var childrenRecs = children[l2][ '_children' ];
                            //selectedData.push( children[l2].name );       
                            if(childrenRecs){
                                for ( var k = 0; k < childrenRecs.length; k++ ) {
                                    if(selectedData.indexOf(childrenRecs[ k ].name) == -1) {
                                        selectedData.push( childrenRecs[ k ].name );  
                                    }
                                }    
                            }  
                        } else {
                            // var level3Children = children[l2]._children;
                            // if(level3Children) {
                            //     for(var l3=0; l3 < level3Children.length; l3++) {  
                            //         if ( selectedRows[ i ].name == level3Children[l3].name ) {   
                            //             if(selectedData.indexOf(level3Children[l3].name) == -1) {
                            //                 selectedData.push( level3Children[l3].name );  
                            //             }
                            //         }
                            //     }
                            // }
                        }
                    }
                }     
            }
        }
        console.log('---currentGridExpandedRows='+currentGridExpandedRows.length);
        let deselectItems=[];
        for ( var i = 0; i < deselections.length; i++ ) {      
            for ( var l1 = 0; l1 < data.length; l1++ ){  
                if(deselections[ i ] == data[l1].name && data[l1]._children) {
                    deselectItems.push(data[l1].name);
                    var children = data[l1]._children;
                    if(children) {
                        for(var l2=0; l2 < children.length; l2++) {  
                            deselectItems.push(children[l2].name);            
                            var childrenRecs = children[l2][ '_children' ];
                            if(childrenRecs) {
                                for(var l3=0; l3 < childrenRecs.length; l3++) { 
                                    deselectItems.push(childrenRecs[l3].name);
                                }
                            }    
                        }
                    }
                    
                } else if(data[l1]._children) {
                    var children = data[l1]._children;
                    if(children) {
                        for(var l2=0; l2 < children.length; l2++) {  
                            //if ( selectedRows[ i ].name == children[l2].name ) {   
                            if ( (deselections[ i ] == children[l2].name) && children[l2]._children ) {             
                                var childrenRecs = children[l2][ '_children' ];
                                //selectedData.push( children[l2].name );     
                                deselectItems.push(children[l2].name);
                                if(childrenRecs) {
                                    for(var l3=0; l3 < childrenRecs.length; l3++) { 
                                        deselectItems.push(childrenRecs[l3].name);
                                    }
                                } 
                            } else if(children[l2]._children) {
                                for(var l3=0; l3 < children[l2]._children.length; l3++) { 
                                    if ( deselections[ i ] == children[l2]._children[l3].name) {
                                        deselectItems.push(children[l2]._children[l3].name);
                                    }
                                } 
                            } 
                        }
                    }
                }     
            }
        }
        
        component.set( 'v.gridData', data );
        selectedData = helper.arrayUnique(component, originalSelectedData.concat(selectedData));
        selectedData = selectedData.filter((item) => deselectItems.indexOf(item) == -1);
        
        //currentGridExpandedRows = helper.arrayUnique(component, currentGridExpandedRows.concat());
        component.set( 'v.gridSelectedRows', selectedData );
        component.set( 'v.oldGridSelectedRows', selectedData );
        component.set(' v.selectedRowsStored', selectedData);
        console.log('---line 448 --' + Date.now());
        let tmpExpanded = component.get( 'v.gridExpandedRows');
        tmpExpanded = tmpExpanded.concat(currentGridExpandedRows);
        tmpExpanded = helper.arrayUnique(component, tmpExpanded.concat());
        console.log('size of tmpExpanded ' + tmpExpanded.length);
        console.log('size of currentGridExpandedRows ' + currentGridExpandedRows.length);
        console.log('size of tmpExpanded ' + tmpExpanded.length);
        component.set( 'v.gridExpandedRows', tmpExpanded );
        component.set( 'v.expandedRowsCount', tmpExpanded.length);
        if(data.length > 1) {
            component.set( 'v.originalGridSelectedRows', selectedData);
        } else if(data.length == 1 ) {
            var originalSelection = component.get( 'v.originalGridSelectedRows');
            var docType = data[0]._children[0].name.split(";")[0];
            var originalSelection = originalSelection.filter(item=>item.indexOf(docType) == -1 );
            originalSelection = originalSelection.concat(selectedData.filter((item) => originalSelection.indexOf(item) < 0));
            component.set( 'v.originalGridSelectedRows', originalSelection);

        }
        console.log('line 468 --' + Date.now());
        console.log('selectedData='+ JSON.stringify(selectedData));
        console.log('---------- set in process to true--------');
        component.set( 'v.inProcess', true ); 
        //helper.mergeSelection(component);
    },
    handleRowToggle: function(component, event, helper) {
        var treeGridComponent = component.find("treegrid_async");
        if(treeGridComponent){
            //get all current expanded rows
            var currentExpandedRows = treeGridComponent.getCurrentExpandedRows();
            if(currentExpandedRows && currentExpandedRows.length != null && currentExpandedRows.length != undefined){
                //checking if row is expanding or collapsing
                if(currentExpandedRows.length >= component.get('v.expandedRowsCount')){
                    //expanding
                    var selectedRowsStored = component.get('v.selectedRowsStored');
                    component.set('v.gridSelectedRows', selectedRowsStored);
                    
                }else{
                    //collapsing
                    component.set('v.bypassOnRowSelection', true);
                }
                //setting new current expanded row count to attribute
                component.set('v.expandedRowsCount', currentExpandedRows.length);
            }
        }
        // retrieve the unique identifier of the row being expanded
        // var rowName = event.getParam('name');
        // // the new expanded state for this row
        // var isExpanded = event.getParam('isExpanded');
        // // does the component have children content for this row already?
        // var hasChildrenContent = event.getParam('hasChildrenContent');
        // // the complete row data
        // var row = event.getParam('row');
        // // the row names that are currently expanded
        // var expandedRows = component.find('treegrid_async').getCurrentExpandedRows();
        // // if hasChildrenContent is false then we need to react and add children
        // if (hasChildrenContent === false) {
        //     component.set('v.isLoading', true);
        //     // call a method to retrieve the updated data tree that includes the missing children
        //     const params = rowName.split(';');
        //     helper.retrieveUpdatedData(component, params[0], params[1], params[2]).then(function (newData) {
        //         component.set('v.gridData', newData);
        //         component.set('v.isLoading', false);
        //     });
        // }
    },
    handleAdmissionFileSelected: function(component, event, helper) {
        var selectedOptionValue = event.getParam("value");
        component.set('v.selectedAdmissionValue', selectedOptionValue);
        console.log("Option selected with value: '" + selectedOptionValue + "'");
        helper.loadTreeNodes(component, event, helper);
    },
    onSearchDate: function(component, event, helper) {
        var fromDate = component.find("fromDate").get("v.value");
        var toDate = component.find("toDate").get("v.value");
        var searchFinalizedDate = component.find("searchFinalizedDate").get("v.value");
        searchFinalizedDate = searchFinalizedDate ? "true" : "false";
        var patientId = component.get("v.patientId");
        var admissionId = component.get("v.selectedAdmissionValue");
        console.log('patientId=' + patientId);
        helper.searchRecordsInDateRange(component, patientId, fromDate, toDate, searchFinalizedDate, admissionId).then($A.getCallback(function (result) {
            console.log(result);
            var allTreeNodes = result.allTreeNodes.replace(/\bchildren\b/g, '_children');
            var selectedRows = result.selectedRows;
            var objResult = JSON.parse(allTreeNodes);
            var expandedRows=[];
            selectedRows = JSON.parse(selectedRows);
            var originalSelectedRows = component.get("v.originalGridSelectedRows");
            //selectedRows = originalSelectedRows.concat(selectedRows.filter((item) => originalSelectedRows.indexOf(item) < 0));

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
            
            component.set('v.originalGridData', newData);
            component.set('v.gridData', newData);
            component.set('v.medicalRecords', JSON.parse(JSON.stringify(newData)));
            
            component.set('v.gridSelectedRows', selectedRows);
            component.set("v.originalGridSelectedRows", selectedRows);
            component.set("v.gridExpandedRows", expandedRows);
        }));
    },
    onBlurHandler: function (component, event, helper) {
    
        setTimeout(
            $A.getCallback(function () {
            // always close after blur
            helper.closeMenu(component);
            }),
            400
        );
    },
    navigateToRecord : function(component, event, helper){
        var requestId = component.get("v.requestId");
        window.open('/' + requestId);
    },
      
}); // eslint-disable-line