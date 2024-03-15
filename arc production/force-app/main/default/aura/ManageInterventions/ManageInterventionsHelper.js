({
    
    getDiciplinesRecords: function (cmp) {
        let helper = this;
        let discipline = cmp.get("v.discipline");
    
        if(discipline) {
            return new Promise($A.getCallback(function(resolve){
                helper.callApexMethod(cmp,'getDiciplinesRecordsForDiscipline',{ treatmentPlanId : cmp.get("v.treatmentPlanId"), discipline: discipline},function(result){
                    if(result){
                        let diciplineInterverntions = {};
                        let requiredDetailsInterventions = {};
                        let diciplines = [];
                        for( let d of result){
                            if( !diciplineInterverntions[d.dicipline] ){
                                diciplineInterverntions[d.dicipline] = [];
                            }
                            diciplineInterverntions[d.dicipline].push(d.intervention);

                            requiredDetailsInterventions[d.intervention] = d.specify == true;
                        }
                        
                        diciplines = Object.getOwnPropertyNames(diciplineInterverntions);

                        cmp.set('v.diciplineInterverntions',diciplineInterverntions);
                        cmp.set('v.requiredDetailsInterventions',requiredDetailsInterventions);
                        cmp.set('v.diciplines',diciplines);
                        let interventions = (diciplines.length > 0)? helper.clone(diciplineInterverntions[diciplines[0]]) : [];
                        cmp.set('v.interventions',interventions);
                    }
                    resolve();
                });    
            }));
        } else {
            return new Promise($A.getCallback(function(resolve){
                helper.callApexMethod(cmp,'getDiciplinesRecords',{ treatmentPlanId : cmp.get("v.treatmentPlanId")},function(result){
                    if(result){
                        let diciplineInterverntions = {};
                        let requiredDetailsInterventions = {};
                        let diciplines = [];
                        for( let d of result){
                            if( !diciplineInterverntions[d.dicipline] ){
                                diciplineInterverntions[d.dicipline] = [];
                            }
                            diciplineInterverntions[d.dicipline].push(d.intervention);

                            requiredDetailsInterventions[d.intervention] = d.specify == true;
                        }
                        
                        diciplines = Object.getOwnPropertyNames(diciplineInterverntions);

                        cmp.set('v.diciplineInterverntions',diciplineInterverntions);
                        cmp.set('v.requiredDetailsInterventions',requiredDetailsInterventions);
                        cmp.set('v.diciplines',diciplines);
                        let interventions = (diciplines.length > 0)? helper.clone(diciplineInterverntions[diciplines[0]]) : [];
                        cmp.set('v.interventions',interventions);
                    }
                    resolve();
                });    
            }));
        }
    },

    discontinueIntervention : function(cmp, interventionId ){
        let self = this;
        return new Promise($A.getCallback(function(resolve){
            self.callApexMethod( cmp, "discontinueIntervention",{ interventionId },$A.getCallback(function(result){
                resolve(result);
            }));
        }));
    },

    hasPermissions : function(cmp, treatmentPlanId ){
        let helper = this;
        return new Promise($A.getCallback(function(resolve){
            helper.callApexMethod( cmp, "hasPermissions",{ treatmentPlanId },function(result){
                cmp.set("v.haspermissions",result? true : false);
                if(result){
                    resolve(result);
                }
            });
        }));
    },

    reload: function(cmp,value){
        let helper = this;
        helper.showSpinner(cmp);
        helper.getAllInterventions(cmp,value == 'All').then(function(){
            helper.hideSpinner(cmp);
        });
    },

    validateNewInter: function(cmp,newIntervention){
        let me = this;
        let map = me.clone( cmp.get('v.requiredDetailsInterventions'));
        let intervention = me.clone(newIntervention);
        let inter = intervention.description;
        let specifyRequired = inter? map[inter]==true: false;
        let specify =  specifyRequired? intervention.patientSpecificDetail : true;

        return intervention.dicipline && intervention.description && intervention.startDate && specify;
    },

    saveNewIntervention : function(cmp, newIntervention){
        let helper = this;
        
        return new Promise($A.getCallback(function(resolve){
            helper.callApexMethod( cmp, "saveNewIntervention",{ 
                treatmentPlanId: cmp.get("v.treatmentPlanId"),
                dicipline : newIntervention.dicipline,
                intervention : newIntervention.description,
                patientSpecificDetail : newIntervention.patientSpecificDetail,
                startDate : newIntervention.startDate,
             },function(result){
                cmp.set('v.newIntervention.description', '' );
                cmp.set('v.newIntervention.startDate', null );
                cmp.set('v.newIntervention.patientSpecificDetail', null );
                resolve(result);
            });
        }));
    },

    getAllInterventions: function (cmp, showAll) {
        let helper = this;
        let treatmentPlanId= cmp.get("v.treatmentPlanId");
        let showOnlyToAllowedDiciplines = cmp.get('v.showOnlyToAllowedDiciplines');
        let discipline = cmp.get("v.discipline");
    
        if(discipline) {
            return new Promise($A.getCallback(function(resolve){
                helper.callApexMethod( cmp, "getInterventionsForDiscipline",{ treatmentPlanId, discipline, showAll},
                function (result) {
                    if(result){
                        let data = result.map(function(item){
                            return {
                                "id": item.Id,
                                "discipline" : item.Discipline__c? item.Discipline__c : '',
                                "description" : item.Description__c,
                                "patientSpecificDetail" : item.Patient_specific_Details__c,
                                "startDate" : item.Start_Date__c,
                                "endDate" : item.End_Date__c,
                                'status' : item.Status__c,
                            };
                        });

                        let set = {};
                        let viewdata = helper.clone(data).map(function(itemv){
                            if(set[itemv.discipline]){
                                itemv.discipline = '';
                            }else{
                                set[itemv.discipline] = true;
                            }
                            return itemv;
                        });

                        cmp.set('v.view_data', viewdata);

                        cmp.set('v.data', data);
                    }
                    resolve();
                });
            }));

        } else {
            return new Promise($A.getCallback(function(resolve){
                helper.callApexMethod( cmp, "getInterventions",{ treatmentPlanId, showAll, showOnlyToAllowedDiciplines },
                function (result) {
                    if(result){
                        let data = result.map(function(item){
                            return {
                                "id": item.Id,
                                "discipline" : item.Discipline__c? item.Discipline__c : '',
                                "description" : item.Description__c,
                                "patientSpecificDetail" : item.Patient_specific_Details__c,
                                "startDate" : item.Start_Date__c,
                                "endDate" : item.End_Date__c,
                                'status' : item.Status__c,
                            };
                        });

                        let set = {};
                        let viewdata = helper.clone(data).map(function(itemv){
                            if(set[itemv.discipline]){
                                itemv.discipline = '';
                            }else{
                                set[itemv.discipline] = true;
                            }
                            return itemv;
                        });

                        cmp.set('v.view_data', viewdata);

                        cmp.set('v.data', data);
                    }
                    resolve();
                });
            }));
        }
    },

    clone: function(o){
        return o? JSON.parse(JSON.stringify(o)) : o;
    },
})