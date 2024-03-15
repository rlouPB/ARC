/* eslint-disable no-console */
import { LightningElement, api, track, wire} from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fullCalendar from "@salesforce/resourceUrl/fullCalendarv4";
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import getEventsNearbyDynamic from "@salesforce/apex/FullCalendarController.getEventsNearbyDynamic";
import { NavigationMixin } from 'lightning/navigation';

// Import message service features required for subscribing and the message channel
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import medicationDispensed from '@salesforce/messageChannel/medicationDispensed__c';
import SystemModstamp from "@salesforce/schema/Account.SystemModstamp";


//global variables
var objectName;
var startField;
var endField;
var colorField;
var additionalFilter;
var allDayField;
var titleField;


export default class FullCalendarLwc extends NavigationMixin(LightningElement) {
    calendar;
    fullCalendarInitialized = false;
    
    @api titleField;
    @api objectName;
    @api startField;
    @api endField;
    @api colorField;
    @api additionalFilter;
    @api aspectRatio;
    @api allDayField;
    @api height=450;
    
    defaultView='dayGridMonth' // Possible Values: listDay,listWeek,listMonth,timeGridWeek,timeGridDay,dayGridMonth,dayGridWeek,dayGridDay
  
    @api viewType='month' //Possible: month, week, day
    @api listType = false

    // get isList(){
    //     return 'listDay,listWeek,listMonth'.split(",").indexOf( this.defaultView ) >= 0
    // }

    subscription = null;
    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                medicationDispensed,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    // Handler for message received by component
    handleMessage(message) {
        console.log('message : ', message);
        this.refresh();
    }

    get currentView(){
        console.log('this.listType : ', this.listType)
        if ( !this.listType ) {
            if (this.viewType == 'month'){ return 'listMonth'}
            if (this.viewType == 'week'){ return 'listWeek'}
            if (this.viewType == 'day'){ return 'listDay'}
        }else{
            if (this.viewType == 'month'){return 'dayGridMonth'}
            if (this.viewType == 'week'){ return 'dayGridWeek'}
            if (this.viewType == 'day'){return 'dayGridDay'}
        }
        return 'dayGridMonth'
    }

  
    @track calendarLabel;

    get listButtonClass(){
        return `slds-button slds-button_icon ${this.listType? 'slds-button_brand' : ''}`
    }

    connectedCallback() {
        this.addEventListener('eventclick', this.handleEventClick.bind(this));
        this.addEventListener('mousewheel', this.handleScroll.bind(this)); 
        this.subscribeToMessageChannel(); 
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }
    
    renderedCallback() {
        if (this.fullCalendarInitialized) {
            return;
        }
        this.fullCalendarInitialized = true;

        //set global vars
        objectName = this.objectName;
        startField = this.startField;
        endField = this.endField;
        colorField = this.colorField;
        additionalFilter = this.additionalFilter;
        allDayField = this.allDayField;
        titleField = this.titleField;
        this.defaultView = this.currentView

        Promise.all([
            loadScript(this, fullCalendar + "/packages/core/main.js"),
            loadStyle(this, fullCalendar + "/packages/core/main.css")
        ]).then(() => {
            console.debug("******************* CORE  init *******************");
            //got to load core first, then plugins
            Promise.all([
                loadScript(this, fullCalendar + "/packages/daygrid/main.js"),
                loadStyle(this, fullCalendar + "/packages/daygrid/main.css"),
                loadScript(this, fullCalendar + "/packages/list/main.js"),
                loadStyle(this, fullCalendar + "/packages/list/main.css"),
                loadScript(this, fullCalendar + "/packages/timegrid/main.js"),
                loadStyle(this, fullCalendar + "/packages/timegrid/main.css"),
                loadScript(this, fullCalendar + "/packages/interaction/main.js"),
                loadScript(this, fullCalendar + "/packages/moment/main.js"),
                loadScript(this, fullCalendar + "/packages/moment-timezone/main.js"),
            ]).then(() => {
                console.debug("******************* PLUGINS  init *******************");
                this.init();
            })
        }).catch(error => {
            console.log("error", error);
            this.dispatchEvent(
                new ShowToastEvent({
                title: "Error loading FullCalendar",
                //message: error.message,
                variant: "error"
                })
            );
        });
    }

    init() {
        let defaultDate = new Date()
        var calendarEl = this.template.querySelector(".calendar");
        // eslint-disable-next-line no-undef
        this.calendar = new FullCalendar.Calendar(calendarEl, {
            
            header: false,
            defaultDate: defaultDate,
            height: this.height,
            defaultView: this.defaultView,
            // navlinks: true,
            editable: false,
            droppable: false,
            fixedWeekCount: false,
            selectable: false,
            selectHelper: false,
            eventLimit: true,
            events: [],

            plugins: ["dayGrid", "timeGrid", "list","interaction","moment"],
            views: {
                listDay: { buttonText: "list day" },
                listWeek: { buttonText: "list week" },
                listMonth: { buttonText: "list month" },
                timeGridWeek: { buttonText: "week time" },
                timeGridDay: { buttonText: "day time" },
                dayGridMonth: { buttonText: "month" },
                dayGridWeek: { buttonText: "week" },
                dayGridDay: { buttonText: "day" },
            },      
            eventClick: info => {
                const selectedEvent = new CustomEvent('eventclick', { detail: info });
                console.log("********** eventClick **********",info);
                this.dispatchEvent(selectedEvent);
            },
            // eventMouseEnter: (info) => {console.log("mouse enter", info)},
            dateClick:info => {console.log("********** date click **********", info)},
            // header: false,
            /*header: {
            left: "title",
            center: "today prev,next",
            right:
                "listDay,listWeek,listMonth,timeGridWeek,timeGridDay,dayGridMonth,dayGridWeek,dayGridDay"
            },*/
            eventSources: [
            {
                events: this.eventSourceHandler,
                id: "custom"
            },
            //{
            //  events: "https://fullcalendar.io/demo-events.json",
            //  id: "demo"
            //}
            ],
        });
        this.calendar.render();
        this.calendarLabel = this.calendar.view.title;
    }

    nextHandler() {
        console.debug('**** nextHandler ****' )
        this.calendar.next();
        this.calendarLabel = this.calendar.view.title;
    }

    previousHandler() {
        console.debug('**** previousHandler ****' )
        this.calendar.prev();
        this.calendarLabel = this.calendar.view.title;
    }

    dailyViewHandler() {
        this.viewType='day'
        this.calendar.changeView(this.currentView)
        this.calendarLabel = this.calendar.view.title;
    }

    weeklyViewHandler() {
        this.viewType='week'
        this.calendar.changeView(this.currentView)    
        this.calendarLabel = this.calendar.view.title;
    }

    monthlyViewHandler() {
        this.viewType='month'
        this.calendar.changeView(this.currentView);
        this.calendarLabel = this.calendar.view.title;
    }

    listViewToggleChangeHandler(e){
        this.listType = e.detail.checked
        this.calendar.changeView(this.currentView)
        this.calendarLabel = this.calendar.view.title;
    }

    today() {
        console.debug('**** today ****' )
        this.calendar.today();
        this.calendarLabel = this.calendar.view.title;
    }

    refresh() {
        var eventSource = this.calendar.getEventSourceById('custom');
        eventSource.refetch();
    }

    handleScroll(event) {
        console.log("handleScroll");
        //event.stopImmediatePropogation();
    }


    handleEventClick(event) {       
        console.debug('**** handleEventClick ****')
    }

    eventSourceHandler(info, successCallback, failureCallback) {
        console.info('begin eventSourceHandler')    
        getEventsNearbyDynamic({
            startDate: info.start,
            endDate: info.end,
            objectName: objectName,
            titleField: titleField,
            startField: startField,
            endField: endField,
            colorField: colorField,
            allDayField: allDayField,
            additionalFilter: additionalFilter
        }).then(result => {
            console.info('------- eventSourceHandler - RESULTS', result )
            if (result) {                
                let e = result.map(x=>({
                    ...x,
                    id: x.Id,
                    title: x[titleField],
                    start: x[startField],
                    end: x[endField],
                    color: x[colorField],
                    //color: 'red',
                    allDay: x[allDayField]
                }))
                console.log("num events = ",e.length, e);
                successCallback(e);
            }
        }).catch(error => {
            console.error("error calling apex controller:",error);
            failureCallback(error);
        });
    }
}