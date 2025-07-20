# Engine runtime
The engine runtime is participated in multiple modules.
Some 

### Dart Engine Bridge ``spark`` 
The bridge between the C written engine and Dart. The platform embedder using the Dart C API and systems for Dart interaction.
Important is, that the other modules defines Dart sources and an interface to the C logic but 
the modules never have to depend on ``spark``. Only modules that want to use Dart as language have to depend on ``spark``. 
With this design Fireworks will be able to run on all devices that support LLVM.
### Realtime Physics Engine ``physics``
Augmented Vertex Block Discent is an edge technique for highly parallel physics simulations. With virtual reality physics become more important
and Fireworks should support an environment full of calculated entities.
With the data driven design Fireworks should be capable with handling full physics based water particles and more using AVBD.
### Simulation Physics Engine ``simulate``
These physics are deterministic and realistic. They have their own physics engine that can be used instead of ``physics`` or be disabled.
When disabled you can still use the parts of ``simulate`` that provide temperature and ray-traced sounds.
### Networking ``network``
Network synchronization library for multiplayer games. It utilizes the Fireworks additive meta preprocessor to add automatic participation in
server and client side for easy multiplayer games.
### Renderer ``render`` 
Cross-platform high efficient renderer abstracting vulkan, opengl and metal.
Comes with global illumination, reflections and raytracing.
### Machine Learning ``vino`` 
OpenVINO based framework to power token based models. Can be used 
### Virtual Reality ``xvr``
OpenXR vr systems
### Input & Output ``io``
As the name suggests keyboard, mouse and controller input.
### Core ``core``
**The core main module** provides the overall entry point and management of the
entire runtime. It has to manage the resources, initialization, fragility and software architecture. On demand, it can be run
headless (without io).

Core submodules:
* ``math`` Math for physics, calculations, raytracing and casting or collisions.
* ``platform`` Platform abstraction and information
* ``assets`` Loader for assets on several platforms.
* ``system`` Subsystem for resource management. Threads and memory.
* ``debug`` Debug library for better insights into the C code.
* ``stdlog`` Log crucial information and communicate in headless mode with the user. Also supports stdin and stderr.
* ``serialize`` Binary, JSON and YAML converting formats.
* ``entities`` Entity component system framework with interface/dependency inversion.

Every system depends on the core. Therefore, only the most important systems should be placed here.
Platform abstractions for windows, input and output. Contains an asset manager and platform information.
The entity component system, thread and memory system and the highest interfaces.