# adRise Roku platform

This is the repo for the source code of roku platform.

## Install

After checkout code, please run:

```bash
$ cd tools
$ npm install  # this expect you have node > 4.x installed
```

## Development

### Run local build

To run a local build, you just need to:

```
export ROKU_DEV_TARGET=<your-roku-ip>
$ make install
```

It will automatically build the target from ``src`` to ``build``, including:

* generate manifest file
* generate Settings.brs from configuration
* create a zip file for source files

And it will run then run telnet to listen to the roku console output.

```
$ make install
Generated the file: build/source/Settings.brs.
Project adrise_roku.zip is built with profile dev.
Installing adrise_roku to host 192.168.1.164...(this might take up to a minute)
pplication Received: 774617 bytes stored.
Install Success.</font>
Telnet to 192.168.1.164 8085
Trying 192.168.1.164...
Connected to 192.168.1.164.
Escape character is '^]'.

<here are all the debug output>
```

If you don't like to assign ``ROKU_DEV_TARGET`` every time, please add

```
export ROKU_DEV_TARGET=<your-roku-ip>
```

to your ~/.bash_profile, and run ``source ~/.bashrc`` on current shell. For any new shell it will have this envar defined.

You can also tune the ``ROKU_PROFILE`` with envar. By default it is ``dev``. You can change it to ``production``, ``staging`` and ``test``. Their difference can be found in ``config/*``.


You can set `DEV_PASSWORD` with the developer password set on the roku device if it is something other than the default `1234`


## Test

### Smoke tests

[Smoke tests](docs/tubi_tv_smoke_test.md) should be manually run for each release.

### Run unit tests

``test`` profile is just for testing purpose. If you run this:

```
16:56 $ export ROKU_PROFILE=test
✔ ~/projects/adrise/roku/adrise_roku [feature/add-readme|✚ 1…1]
16:56 $ make install
Generated the file: build/source/Settings.brs.
Project adrise_roku.zip is built with profile test.
Installing adrise_roku to host 192.168.1.164...(this might take up to a minute)

------ Running dev 'tubitv_roku' main ------
Roku_Ads Framework version 1.5
Roku_Ads_checkAllowedFeature: Parsing whitelist for ROKU_ADS_NIELSEN_ID
Starting all the tests...
.......................................................................................................
----------------------------------------------------------------------
Ran 103 tests

OK
```

The code will run all the test suites defined in ``src/source/tests`` only. Run this every time before a pull request is suggested. Later on we will integrate this with jenkins build server.

You can set `DEV_PASSWORD` with the developer password set on the roku device if it is something other than the default `1234`


## Release Process

### Testing

- Smoke tests (manual)
- Run unit tests (white box)
- Run jasmine tests (black box)

### Versioning and Building

- For every submission cycle to Roku:
  - Bump the minor version number, e.g.
  - Reset the build number to 1
  - Update default.yml and staging.yml
	  - Set the hotpatchUrl to `http://.../<major>.<minor>.newUI.brs`
	  - Set the hotPatchUrlOldUI to `http://.../<major>.<minor>.oldUI.brs`
  - Merge contents of n-1 hotpatches to source base
  - Create new empty hotpatch files
  - Update staging.yml
- For every bugfix update, either via internal QA or Roku QA:
  - Bump the build number in build.yml by running `make release`
  - make the build with ROKU_PROFILE=production (`make release` does this)
  - Bump the build number for `remoteComponentsUrl` to `"http://.../tubitv_remote_components_<major>_<minor>_<build>.pkg"`

### Deployment and Internal QA

- Rekey and run `make pkg`
- For major versions
    1. Collect build artifacts
        - tubitv\_remote\_components-\<major\>.\<minor\>.\<build\>.zip (remote components for \<major\>.\<minor\>.\<build\>)
        - tubitv_roku.zip
        - \<major\>.\<minor\>.oldui.brs (oldUI hotpatch)
        - \<major\>.\<minor\>.newui.brs (newUI hotpatch)
    2. Deploy remote components to CDN
    3. Deploy hotpatch files to CDN
- git tag the release
- Push tags to repo
- Create github release for the tag
- Publish staging build to private channel

### Roku Submission

- Send build via Roku portal

### (needs update) Tag the release

Running `make release` will take care of a few steps for prepping a release build.  These include

* Cleaning up any previous builds from the build directory to avoid stale sources
* Verifying a clean build directory to avoid uncommited changes in the build
* Incrementing the build number in the manifest and generated Settings.brs file
* Tagging the source tree

The following is example output of running the release target:



```
$ make release
Incremented the build number to 2.1.33
[release_target c76bb0a] incrementbuild: Bump build number
 1 file changed, 1 insertion(+), 1 deletion(-)
Tagging 2_1_33
Generated the file: build/source/Settings.brs.
Generated the file build/manifest.
Project tubitv_roku.zip is built with profile production.

If you are intending this to be a formal release, create a pull request for the current branch
    git branch release_2_1_33
    git push origin release_2_1_33
Remember to push the new tag to remote with 'git push --tags origin'

```



## Project Layout


| Path | Usage |
| ---- | ----- |
| Makefile| Main project Makefile.  This builds and install the channel |
| /build | build output goes here.  This is not checked in to git. |
| /config | Run-time environment settings for the channel. |
| /docs | Supplemental documentation for the channel |
| /spec | Black box tests for the channel |
| /src | Sources and assets which will be selectively included in the channe zip file, depending on build configuration. |
| /src/3rdparty | 3rd party brightscript sources |
| /src/components | SceneGraph components and accompanying code |
| /src/components/controllers | "Controller"-type scene graph components which control visibility and flow of the application |
| /src/components/lib | Custom Scene-Graph components which are not full screen, i.e. keyboard, left-hand menu |
| /src/components/screens | Custom SceneGraph components which are full screen, usually managed as a stack or workflow from a controller |
| /src/components/tasks | Components derived from Task node which are related to background threads |
| /src/images | Packaged channel image assets |
| /src/source | Non-SceneGraph BrightScript code; Libraries and non-SceneGraph screens |
| /src/source/tests | Unit tests for non-SceneGraph Brightscript code |
| /tools | These are build-time tools based on node.  They are launched from the Makefile. |




## Tubi TV Brightscript Style Guide
Please reference the following style guide for best practices:

[Tubi TV Brightscript Style Guide] (https://gist.github.com/brybott-adrise/ba0233b203a8f5c3ff75d7a59a7ee6e5)