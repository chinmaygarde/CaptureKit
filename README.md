Capture Kit
-----------

Efficiently capture videos of UIKit hierarchies

* Automatically save the captured video to the users photo library
* Use the bundled UI controls for controlling playback or use the `CKScreenRecorder` class directly
* Captures UIKit hierarchies on a dedicated background thread
* Avoid unnecessary buffer allocations and minimizes data copies

Usage
-----

* Use the `CKScreenRecorderHUD` and specify the `targetView` (which may be a window). Control capture via onscreen controls
* Directly use the `CKScreenRecorder` with your own controls to control playback


Example
-------

* Run the `CaptureKitExample` sample project

