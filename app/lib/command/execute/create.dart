
import 'package:fireworks/command/command.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

const String allowed = "abcdefghijklmnopqrstufwxyz1234567890_";

CommandError? create(Command cmd, String? arg, List<CommandFlag> flags) {
  if (arg == null) return CommandError(cmd, false,
      errorMessage: "There have to be a project name as argument."
  );
  final String projectName = arg.toLowerCase();
  for (final int char in projectName.codeUnits)
    if (!allowed.codeUnits.contains(char)) return CommandError(cmd, false,
      errorMessage: "The character '${String.fromCharCode(char)}' results in an invalid project name.\n"
          "Allowed are lower case latin letters, arabic numbers and the underscore."
    );

  String projectTemplatesRoot = path.join(
      path.dirname(path.dirname(Platform.script.path)),
      "resources", "templates", "projects"
  );
  String templateName = "app";
  for (CommandFlag flag in flags)
    if (flag.name == "template") {
      templateName = flag.value;
      break;
    }

  String templatePath = path.join(projectTemplatesRoot, templateName);

  print(templatePath);

  return null;
}