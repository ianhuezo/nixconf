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
import { DateBar } from './calendar.js' //@ignore

//create a toolbar.  Toolbar includes Wi-Fi, Bluetooth, CPU,

const Bar = (monitor = 0) => {
    const allWidgets = Widget.Box({
	spacing: 8,
	homogeneous: false,
	hpack: "end",
	vertical: false,
	children:[
		DateBar()
	]
    })
    return Widget.Window({
           monitor,
           name: `bar1${monitor}`,
           exclusivity: 'exclusive',
           margins: [5, 10],
           anchor: ['top', 'left', 'right'],
	   child: allWidgets,
    })
}

App.applyCss(`
window {
    background-color: transparent;
}
`)
App.config({
    windows: [
        Bar(0), // can be instantiated for each monitor
    ],
})
