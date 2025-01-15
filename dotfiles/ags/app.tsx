import { App, Astal, Gdk, Gtk, hook, Widget } from "astal/gtk4"
import { Variable, GLib, bind, Binding } from "astal"
import style from "style.scss"
import Mpris from "gi://AstalMpris"
import { astalify, type ConstructProps } from "astal/gtk4"


type GridProps = ConstructProps<Gtk.Grid, Gtk.Grid.ConstructorProps>
const Grid = astalify<Gtk.Grid, Gtk.Grid.ConstructorProps>(Gtk.Grid, {
	getChildren(self) { return [] },
	setChildren(self, children) { },
})

type InscriptionProps = ConstructProps<Gtk.Inscription, Gtk.Inscription.ConstructorProps>
const Inscription = astalify<Gtk.Inscription, Gtk.Inscription.ConstructorProps>(Gtk.Inscription, {})

interface MusicInfoProps {
	artist?: string | Binding<string>;
	title?: string | Binding<string>;
}

function ScrollBackAndForthCallback() {

}

function ArtistWidget(artist: Variable<string>) {
	return (
		<box setup={(setup) => {
		}}
			cssClasses={["artist-container"]} name="artist-container">
			<Inscription
				name="music-artist-label"
				cssClasses={["music-artist"]}
				setup={(setup) => {
					setup.set_size_request(300, -1);
				}}
				text={bind(artist).as((value) => {
					if (value == undefined) return "";
					return artist.get()
				})}
			/>
		</box>
	)
}

function TitleWidget(title: Variable<string>) {
	let increasing = true;
	let currentText = "";
	let pauseCounter = 0;
	const pauseDuration = 60;
	let tickCallbackId: number | null = null;



	return (
		<box setup={(setup) => {
		}}
			cssClasses={["title-container"]} name="title-container">
			<Inscription
				name="music-title-label"
				setup={(setup) => {
					setup.set_size_request(300, -1);
					//@ts-ignore
					const tickCallback = () => {
						if (currentText != setup.text && setup.get_xalign() != 0) {
							currentText = setup.text
							increasing = true
							pauseCounter = 0
							setup.set_xalign(0)
							return GLib.SOURCE_CONTINUE
						}
						const layout = setup.create_pango_layout(setup.text)
						const text_width = layout.get_pixel_size().at(0)
						const container_width = setup.get_width()
						if (text_width && text_width > container_width) {
							//rate of change will be 0.01 maybe?
							//@ts-ignore
							const pixels_per_frame = 0.3 // Adjust this value to control speed
							const total_scroll_distance = text_width - container_width
							const rate = pixels_per_frame / total_scroll_distance

							if ((setup.get_xalign() >= 1 || setup.get_xalign() <= 0) && pauseCounter < pauseDuration) {
								pauseCounter++
								return GLib.SOURCE_CONTINUE
							}
							if (pauseCounter >= pauseDuration) pauseCounter = 0;
							// Convert desired pixel movement to xalign value
							if (setup.get_xalign() >= 1) increasing = false;
							//@ts-ignore
							if (setup.get_xalign() <= 0) increasing = true;
							//@ts-ignore
							if (increasing == true) {
								setup.set_xalign(Math.min(1.0, setup.get_xalign() + rate));
							}
							if (increasing == false) {
								setup.set_xalign(Math.max(0.0, setup.get_xalign() - rate));
							}

						}

						return GLib.SOURCE_CONTINUE
					}
					tickCallbackId = setup.add_tick_callback(tickCallback);
				}}
				onDestroy={(setup) => {
					if (tickCallbackId !== null) {
						setup.remove_tick_callback(tickCallbackId);
						tickCallbackId = null;
					}
				}}

				cssClasses={["music-title"]}
				text={bind(title).as((value) => {
					if (value == undefined) return "";
					return title.get()
				})}
			/>
		</box>
	)
}

function CoverArtWidget(coverArt: Variable<string>) {
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
	const musicProps = {
		title: title,
		artist: artist,
		coverArt: coverArt
	};
	//Initialization of player properties
	mpris.connect('player-added', (mpris, busName) => {
		allPlayers.get().forEach(player => disconnectPlayerSignals(player));
		allPlayers.set(Mpris.Mpris.get_default().get_players())
		allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title, musicProps))
		currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
		for (const [key, value] of Object.entries(musicProps)) {
			value.set(currentPlayer.get() ? currentPlayer.get()[key] : "")
		}
	});

	mpris.connect('player-closed', (mpris, busName) => {
		allPlayers.get().forEach(player => disconnectPlayerSignals(player));
		allPlayers.set(Mpris.Mpris.get_default().get_players())
		if (allPlayers.get().length > 0) {
			currentplayer.set(getcurrentplayer({ players: allplayers.get() }))
		} else {
			currentPlayer.set(undefined)
			for (const [key, value] of Object.entries(musicProps)) {
				value.set(currentPlayer.get() ? currentPlayer.get()[key] : "")
			}
		}
	});
	allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title, musicProps))
	currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
	for (const [key, value] of Object.entries(musicProps)) {
		value.set(currentPlayer.get() ? currentPlayer.get()[key] : "")
	}
	//Now create the grid to attach all the relevant icons


	return (
		<box>
			{CoverArtWidget(coverArt)}
			<box name="music-info" cssClasses={["music-info"]}
				setup={(setup) => {
					setup.set_size_request(300, -1)
				}}
			>
				<Grid
					cssClasses={["grid-container"]}
					setup={(self) => {
						self.set_row_spacing(0)
						self.attach(TitleWidget(title), 0, 0, 1, 1);
						self.attach(ArtistWidget(artist), 0, 1, 1, 1);
					}}
				/>
			</box>
		</box>
	)
};


function connectPlayerSignals(player: Mpris.Player, currentPlayer: Variable<Mpris.Player | undefined>, title: Variable<string>, musicProps: MusicProperties) {
	const notifiers = [
		'notify::title',
		'notify::artist',
		'notify::cover-art',
		'notify::playback-status'
	]
	notifiers.forEach(notifier => {
		//youtube is a big problem.  Waay to many notifiers
		player.connect(notifier, (player) => {
			for (const [key, value] of Object.entries(musicProps)) {
				//if (currentPlayer.get() != player && currentPlayer.get()?.playbackStatus != Mpris.PlaybackStatus.PLAYING) continue;
				value.set(player[key])
			}
		});
	})
}

function disconnectPlayerSignals(player: Mpris.Player) {
	if (player == undefined) return;
	const notifiers = [
		'notify::title',
		'notify::artist',
		'notify::cover-art',
		'notify::playback-status'
	]
	notifiers.forEach(notifier => {
		//@ts-ignore
		player.disconnect(notifier, (_player) => { });
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

	const monitors = App.get_monitors();
	return Bar(monitors[1]);
}


App.start({
	css: style,
	main
})
