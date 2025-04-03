# Overview of engine runtime steps
1. Create the core systems, entry point and application layer as well as launch the first window.
2. Write the basics such as dynamic arrays and strings.
3. Plan a memory and thread subsystem.
4. Start with the render surface to make at first the nuklear ui functional and allow to build debug interfaces in c.
5. Build test pipeline for supported platforms on ci.
6. Create math lib with vectors and matrix multiplication.
7. Start with the first basic 3d rendering of cube (Remember cubes must be reinstanceable to test the dart interaction module).
8. Calm down and remember what to refector.
9. Write the physics module.
10. Combine the renderer and physics module to see the first impulses.
11. Design a consistent way if representing the actual 3d space in code.
12. Implement 3d spatial sounds.
13. Check to ensure the modules runs multithreaded and performant.
14. Implement the Dart logic interaction layer, which should be a subsystem on its own, that creates a queue for rendering its entities, play audio, send information through network, bring the information of the network in the dart layer, send native calls for platform application and push this queue async on their implemented interfaces on their threads.
15. Calm down after the hard steps and remember to refector a bunch.
16. Now its time to test the extensibility of the dart interaction by working further on the renderer.
17. Furthermore an asset manager would be required to load assets. Also its implementation in the Dart Engine Interaction Layer (Ill call it from now on DEIL)
18. The engine renderer must use shaders, so a loader and its infrastructure is required.
19. Dart must be able to take advantage of the shader loading so an api for DEIL is required.
20. Heavy optimizing should be done for DEIL and its connection to ensure the quality.
21. Remember to refector again because the current time is hard.
22. Build a stable interface for the C language.
23. Implement advanced render techniques such as ambient occlusion, screen space reflections, global illumination, lod loader and its transitions, materials and post processing. Ensure these feature pipelines are open to add also via DEIL.
24. Implement water shaders, and 2d rendering on planes.
25. Dart api: Create a state machine, flipbooks and 2d animations to display complex 2d entities.
26. Add configuration to graphics pipeline to allow changing the general render appearance and disable feature for support lower end devices.
27. Now it should be time to add ui debug capabilites to dart, so an ui abstraction to the DEIL and a new ui thread module should be created.
28. A 3d skeleton that allows to attach meshes and components such as entities to it should be implemented. C & DEIL
29. A good math lib should also be in dart. (Remember to used unboxed variables)
30. Calm down and refector a much of the old garbage.
31. Integrate debugging tools for performance monitoring of the frame times.
32. Optimize frame times.
33. Implement material properties for reflection surfaces, roughness, texture, height map for lighting, height map for tesselate the shit.
34. Furthermore the post processing should be available in dart.
35. Ensure multiple window support.
36. Ensure platform support.
37. Ensure quality and frame times.
38. Make the state machine available for multiple purposes.
39. Add features for the state machine for extensive use in multiple scenarios.
40. Add AI behaviour and pathfindig, line of sight etc. algorithms.
41. Port over to DEIL.
42. Refector a bunch.

Finished up the first chapter of fireworks

# Overview of the runner and its steps

> Note that the runner brings the pkgs together. 
> In this way there will be less dependencies between them. Builder, Analyzer.. these are pkgs.
1. Start off with implement the builder wich can compile c code and uses gen_snapshots of dart for dart cross compilation.
2. Enable hot reloading the c code by replacing the applications shared lib at runtime while dev cycle.
3. Write the project analyzer for containing the peoject information that the builder will later get as well as debugging puproses and data processing for its representation in fancy uis. Source code classes must be analyzed for the dependency graph in the editor.
5. Internally the runner should host an http where requests can receive data with the analyzer about the project and can send data to perform actions on the project. Its the main interface for the project runner dev cycle where many tools for creating, viewing and manage dependencies and assets will come together. For maximizing modularity.
6. Implement the dart ecosystem toolchain, an c package manager, a vcs manager, a deps version manager, a debug manager, a http backend host management toolchain, language serialization and parsing.
7. Refector that shit to make it more acceptable.
8. Create a second http server with a static port to host the editor which is a web app.
It should receive paths as well as the port of the project server and then pushes these web paths over as arguments to the hosted web app.

# Overview for the editor tooling
1. Import the widgets of old projects.
2. Refector a bit.

**Needs more planning then**
3. Create a good main class responsible to start up by receiving the http port and paths via 
cmdline.


4. Call the project server http interface based on widget requests to show up properly the right data and tooling. The state of one widget must be saved in the web host server provided by the runner which also provides a backend for the web application that can be opened multiple times. 
5. The business logic goes for animation and responses in to the web app and for application state in the web host server backend.
6..... Furthermore it needs to be a bit further with runtime and the runner.