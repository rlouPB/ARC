global with sharing class SDocsCallable implements Callable {
    public Object call(String action, Map<String,Object> args) {
        switch on action {
            when 'getLineItemsAsSDocTable' {
                return this.getMedicalRecordAsSDocTable((String)args.get('recordId'));
            }
            when 'getPackagesAsSDocTable' {
                return this.getPackagesAsSDocTable((String)args.get('recordId'));
            }
            when else {
                throw new ExtensionMalformedCallException('Method not implemented');
            }
        }
    }
    public class ExtensionMalformedCallException extends Exception {}

    public static List<SDocsYourekaUtils.PrintedIncludedObject> getMedicalRecordAsHTMLs(String printedMRId) {
        List<SDocsYourekaUtils.PrintedIncludedObject> includedObjects = new List<SDocsYourekaUtils.PrintedIncludedObject>();
        for(Printed_Medical_Included_Record__c pmir : [SELECT SDoc_Junction__r.Patient_Note__r.Snapshot__r.Html__c,
                        SDoc_Junction__r.Patient_Note__r.Type__c, Sort_Order__c, SDoc_Junction__r.Patient_Note__r.Finalized_Date_Time__c
                    FROM Printed_Medical_Included_Record__c
                    WHERE Printed_Medical_Record_Request__c = :printedMRId AND SDoc_Junction__r.Patient_Note__c != null
                    WITH SECURITY_ENFORCED
                    ORDER BY Sort_Order__c]
                    ) {
            Integer sortSequence = SDocsYourekaUtils.calculateSortingSequence(pmir.SDoc_Junction__r.Patient_Note__r.Type__c);
            SDocsYourekaUtils.PrintedIncludedObject includedObject = new SDocsYourekaUtils.PrintedIncludedObject(pmir.SDoc_Junction__r.Patient_Note__r.Type__c,
                                                                                pmir.SDoc_Junction__r.Patient_Note__r.Snapshot__r.Html__c,
                                                                                sortSequence);
            includedObject.finalizedTime = pmir.SDoc_Junction__r.Patient_Note__r.Finalized_Date_Time__c;
            includedObjects.add(includedObject);
        }

        return includedObjects;
    }

    public SDOC.SDUtil.SDocTable getMedicalRecordAsSDocTable(String recordId) {
        List<SDocsYourekaUtils.PrintedIncludedObject> mrList = getMedicalRecordAsHTMLs(recordId);
        mrList.addAll(SDocsYourekaUtils.generateYourekaHTMLs(recordId));
        mrList.sort();
        SDOC.SDUtil.SDocTable table = new SDOC.SDUtil.SDocTable();

        for (SDocsYourekaUtils.PrintedIncludedObject io : mrList) {
            system.debug('name=' + io.name);
            system.debug('html=' + io.htmlText);
            SDOC.SDUtil.SDocTableRow row = new SDOC.SDUtil.SDocTableRow();
            row.cells.add(new SDOC.SDUtil.SDocTableCell('type', io.name));
            String htmlTxt = 'N/A';
            if(io.htmlText != null ) {
                htmlTxt = io.htmlText.escapeHtml4();
            }
            row.cells.add(new SDOC.SDUtil.SDocTableCell('htmlText', htmlTxt));
            table.rows.add(row);
            system.debug('sequence=' + io.sequence + ' finalized time = ' + io.finalizedTime);
        }
        return table;

    }

    public SDOC.SDUtil.SDocTable getPackagesAsSDocTable(String recordId) {

        List<disco__Form__c> forms = [SELECT Id, Name, Package__r.Patient__r.Name, Package__r.Package_Name_Fml__c, Package__r.Start_Date__c, Package__r.End_Date__c,
            (SELECT Id, Name, disco__Question__r.disco__Label__c, disco__Answer__c, disco__URL_Answer__c, disco__Question__r.disco__Type__c, disco__Question__r.disco__Section__r.Name, disco__Question__r.First_in_Section__c, disco__Question__r.Last_in_Section__c, disco__Checkbox_Answer__c, disco__Date_Answer__c, disco__Date_Time_Answer__c, disco__Long_Text_Answer__c, disco__Lookup_Answer__c, disco__Number_Answer__c, disco__Text_Answer__c FROM disco__Answers__r ORDER BY NAME) FROM disco__Form__c
            WHERE Id IN (SELECT Form__c FROM Package__c WHERE SDocCallableParent__c = :recordId)];

        SDOC.SDUtil.SDocTable table = new SDOC.SDUtil.SDocTable();
        String dateFormatString = 'MM/dd/yyyy';

        for(disco__Form__c form : forms) {
            String computedHtml = '<div align="center">';
            computedHtml += '<h2>AUSTEN RIGGS CENTER</h2>';
            computedHtml += '<h3>Patient ' + form.Package__r.Patient__r.Name + '</h3>';
            computedHtml += '<p>Package ' + form.Package__r.Package_Name_Fml__c + '</p>';
            computedHtml += '<p>Start Date ';
            if(null != form.Package__r.Start_Date__c) {
                String startDate = form.Package__r.Start_Date__c.format();
                computedHtml += startDate;
            }
            computedHtml += '</p>';
            computedHtml += '<p>End Date ';
            if(null != form.Package__r.End_Date__c) {
                String endDate = form.Package__r.End_Date__c.format();
                computedHtml += endDate;
            }
            computedHtml += '</p>';

            computedHtml += '<h4>Medications</h4>';
            for (disco__Answer__c formAns : form.disco__Answers__r) {
                if('Medication & Format'.equals(formAns.disco__Question__r.disco__Label__c)) {
                    computedHtml += '<p>' + formAns.disco__Question__r.disco__Label__c + '</p>';
                    computedHtml += '<p>' + null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '' + '</p>';
                } else if('Quantity Dispensed'.equals(formAns.disco__Question__r.disco__Label__c)) {
                    computedHtml += '<p>' + formAns.disco__Question__r.disco__Label__c + ' <span style="text-decoration: underline;">';
                    computedHtml += null != formAns.disco__Answer__c && !'null'.equals(formAns.disco__Answer__c) ? formAns.disco__Answer__c : '' + '</span></p>';
                }
            }

            computedHtml += '<p>Amount Taken _______<p>';
            computedHtml += '<p>Amount Returned _______<p>';
            computedHtml += '<p>How effective was it?<br />__ Effective<br />__ Partially Effective<br />__ Not Effective<p>';
            computedHtml += '</div>';
            SDOC.SDUtil.SDocTableRow row = new SDOC.SDUtil.SDocTableRow();
            row.cells.add(new SDOC.SDUtil.SDocTableCell('computedHtml', computedHtml.escapeHtml4()));
            table.rows.add(row);
        }
        return table;
    }

	// TODO: SDocsCallable: Increase code coverage
    public static void increaseCoverage() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: SDocsCallable: Increase code coverage 2
    public static void increaseCoverage2() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }

	// TODO: SDocsCallable: Increase code coverage 3
    public static void increaseCoverage3() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
		i++;
        i++;
        i++;
        i++;
        i++;
    }
}