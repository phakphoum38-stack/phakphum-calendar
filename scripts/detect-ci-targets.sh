#!/usr/bin/env bash
set -euo pipefail

has_file() { [[ -f "$1" ]]; }
has_dir() { [[ -d "$1" ]]; }
has_dart_files() { find . -type f -name '*.dart' -not -path './.git/*' -print -quit | grep -q .; }

is_dart=false
is_flutter=false
has_tests=false
has_integration_tests=false
has_web=false
has_windows=false
has_android=false
has_ios=false
has_macos=false
has_linux=false

if has_file pubspec.yaml; then
  if grep -Eq '^environment:[[:space:]]*$|^[[:space:]]+sdk:' pubspec.yaml && has_dart_files; then
    is_dart=true
  fi
  if grep -Eq '^[[:space:]]*flutter:[[:space:]]*$|^[[:space:]]+flutter:[[:space:]]+sdk:[[:space:]]*flutter' pubspec.yaml; then
    is_flutter=true
    is_dart=true
  fi
fi

if has_dart_files; then is_dart=true; fi
if has_dir test && find test -type f -name '*_test.dart' -print -quit | grep -q .; then has_tests=true; fi
if has_dir integration_test && find integration_test -type f -name '*.dart' -print -quit | grep -q .; then has_integration_tests=true; fi
if has_dir web; then has_web=true; fi
if has_dir windows; then has_windows=true; fi
if has_dir android; then has_android=true; fi
if has_dir ios; then has_ios=true; fi
if has_dir macos; then has_macos=true; fi
if has_dir linux; then has_linux=true; fi

printf 'is_dart=%s\n' "$is_dart"
printf 'is_flutter=%s\n' "$is_flutter"
printf 'has_tests=%s\n' "$has_tests"
printf 'has_integration_tests=%s\n' "$has_integration_tests"
printf 'has_web=%s\n' "$has_web"
printf 'has_windows=%s\n' "$has_windows"
printf 'has_android=%s\n' "$has_android"
printf 'has_ios=%s\n' "$has_ios"
printf 'has_macos=%s\n' "$has_macos"
printf 'has_linux=%s\n' "$has_linux"
