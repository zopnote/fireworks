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


import 'dart:io' as io;

/**
 * Representing a specific operating system.
 */
enum Platform { windows, android, linux, ios, macos, meta, steam }

/**
 * Representing a specific processor architecture.
 */
enum Processor { x86_64, x86, arm64, arm, riscv64 }

/**
 * Operating system, processor couple to determine the full platform in context.
 */
final class System {
  final Platform platform;
  final Processor processor;
  System(this.platform, this.processor);
  static System? parseString(String string) {
    Platform? platform = null;
    Processor? processor = null;

    for (Platform systemValue in Platform.values) {
      if (systemValue.name == string.split("_").first) {
        platform = systemValue;
      }
    }
    for (Processor processorValue in Processor.values) {
      if (processorValue.name == string.split("_").sublist(1).join("_")) {
        processor = processorValue;
      }
    }
    if (platform == null || processor == null) return null;
    return System(platform, processor);
  }

  factory System.current() {
    final String system = io.Platform.version.split("\"")[1];
    return System(
      Platform.values.firstWhere(
            (i) => i.name == system.split("_").first,
      ),
      {
        "x64": Processor.x86_64,
        "arm64": Processor.arm64,
        "arm": Processor.arm,
        "riscv64": Processor.riscv64,
      }[system.split("_").last]!,
    );
  }

  /**
   *  A formatted version of System for use of representation.
   */
  String string() {
    return "${platform.name}_${processor.name}";
  }
}