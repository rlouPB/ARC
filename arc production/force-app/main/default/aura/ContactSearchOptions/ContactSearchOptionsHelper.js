({
	prepopulateWhoToSearch : function(component) {
        var searchType = component.get("v.searchType");
        var searchData = component.get("v.searchData");
        var context = component.get("v.context");
        
        searchData.searchFor = 'patient';
        
		if(searchType === 'contactSearch') {
            if(context == 'patient'){
                searchData.searchFor = 'patient';
            } else if(context == 'contact'){
                searchData.searchFor = 'relatedContact';
            }
        } else if(searchType === 'searchByCall') {
            if(context == 'patient'){
                searchData.searchFor = 'patient';
            } else if(context == 'contact'){
                searchData.searchFor = 'caller';
            }
        }
        
        if (searchType === 'searchAllColumns' || searchType === 'notesView') {
            var today = new Date();

            var year = today.getFullYear();
            var month = today.getMonth()+1;
            var day = today.getDate();

            if (day < 10) {
              day = '0' + day;
            }
            if (month < 10) {
              month = '0' + month;
            }

            var todayStr = year + '-' + month + '-' + day;
            var searchData = component.get("v.searchData");
            searchData.startDate = todayStr;
            searchData.endDate = todayStr;
        }
        
        component.set("v.searchData", searchData);
	}
})