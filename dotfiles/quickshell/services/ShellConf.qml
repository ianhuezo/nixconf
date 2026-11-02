pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell_conf/quickshell.conf"
    property var values: ({})

    function get(section, key, fallback) {
        const value = root.values[section]?.[key];
        return value === undefined ? fallback : value;
    }

    function set(section, key, value) {
        const lines = confFile.text().split("\n");
        const activeKey = new RegExp("^\\s*" + key + "\\s*=");
        const commentedKey = new RegExp("^\\s*[;#]\\s*" + key + "\\s*=");
        let current = "";
        let lastInSection = -1;
        let commented = -1;
        let replaced = false;
        for (let i = 0; i < lines.length && !replaced; i++) {
            const header = lines[i].trim().match(/^\[(.+)\]$/);
            if (header) {
                current = header[1].trim();
                if (current === section)
                    lastInSection = i;
                continue;
            }
            if (current !== section)
                continue;
            if (activeKey.test(lines[i])) {
                lines[i] = lines[i].match(/^\s*/)[0] + key + " = " + value;
                replaced = true;
            } else if (commented < 0 && commentedKey.test(lines[i])) {
                commented = i;
            }
            if (lines[i].trim() !== "")
                lastInSection = i;
        }
        if (!replaced) {
            const line = " " + key + " = " + value;
            if (commented >= 0)
                lines[commented] = line;
            else if (lastInSection >= 0)
                lines.splice(lastInSection + 1, 0, line);
            else
                lines.push("", "[" + section + "]", line);
        }
        const text = lines.join("\n");
        root.values = root.parse(text);
        confFile.setText(text);
    }

    function parse(text) {
        const result = {};
        let section = "";
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line === "" || line.startsWith("#") || line.startsWith(";"))
                continue;
            const header = line.match(/^\[(.+)\]$/);
            if (header) {
                section = header[1].trim();
                continue;
            }
            const eq = line.indexOf("=");
            if (eq < 0)
                continue;
            if (!result[section])
                result[section] = {};
            result[section][line.slice(0, eq).trim()] = root.parseValue(line.slice(eq + 1).trim());
        }
        return result;
    }

    function parseValue(value) {
        if (value === "true" || value === "false")
            return value === "true";
        const number = Number(value);
        return value !== "" && !isNaN(number) ? number : value.replace(/^["']|["']$/g, "");
    }

    FileView {
        id: confFile
        path: root.path
        watchChanges: true
        atomicWrites: false
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.values = root.parse(text())
    }
}
