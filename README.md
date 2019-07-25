# Tubi Roku Channel


[![Build Status](https://travis-ci.com/adRise/project-total-recall.svg?token=qNG1ev4HcXszAoNpcy3a&branch=master)](https://travis-ci.com/adRise/project-total-recall)


## Production Channel

![Staging Channel Logo](channel-store/channel-store-poster-540x405.png)

Roku Channel Store: [channelstore.roku.com/details/41468/tubi](https://channelstore.roku.com/details/41468/tubi)

Direct Install: [my.roku.com/add/tubitv](https://my.roku.com/add/tubitv)

## Staging Channel

![Staging Channel Logo](channel-store/channel-store-poster-staging-540x405.png)

Direct Install: [my.roku.com/add/NDDHPHK](https://my.roku.com/add/NDDHPHK)





-----

# Build

1\. Clone repo:

```
$ git clone git@github.com:adRise/project-total-recall.git
```

2\. Navigate to the github repo in terminal and then install build tools

```
$ cd tools
$ npm install  # this expect you have node > 4.x installed
$ cd ..
```

3\. Enable developer mode on the Roku device remote control:


![](docs/remote.png)

![](docs/dev-mode.png)

When asked to set up a dev password, use "1234" so it's easier for any developer to easily know the password for any device.


4\. Set the developer id to "c1e4c3108580bda0bdb8c690284c7d83c6b0a5a7" on your Roku device

* Navigate to the Roku device's IP in your broswer; select Utilities. Take note of the IP address for step #5 when you will set the "ROKU_DEV_TARGET".
* Upload the pkg file and enter the password and select `Rekey`. (Get both the pkg and password from other roku developers on the team. This password will be used in step #5 to set "PKG_PASSWORD".)
* Check that you have the proper developer ID by navigating in your web browser to the Roku device's IP and then select Packager

5\. Set the build environment. (The following settings are temporary and setting them must be done everytime you create a new terminal session.)

```
$ export ROKU_DEV_TARGET=<your-roku-ip>
$ export DEV_PASSWORD=<dev password set up on Roku device>
$ export PKG_PASSWORD=<password from the GENKEY utility used for signing packages>
```

6\. Make a development build, sideload to the device, and attach to the developer console

```
$ make install
```



# Test

1\. Unit tests - run on a sideloaded channel

```
$ make ROKU_PROFILE=test install
```

2\. Functional / regression tests - run against staging

[github.com/stb-tester/stb-tester-test-pack-veeta](https://github.com/stb-tester/stb-tester-test-pack-veeta)

[Smoke tests](docs/tubi_tv_smoke_test.md) should be manually run for each release.

3\. If you want to provide someone (i.e. QA) a zip file of the app to [sideload](https://tubitv.atlassian.net/wiki/spaces/EC/pages/879460427/Side+Load+Roku+.zip), you first need to modify temporarily 2 values within the Constants.brs file so it is not trying to load the hotpatch/remote components from the local server:

```
constants.remoteComponents = false
constants.useHotpatch = false
```
# Submission Release
Submission releases are releases that are sent to Roku.

1\. Run unit tests locally

```
$ make ROKU_PROFILE=test install
```

2\. Prepare for submission release.
- Create a new branch based off of master and call it “[MAJOR_RELEASE]_[MINOR_RELEASE]_branch”: i.e. `2_9_branch`.

- Create a new `new_images_since_x_y` file where x and y are the major and minor build numbers: i.e. `new_images_since_2_9`

- Update the Makefile with the new `new_images_since_x_y` path (3 instances should be updated)
- Create a new hotpatch for the new version: ie. `2.9.brs`

- Move any necessary logic from the previous version's hotpatch to the new version's hotpatch

  - Ensure you have 2 comment sections in the hotpatch file
    - "always present"

    - "temporary changes that can be can be deleted unless noted otherwise"

- Update version numbers in `config/build.yml`

  - Increment `minor_version`

  - set `build_version` to `1`

- Update the value of hotPatchUrl in `./config/staging.yml` to reflect the new build version.

- Make a new PR of the `x_y_branch` against master. Once the PR has been merged _DO NOT_ delete the `x_y_branch`, as this will remain the source of truth for what is in production.

3\. Create a staging channel for the minor build
- Run `make ROKU_PROFILE=staging install`

- Navigate to the `/build` directory, and note the `tubi_x_y_z.pkg file`, you will be creating a private Roku channel with this file.

- Create a new image to serve as the staging channel launch icon.
	- Using GIMP or Photoshop or other image editor, modify the `channel-store/channel-store-poster-540x405.png` with some text to identify it as the x_y staging channel.

	- Save the modified image as `channel-store/channel-store-poster-staging-540x405.png`, overwriting the old staging channel launch icon.

- In a browser, navigate to [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to create a new private channel.

	- Upload the `build/tubi_x_y_z.pkg` file.

	- Name the channel `Staging x_y`.

	- Upload `channel-store/channel-store-poster-staging-540x405.png` as the "Channel Poster".


4\. Deploy to staging

* Before deploying to staging, ensure you have the AWS CLI tool installed. If you have not done that yet, then do that now,
[https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)


* Navigate to your `.aws` directory (typically found at `~/.aws`)

* In the `config` file set the `AWS_DEFAULT_REGION `.

	```
	[default]
	region = us-west-1
	```
* In the `credentials` file, set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

	```
	[default]
	aws_access_key_id = <<aws_access_key_id>>
	aws_secret_access_key = <<aws_secret_access_key>>
	```

* Upload the hotpatch and remote components onto the staging AWS server, run:

```
$ make ROKU_PROFILE=staging install
```

5\. Run functional tests against staging

```
TBD
```

6\. Submit build to Roku
- Run the following command to increment the build version number, create a new tag for the build,  and output .pkg files that can be submitted to Roku.
```
$ make release
```
- In a browser, visit [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to update the "Tubi - Free Movies & TV" channel with the `/build/roku_x_y_z.pkg` file.

7\. Update the hotpatch and remote component files to the CDN
- Create a new branch in the CDN repo [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/)

- Copy two files to the CDN repo:

  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z.pkg`) into the folder: hotpatches/roku/components/

  - copy the hotpatch file (i.e. `build/hotpatch/x.y.brs`) into folder: hotpatches/roku/

- Submit a PR to the CDN repo.

8\. Email Roku Partner Success to let them know the build is in their queue.

9\. Push the tag corresponding to the build that was just pushed to Github `git push origin x_y_z`

10\. Create a release on Github
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)


- Select "Edit Release"

- Update the "Release Title" to be either Submission Release or Remote Release depending on the type of release.

- Add the changes that were included in the release to the "Describe this release" description text box, with each change ending in a period, and on it's own line.

- Select "Update Release"


# Remote Release
Remote releases are releases that are not sent to Roku, and updates are made when a device loads the Tubi channel, by downloading the hotpatch and remote component files, which are used to build the channel UI.

1\. Checkout the most recent `x_y_branch` branch, and pull any potential updates from origin. Create a new branch off of the `x_y_branch` called something like `qa_x_y_z`.

2\. Cherry pick any commits from `master` that are to be included in the next release onto the `x_y_branch`.

3\. Check each of the cherry picked commits for updates to `Constants.brs` or `TubiChannel.brs`. If any updates have been made to either of these files, copy the changes into `x.y.brs` hotpatch file in the "temporary changes that can be can be deleted unless noted otherwise" section.

4\. Check each of the cherry picked commits for images that have been added or updated as part of any UI updates. Update the `new_images_since_x_y` file with the image locations of any new or updated images.

5\. Make a new commit on the `qa_x_y_z` branch with the hotpatch and new images updates.

6\. Run `make release` in order to increment the version number.

7\. Deploy to staging by running `make ROKU_PROFILE=staging install`. (See instructions for setting up AWS CLI in Submission Release section 4 if you have not yet up AWS CLI).

8\. Create a CH ticket with any changes that have been made and give to the QA team for manual testing. Once the QA team has signed off on the build...

9\. Run `make release` in order to increment the version number once more (the QA build should not be the same version number as the production build).

10\. Update the hotpatch and remote component files to the CDN
- Create a new branch in the CDN repo [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/)

- Copy two files to the CDN repo:

  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z.pkg`) into the folder: hotpatches/roku/components/

  - copy the hotpatch file (i.e. `build/hotpatch/x.y.brs`) into folder: hotpatches/roku/

- Submit a PR to the CDN repo.

11\. Use an infra script to move the updates to the CDN repo to the actual CDN servers. (Please see the [CDN README](github.com/adRise/adrise_cdn/) for more info).

12\. Verify the release
- Run a smoke test on production checking at minimum:
    - The production channel loads
		- Video plays
		- Ads play
- Monitor various metrics for signs of any issues:
	- [Ad impressions per second](https://app.datadoghq.com/dashboard/ckr-vrw-xh4/ad-server-business-metrics?from_ts=1563412592034&to_ts=1564017392034&live=true&tile_size=m&fullscreen_widget=80673160&fullscreen_section=overview)

13\. Push the tag corresponding to the build that was just pushed to Github `git push origin x_y_z`

14\. Create a release on Github
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)


- Select "Edit Release"

- Update the "Release Title" to be either Submission Release or Remote Release depending on the type of release.

- Add the changes that were included in the release to the "Describe this release" description text box, with each change ending in a period, and on it's own line.

- Select "Update Release"




# Contributing

See [CONTRUBUTING.md](CONTRIBUTING.md)

Last updated by: Jack Hand
