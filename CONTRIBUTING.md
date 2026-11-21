# Contributing

Thanks for wanting to help! Hyprdock is young, so every bug report and idea is useful.

## Reporting a bug
Open an issue and include:
- your distro, Hyprland version (`hyprctl version`) and Quickshell version
- what you expected and what happened
- the output of `hyprdock` run in a terminal (errors show up there)

## Sending code
1. Fork the repo and create a branch: `git checkout -b my-change`
2. Run the dock straight from the folder (no install needed): `./bin/hyprdock`
3. Keep changes small and focused; one feature or fix per pull request.
4. Describe what you changed and how you tested it.

## Project layout
| Folder        | What is inside                                       |
|---------------|------------------------------------------------------|
| `components/` | The dock itself and its icons                        |
| `services/`   | Config, Hyprland state, launching                    |
| `settings/`   | The settings window and its small widgets            |
| `docs/`       | Extra documentation                                  |

## Style
- QML: 4 spaces, JetBrains Mono, colors only from `services/Theme.qml`.
- Shell: POSIX `sh`, check with `sh -n install.sh`.
- User-visible text is English.
