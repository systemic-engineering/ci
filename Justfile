[no-exit-message]
check:
    nix develop --command actionlint

[no-exit-message]
pre-commit: check
