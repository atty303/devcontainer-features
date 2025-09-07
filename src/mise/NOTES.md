## Notes

To trust all `mise.toml` files including those in workspace subdirectories, add the following to your `devcontainer.json`:

```json
"containerEnv": {
    "MISE_TRUSTED_CONFIG_PATHS": "${containerWorkspaceFolder}"
}
```
