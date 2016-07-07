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

