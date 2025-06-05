
class CommandFlag<T> {
  CommandFlag({
    required this.name,
    required this.value,
    this.helpfulAvailable
  });
  final String name;
  final List<String>? helpfulAvailable;
  T value;
}


final class CommandError {
  const CommandError(this.executedCmd, this.syntax, {
    this.errorMessage
  });
  final Command executedCmd;
  final bool syntax;
  final String? errorMessage;

}


/**
 * A command as part of the command line interface.
 */
class Command {
  Command({
    required this.use,
    required this.description,
    required this.sub,
    required this.flags,
    required this.run,
    this.inheritFlags = false
  }) {
    assert(use.length < 15);
    assert(description.length < 50);
    if (sub.isNotEmpty) sub.forEach((a) {
      a.parentCommands.add(this);
    });
  }

  final String use;
  final String description;
  final List<Command> sub;
  final List<CommandFlag> flags;
  final CommandError? Function(Command thisCmd, String? arg, List<CommandFlag> flags) run;
  final bool inheritFlags;

  /**
   * A command can be the child of multiple command structures.
   * This list refers to the parents.
   */
  final List<Command> parentCommands = [];

  /**
   * Returns a string representation of the available command structure and
   * its flags.
   */
  String? syntax() {

    String syntax = parentCommands.isNotEmpty ?
      "(Command: ${this.use}) " + this.description + "\n" :
      this.description + "\n";
    if (sub.isNotEmpty) {
      syntax = syntax + "\nAvailable sub commands:\n";
      for (Command subCmd in sub) {
        int needWhitespace = 15 - subCmd.use.length;
        syntax = syntax + subCmd.use;
        for (int i = 0; i <= needWhitespace; i++) syntax = syntax + " ";
        syntax = syntax + subCmd.description + "\n";
      }
    }

    List<CommandFlag> flags = [];
    if (parentCommands.isNotEmpty && this.inheritFlags)
      parentCommands.forEach((a) {
        if (a.flags.isNotEmpty) flags.addAll(a.flags);
      });
    if (this.flags.isNotEmpty) flags.addAll(this.flags);
    if (flags.isNotEmpty) {
      syntax = syntax + "\nAvertable flags:\n";
      for (CommandFlag flag in flags) {
        syntax = syntax + "--" + flag.name + " (default: " + flag.value.toString() + ")\n";
        if (flag.helpfulAvailable == null) continue;
        syntax = syntax + " (available: "+flag.helpfulAvailable!.toString()+")";
      }
    }
    return syntax;
  }



  /**
   * Run the command and recursive the sub commands of the [Command] that
   * the action got applied on. The arguments as well as the flags will
   * get parsed inside the function.
   */
  Future<CommandError?> execute(List<String> rawArgs) async {
    Command curCmd = this;
    String? arg;


    final List<CommandFlag> givenFlags = [];
    void Function(String arg) addFlag = (arg) => givenFlags.add(
        CommandFlag(
          name: arg.contains("=") ?
          arg.split("=").first.substring(2) : arg.substring(2),

          value: arg.contains("=") ?
          arg.split("=").last : true,
      ));


    final List<CommandFlag> avertFlags = []..addAll(curCmd.flags);
    String? Function(String arg) parseSubCmd = (arg) {
      Command? foundCmd;
      curCmd.sub.forEach(
              (a) => a.use == arg ? foundCmd = a : null
      );
      if (foundCmd == null) return arg;
      if (!foundCmd!.inheritFlags) curCmd.flags.forEach((a) => avertFlags.remove(a));
      avertFlags.addAll(foundCmd!.flags);
      curCmd = foundCmd!;
      return null;
    };


    String? argThatWasNotFound;
    for (String givenArg in rawArgs) {
      if (givenArg.startsWith("--")) addFlag(givenArg);
      else if (curCmd.sub.isNotEmpty) argThatWasNotFound = parseSubCmd(givenArg);
      else arg = givenArg;
    }


    if (argThatWasNotFound != null) return CommandError(curCmd, true,
        errorMessage: "The given argument ${argThatWasNotFound} isn't responding to any available commands."
    );


    final List<CommandFlag> noInfluence = [];
    for (CommandFlag givenFlag in givenFlags) {
      bool found = false;
      for (CommandFlag flag in avertFlags) {
        if (flag.name != givenFlag.name) continue;
        found = true;
        break;
      }
      if (found) break;
      noInfluence.add(givenFlag);
    }
    if (noInfluence.isNotEmpty) {
      print("Warning: The following flags have no influence on the operation.");
      for (CommandFlag flag in noInfluence) print("       --${flag.name}");
    }


    return curCmd.run(curCmd, arg, avertFlags);
  }
}