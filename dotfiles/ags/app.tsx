import { App, Astal, Gdk, Gtk, hook, Widget } from "astal/gtk4"
import { Variable, GLib, bind, Binding } from "astal"
import style from "style.scss"
import Mpris from "gi://AstalMpris"
import { astalify, type ConstructProps } from "astal/gtk4"
import Pango from "gi://Pango?version=1.0"


//on startup, doesn't work.  
//

const Grid = astalify<Gtk.Grid, Gtk.Grid.ConstructorProps>(Gtk.Grid, {
	getChildren(self) { return [] },
	setChildren(self, children) { },
})

const Inscription = astalify<Gtk.Inscription, Gtk.Inscription.ConstructorProps>(Gtk.Inscription, {})

interface MarqueeConfig {
	startDelay?: number;  // Delay before animation starts in ms
	pauseDuration?: number;  // How long to pause at each end
	containerWidth?: number;  // Width of the container
	containerHeight?: number;  // Height of the container
	pixelsPerFrame?: number;  // Speed of the scrolling
	boxCssClasses?: string[];  // CSS classes for the container box
	inscriptionCssClasses?: string[];  // CSS classes for the inscription
}

interface TextMarqueeProps {
	text: Variable<string>;
	config?: MarqueeConfig;
}

const DEFAULT_CONFIG: MarqueeConfig = {
	startDelay: 0,
	pauseDuration: 200,
	containerWidth: 300,
	containerHeight: 20,
	pixelsPerFrame: 0.2,
	boxCssClasses: ["title-container"],
	inscriptionCssClasses: ["music-title"]
};

function TextMarquee({ text, config = {} }: TextMarqueeProps) {
	// Merge default config with provided config
	const finalConfig = { ...DEFAULT_CONFIG, ...config };
	// State variables
	let increasing = true;
	let pauseCounter = 0;
	let tickCallbackId: number | null = null;
	let currentAlignment = Variable(0);
	let nextText = "THISISHTEASDFJFJDSAKFJLSD"
	let widget: Gtk.Inscription | null = null;
	text.subscribe(_value => {
		if (tickCallbackId) {
			widget?.remove_tick_callback(tickCallbackId)
			tickCallbackId = null
		}
		currentAlignment.set(0)
		tickCallbackId = widget?.add_tick_callback(createTickCallback(widget)) || null;
		widget?.queue_resize()
	})

	function createTickCallback(setup: Gtk.Inscription) {
		return () => {
			if (text.get().length == 0) {
				return GLib.SOURCE_CONTINUE;
			}
			if (nextText != text.get()) {
				GLib.timeout_add(GLib.PRIORITY_DEFAULT, finalConfig.startDelay!, () => {
					nextText = text.get()
					increasing = true;
					pauseCounter = 0;
					currentAlignment.set(0)
					return GLib.SOURCE_REMOVE;
				});
				return GLib.SOURCE_CONTINUE;
			}


			const layout = setup.create_pango_layout(nextText);
			const [text_width, text_height] = layout.get_pixel_size();

			if (text_width && text_width > finalConfig.containerWidth!) {
				const total_scroll_distance = text_width - finalConfig.containerWidth!;
				const rate = finalConfig.pixelsPerFrame! / total_scroll_distance;

				if ((currentAlignment.get() >= 1.0 || currentAlignment.get() <= 0.0) &&
					pauseCounter < finalConfig.pauseDuration!) {
					pauseCounter++;
					return GLib.SOURCE_CONTINUE;
				}

				if (pauseCounter >= finalConfig.pauseDuration!) {
					pauseCounter = 0;
				}

				if (currentAlignment.get() >= 1) increasing = false;
				if (currentAlignment.get() <= 0) increasing = true;
				if (currentAlignment.get() === -1) return GLib.SOURCE_CONTINUE;

				if (increasing) {
					currentAlignment.set(Math.min(1, currentAlignment.get() + rate));
				} else {
					currentAlignment.set(Math.max(0, currentAlignment.get() - rate));
				}

				// Reset conditions
				if (rate === 0 || rate > 1 || rate >= 0.5 || rate < 0) {
					currentAlignment.set(0)
				}
			}
			return GLib.SOURCE_CONTINUE;
		};
	}

	function setupMarquee(setup: Gtk.Inscription) {
		setup.set_min_lines(1)
		tickCallbackId = setup.add_tick_callback(createTickCallback(setup))
		widget = setup;
	}

	function cleanupMarquee(setup: Gtk.Inscription) {
		if (tickCallbackId !== null) {
			setup.remove_tick_callback(tickCallbackId);
			tickCallbackId = null;
		}
		currentAlignment.set(0);
	}


	return (
		<box cssClasses={finalConfig.boxCssClasses} name="marquee-container">
			<Inscription
				name="marquee-text"
				setup={setupMarquee}
				onDestroy={cleanupMarquee}
				cssClasses={finalConfig.inscriptionCssClasses}
				width_request={finalConfig.containerWidth!}
				text={bind(text).as(value => value)}
				xalign={bind(currentAlignment).as(value => value)}
				halign={Gtk.Align.START}

			/>
		</box>
	);
}




function ArtistWidget(artist: Variable<string>) {
	let increasing = true;
	let pauseCounter = 0;
	const pauseDuration = 60;
	let tickCallbackId: number | null = null;
	let currentAlignment = 0;
	return (
		<box
			cssClasses={["artist-container"]} name="artist-container">
			<Inscription
				name="music-artist-label"
				cssClasses={["music-artist"]}
				setup={(setup) => {
					setup.set_size_request(300, 16);
					//@ts-ignore
					const tickCallback = () => {
						if (currentAlignment === -1) {
							increasing = true
							pauseCounter = 0
							currentAlignment = 0
							setup.set_xalign(0)
							return GLib.SOURCE_CONTINUE
						}
						currentAlignment = setup.get_xalign()
						if (setup.text.length == 0) {
							return GLib.SOURCE_REMOVE
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

							if ((currentAlignment >= 1.0 || currentAlignment <= 0.0) && pauseCounter < pauseDuration) {
								pauseCounter++
								return GLib.SOURCE_CONTINUE
							}
							if (pauseCounter >= pauseDuration) pauseCounter = 0;
							// Convert desired pixel movement to xalign value
							if (currentAlignment >= 1) increasing = false;
							//@ts-ignore
							if (currentAlignment <= 0) increasing = true;
							if (currentAlignment === -1) return GLib.SOURCE_CONTINUE
							//@ts-ignore
							if (increasing == true) {
								setup.set_xalign(Math.min(1.0, currentAlignment + rate));
							}
							if (increasing == false) {
								setup.set_xalign(Math.max(0.0, currentAlignment - rate));
							}
							if (rate === 0) currentAlignment = -1;
							if (rate >= 0.5) currentAlignment = -1;
							if (rate < 0) currentAlignment = -1;

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
				text={bind(artist).as((value) => {
					currentAlignment = -1;
					if (value == undefined) return "";
					return artist.get()
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
	const playbackStatus: Variable<Mpris.PlaybackStatus> = Variable(Mpris.PlaybackStatus.STOPPED)
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
	//Initialization of player properties
	mpris.connect('player-added', (mpris, player) => {
		connectPlayerSignals(player, currentPlayer, title, musicProps)
	});

	mpris.connect('player-closed', (mpris, player) => {
		disconnectPlayerSignals(player, currentPlayer, musicProps, initialValues);
	});
	allPlayers.get().forEach(player => connectPlayerSignals(player, currentPlayer, title, musicProps))
	currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
	for (const [key, value] of Object.entries(musicProps)) {
		value.set(currentPlayer.get() ? currentPlayer.get()[key] : "")
	}
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
						self.attach(TextMarquee({ text: musicProps.title }), 0, 0, 1, 1);
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
		player.connect(notifier, (_player) => {
			for (const [key, value] of Object.entries(musicProps)) {
				//if (currentPlayer.get() != player && currentPlayer.get()?.playbackStatus != Mpris.PlaybackStatus.PLAYING) continue;
				value.set(_player[key])
			}
		});
	})
}

function disconnectPlayerSignals(player: Mpris.Player, currentPlayer: Variable<Mpris.Player | undefined>, musicProps: MusicProperties, initialValues: MusicProperties) {
	if (player == undefined) return;
	const notifiers = [
		'notify::title',
		'notify::artist',
		'notify::cover-art',
		'notify::playback-status'
	]
	notifiers.forEach(notifier => {
		//@ts-ignore
		player.disconnect(notifier, (_player) => {
			for (const [key, value] of Object.entries(musicProps)) {
				value.set(initialValues[key].get())
			}
		});
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

	const monitors = App.get_monitors();
	return Bar(monitors[1]);
}


App.start({
	css: style,
	main
})
