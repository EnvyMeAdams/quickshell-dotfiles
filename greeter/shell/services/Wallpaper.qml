pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // empty list = every display
    function onDisplay(list, name) { return !list || list.length === 0 || list.includes(name); }
}
