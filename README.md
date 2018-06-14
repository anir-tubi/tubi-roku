# Tubi Roku Channel

[![Build Status](https://travis-ci.com/adRise/project-total-recall.svg?token=qNG1ev4HcXszAoNpcy3a&branch=master)](https://travis-ci.com/adRise/project-total-recall)

## Setup

Get the sources and set up the toolchain:

```bash
$ git clone git@github.com:adRise/project-total-recall.git
$ cd tools
$ npm install  # this expect you have node > 4.x installed
```

Set up the device and signing keys:

```
export ROKU_DEV_TARGET=<your-roku-ip>
export DEV_PASSWORD=<dev password set up on Roku device>
export PKG_PASSWORD=<password from the GENKEY utility used for signing packages>
```


## Development

### Run local build

To run a local build:

```bash
$ make install
```

Once the build is complete, make will telnet to listen to the roku console on port 8085


**Artifacts:**

    build/hotpatch/x.x.brs				# Hotpatch brightscript file
    build/tubi_x_x_x.zip						# Unsigned client package for sideloading
	build/tubi_remote_components_2_5_1.pkg		# Remove SceneGraph components for dynamic loading


## Test

### Unit tests


Run the unit tests located in `src/source/tests`:

```bash
$ make ROKU_PROFILE=test install
```

Expect output report:

```
------ Running dev 'tubitv_roku' main ------
Roku_Ads Framework version 1.5
Roku_Ads_checkAllowedFeature: Parsing whitelist for ROKU_ADS_NIELSEN_ID
Starting all the tests...
.......................................................................................................
----------------------------------------------------------------------
Ran 103 tests

OK
```

### Manual tests

[Smoke tests](docs/tubi_tv_smoke_test.md) should be manually run for each release.


## Release Process

### Testing

- Manual tests
- Run unit tests (white box)
- ~~Run jasmine tests (black box)~~ `DEFUNCT`

### Deploy to Staging for QA

```bash
$ export AWS_ACCESS_KEY_ID=<s3 staging bucket access_key>
$ export AWS_SECRET_ACCESS_KEY=<s3 staging bucket secret_key>
$ export AWS_DEFAULT_REGION=<s3 staging bucket region>
$ make ROKU_PROFILE=staging install
```

This will:

1. generate a version of the main app that can be used for staging
1. upload hotpatch files and remote components build to a s3 bucket on AWS


### Versioning and Building for Production 


##### Building For Roku Submission
- Verify that the PKG_PASSWORD environment variable is set with the password needed for the production dev id
- Run `make release`. This will:
    - Clean up any previous builds from the build directory to avoid stale sources
    - Verify a clean build directory to avoid uncommited changes in the build
    - Increment the build number in the manifest and generated Settings.brs file
    - Tag the source tree
    - Build `tubi_remote_components.pkg`
    - Build `tubi_roku.pkg`

The following is example output of running the release target:

```
$ make release
Incremented the build number to 2.1.33
[release_target c76bb0a] incrementbuild: Bump build number
 1 file changed, 1 insertion(+), 1 deletion(-)
Tagging 2_1_33
Generated the file: build/source/Settings.brs.
Generated the file build/manifest.
Project tubi_roku.zip is built with profile production.

If you are intending this to be a formal release, create a pull request for the current branch
    git branch release_2_1_33
    git push origin release_2_1_33
Remember to push the new tag to remote with 'git push --tags origin'

```

- Create "empty" hotpatch on the CDN named `x.y.brs`, where x and y are major and minor version numbers.
- Make sure to update the version number in the hotpatch.
- Copy the newly created `tubi_remote_components.pkg` file to the CDN and rename it to `tubi_remote_components_x_y_z.pkg`
- Push the tag created during `make release` to GitHub
- Create a GitHub release for the tag with title "Submission Build" and set as "Pre Release"
- Upload the build to Roku via the development portal
- Email Roku Partner Success to let them know the build is in their queue


##### After Submitting to Roku, Before Starting New Development
  - Bump the minor version number, e.g.
  - Reset the build number to 1
  - Update default.yml
    - Set the hotpatchUrl to `http://.../<major>.<minor>.brs`
  - Merge contents of n-1 hotpatches to source base
  - Create new empty hotpatch file

##### After Roku Deploys our Build
- Update the GitHub release's title to "Submission Release" and set to "Latest Release"
- Create a staging build for the latest production version number and 
  - checkout out the "Submission Release" tag.
  - run `make ROKU_PROFILE=staging install`
  - package the `tubi_roku_x_y_z.zip` file
  - update the staging private channel with the newly created package via the Roku Developer Portal

##### Building for Remote Components Deployment
- **Before updating any functionality, checkout the tag for the latest Roku Submission Release so you are building on what is in production**
- Run `make release`
- Copy the newly created `tubi_remote_components.pkg` file to the CDN and rename it to `tubi_remote_components_x_y_z.pkg` where x, y, and z are the major, minor, and build numbers after the version number was incremented during `make release`
- Update the version number in the hotpatch
- Push the tag created during `make release` to GitHub
- Create a GitHub release for the tag with title "Remote Release"



## Architecture

See [docs/archicture.md](docs/architecture.md) for details architectural information



## Tubi TV Brightscript Style Guide
Please reference the following style guide for best practices:

[Tubi TV Brightscript Style Guide] (https://gist.github.com/brybott-tubi/ba0233b203a8f5c3ff75d7a59a7ee6e5)
