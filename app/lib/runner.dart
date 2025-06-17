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


final class Flag {
  const Flag(this.name, {
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
  const CommandResponse(this.message, {
    this.isError = false,
  });
  final bool isError;
  final String message;
}

final class Command {
  const Command(this.use, {
    required this.description,
    required this.run,
    this.flags = const [],
    this.subCommands = const [],
    this.inheritFlags = false
  });

  /// The use name of the command that has to be
  final String use;
  final String description;
  final List<Flag> flags;
  final List<Command> subCommands;
  final bool inheritFlags;
  final CommandResponse Function(Command cur, String argument, List<Flag> flags) run;
}

String syntax(Command cmd) {
  return "";
}

Future<void> run(Command root, { List<Flag> globalFlags = const [] }) async {

}