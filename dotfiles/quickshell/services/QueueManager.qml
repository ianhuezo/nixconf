#pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: queue

    QtObject {
        id: internal
        property list<var> jobs: []
        property int MAX_QUEUE_SIZE: 10
    }

    function enqueue() {
    }

    function dequeue() {
    }

    function showQueue() {
    }
}
