import { Gtk } from "astal/gtk4"
import { Variable, GLib, bind } from "astal"
import { astalify } from "astal/gtk4"

const Inscription = astalify<Gtk.Inscription, Gtk.Inscription.ConstructorProps>(Gtk.Inscription, {})

export interface MarqueeConfig {
	startDelay?: number;  // Delay before animation starts in ms
	pauseDuration?: number;  // How long to pause at each end
	containerWidth?: number;  // Width of the container
	containerHeight?: number;  // Height of the container
	pixelsPerFrame?: number;  // Speed of the scrolling
	boxCssClasses?: string[];  // CSS classes for the container box
	inscriptionCssClasses?: string[];  // CSS classes for the inscription
	visible?: Variable<boolean>;
}

export interface TextMarqueeProps {
	text: Variable<string>;
	config?: MarqueeConfig;
}

export const DEFAULT_CONFIG: MarqueeConfig = {
	startDelay: 0,
	pauseDuration: 200,
	containerWidth: 300,
	containerHeight: 20,
	pixelsPerFrame: 0.2,
	boxCssClasses: ["title-container"],
	inscriptionCssClasses: ["music-title"],
	visible: Variable(true)
};

export default function TextMarquee({ text, config = {} }: TextMarqueeProps) {
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
		currentAlignment.drop()
		if (tickCallbackId) {
			currentAlignment.drop()
			widget?.remove_tick_callback(tickCallbackId)
			tickCallbackId = null
		}
		currentAlignment.set(0)
		tickCallbackId = widget?.add_tick_callback(createTickCallback(widget)) || null;
		widget?.queue_resize()
	})
	finalConfig.visible?.subscribe(value => {
		if (!value && widget) {
			cleanupMarquee(widget)
		}
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
					text.drop()
					return GLib.SOURCE_REMOVE;
				});
				return GLib.SOURCE_CONTINUE;
			}



			const layout = setup.create_pango_layout(nextText);
			const [text_width, _text_height] = layout.get_pixel_size();

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
		currentAlignment.set(0);
		if (tickCallbackId !== null) {
			setup.remove_tick_callback(tickCallbackId);
			tickCallbackId = null;
		}
		widget = null;
		text.drop()
		currentAlignment.drop()
		finalConfig.visible?.drop()
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

