({
  getPropByString: function (obj, propString) {
    if (!propString) return obj;

    var prop,
      props = propString.split(".");

    for (var i = 0, iLen = props.length - 1; i < iLen; i++) {
      prop = props[i];

      var candidate = obj[prop];
      if (candidate !== undefined) {
        obj = candidate;
      } else {
        break;
      }
    }
    return obj[props[i]];
  },
  loadData: function (cmp) {
    let me = this;
    let recordId = cmp.get("v.recordId");
    let parameters = cmp.get("v.parameters")[0] || cmp.get("v.parameters");
    cmp.set("v.data");

    if (parameters && parameters.fieldNames) {
      let isCollapsed = localStorage.getItem("isCollapsed") || "NO";
      cmp.set("v.isCollapsed", isCollapsed == "YES");
      localStorage.setItem("isCollapsed", isCollapsed);
      let patientAccountId = cmp.get("v.patientAccountId");
      let defaultPatientFields = "Id,Name,Photo__c".split(",");
      let patientFieldNames = parameters.patientFields
        ? defaultPatientFields
            .concat(parameters.patientFields.map((x) => x.fieldName))
            .filter((x) => x && x.fieldName)
        : defaultPatientFields;
      let loadRecordDataParams = {
        recordId: patientAccountId,
        fieldNames: patientFieldNames
      };
      // console.info('loadRecordDataParams ==========> ',loadRecordDataParams);
      me.callApexMethod(
        cmp,
        "loadRecordData",
        loadRecordDataParams,
        function (patientResult) {
          // console.info('patientResult ==========> ',patientResult);
          if (patientResult.errorMessage) {
            me.showToast({
              type: "error",
              duration: 10000,
              message: patientResult.errorMessage
            });
          } else {
            let resFieldNames = patientResult.fields.map((x) => x.name);
            let data = {
              patient: patientResult.record,
              patientFields: (parameters.patientFields || [])
                .filter(
                  (x) => x && x.name && resFieldNames.indexOf(x.name) >= 0
                )
                .map((x) => {
                  let y = recordResult.fields.filter(
                    (y) => y.name == x.fieldName
                  )[0];
                  x.type = y.type;
                  x.label = x.label || y.label;
                  x.value = me.getPropByString(patientResult.record, x.name);
                  return x;
                })
            };
            if (recordId) {
              let recordFieldNames = (parameters.fieldNames || [])
                .filter((x) => x && x.fieldName)
                .map((x) => x.fieldName);
              let loadRecordDataParams2 = {
                recordId,
                fieldNames: recordFieldNames
              };
              // console.info('loadRecordDataParams2 ==========> ',loadRecordDataParams2);
              me.callApexMethod(
                cmp,
                "loadRecordData",
                loadRecordDataParams2,
                function (recordResult) {
                  // console.info('recordResult ==========> ',recordResult);
                  if (recordResult.errorMessage) {
                    me.showToast({
                      type: "error",
                      duration: 10000,
                      message: recordResult.errorMessage
                    });
                  } else {
                    let recordFieldNames = recordResult.fields.map(
                      (x) => x.name
                    );
                    data.record = recordResult.record;
                    data.recordFields = parameters.fieldNames
                      .filter(
                        (x) =>
                          x &&
                          x.fieldName &&
                          recordFieldNames.indexOf(x.fieldName) >= 0
                      )
                      .map((x) => {
                        let y = recordResult.fields.filter(
                          (y) => y.name == x.fieldName
                        )[0];
                        x.type = y.type;
                        x.value = me.getPropByString(data.record, x.fieldName);
                        x.label = x.label || y.label;
                        return x;
                      });
                    // console.info("================================== DATA ==================================", JSON.parse(JSON.stringify(data)));
                    cmp.set("v.data", data);
                  }
                }
              );
            } else {
              alert("does not have record?");
              data.record = null;
              data.recordFields = [];
              cmp.set("v.data", data);
            }
          }
        }
      );
    }
  }
});