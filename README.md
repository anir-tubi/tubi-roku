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

2\. Install build tools

```
$ cd tools
$ npm install  # this expect you have node > 4.x installed
```

3\. Enable developer mode on the Roku device remote control:


![](docs/remote.png)

![](docs/dev-mode.png)

4\. Set the developer id on your Roku device

* Navigate to the Roku device's IP in your broswer; select Utilities
* Upload the pkg file and enter the password (get from other roku developers on the team), select `Rekey`

5\. Set the build environment

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


# Release

1\. Run unit tests locally

```
$ make ROKU_PROFILE=test install
```

2\. Deploy to staging

* Before deploying to staging, install the AWS CLI tool.
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

Then run:

```
$ make ROKU_PROFILE=staging install
```

3\. Run functional tests against staging

```
TBD
```

4\. Create production build

```
$ make release
$ git push --tags 
```

5\. Deploy to production (Remote components & submission build)

- Make pull request in [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/) including
  - Remote components bundle: `tubi_remote_components_x_y_z.pkg`
  - Hotpatch: `x.y.brs`

6\. Submit build to Roku (only for submission builds)

- Create a new `new_images_since_x_y` file where x and y are the major and minor build numbers
- Update the Makefile with the new `new_images_since_x_y` path (2 variables should be updated)
- Create a new hotpatch for the new version (ie. 2.7.brs)
- Move any necessary logic from the previous version's hotpatch to the new version's hotpathc
- Update version numbers in `config/build.yml`
  - Increment `minor_version`
  - set `build_version` to `1`
- Update the staging channel store poster located in `./channel-store/channel-store-poster-staging-540x405.png`
- Update the hotpatch url in `./config/staging.yml` to reflect the new build version
- Commit the above changes to master
- --

- Run `make ROKU_PROFILE=staging install`
- Use the "Application Packager" web interface on the Roku device to package the build
- Create a new private channel with the created .pkg file via [developer.roku.com/developer](developer.roku.com/developer)
- --

- Run `make release`
- Upload the .pkg file to Roku via [developer.roku.com/developer](developer.roku.com/developer)
- Email Roku Partner Success to let them know the build is in their queue

7\. Create release in github

- [github.com/adRise/project-total-recall/releases](https://github.com/adRise/project-total-recall/releases)




# Contributing

See [CONTRUBUTING.md](CONTRIBUTING.md)

Last updated by: Jack Hand