/*
 * Copyright (c) 2025 Lenny Siebert
 *
 * This software is dual-licensed:
 *
 * 1. Open Source License:
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License version 3
 *    as published by the Free Software Foundation.
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY. See the GNU General Public
 *    License for more details: https://www.gnu.org/licenses/gpl-3.0.en.html
 *
 * 2. Commercial License:
 *    A commercial license will be available at a later time for use in commercial products.
 */

import 'dart:io';

/**
 * A command flag which presence in the run function indicates already a bool.
 *
 * If it is a [String] flag the value is set to a non-empty string.
 */
final class Flag {
  const Flag(
    this.name, {
    this.description = "",
    this.value = "",
    this.overview = const [],
  });

  final String name;
  final String description;
  final String value;

  /// Provides an overview by giving possible values to provide help to decide.
  final List<String> overview;
}

/**
 * Command response that describes the final result of the operation.
 * In positive as well in error cases a message has to be provided.
 */
final class CommandResponse {
  const CommandResponse({
    this.message = "",
    this.isError = false,
    this.printSyntax,
  });
  final bool isError;
  final String message;
  final Command? printSyntax;
}

final class Command {
  const Command(
    this.use, {
    required this.description,
    required this.run,
    this.hidden = false,
    this.flags = const [],
    this.subCommands = const [],
  });

  /// The use name of the command that has to be
  final String use;
  final String description;
  final bool hidden;
  final List<Flag> flags;
  final List<Command> subCommands;
  final Future<CommandResponse> Function(
    Command cur,
    String argument,
    List<Flag> flags,
  )
  run;
}

/**
 * Formats a syntax message of a flag list.
 */
String _flagSyntax(List<Flag> flags, String prefix) {
  String syntax = "$prefix flags:";
  for (Flag flag in flags) {
    syntax = syntax + "\n--${flag.name}";
    final int space = 13 - flag.name.length;
    if (flag.description.isNotEmpty) {
      syntax = syntax + (" " * space) + "${flag.description}";
    }
    if (flag.value.isNotEmpty) {
      syntax = syntax + " (default: ${flag.value})";
    }
    if (flag.overview.isNotEmpty) {
      syntax = syntax + " (available: ${flag.overview.toString()})";
    }
  }
  return syntax;
}

/**
 * Formats a syntax message as [String] of the command.
 */
String syntax(Command cmd) {
  String syntax = "${cmd.description}\n";
  if (cmd.subCommands.isNotEmpty) {
    syntax = syntax + "\nAvailable sub commands:\n";
    for (final Command sub in cmd.subCommands) {
      if (sub.hidden) continue;
      final int space = 20 - sub.use.length;
      syntax = syntax + sub.use + (" " * space) + sub.description + "\n";
    }
  }
  if (cmd.flags.isNotEmpty) {
    syntax = syntax + _flagSyntax(cmd.flags, "Avertable");
  }
  return syntax;
}

/**
 * Runs a root command and applies the parsed arguments as
 * subcommands or flags to it. At the end one [Command].run() function is
 * determined and will be executed.
 */
Future<bool> run({
  required List<String> rawArgs,
  required Command command,
  List<Flag> globalFlags = const [],
}) async {
  Command current = command;
  String arg = "";

  for (String rawArg in rawArgs) {
    bool complete = false;
    for (Command subCommand in current.subCommands) {
      if (rawArg == subCommand.use) {
        current = subCommand;
        complete = true;
        break;
      }
    }
    if (!complete) {
      arg = rawArg;
      break;
    }
  }

  final List<String> acceptableFlags = [];
  void Function(Flag flag) addName = (flag) {
    acceptableFlags.add(flag.name);
  };
  current.flags.forEach(addName);
  globalFlags.forEach(addName);

  final List<Flag> flags = [];
  void Function(String arg) addFlag = (arg) {
    Flag flag = Flag(
      arg.contains("=") ? arg.split("=").first.substring(2) : arg.substring(2),
      value: arg.contains("=") ? arg.split("=").last : "",
    );
    if (!acceptableFlags.contains(flag.name)) {
      stdout.writeln(
        "The given flag with the name ${flag.name} isn't avertable.",
      );
      return;
    }
    flags.add(flag);
  };

  for (String flag in rawArgs.where((arg) => arg.startsWith("--"))) {
    addFlag(flag);
  }

  CommandResponse response = await current.run(current, arg, flags);
  if (response.printSyntax != null) {
    stdout.writeln(syntax(response.printSyntax!));
    if (globalFlags.isNotEmpty) {
      stdout.writeln(_flagSyntax(globalFlags, "Global"));
    }
  }

  if (response.isError) {
    stderr.writeln(
      response.message.isNotEmpty
          ? "\nAn error occurred: ${response.message}"
          : "\nAn error occurred.",
    );
    return false;
  }
  if (response.message.isNotEmpty) {
    stdout.writeln("\n${response.message}");
  }
  return true;
}
