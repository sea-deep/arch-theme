# Quickshell Bug Report: SIGSEGV in `libQt6QmlModels.so.6` during `QQuickRepeater::regenerate()` on destroyed C++ QObjects

**Issue Title**: Crash (SIGSEGV) in `QQuickRepeater::regenerate()` / `QQmlIncubatorPrivate::incubate()` when dynamic backend collections (`Pipewire.nodes`, `workspace.toplevels`) destroy C++ objects

---

## 1. Environment & Build Information

- **Quickshell Version**: 0.3.1 (distributed by Arch Linux)
- **Qt Version**: 6.11.2 (built against 6.11.2)
- **OS**: Arch Linux (rolling, AMD x86-64)
- **Compositor**: Hyprland (Wayland)
- **Memory Allocator**: jemalloc (`-DUSE_JEMALLOC=ON`)
- **Signal**: `SIGSEGV` (Signal 11, `si_code: SI_TKILL`)

---

## 2. Summary of the Crash

Quickshell crashes with a segmentation fault when background events destroy C++ QObjects that are currently part of a QML `Repeater` model. Specifically, when:
1. An audio stream closes and PipeWire destroys a `PwNode` (`quickshell.service.pipewire.registry: Destroying object PwNode(0x..., id=.../unbound)`), or
2. A window closes in Hyprland and `HyprlandWorkspace` destroys a `HyprlandToplevel`.

If a `Repeater` has its `model` bound to an array derived from these objects (e.g. `Pipewire.nodes.values.filter(...)` or `activeWs.toplevels.values`), the QML engine attempts to regenerate delegate items. During incubator execution (`QQmlIncubatorPrivate::incubate()`), reading properties of `modelData` dereferences a jemalloc freed memory block (`0xfefefefefefefefe`), crashing immediately with `SIGSEGV`.

---

## 3. Backtrace & Coredump Details

Stack trace of crashed thread (PID 8340):

```
#0  0x00007f3d9589a17c in ?? () from /usr/bin/../lib/libc.so.6
#1  0x00007f3d9583e5d0 in raise () from /usr/bin/../lib/libc.so.6
#2  0x0000562f5a71c389 in ?? () from /usr/bin/quickshell
#3  0x00007f3d9583e6f0 in <signal handler called> () from /usr/bin/../lib/libc.so.6
#4  0x00007f3d95648530 in ?? () from /usr/bin/../lib/libQt6QmlModels.so.6
#5  0x00007f3d95648f01 in ?? () from /usr/bin/../lib/libQt6QmlModels.so.6
#6  0x00007f3d95620790 in ?? () from /usr/bin/../lib/libQt6QmlModels.so.6
#7  0x00007f3d9562346d in ?? () from /usr/bin/../lib/libQt6QmlModels.so.6
#8  0x00007f3d96d151de in QQmlIncubatorPrivate::incubate(QQmlInstantiationInterrupt&) () from /usr/bin/../lib/libQt6Qml.so.6
#9  0x00007f3d96d156b2 in QQmlEnginePrivate::incubate(QQmlIncubator&, QQmlRefPointer<QQmlContextData> const&) () from /usr/bin/../lib/libQt6Qml.so.6
#10 0x00007f3d9562187c in ?? () from /usr/bin/../lib/libQt6QmlModels.so.6
#11 0x00007f3d97f70432 in QQuickRepeater::regenerate() () from /usr/bin/../lib/libQt6Quick.so.6
#12 0x00007f3d97f70e68 in QQuickRepeater::setModel(QVariant const&) () from /usr/bin/../lib/libQt6Quick.so.6
#13 0x00007f3d96c8623b in ?? () from /usr/bin/../lib/libQt6Qml.so.6
#14 0x00007f3d96d722a8 in QQmlPropertyPrivate::write(...) () from /usr/bin/../lib/libQt6Qml.so.6
#15 0x00007f3d96ca5531 in QQmlBinding::slowWrite(...) () from /usr/bin/../lib/libQt6Qml.so.6
#16 0x00007f3d96ca72f9 in ?? () from /usr/bin/../lib/libQt6Qml.so.6
#17 0x00007f3d96ca8805 in QQmlBinding::doUpdate(...) () from /usr/bin/../lib/libQt6Qml.so.6
#18 0x00007f3d96c9f861 in QQmlBinding::update(...) () from /usr/bin/../lib/libQt6Qml.so.6
#19 0x00007f3d96d4cc20 in QQmlNotifier::emitNotify(...) () from /usr/bin/../lib/libQt6Qml.so.6
#20 0x00007f3d961eef5f in ?? () from /usr/bin/../lib/libQt6Core.so.6
#21 0x00007f3d96bf928b in QV4::QObjectWrapper::setProperty(...) () from /usr/bin/../lib/libQt6Qml.so.6
#22 0x00007f3d96bfa5e1 in QV4::QObjectWrapper::setQmlProperty(...) () from /usr/bin/../lib/libQt6Qml.so.6
#23 0x00007f3d96bedbb4 in QV4::QQmlContextWrapper::virtualPut(...) () from /usr/bin/../lib/libQt6Qml.so.6
#24 0x00007f3d96b6b4d3 in QV4::ExecutionContext::setProperty(...) () from /usr/bin/../lib/libQt6Qml.so.6
#25 0x00007f3d96c24a6b in QV4::Runtime::StoreNameSloppy::call(...) () from /usr/bin/../lib/libQt6Qml.so.6
```

### Register Dump at Frame 12 (`QQuickRepeater::setModel`):
```
rax: 0x0
rbx: 0x7f3d76889740 (QQuickRepeater instance)
r15: 0xfefefefefefefefe (jemalloc freed memory block pattern)
```

The value `0xfefefefefefefefe` confirms that a QObject pointer freed by jemalloc is being dereferenced as an active pointer.

---

## 4. Quickshell Log Tail Immediately Preceding Crash

```
DEBUG quickshell.service.pipewire.loop: Pipewire event loop received new events, iterating.
DEBUG quickshell.service.pipewire.node: Enumerating props param for PwNode(0x7f3d6a289200, id=59/bound)
DEBUG quickshell.service.pipewire.registry: Destroying object PwLink(0x7f3d71460390, id=88/unbound)
DEBUG quickshell.service.pipewire.registry: Destroying object PwLink(0x7f3d6eb93580, id=90/unbound)
DEBUG quickshell.service.pipewire.registry: Unbinding object PwNode(0x7f3d6a04d800, id=87/bound)
DEBUG quickshell.service.pipewire.registry: Destroying object PwNode(0x7f3d6a04d800, id=87/unbound)
DEBUG quickshell.service.pipewire.loop: Done iterating pipewire event loop.
ERROR: Quickshell has crashed under pid 8340 (Coredumps will be available under that pid.)
```

---

## 5. Minimal Reproduction Pattern in QML

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    // Dynamically filtered stream list from Pipewire.nodes
    readonly property var streams: Pipewire.nodes && Pipewire.nodes.values
        ? Pipewire.nodes.values.filter(n => n && n.isStream)
        : []

    // When an audio stream ends in the background, Pipewire unbinds and deletes the PwNode.
    // Repeater attempts to regenerate, accessing the deleted PwNode:
    Repeater {
        model: streams
        delegate: Text {
            required property var modelData
            text: modelData ? (modelData.description || modelData.name || "") : ""
        }
    }
}
```

---

## 6. Proposed Upstream Fixes

1. **Weak Reference Invalidation**:
   Ensure `QObjectWrapper` instances created for backend items (like `PwNode` and `HyprlandToplevel`) hook into `QObject::destroyed` so the V4 engine marks the JavaScript wrapper as `null` or invalidated prior to memory deallocation.
2. **Atomic Collection Mutation**:
   When C++ models (such as `Pipewire.nodes` or `workspace.toplevels`) remove items, emit model removal signals (`beginRemoveRows` / `endRemoveRows`) before invoking `deleteLater()` or deleting the underlying C++ objects.
3. **Configuration-Level Workaround**:
   In user configurations:
   - Lazily unbind dynamic `Repeater` models when dropdowns are not visible (`model: expanded ? streams : []`).
   - Project raw C++ QObjects into plain JavaScript dictionaries (`{ id, name, icon, address }`) before passing them to `Repeater.model`.
