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
 *
 */


import 'package:build/build.dart';
import 'package:build/runner.dart';
import 'package:build/targets.dart';

void main(List<String> args) => execute(
  args,
  Command(
    use: "step",
    description:
        "Execute just particular steps of a target for specific use cases.",
    run: (data) async {

      final Flag? targetFlag = data.flags.firstWhereOrNull(
        (e) => e.name == "target",
      );

      final Flag? stepFlag = data.flags.firstWhereOrNull(
        (e) => e.name == "steps",
      );

      final bool force =
          data.flags.firstWhereOrNull((e) => e.name == "force") == null
          ? false
          : true;

      if (targetFlag == null || targetFlag.value.isEmpty) {
        return CommandResponse(
          message: "Please specify a target.",
          error: true,
        );
      }

      if (stepFlag == null || targetFlag.value.isEmpty) {
        return CommandResponse(
          message: "Please specify a valid step.",
          error: true,
        );
      }

      if (!targets.keys.contains(targetFlag.value)) {
        return CommandResponse(
          message:
              "\nAvailable targets:\n" +
              targets.keys.join("\n") +
              "\nThe target ${targetFlag.value} isn't valid.",
          error: true,
        );
      }

      final Environment environment = Environment(targetFlag.value);
      final Iterable<int> executeSteps = stepFlag.value
          .split(";")
          .map<int>((e) => int.parse(e));
      final int length = targets[targetFlag.value]!.length;
      for (int i = 0; i < length - 1; i++) {
        final Step target = targets[targetFlag.value]![i];

        if (target.configure != null) {
          await target.configure!(environment);
        }
        bool execute = true;
        if (target.condition != null && !force) {
          execute = await target.condition!(environment);
        }
        if (executeSteps.contains(i + 1) && execute) {
          await target.execute(
            environment,
            message: "(${i + 1}/$length) " + target.name,
          );
        }
      }

      return CommandResponse(message: "Executed the steps successfully.");
    },
    flags: [
      Flag(name: "target", overview: targets.keys.toList()),
      Flag(name: "steps", overview: ["1", "2", "2;3;5", "..."]),
      Flag(
        name: "force",
        description:
            "Enforces the execution of the steps regardless of the condition.",
      ),
    ],
  ),
);
