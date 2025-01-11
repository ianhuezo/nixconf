import { App, Astal, Gtk, Gdk } from "astal/gtk4"
import { Variable, GLib, bind } from "astal"
import style from "style.scss"
import Mpris from "gi://AstalMpris"
import { astalify, type ConstructProps } from "astal/gtk4"

function MusicWidget({ player }: { player: Mpris.Player }) {
	const { START, END } = Gtk.Align

	const title = bind(player, "title").as(t =>
		t || "Unknown Track")

	const artist = bind(player, "artist").as(a =>
		a || "Unknown Artist")

	const coverArt = bind(player, "coverArt").as(c =>
		`background-image: url('${c}')`)

	//const playerIcon = bind(player, "entry").as(e =>
	//Astal.Icon.lookup_icon(e) ? e : "audio-x-generic-symbolic")

	const position = bind(player, "position").as(p => player.length > 0
		? p / player.length : 0)

	const playIcon = bind(player, "playbackStatus").as(s =>
		s === Mpris.PlaybackStatus.PLAYING
			? "media-playback-pause-symbolic"
			: "media-playback-start-symbolic"
	)

	return (
		<box
			css={coverArt.get()}
		>
			<label label={title.get()} />
		</box>
	)

}


export default function Bar(gdkmonitor: Gdk.Monitor) {
	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
	const mpris = Mpris.Mpris.new()
	const currentPlayer = Variable("")
	const playerAddedListener = currentPlayer.observe(mpris, "player-added", () => {
		print("player added")
		return Mpris.Mpris.get_default().get_players()[0].title
	})
	const playerClosedListener = currentPlayer.observe(mpris, "player-closed", () => {
		print("player removed")
		return "closed :("
	})



	return <window
		visible
		cssClasses={["Bar"]}
		gdkmonitor={gdkmonitor}
		exclusivity={Astal.Exclusivity.EXCLUSIVE}
		anchor={TOP | LEFT | RIGHT}
		application={App}>
		<centerbox cssName="centerbox">
			<label label={bind(currentPlayer).as((value) => `${value}`)} />
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
