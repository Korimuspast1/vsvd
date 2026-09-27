# Modding Guide

Mods should be placed in `user://mods/<mod_name>/` with a `mod.cfg` file. The scaffold is data-driven; new signals, items, emails, upgrades, achievements, and entities can be provided as `.tres` resources matching the resource scripts under `res://resources/`.

## Signal mod example

Create a `SignalData` resource with a unique `id`, display name, object type, quality, frequency band, altitude bands, and optional decoded text/audio/spectrogram paths. A future `ModAPI` singleton can call `SignalDatabase.register_signal(resource)` at startup.

## Content rules

Ship only original or properly licensed content. Do not include assets extracted from commercial games.
