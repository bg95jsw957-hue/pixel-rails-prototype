# Pixel Rails — Prototype

Godot 4.7.2 web prototype: Omaha→Sacramento corridor, 1865 scenario.

## Run tests
```
godot --headless --path . -s res://tests/test_runner.gd
```

## Export web (threads off for iOS Safari)
```
godot --headless --path . --export-release "Web" export/web/index.html
```
