import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    readonly property var targetScreens: Quickshell.screens.filter(screen => screen.name === "HDMI-A-1")
    property bool loading: true
    property bool hasData: false
    property string errorMessage: ""
    property string temperature: "--"
    property string feelsLike: "--"
    property string windSpeed: "--"
    property string windDirection: ""
    property string humidity: "--"
    property string description: "Waiting for wttr.in"
    property string location: "Locating…"
    property int weatherCode: 113
    property bool isNight: false
    property date updatedAt: new Date()
    readonly property string weatherKind: kindForCode(weatherCode)
    readonly property string updatedLabel: hasData ? Qt.formatTime(updatedAt, "h:mm AP") : ""

    function kindForCode(code) {
        if ([200, 386, 389, 392, 395].indexOf(code) !== -1)
            return "storm";
        if ([143, 248, 260].indexOf(code) !== -1)
            return "fog";
        if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320,
             323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371,
             374, 377].indexOf(code) !== -1)
            return "snow";
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356,
             359].indexOf(code) !== -1)
            return "rain";
        if (code === 116)
            return "partlyCloudy";
        if ([119, 122].indexOf(code) !== -1)
            return "cloudy";
        return "clear";
    }

    function firstValue(list, fallback) {
        return list && list.length > 0 && list[0].value !== undefined
            ? String(list[0].value).trim()
            : fallback;
    }

    function applyPayload(payload) {
        if (!payload || payload.trim().length === 0)
            return;

        try {
            const data = JSON.parse(payload);
            if (!data.current_condition || data.current_condition.length === 0)
                throw new Error("missing current_condition");

            const current = data.current_condition[0];
            const area = data.nearest_area && data.nearest_area.length > 0
                ? data.nearest_area[0]
                : {};
            const areaName = firstValue(area.areaName, "Current location");
            const regionName = firstValue(area.region, "");
            const iconUrl = firstValue(current.weatherIconUrl, "");

            temperature = String(current.temp_F ?? "--");
            feelsLike = String(current.FeelsLikeF ?? "--");
            const windKmph = Number(current.windspeedKmph);
            windSpeed = current.windspeedMiles !== undefined && current.windspeedMiles !== ""
                ? String(current.windspeedMiles).trim()
                : (Number.isFinite(windKmph) ? String(Math.round(windKmph * 0.621371)) : "--");
            windDirection = String(current.winddir16Point ?? "");
            humidity = String(current.humidity ?? "--");
            description = firstValue(current.weatherDesc, "Current conditions");
            location = regionName && regionName !== areaName
                ? areaName + ", " + regionName
                : areaName;
            weatherCode = Number(current.weatherCode ?? 113);
            isNight = iconUrl.indexOf("_night") !== -1;
            updatedAt = new Date();
            hasData = true;
            loading = false;
            errorMessage = "";
        } catch (error) {
            loading = false;
            errorMessage = "Weather data unavailable";
            console.error("Weather: invalid wttr.in response:", error.message);
        }
    }

    Process {
        id: weatherRequest
        command: [
            "curl", "--fail", "--silent", "--show-error", "--compressed",
            "--connect-timeout", "5", "--max-time", "12",
            "https://wttr.in/?format=j1"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.applyPayload(text)
        }

        stderr: StdioCollector {}

        onStarted: {
            root.loading = !root.hasData;
            root.errorMessage = "";
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.errorMessage = root.hasData
                    ? "Update delayed"
                    : "Unable to reach wttr.in";
                console.warn("Weather: wttr.in request failed with exit code", exitCode);
            }
        }
    }

    Timer {
        interval: root.hasData ? 45 * 60 * 1000 : 2 * 60 * 1000
        running: true
        repeat: true
        onTriggered: {
            if (!weatherRequest.running)
                weatherRequest.running = true;
        }
    }

    Variants {
        model: root.targetScreens

        delegate: WeatherOverlay {
            required property var modelData
            screen: modelData
            weather: root
        }
    }
}
