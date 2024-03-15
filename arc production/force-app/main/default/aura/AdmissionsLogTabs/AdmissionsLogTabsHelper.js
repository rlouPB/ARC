({
  parseURL: function (cmp) {
    console.log("AdmissionsLogTabsHelper parseURL...");
    var url = window.location.href,
      params = {},
      match;

    var pUrl = url.split("&");
    url = pUrl[0];
    if (pUrl[1] == "c__tab=notes") {
      this.selectTab(cmp, "Admissions Officer Highlight");
      params.tab = "notes";
    }

    var regex = new RegExp("[?&]" + "c__noteId" + "(=([^&#]*)|&|#|$)");

    var results;
    if (regex.exec(url) != null) {
      results = regex.exec(url);
    }

    if (!results) return null;

    if (!results[2]) return "";

    if (results[2]) {
      params.noteId = decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    return params;
  },
  selectTab: function (component, noteRtName) {
    console.log("AdmissionsLogTabsHelper selectTab...");
    console.log("note recordtype: " + noteRtName);
    if (noteRtName == "Admissions Notes") {
      component.set("v.selectedTabId", "logCall");
    } else if (noteRtName == "Admissions Officer Highlight") {
      component.set("v.selectedTabId", "logNote");
    }
  }
});