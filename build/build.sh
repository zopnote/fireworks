#!/bin/bash
cd "$(dirname "$0")"
dart run ./lib/build.dart "$@"
