# Flutter-web-based editor and ide integration
There should be multiple implementations of plugins for different IDEs, which all have one in same.
The interfaces will be a webview with the Flutter-web-based editor surfaces.
The webapp build with Flutter will have two backends. 

First, the backend for the webapp data and interaction, e.g.
because the webapp is instantiated multiple times in multiple webview to allow multiple windows, there will be
data transfer to realize clickable buttons and changes on the different windows and its widgets.

The second backend is requested and used only by the first backend to gather information about the currently opened project.
This backend is hosted by the cmdline-tool. It consists of multiple http applications that let do operations and analyzes
of the indexed project.