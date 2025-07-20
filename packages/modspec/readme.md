# Module specification library
To ensure a consistent representation of project related information and build system data,
Fireworks provide an own ecosystem based on modules. A module is project that can contain ``private/`` and ``public/`` sources,
``assets/``, other ``modules/``, ``build/`` configurations and their entry point ``modspec.dart``. 
A module can depend on other modules by path or git repository. 
