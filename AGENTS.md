# AGENTS.md - wafflOSagus Development Guidelines

This document provides guidelines for agentic coding agents working on the wafflOSagus BlueBuild project. This is an infrastructure-as-code repository for building custom Fedora Atomic images using BlueBuild.

## btca

When the user says "use btca" for codebase/docs questions.

Run:

- btca ask -t <resource> -q "<question>"

Available resources: blue-build, ucore

## Project Overview

wafflOSagus is a custom Fedora Atomic image distribution built with BlueBuild. It provides container-native, immutable system images with pre-configured developer tools and customizations.

### Image Variants

- `wafflosagus-ucore`: Server-focused, minimal footprint based on uCore
- `wafflosagus-bazzite`: Gaming-focused with NVIDIA support
- `wafflosagus-DX`: Desktop-focused with GNOME/COSMIC support

### Core Principles

- **Immutability**: System files cannot be modified at runtime, ensuring consistency
- **Container-First**: Services run in containers using podman
- **Atomic Updates**: Full system updates via rpm-ostree with rollback capability
- **Security**: Signed images, SELinux enforcement, SecureBoot support
