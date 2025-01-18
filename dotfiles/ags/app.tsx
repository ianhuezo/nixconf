import { App, Astal, Gdk, Gtk } from "astal/gtk4"
import { Variable, bind } from "astal"
import style from "style.scss"
import Mpris from "gi://AstalMpris"
import { astalify } from "astal/gtk4"
import TextMarquee, { MarqueeConfig } from "./widget/TextMarquee"
import Cava from "gi://AstalCava"
import CavaWidget from "./widget/CavaWidget"
import GdkWayland from "gi://GdkWayland?version=4.0"

const Grid = astalify<Gtk.Grid, Gtk.Grid.ConstructorProps>(Gtk.Grid, {
	getChildren(self) { return [] },
	setChildren(self, children) { },
})

function CoverArtWidget(coverArt: Variable<string>) {
	let widget: Gtk.Image | null = null;
	const coverArtFunc = bind(coverArt).as(value => {
		if (value == undefined) return ""
		return value;
	})
	return <image
		name="cover-art-image"
		visible={bind(coverArt).as(value => {
			if (!value) return false;
			return value.length > 0;
		})}
		file={coverArtFunc}
		pixelSize={40}
	/>
}

const MusicInfoWidget = () => {
	const mpris = Mpris.Mpris.new()
	const currentPlayer: Variable<Mpris.Player | undefined> = Variable(undefined)
	const allPlayers: Variable<Array<Mpris.Player>> = Variable(Mpris.Mpris.new().get_players())
	const title: Variable<string> = Variable("")
	const artist: Variable<string> = Variable("")
	const coverArt: Variable<string> = Variable("")
	const playbackStatus: Variable<Mpris.PlaybackStatus> = Variable(Mpris.PlaybackStatus.STOPPED)
	const isMusicBarDisplayed: Variable<boolean> = Variable(false)
	const isTextDisplayed: Variable<boolean> = Variable(true)
	const musicProps = {
		title: title,
		artist: artist,
		coverArt: coverArt,
		playbackStatus: playbackStatus
	};
	const initialValues = {
		title: Variable(""),
		artist: Variable(""),
		coverArt: Variable(""),
		playbackStatus: Variable(Mpris.PlaybackStatus.STOPPED)
	}
	const signalIds: Variable<Array<{ busName: string, signalId: number }>> = Variable([])
	//Initialization of player properties
	mpris.connect('player-added', (mpris, player) => {
		connectPlayerSignals(player, currentPlayer, title, musicProps, signalIds)
	});

	mpris.connect('player-closed', (mpris, player) => {
	});
	allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title, musicProps, signalIds))
	currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
	for (const [key, value] of Object.entries(musicProps)) {
		value.set(currentPlayer.get() ? currentPlayer.get()[key] : "")
	}
	function toggleMusicPlayerText() {
		isMusicBarDisplayed.set(!isMusicBarDisplayed.get())
		isTextDisplayed.set(!isTextDisplayed.get())
	}
	const artistConfig: MarqueeConfig = {
		startDelay: 0,
		pauseDuration: 200,
		containerWidth: 300,
		containerHeight: 20,
		pixelsPerFrame: 0.2,
		boxCssClasses: ["artist-container"],
		inscriptionCssClasses: ["music-artist"],
		visible: isMusicBarDisplayed
	};
	const songConfig: MarqueeConfig = {
		visible: isTextDisplayed
	}
	function GridWidget() {
		return <Grid
			cssClasses={["grid-container"]}
			setup={(self) => {
				self.set_row_spacing(0)
				self.attach(TextMarquee({ text: musicProps.title, config: songConfig }), 0, 0, 1, 1);
				self.attach(TextMarquee({ text: musicProps.artist, config: artistConfig }), 0, 1, 1, 1);
			}}
		/>

	}
	return (
		<box>
			<button cssClasses={["art-toggle"]} onClicked={toggleMusicPlayerText}>{CoverArtWidget(coverArt)}</button>
			<box name="music-info" cssClasses={["music-info"]}
				setup={(setup) => {
					setup.set_size_request(300, -1)
				}}
			>
				{bind(isMusicBarDisplayed).as(value => {
					return value ? CavaWidget({ isVisible: isMusicBarDisplayed }) : GridWidget()
				})}
			</box>

		</box>
	)
};


function connectPlayerSignals(player: Mpris.Player, currentPlayer: Variable<Mpris.Player | undefined>, title: Variable<string>, musicProps: MusicProperties, signalIds: Variable<Array<{ busName: string, signalId: number }>>) {
	const notifiers = [
		'notify::title',
		'notify::artist',
		'notify::cover-art',
		'notify::playback-status'
	]
	notifiers.forEach(notifier => {
		//youtube is a big problem.  Waay to many notifiers
		const signalId = player.connect(notifier, (_player) => {
			for (const [key, value] of Object.entries(musicProps)) {
				//if (currentPlayer.get() != player && currentPlayer.get()?.playbackStatus != Mpris.PlaybackStatus.PLAYING) continue;
				value.set(_player[key])
			}
		});
		signalIds.set([...signalIds.get(), { busName: player.get_bus_name(), signalId: signalId }])
	})
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

//these are all props related to Mpris player that will be used
export type MusicProperties = {
	title: Variable<string>,
	artist: Variable<string>,
	coverArt: Variable<string>
	playbackStatus: Variable<Mpris.PlaybackStatus>
}

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
			<label label="" />
			<MusicInfoWidget />
			<label label="" />
		</centerbox>
	</window>
}

function main() {

	for (const monitor of App.get_monitors()) {
		if (monitor.model == "VG278") {
			return Bar(monitor)
		}
	}


}


App.start({
	css: style,
	main
})
