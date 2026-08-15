pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    property string enteredPassword: ""
    property bool unlocking: false
    property bool showError: false

    signal authFailed()

    function lock() {
        if (sessionLock.locked) return
        sessionLock.locked = true
        pam.start()
    }

    PamContext {
        id: pam
        config: "login"

        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.unlocking = false
                root.showError = false
                sessionLock.locked = false
            } else {
                root.enteredPassword = ""
                root.unlocking = false
                root.showError = true
                root.authFailed()
                pam.start()
            }
        }
    }

    function tryUnlock() {
        if (root.unlocking || root.enteredPassword.length === 0) return
        root.showError = false
        root.unlocking = true
        pam.respond(root.enteredPassword)
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                root: root
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
    }
}