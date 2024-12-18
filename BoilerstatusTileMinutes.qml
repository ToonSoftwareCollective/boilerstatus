import QtQuick 2.1
import qb.components 1.0

/*
 * Tile for showing boiler burner minutes of today 
 * usefull for Spanish users without gas meter.
 *
 */

Tile {
    id: boilerBurnerMinutesTile
    
    property bool dimState: screenStateController.dimmedColors
	

	Text {
	    id: burnerLabel
	    
	    text: "Boiler burning today:"
	    anchors {
		top: parent.top
		left: parent.left
		leftMargin: isNxt ? 13 : 10
		topMargin: isNxt ? 13 : 10
	    }
	    font {
		family: qfont.bold.name
		pixelSize: isNxt ? 24 : 18
	    }
	    color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
	}

	Text { 
	    id: burnerMinutes
	    
	    text: i18n.number( Number( app.boilerBurnerMinutesNow - app.boilerBurnerMinutesDayStart ), 0 ) + " min"
	    anchors {
		top: burnerLabel.bottom
		topMargin: isNxt ? 12 : 15
		left: burnerLabel.left
		leftMargin: isNxt ? 75 : 60
	    }
	    font {
		family: qfont.bold.name
		pixelSize: isNxt ? 24 : 18
	    }
	    color: (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : (typeof dimmableColors !== 'undefined') ? dimmableColors.clockTileColor : colors.clockTileColor
	}
}
