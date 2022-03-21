# Contributing to Tubi Roku channel


# Architecture

See [docs/archicture.md](docs/architecture.md) for details architectural information


# Style Guide

[Tubi TV Brightscript Style Guide] (https://gist.github.com/brybott-tubi/ba0233b203a8f5c3ff75d7a59a7ee6e5)


# Branching & Pull Requests

See [barro.github.io/2016/02/a-succesful-git-branching-model-considered-harmful/](https://barro.github.io/2016/02/a-succesful-git-branching-model-considered-harmful/) for our general branching strategy

Key points:

- `master` is for latest features
- Developers create local branches off `master`
- Pull requests are made against `master` for a feature once it's ready
- Releases branch from `master`
- Releases have no long-lived branch but tags exist and have an associated Github Release


# Code Reviews

Code reviews:

- are done on pull requests by someone other than the submitter
- should test the branch to make sure functional requirements are met
- should review the code for logic errors, style errors, opportunities for improvement


# Version numbers

Version numbers are semantic versioning and used as [Roku Channel Manifest](https://sdkdocs.roku.com/display/sdkdoc/Roku+Channel+Manifest) version numbers.

* Major version increments with huge changes in the channel (such as a rewrite)
* Minor version increments when channel is submitted to Roku channel certification process
* Build version increments when remote components are deployed
* Revision version increments when QA revisions are made


