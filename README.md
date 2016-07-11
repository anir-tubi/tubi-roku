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

## Project Layout


| Path | Usage |
| ---- | ----- |
| Makefile| Main project Makefile.  This builds and install the channel |
| /build | build output goes here.  This is not checked in to git. |
| /config | Run-time environment settings for the channel. |
| /docs | Supplemental documentation for the channel |
| /spec | Black box tests for the channel |
| /src | Sources and assets which will be selectively included in the channe zip file, depending on build configuration. |
| /src/components | SceneGraph components and accompanying code |
| /src/components/controllers | "Controller"-type scene graph components which control visibility and flow of the application |
| /src/components/lib | Custom Scene-Graph components which are not full screen, i.e. keyboard, left-hand menu |
| /src/components/screens | Custom SceneGraph components which are full screen, usually managed as a stack or workflow from a controller |
| /src/components/tasks | Components derived from Task node which are related to background threads |
| /src/images | Packaged channel image assets |
| /src/source | Non-SceneGraph BrightScript code; Libraries and non-SceneGraph screens |
| /src/source/tests | Unit tests for non-SceneGraph Brightscript code |
| /tools | These are build-time tools based on node.  They are launched from the Makefile. |
