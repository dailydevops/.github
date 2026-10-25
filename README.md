# .github

Daily DevOps &amp; .NET - GitHub Landing Page

This is the special [`.github`](https://docs.github.com/en/organizations/collaborating-with-your-organization/customizing-your-organizations-profile) repository of the [dailydevops](https://github.com/dailydevops) organization. It holds the organization profile and the shared automation behind it.

## Contents

| Path                                                                                           | Purpose                                                                                                           |
| ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| [`profile/README.md`](profile/README.md)                                                       | Organization landing page shown on <https://github.com/dailydevops>. Lists our GitHub Actions and NuGet packages. |
| [`scripts/update-packages.ps1`](scripts/update-packages.ps1)                                   | Queries the NuGet search API for `NetEvolve.*` packages and rewrites the package table in the profile.            |
| [`.github/workflows/update-readme-packages.yml`](.github/workflows/update-readme-packages.yml) | Runs the script daily and opens a pull request with the result.                                                   |
| [`.github/dependabot.yml`](.github/dependabot.yml), [`renovate.json`](renovate.json)           | Dependency update configuration.                                                                                  |
| [`.editorconfig`](.editorconfig)                                                               | Shared editor settings.                                                                                           |

## How the package list stays current

1. The workflow `Update packages in README.md` runs daily at 04:21 UTC, on pushes to `main` that touch the script, and on manual dispatch.
2. `update-packages.ps1` fetches all packages matching `netevolve` from NuGet, keeps those with the `NetEvolve.` prefix, and renders them sorted by id. Deprecated packages are marked.
3. The output replaces everything between the `<!-- packages:start -->` and `<!-- packages:end -->` markers in every `README.*` file that contains them.
4. `peter-evans/create-pull-request` opens a PR titled `docs: Update nuget packages in README.md` if anything changed.

Do not edit the content between the markers by hand, it is overwritten on the next run.

### Run locally

```powershell
./scripts/update-packages.ps1 -WorkingDirectory (Get-Location)
```

## Contributing

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/), e.g. `docs: ...`, `chore(renovate): ...`.
- Changes to the profile text go outside the marker blocks in [`profile/README.md`](profile/README.md).
- Open a pull request against `main`.

## License

[MIT](LICENSE) - Copyright (c) 2024 Daily DevOps &amp; .NET
