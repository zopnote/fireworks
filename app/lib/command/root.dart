
import 'package:fireworks/command/execute/create.dart';
import 'package:fireworks/command/command.dart';

Command rootCommand = Command(
    use: "fireworks",
    description: "Manage your Fireworks projects.",
    sub: [
      Command(
          use: "create",
          description: "Create a new project from a template.",
          sub: [],
          inheritFlags: true,
          flags: [
            CommandFlag(
              name: "template",
              value: "app",
              helpfulAvailable: [ "native", "package" ]
            )
          ],
          run: create
      )
    ],
    flags: [
      CommandFlag(name: "verbose", value: false),
      CommandFlag(name: "help", value: false)
    ],
    run: (cmd, arg, flags) => CommandError(cmd, true)
);


/*
  dart-sdk, clang, ninja
 */
void ensureDeps() {

}