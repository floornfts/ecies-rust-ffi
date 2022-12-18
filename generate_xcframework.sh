#!/bin/bash

# ASSUMPTIONS
# - Cargo package manager is already installed on your computer

# This generates an .xcframework that can be embedded in your app as a crypto module

# Install `cbindgen`
# cbindgen (C Bindings Generator) is a tool that generates C header files from Rust source code
# It is designed to make it easier to create FFI (Foreign Function Interface) bindings between Rust and C/C++ code
cargo install --force cbindgen

# Generates a C header file named ecies.h
# The --lang c flag specifies that the generated header file should be in C syntax
cbindgen --lang c --output include/ecies.h

# Create a `module.modulemap` file
# Used by the Clang compiler to define our module i.e collection of related header files
# We only have one header file so we don't need am umbrella definition
cat > include/module.modulomap <<- endof
module Ecies {
    header "Ecies.h"
    export *
}
endof

# Build for Apple iOS devices/platform's 64-bit ARM (aarch64) architecture 
# The --release flag specifies that the build should be optimized for release, rather than debugging.
cargo build --release --target aarch64-apple-ios

# Build for Apple iOS Simulator on macs with x86 Intel microprocessor chip
cargo build --release --target x86_64-apple-ios

# Build for Apple iOS Simulator running on macs with Apple Silicon chip 
# NOTE - this command currently (December 2022) fails with the error:
# thread 'main' panicked at 'don't know how to configure OpenSSL for aarch64-apple-ios-sim'
# cargo build --release --target aarch64-apple-ios-sim

# Generate an xcframework named `Ecies`, with support for aarch64-apple-ios and x86_64-apple-ios
xcodebuild -create-xcframework \
  -library ./target/aarch64-apple-ios/release/libecies.a \
  -headers ./include/ \
  -library ./target/x86_64-apple-ios/release/libecies.a \
  -headers ./include/ \
  -output Ecies.xcframework

# The generated framework looks like this
# Ecies.xcframework
# ├── Info.plist
# ├── ios-arm64
# │   ├── Headers
# │   │   ├── ecies.h
# │   │   └── module.modulemap
# │   └── libecies.a
# ├── ios-arm64_x86_64-simulator
#     ├── Headers
#     │   ├── ecies.h
#     │   └── module.modulemap
#     └── libecies.a
