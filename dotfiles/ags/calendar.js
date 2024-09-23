//system: "base16"
//name: "Tokyo City Dark"
//author: "Michaël Ball"
//variant: "dark"
//palette:
//  base00: "171D23"
//  base01: "1D252C"
//  base02: "28323A"
//  base03: "526270"
//  base04: "B7C5D3"
//  base05: "D8E2EC"
//  base06: "F6F6F8"
//  base07: "FBFBFD"
//  base08: "F7768E"
//  base09: "FF9E64"
//  base0A: "B7C5D3"
//  base0B: "9ECE6A"
//  base0C: "89DDFF"
//  base0D: "7AA2F7"
//  base0E: "BB9AF7"
//  base0F: "BB9AF7"
//
//calendar widget.  Has two components, a button and a calendar in a box.
//when button is clicked the box renders the calendar, else no
const date = Variable('', {
    poll: [1000, 'date "+%A %b %d | %I:%M %p"'],
})
let showCalendar = Variable(false);

const defaultBackdropColor = "#171D23";
const defaultTextColor = "#FBFBFD";
const borderColor = "#BB9AF7";

function dateBarCss(){
	return {
		css:
		`
		background-color: ${defaultBackdropColor};
		color: ${defaultTextColor};
		padding-top: 5px;
		padding-bottom: 5px;
		border-radius: 10px;
		min-height: 15px;
		border: 2px solid ${borderColor};
		box-shadow: 0 0 2px ${borderColor};
		`
	}
}
//TODO Calendar App?
function calendarCss () {
	return {
		css:
		`
		  background-color: ${defaultBackdropColor};
		  color: ${defaultTextColor};
		`
	};
};
function calendarButtonCss(){
	return {
	   css:
	   `
		all: unset;
		background-color: #171D23;
		padding: 5px 10px;
		border-radius: 10px;
		color: #FBFBFD
	   `
	};
};
function getCalendar() {
  return Widget.Calendar({
    showDayNames: true,
    showDetails: true,
    showHeading: true,
    ...calendarCss(),
  })
}
const keyGrabberWindowForClose = () => Widget.Window({
   monitor: 0,
   name: `keygrabberwindow`,
   exclusivity: 'ignore',
   anchor: ['top', 'bottom', 'left', 'right'],
   visible: showCalendar.bind().as(x => x == true),
   child: Widget.EventBox({
       onPrimaryClick: () => { showCalendar.value = false}
   }),
   css: 'opacity: 0;',
   layer: 'top',
})

const renderCalendarWindow = () => Widget.Window({
	monitor: 0,
	name: `calendar${0}`,
	exclusivity: 'normal',
	anchor: ['top', 'left', 'right'],
	margins: [0, 10, 0, 1700],
	visible: showCalendar.bind(),
	layer: 'overlay',
	child: getCalendar()
})

function ClickableCalendarWidget(){
   renderCalendarWindow()
   const button = Widget.Button({
	child: Widget.Label({label: date.bind() }),
	onClicked: () => {
		showCalendar.value = !showCalendar.value
		if(showCalendar.value){
			keyGrabberWindowForClose();
		};
	},
	...calendarButtonCss()
   })
   return button
}

export const DateBar = () => Widget.Box({
	spacing: 8,
	homogeneous: false,
	hpack: "end",
	vertical: false,
	...dateBarCss(),
	children:[
		ClickableCalendarWidget(),
	]
})

