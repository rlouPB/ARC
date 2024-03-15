({
    init : function(cmp,e,h) {
        h.initialize(cmp, cmp.get('v.currentTab'))     
	},
    buttonClick : function(cmp,e,h) {
        cmp.set('v.currentTab',e.currentTarget.dataset.id)
    },
    onRefreshViewHandler: function(cmp,e,h){
        console.info('---------------------onRefreshView---------------------')
        h.initialize(cmp, cmp.get('v.currentTab'))
    },
})