({
    checkIfCollapsed : function(cmp,e,h) {
        return cmp.get('v.isCollapsed') == true;
    },
    doInit : function(cmp,e,h) {
        h.loadData(cmp);
    },
    onCloseClickHandler: function(cmp,e,h){
        cmp.set('v.isCollapsed',true);
        localStorage.setItem('isCollapsed','YES');
    },
    onOpenClickHandler:function(cmp){
        localStorage.setItem('isCollapsed','NO');
        cmp.set('v.isCollapsed',false);
    },
    onParametersChange: function(cmp,e,h){
        h.loadData(cmp);
    },
})