# Sharing your app

## Versions

Change `version` in `barry-app.json` with every release you share.
[Semantic versions](https://semver.org) are clearest:

- `1.0.0` → `1.0.1` for fixes,
- `1.1.0` for new features,
- `2.0.0` when something people relied on changes (say, saved data
  starts over).

**Never change the `id`.** It's what makes a new zip an update of the app
people already have (keeping their saved data) instead of a second app.

## Make the zip

```sh
python3 tools/barry-app pack myapp
```

This writes `NAME-VERSION.zip` after checking it installs. It leaves out
`.git`, editor folders and `.DS_Store`.

## Publish on GitHub

A GitHub repository with releases is the easiest way to share an app and
its updates:

1. Put your app folder in a repository, with `tools/` from this repository
   (or the whole of this repository as a starting point).
2. Copy [`.github/workflows/apps.yml`](https://github.com/project-barry/barry-launcher-apps/blob/main/.github/workflows/apps.yml).
   On every push it checks your app and packs it (the zips are under the
   run's **Artifacts**).
3. To release, tag the commit and push the tag:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

   The workflow makes a release with the zip attached. Its download link is
   what you share; people can open it in Firefox on the Thor's bottom
   screen and install from Downloads.

## Tell people what it needs

In your README:

- what the app does, with a screenshot (`barry-app run` and your
  computer's screenshot tool),
- any Qt modules beyond `QtQuick` and `QtCore`, for people on other
  distributions,
- what it saves and whether it uses the network.

## Licensing

Choose a license so people know what they may do with your code. The
example and template here are MIT: copy them freely into your own apps,
under any license you like.

## A store, later

Barry Launcher already keeps `description`, `author` and `homepage` from
each app, for an app list or store to come. Fill them in.
