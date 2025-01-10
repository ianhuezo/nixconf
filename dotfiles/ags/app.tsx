import { App, Astal, Gtk, Gdk } from "astal/gtk4"
import { Variable } from "astal"
import style from "style.scss"

const time = Variable("").poll(1000, "date")

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

	return <window
		visible
		cssClasses={["Bar"]}
		gdkmonitor={gdkmonitor}
		exclusivity={Astal.Exclusivity.EXCLUSIVE}
		anchor={TOP | LEFT | RIGHT}
		application={App}>
		<centerbox cssName="centerbox">

		</centerbox>
	</window>
}

function main() {

	const monitors = App.get_monitors();
	return Bar(monitors[1]);
}


App.start({
	css: style,
	main
})
