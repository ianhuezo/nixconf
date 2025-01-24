import { Variable, GLib } from "astal"
import { astalify } from "astal/gtk4"
import Cava from "gi://AstalCava"
import Gtk from 'gi://Gtk?version=4.0';
import Cairo from 'cairo'

const DrawingArea = astalify<Gtk.DrawingArea, Gtk.DrawingArea.ConstructorProps>(Gtk.DrawingArea, {})

Gtk.init()

export interface CavaConfig {
	containerWidth?: number;  // Width of the container
	containerHeight?: number;  // Height of the container
}
export interface CavaProps {
	isVisible: Variable<boolean>
	config?: CavaConfig;
}

export default function CavaWidget({ isVisible, config = {} }: CavaProps) {
	const finalConfig = { ...config };
	let cava: Cava.Cava | null = null;
	let cavaListenerId: null | number = null
	let valueListener: Variable<boolean> = Variable(false)
	// Subscription cleanup handler
	let visibilitySubscription: null | (() => void) = null;
	const align: "start" | "center" | "end" = "end"

	async function initializeCava(): Promise<void> {
		return new Promise((resolve) => {
			// Use a small timeout to let the UI render first
			GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => {
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
	async function initialize(setup: Gtk.DrawingArea) {
		setup.set_content_width(finalConfig.containerWidth ?? 300)
		setup.set_content_height(finalConfig.containerHeight ?? 40)
		setup.set_size_request(finalConfig.containerWidth ?? 300, finalConfig.containerHeight ?? 40)
		await initializeCava().then(() => {
			if (cava && !cavaListenerId) {
				visibilitySubscription = isVisible.subscribe(value => {
					if (!value) {
						destroyCava()
					}
				})
				cavaListenerId = cava.connect("notify::values", () => {
					valueListener.set(!valueListener.get())
				});
			}
		});
		valueListener.subscribe(_value => {
			setup.queue_draw()
		})
		setup.set_draw_func((area: Gtk.DrawingArea, cr: Cairo.Context, width: number, height: number) => {
			drawBars(area, cr, cava!, height, width)
			cr.$dispose()
		})

	}

	function destroyCava() {
		if (cavaListenerId) {
			cava!.disconnect(cavaListenerId)
		}

		if (visibilitySubscription) {
			visibilitySubscription();
			visibilitySubscription = null;
		}
		isVisible.drop()
		cavaListenerId = null;
		cava = null;
	}

	function drawBars(drawingArea: Gtk.DrawingArea, cr: cairo.Context, cavaCtx: Cava.Cava, h: number, w: number) {
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
			for (let i = 0; i < cavaCtx.get_values().length; i++) {
				const height = h * (cavaCtx.get_values()[i] / 1);
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
				cr.rectangle(i * (w / cavaCtx.get_bars()), y, w / cavaCtx.get_bars(), height);
				cr.fill();
			}
		} else {
			let lastX = 0;
			let lastY = h - h * (cavaCtx.get_values()[0] / 1);
			cr.moveTo(lastX, lastY);
			for (let i = 1; i < cavaCtx.get_values().length; i++) {
				const height = h * (cavaCtx.get_values()[i] / 1);
				let y = h - height;
				cr.curveTo(lastX + w / (cavaCtx.get_bars() - 1) / 2, lastY, lastX + w / (cavaCtx.get_bars() - 1) / 2, y, i * (w / (cavaCtx.get_bars() - 1)), y);
				lastX = i * (w / (cavaCtx.get_bars() - 1));
				lastY = y;
			}
			cr.lineTo(w, h);
			cr.lineTo(0, h);
			cr.fill();
		}
	}




	return (
		<DrawingArea
			setup={initialize}
			onDestroy={destroyCava}
		/>
	)
}
