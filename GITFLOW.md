# Git Flow

This repository uses Git Flow.

## Branches

- `main`: production-ready code only.
- `develop`: integration branch for ongoing work.
- `feature/*`: new features, branched from `develop`, merged back into `develop`.
- `bugfix/*`: non-production bug fixes, branched from `develop`, merged back into `develop`.
- `release/*`: release preparation, branched from `develop`, merged into `main` and `develop`.
- `hotfix/*`: urgent production fixes, branched from `main`, merged into `main` and `develop`.
- `support/*`: long-lived support work when needed.

## Daily Workflow

1. Start new work from `develop`.
2. Use a Git Flow branch name, for example `feature/image-preview`.
3. Commit only on `develop` or Git Flow work branches.
4. Do not commit directly on `main`.
5. Merge finished work back through the appropriate Git Flow branch path.

## Examples

```sh
git switch develop
git switch -c feature/my-change
git commit -m "Add my change"
```

For releases:

```sh
git switch develop
git switch -c release/1.0.0
```

For urgent production fixes:

```sh
git switch main
git switch -c hotfix/1.0.1
```
