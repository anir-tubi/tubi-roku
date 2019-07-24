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
# Release

1\. Run unit tests locally

```
$ make ROKU_PROFILE=test install
```

2\. Prepare for releases 
- Create a new branch (based off of master), commit changes, and create a Pull Request
- Once the PR has been approved, create a new branch based off of master and call it “[MAJOR_RELEASE]_[MINOR_RELEASE]_branch”: i.e. 2_9_branch. The release number should be 2 builds greater than the current release.  (We increment 2 versions because 1 version is for QA and if nothing goes wrong, then the other time is for a production release.)
- Create a new `new_images_since_x_y` file where x and y are the major and minor build numbers
- Update the Makefile with the new `new_images_since_x_y` path (3 instances should be updated)
- Create a new hotpatch for the new version (ie. 2.9.brs)
- Move any necessary logic from the previous version's hotpatch to the new version's hotpatch
  - Ensure you have 3 comment sections in the hotpatch file
    - "always present"
    - "experiments that will be deleted if no longer needed"
    - "temporary changes that can be assumed (unless noted) can be deleted"
- Update version numbers in `config/build.yml`
  - Increment `minor_version`
  - set `build_version` to `1`

3\. Deploy to staging

* Before deploying to staging, ensure you have the AWS CLI tool installed. If you have not done that yet, then do that now, 
[https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)


* Navigate to your `.aws` directory.

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

- Update the staging channel store to include the new version number. The poster is located in `./channel-store/channel-store-poster-staging-540x405.png`
- Update the value of hotPatchUrl in `./config/staging.yml` to reflect the new build version
- Commit the above changes, and create a new PR. 


To upload the app onto the staging AWS servewr, run:

```
$ make ROKU_PROFILE=staging install
```
- Use the "Application Packager" web interface on the Roku device to package the build
- Update or create a new private channel with the created .pkg file via [developer.roku.com/developer](developer.roku.com/developer)

4\. Run functional tests against staging

```
TBD
```

5\. Deploy Remote components to production
This step can be used to JUST submit the remote components without submitting a new build to Roku.  
- Run the following command:
```
$ make release
```
- Create a new branch in the CDN repo [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/) 
- Copy two files to the CDN repo:
  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z.pkg`) into the folder: hotpatches/roku/componewnts/
  - copy the hot patches file (i.e. `build/hotpatch/x.y.brs`) into folder: hotpatches/roku/
- Submit a Pull Request and if you wish to submit a new build to Roku, then wait for the PR to be approved and the files to be uploaded to the CDN before proceeding to the next step.

6\. Create production build (Submit build to Roku)

- Run the following commands if you diod not run the commands in the previous step:
```
$ make release
$ git push --tags 
```
Note: The above 'make' command will automatically increase the build number in build.yml AND it will also create a new tag for that build.
- Open the hotpatch file in projectTotalRecall/build/hotpatch/ and double check that the version and remoteComponentsUrl match
- Upload the .pkg file to Roku via [developer.roku.com/developer](developer.roku.com/developer)
- Email Roku Partner Success to let them know the build is in their queue


7\. Create release in github
- From the link below, find the tag that corresponds to the release number that was just pushed to production, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)
- Select "Edit Release"
- Update the "Release Title" to be either Submission Release or Remote Release depending on the type of release.
- Add the changes that were included in the release to the "Describe this release" description text box, with each change ending in a period, and on it's own line.
- Select "Update Release"




# Contributing

See [CONTRUBUTING.md](CONTRIBUTING.md)

Last updated by: Jack Hand