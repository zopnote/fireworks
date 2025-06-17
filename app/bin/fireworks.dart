
import 'package:fireworks/execution/doctor.dart';
import 'package:fireworks/runner.dart';
void main() {

  doctor(rootCommand, "", []);
}
void ads(List<String> args) => run(rootCommand,
  globalFlags: [
    Flag("verbose", description: "Prints out detailed information of the process."),
    Flag("help", description: "Prints out help of a command.")
  ]
);

Command rootCommand = Command(
  "fireworks",
  description: "Manage your fireworks projects with the corresponding tools.",
  run: (cmd, _, _) => CommandResponse(syntax(cmd)),
  subCommands: [
    Command("doctor",
        description: "Ensures the presence of crucial tools for fireworks in the environment.",
        run: (_, _, _) => CommandResponse("asd")
    ),
  ]
);