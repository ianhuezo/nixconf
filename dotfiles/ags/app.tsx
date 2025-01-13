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

interface MusicInfoProps {
	artist?: string | Binding<string>;
	title?: string | Binding<string>;
}

function ArtistWidget(artist: Variable<string>) {
	return <label
		cssClasses={["music-artist"]}
		label={bind(artist).as((value) => {
			if (value == undefined) return "";
			return artist.get()
		})}
	/>
}

function TitleWidget(title: Variable<string>) {
	return <label
		cssClasses={["music-title"]}
		label={bind(title).as((value) => {
			if (value == undefined) return "";
			return title.get()
		})}
		maxWidthChars={20}
	/>
}

function CoverArtWidget(coverArt: Variable<string>) {
	const coverArtFunc = bind(coverArt).as(value => {
		return value;
	})
	return <image
		visible={bind(coverArt).as(value => {
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
			currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
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
			<box cssClasses={["music-info"]} vexpand={true}>
				<Grid
					setup={(self) => {
						self.attach(ArtistWidget(artist), 0, 0, 1, 1);
						self.attach(TitleWidget(title), 0, 1, 1, 1);
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
		player.connect(notifier, (player) => {
			for (const [key, value] of Object.entries(musicProps)) {
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
			currentPlayer.set(getCurrentPlayer({ players: allPlayers.get() }))
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
	const coverArtFunc = bind(coverArt).as(value => {
		return value;
	})
	//TODO: Go to whatever screen is playing the music by clicking the image

	return <window
		visible
		cssClasses={["Bar"]}
		gdkmonitor={gdkmonitor}
		exclusivity={Astal.Exclusivity.EXCLUSIVE}
		anchor={TOP | LEFT | RIGHT}
		application={App}>
		<centerbox cssName="centerbox">
			<MusicInfoWidget />
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
