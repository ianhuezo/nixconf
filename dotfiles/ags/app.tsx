import { App, Astal, Gtk, Gdk } from "astal/gtk4"
import { Variable, GLib, bind } from "astal"
import style from "style.scss"
import Mpris from "gi://AstalMpris"
import { astalify, type ConstructProps } from "astal/gtk4"

function connectPlayerSignals(player: Mpris.Player, currentPlayer: Variable<Mpris.Player | undefined>, title: Variable<string>) {
	// Connect to metadata changes
	player.connect('notify::title', (player) => {
		if (player.playbackStatus == Mpris.PlaybackStatus.PLAYING) {
			title.set(player.title);
		}
	});

	player.connect('notify::artist', (player) => {
		if (player.playbackStatus == Mpris.PlaybackStatus.PLAYING) {

		}
	});

	// Connect to playback status changes
	player.connect('notify::playback-status', (player) => {
		if (player.playbackStatus == Mpris.PlaybackStatus.PLAYING) {
			currentPlayer.set(player)
		}
	});
}

function disconnectPlayerSignals(player: Mpris.Player) {
	if (player == undefined) return;
	player.disconnect('notify::title', (player) => { });
	player.disconnect('notify::artist', (player) => { });
	player.disconnect('notify::playback-status', (player) => { });
}

function getCurrentPlayer({ players }: { players: Array<Mpris.Player> }) {
	if (players.length == 0) return undefined;
	const onlyPlayingPlayers = players.filter(player => {
		return player.get_playback_status() == Mpris.PlaybackStatus.PLAYING
	});
	if (onlyPlayingPlayers.length == 0) return undefined;
	const spotifyPlayer = onlyPlayingPlayers.filter(player => {
		return player.get_bus_name().toLowerCase().includes("spotify")
	})
	if (spotifyPlayer.length > 0) return spotifyPlayer[0];
	return onlyPlayingPlayers[0]
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
	const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
	const mpris = Mpris.Mpris.new()
	const currentPlayer: Variable<Mpris.Player | undefined> = Variable(undefined)
	const allPlayers: Variable<Array<Mpris.Player>> = Variable(Mpris.Mpris.new().get_players())
	const title: Variable<string> = Variable("")
	mpris.connect('player-added', (mpris, busName) => {
		allPlayers.get().forEach(player => disconnectPlayerSignals(player));
		allPlayers.set(Mpris.Mpris.get_default().get_players())
		allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title))
		currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
		title.set(currentPlayer.get() ? currentPlayer.get().title : "")
	});

	mpris.connect('player-closed', (mpris, busName) => {
		allPlayers.get().forEach(player => disconnectPlayerSignals(player));
		allPlayers.set(Mpris.Mpris.get_default().get_players())
		if (allPlayers.get().length > 0) {
			currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
		} else {
			currentPlayer.set(undefined)
			title.set("")
		}
	});
	allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title))
	currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
	title.set(currentPlayer.get() != undefined ? currentPlayer.get().title : "")


	return <window
		visible
		cssClasses={["Bar"]}
		gdkmonitor={gdkmonitor}
		exclusivity={Astal.Exclusivity.EXCLUSIVE}
		anchor={TOP | LEFT | RIGHT}
		application={App}>
		<centerbox cssName="centerbox">
			<label
				label={bind(title).as((value) => {
					if (value == undefined) return "";
					return title.get()
				})}
			/>
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
