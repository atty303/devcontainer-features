
# mise-en-place (mise)

Installs the mise CLI

## Example Usage

```json
"features": {
    "ghcr.io/atty303/devcontainer-features/mise:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Install a specific version | string | latest |
| installPath | Path to install mise | string | /usr/local/bin/mise |
| activate | Select how to activate mise in the system. `none` means no activation, `path` means add to PATH, and `shims` means use shims to activate. Supports bash and zsh. | string | path |
| trust | Automatically run `mise trust` to trust workspace (**WARNING**: `mise.toml` in subdirectories will not be trusted even if this option is enabled) | boolean | true |
| install | Automatically run `mise install` to install workspace tools | boolean | true |

## Notes

To trust all `mise.toml` files including those in workspace subdirectories, add the following to your `devcontainer.json`:

```json
"containerEnv": {
    "MISE_TRUSTED_CONFIG_PATHS": "${containerWorkspaceFolder}"
}
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
