import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0

/*
 * BoilerstatusApp.qml
 *
 * Toon application for boiler parameters display.
 * data is retrieved from the rra databases (used to be happ_thermstat)
 *
 * 20170117: marcelr, first draft
 * 20180118: Toonz, rewritten to use rra database as datasource
 */

App {
    id: boilerStatusApp
    
   
    property url tileUrl : "BoilerstatusTile.qml"
    property url tile2Url : "BoilerstatusTileMinutes.qml"
    property url thumbnailIcon: "qrc:/tsc/boilerstatus.png"

    /* boiler status parameters */

    property real boilerSetpoint
    property real roomTempSetpoint
    property real boilerPressure
    property real roomTemp
    property real boilerOutTemp
    property real boilerInTemp
    property real boilerModulationLevel : 1
    property int boilerBurnerMinutesNow
    property int boilerBurnerMinutesDayStart
    property bool showPressureInDimState : true
 
    property string ipToon : "127.0.0.1"  //can put any external Toon ip address as well for testing purposes
   
    function init() {
	registry.registerWidget( "tile", tileUrl, this, null, 
				 { thumbLabel: qsTr("Ketel status"), 
				   thumbIcon: thumbnailIcon, 
				   thumbCategory: "general", 
				   thumbWeight: 30, 
				   baseTileWeight: 10, 
				   thumbIconVAlignment: "center" } );
	registry.registerWidget( "tile", tile2Url, this, null, 
				 { thumbLabel: qsTr("Boiler Minutes"), 
				   thumbIcon: thumbnailIcon, 
				   thumbCategory: "general", 
				   thumbWeight: 30, 
				   baseTileWeight: 10, 
				   thumbIconVAlignment: "center" } );
	}

	Component.onCompleted: {

 		datetimeTimer.start();
		boilerMinutesTimer.start();
		readDefaults();
	}

	function readDefaults() {
		var doc4 = new XMLHttpRequest();
		doc4.onreadystatechange = function() {
			if (doc4.readyState == XMLHttpRequest.DONE) {
				if (doc4.responseText.length > 2) {
					showPressureInDimState = (doc4.responseText == "true");
				}
			}
		}  		
		doc4.open("GET", "file:///HCBv2/qml/apps/boilerstatus/showPressureInDimState.txt", true);
		doc4.send();
	}

	function saveShowPressureInDimState() {

   		var doc2 = new XMLHttpRequest();
		doc2.open("PUT", "file:///HCBv2/qml/apps/boilerstatus/showPressureInDimState.txt");
		doc2.send(showPressureInDimState);
	}

    function getBoilerParameter(loggerName, variableName, rradatabase, fullDateStr) {
	
	var xmlhttp = new XMLHttpRequest();
	var infoJson = {};
	var resultValue = 0.1;

	xmlhttp.onreadystatechange = function() {
		if  ( xmlhttp.readyState == 4 ) {
			if  ( xmlhttp.status == 200  ) {

		   		infoJson = JSON.parse( xmlhttp.responseText );
				for (var props in infoJson ) {
					resultValue = parseFloat(infoJson [props]);  //only interested in the last one == most recent
//					sampleTime = props;
				}
				switch(variableName) {
					case "boilerSetpoint":
						boilerSetpoint = resultValue;
						break;
					case "roomTempSetpoint":
						roomTempSetpoint = resultValue;
						break;
					case "boilerPressure":
						boilerPressure = resultValue;
						break;
					case "roomTemp":
						roomTemp = resultValue;
						break;
					case "boilerOutTemp":
						boilerOutTemp = resultValue;
						break;
					case "boilerInTemp":
						boilerInTemp = resultValue;
						break;
					case "boilerBurnerMinutesNow":
						boilerBurnerMinutesNow = resultValue;
//						console.log("*******BOILER reading:" + boilerBurnerMinutesNow);
						break;
					case "boilerBurnerMinutesDayStart":
						boilerBurnerMinutesDayStart = resultValue;
//						console.log("*******BOILER reading  dayStart:" + boilerBurnerMinutesDayStart);
						break;
					default:
						break;
				}
			}
	    	}
	}
	xmlhttp.open( "GET", "http://" + ipToon + "/hcb_rrd?action=getRrdData&loggerName=" + loggerName + "&" + rradatabase + "&readableTime=1&nullForNaN=1&from=" + fullDateStr, true );
	xmlhttp.send();
//	console.log("********** BOILER request:" + "http://" + ipToon + "/hcb_rrd?action=getRrdData&loggerName=" + loggerName + "&" + rradatabase + "&readableTime=1&nullForNaN=1&from=" + fullDateStr);
    }

    function getThermostatInfo() {
	
	var xmlhttp = new XMLHttpRequest();
	var infoJson = {};
	var resultValue = 0.1;

	xmlhttp.onreadystatechange = function() {
		if  ( xmlhttp.readyState == 4 ) {
			if  ( xmlhttp.status == 200  ) {
		   		infoJson = JSON.parse( xmlhttp.responseText );
				boilerModulationLevel = parseFloat(infoJson ["currentModulationLevel"]);
				writeBoilerValues();
			}
	    	}
	}
	xmlhttp.open( "GET", "http://" + ipToon + "/happ_thermstat?action=getThermostatInfo", true );
	xmlhttp.send();
    }
      
	function writeBoilerValues() {
		var infoJSson = {};
		infoJSson["sampleTime"] = sampleTime;
		infoJSson["boilerSetpoint"] = boilerSetpoint;
		infoJSson["roomTempSetpoint"] = roomTempSetpoint;
		infoJSson["boilerPressure"] = boilerPressure;
		infoJSson["roomTemp"] = roomTemp;
		infoJSson["boilerOutTemp"] = boilerOutTemp;
		infoJSson["boilerInTemp"] = boilerInTemp;
		infoJSson["boilerModulationLevel"] = boilerModulationLevel;
	 	var doc2 = new XMLHttpRequest();
   		doc2.open("PUT", "file:///var/volatile/tmp/boilervalues.txt");
   		doc2.send(JSON.stringify(infoJSson));
	}


    Timer {
	id: datetimeTimer
	interval: 60000  // update every minute 
	triggeredOnStart: true
	running: false
	repeat: true
	onTriggered: {
		var now = new Date().getTime() - 300000;  // 5 min interval
		var fullDateStr = i18n.dateTime(now, i18n.cent_yes) + " " + i18n.dateTime(now, i18n.time_yes);
		getBoilerParameter("thermstat_realTemps", "roomTemp", "rra=30days", fullDateStr);
		getBoilerParameter("thermstat_boilerRetTemp", "boilerInTemp", "rra=30days", fullDateStr);
		getBoilerParameter("thermstat_boilerTemp", "boilerOutTemp", "rra=30days", fullDateStr);
		getBoilerParameter("thermstat_boilerSetpoint", "boilerSetpoint", "rra=30days", fullDateStr);
		getBoilerParameter("thermstat_boilerChPressure", "boilerPressure", "rra=30days", fullDateStr);
		getBoilerParameter("thermstat_setpoint", "roomTempSetpoint", "rra=30days", fullDateStr);
		getThermostatInfo();
	    }
	}

    Timer {
	id: boilerMinutesTimer
	interval: 300000  // update every 5 minutes 
	triggeredOnStart: true
	running: false
	repeat: true
	onTriggered: {
		var now = new Date().getTime() - 3600000;  // 1 hour interval updates by Toon
		var now2 = new Date().getTime();

		var fullDateStr1 = i18n.dateTime(now, i18n.cent_yes) + " " + i18n.dateTime(now, i18n.time_yes) + "&to=" + i18n.dateTime(now, i18n.cent_yes) + " " + i18n.dateTime(now2, i18n.time_yes);
		getBoilerParameter("boiler_burner_minutes", "boilerBurnerMinutesNow", "rra=5yrhours", fullDateStr1);

		var fullDateStr3 = i18n.dateTime(now-86400000, i18n.cent_yes) + " 23:59&to=" + i18n.dateTime(now, i18n.cent_yes) + " 00:05";  // start of day
		getBoilerParameter("boiler_burner_minutes", "boilerBurnerMinutesDayStart", "rra=5yrhours", fullDateStr3);
	    }
	}
}
