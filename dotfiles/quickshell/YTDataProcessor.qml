import Quickshell.Io
import QtQuick

Process {
    id: processor
    property string scriptLocation: Qt.resolvedUrl("../scripts/cava_startup.sh")
    command: [scriptLocation]
    running: true
    signal newData(var processedValues)

    stdout: SplitParser {
        onRead: data => {
            //captures percentage and JSON
            const regex = /(\d+\.?\d*)%.*?({.*})/;
            const match = data.match(regex);
            if (match) {
                const percentage = match[1]; // "1.8"
                const jsonString = match[2]; // The entire JSON object as string
                const jsonObject = JSON.parse(jsonString);
                console.log(percentage, jsonObject);
            }
        }
    }
}
