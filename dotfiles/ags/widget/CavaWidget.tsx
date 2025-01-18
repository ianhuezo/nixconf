import { Variable, GLib } from "astal"
import { astalify, Gtk } from "astal/gtk4"
import Cava from "gi://AstalCava"

const DrawingArea = astalify<Gtk.DrawingArea, Gtk.DrawingArea.ConstructorProps>(Gtk.DrawingArea, {})

export interface CavaConfig {
	containerWidth?: number;  // Width of the container
	containerHeight?: number;  // Height of the container
}
export interface CavaProps {
	isVisible: Variable<boolean>
	config?: CavaConfig;
}

export default function CavaWidget({ isVisible, config = {} }: CavaProps) {
	let finalConfig = { ...config };
	const cavaValues: Variable<Array<number>> = Variable(Array(20).fill(0))
	let cava: Cava.Cava | null = null;
	let cavaListenerId: null | number = null
	let initializationTimeout: number | null = null;
	let widget: Gtk.DrawingArea | null = null;
	const align: "start" | "center" | "end" = "end"

	async function initializeCava(): Promise<void> {
		return new Promise((resolve) => {
			// Use a small timeout to let the UI render first
			initializationTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => {
				try {
					cava = Cava.get_default();
					resolve();
					return GLib.SOURCE_REMOVE; // Removes the timeout
				} catch (error) {
					print('Error initializing Cava:', error);
					return GLib.SOURCE_REMOVE;
				}
			});
		});
	}
	function initialize(setup: Gtk.DrawingArea) {
		setup.set_content_width(finalConfig.containerWidth ?? 300)
		setup.set_content_height(finalConfig.containerHeight ?? 40)
		setup.set_size_request(finalConfig.containerWidth ?? 300, finalConfig.containerHeight ?? 40)
		initializeCava().then(() => {
			if (cava && !cavaListenerId) {
				cavaListenerId = cava.connect("notify::values", () => {
					cavaValues.set([...cava!.get_values()]);
				});
			}
		});
		widget = setup
		widget.set_draw_func(drawBars)

	}
	cavaValues.subscribe(_value => {
		widget?.queue_draw()
	})

	function drawBars(widget: Gtk.DrawingArea, cr: any) {
		//code mostly stolen and modified slightly. nice affect, though :)
		//20 is amount of bars
		//40 is height of total widget
		if (!cava) {
			return GLib.SOURCE_REMOVE
		}
		const context = widget.get_style_context();
		const h = widget.get_allocated_height();
		const w = widget.get_allocated_width();

		const bg = {
			red: 0.09,   // #17
			green: 0.11, // #1D
			blue: 0.14,  // #23
			alpha: 0
		}

		const fg = {
			red: 1.0,    // #FF
			green: 0.62, // #9E
			blue: 0.39,  // #64
			alpha: 1
		}
		const radius = 0;

		cr.arc(radius, radius, radius, Math.PI, 3 * Math.PI / 2);
		cr.arc(w - radius, radius, radius, 3 * Math.PI / 2, 0);
		cr.arc(w - radius, h - radius, radius, 0, Math.PI / 2);
		cr.arc(radius, h - radius, radius, Math.PI / 2, Math.PI);
		cr.closePath();
		cr.clip();

		cr.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha);
		cr.rectangle(0, 0, w, h);
		cr.fill();

		cr.setSourceRGBA(fg.red, fg.green, fg.blue, fg.alpha);
		if (!true) {
			for (let i = 0; i < cavaValues.get().length; i++) {
				const height = h * (cavaValues.get()[i] / 1);
				let y = 0;
				let x = 0;
				switch (align) {
					case "start":
						y = 0;
						x = 0;
						break;
					case "center":
						y = (h - height) / 2;
						x = (w - height) / 2;
						break;
					case "end":
					default:
						y = h - height;
						x = w - height;
						break;
				}
				cr.rectangle(i * (w / cava!.get_bars()), y, w / cava!.get_bars(), height);
				cr.fill();
			}
		} else {
			let lastX = 0;
			let lastY = h - h * (cavaValues.get()[0] / 1);
			cr.moveTo(lastX, lastY);
			for (let i = 1; i < cavaValues.get().length; i++) {
				const height = h * (cavaValues.get()[i] / 1);
				let y = h - height;
				cr.curveTo(lastX + w / (cava!.get_bars() - 1) / 2, lastY, lastX + w / (cava!.get_bars() - 1) / 2, y, i * (w / (cava!.get_bars() - 1)), y);
				lastX = i * (w / (cava!.get_bars() - 1));
				lastY = y;
			}
			cr.lineTo(w, h);
			cr.lineTo(0, h);
			cr.fill();
		}

	}
	isVisible.subscribe(value => {
		if (!value) {
			destroyCava()
		}
	})

	function destroyCava() {
		if (cavaListenerId) {
			cava!.disconnect(cavaListenerId)
		}
		widget = null;
		isVisible.drop()
		cavaValues.drop()
		cavaListenerId = null;
	}

	return (
		<box >
			<DrawingArea
				cssClasses={["cava-widget"]}
				cssName="cava-widget"
				setup={initialize}
				onDestroy={destroyCava}
			/>
		</box>
	)
}
