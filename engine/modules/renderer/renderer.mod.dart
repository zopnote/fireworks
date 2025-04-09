import 'package:fireworks_module/module.dart';

Future<Module> register(BuildInformation host, BuildInformation target) async {
  
  Module module = Module(
      namespace: "fireworks",
      name: "renderer", 
      description: "Renderer of the Fireworks framework."
  );

  module.pubspec
    ..packages = {
      "glob": "2.1.3",
      "steamworks": "0.4.7",
      "path_provider": "2.1.4"
    };

  module.assetBundles = [
    "assets"
  ];

  module.cmake
    ..languages = [ lang.c, lang.cxx ]
    ..standard = 23
    ..external = [
      ExternalProject(
          name: "JoltPhysics",
          repository: "https://github.com/zopnote/JoltPhysics.git",
          branch: "forked-1"
      ),
      ExternalProject(
          name: "SDL",
          repository: "https://github.com/zopnote/SDL.git",
          branch: "forked-1"
      )
  ];
  
  return module;
}

