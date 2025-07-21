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

import 'package:modspec/build.dart';

class Module {
  final String name;
  final String description;
  final String version;
  final List<Module>? submodules;
  final List<Step>? steps;

  Module({
    required this.name,
    required this.description,
    required this.version,
    this.submodules,
    this.steps
  });
}