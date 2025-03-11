#!/bin/bash
# ASSUMPTIONS
# 1. Cargo package manager is already installed on your computer
#   - If Cargo is not installed, you can install it by running this command on your terminal: `$ curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh`
# This generates an .xcframework that can be embedded in your app as a crypto module

set -e  # Exit immediately if a command exits with a non-zero status

# Set the minimum iOS deployment target to match OpenSSL's build
export IPHONEOS_DEPLOYMENT_TARGET=12.0

# Make sure RUSTFLAGS includes the C++ standard library to resolve the missing symbol
export RUSTFLAGS="-C link-arg=-lc++"

echo "Installing cbindgen..."
# Install `cbindgen`
# cbindgen (C Bindings Generator) is a tool that generates C header files from Rust source code
# It is designed to make it easier to create FFI (Foreign Function Interface) bindings between Rust and C/C++ code
cargo install --force cbindgen

echo "Generating C header file..."
# Generates a C header file named ecies.h
# The --lang c flag specifies that the generated header file should be in C syntax
mkdir -p include
cbindgen --lang c --output include/ecies.h

echo "Creating module.modulemap file..."
# Create a `module.modulemap` file
# Used by the Clang compiler to define our module i.e collection of related header files
# We only have one header file so we don't need an umbrella definition
cat > include/module.modulemap <<- EOF
module Ecies {
    header "ecies.h"
    export *
}
EOF

echo "Building for iOS devices (aarch64-apple-ios)..."
# Build for Apple iOS devices/platform's 64-bit ARM (aarch64) architecture
# The --release flag specifies that the build should be optimized for release, rather than debugging.
# First install target platform
rustup target add aarch64-apple-ios
# Then build for target platform
cargo build --release --target aarch64-apple-ios

echo "Building for iOS Simulator on Intel Macs (x86_64-apple-ios)..."
# Build for Apple iOS Simulator on macs with x86 Intel microprocessor chip
rustup target add x86_64-apple-ios
cargo build --release --target x86_64-apple-ios

echo "Building for iOS Simulator on Apple Silicon (aarch64-apple-ios-sim)..."
# Build for Apple iOS Simulator running on macs with Apple Silicon chip
# First we need to install the nightly toolchain
rustup toolchain install nightly-aarch64-apple-darwin
# Then add rust-src to the toolchain - which is a local copy of the Rust standard library source code
rustup component add rust-src --toolchain nightly-aarch64-apple-darwin
# Finally, build for the simulator from source using build-std - Cargo's experimental feature that allows us to rebuild the standard library locally
rustup target add aarch64-apple-ios-sim
cargo +nightly build -Z build-std --target aarch64-apple-ios-sim --release

echo "Creating universal binary for iOS simulators..."
# Create a universal binary for iOS simulators by combining x86_64 and arm64 architectures
mkdir -p ./target/universal-ios-sim/release
lipo -create \
  ./target/x86_64-apple-ios/release/libecies.a \
  ./target/aarch64-apple-ios-sim/release/libecies.a \
  -output ./target/universal-ios-sim/release/libecies.a

echo "Creating XCFramework..."
# Generate an xcframework named `Ecies`, with support for:
# - aarch64-apple-ios (devices)
# - universal simulator binary (containing both x86_64 and arm64 architectures)
xcodebuild -create-xcframework \
  -library ./target/aarch64-apple-ios/release/libecies.a \
  -headers ./include/ \
  -library ./target/universal-ios-sim/release/libecies.a \
  -headers ./include/ \
  -output Ecies.xcframework

echo "Build complete! The generated framework structure:"
find Ecies.xcframework -type f | sort