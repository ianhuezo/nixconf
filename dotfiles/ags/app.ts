import { App } from "astal/gtk4"
import style from "./widget/Notification.scss"
import NotificationPopups from "./widget/NotificationPopups"

App.start({
    css: style,
    main() {
        App.get_monitors().map(NotificationPopups)
    },
})
