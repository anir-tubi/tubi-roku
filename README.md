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
$ npm install  # this expect you have node > 4.x installed
```

3\. Enable developer mode on the Roku device remote control:


![](docs/remote.png)

![](docs/dev-mode.png)

When asked to set up a dev password, use "1234" so it's easier for any developer to easily know the password for any device.


4\. Set the developer id on your Roku device. (You will need to get a pkg, password, and developer id from other roku developers on the team).

* Navigate to the Roku device's IP in your broswer; select Utilities. Take note of the IP address for step #5 when you will set the "ROKU_DEV_TARGET".
* Upload the pkg file and enter the password and select `Rekey`. (This password will be used in step #5 to set "PKG_PASSWORD").
* Check that you have the proper developer ID by navigating in your web browser to the Roku device's IP and then select Packager.

5\. Set the build environment. (The following settings are temporary and setting them must be done every time you create a new terminal session.)

```
$ export ROKU_DEV_TARGET=<your-roku-ip>
$ export DEV_PASSWORD=<dev password set up on Roku device>
$ export PKG_PASSWORD=<password from the GENKEY utility used for signing packages>
$ export ROKU_DEV_TELNET=sametab (optional)
```
Pro tip: add these environment variables to your .bashrc or .bash_profile file

6\. Create a `dev.yml` file in your `config` directory. Use the existing `dev.yml.example` file as a template.

7\. Make a development build, sideload to the device, and attach to the developer console

`$ gulp install`

## Using Gulp
To see a list of gulp commands `$ gulp --tasks`

__The most commonly used Gulp commands__
* `$ gulp install` - build a zip and side load it to a device (as set by your ROKU_DEV_TARGET)
* `$ gulp stage` - build a zip using the "staging" config and upload starter components, and remote components to the staging CDN.
* `$ gulp release` - bump the build number, and build a zip using the "production" config. The starter components and remote components are ready to be udloaded to the production CDN.

__Gulp options__
* `--<config>` - for example `$ gulp install --staging` will build and install a zip to the targeted device using the "staging" config. There is a .yml file for each accepted config value in the /config directory.
* ``--<IP>`` - for example `$ gulp install --192.168.42.2` will build and install a zip to the device at the IP "192.168.42.2" instead of the device at "ROKU_DEV_TARGET"
* `--sametab` - for example `$ gulp install --sametab` will open the 8085 telnet port automatically in the same tab in which the gulp command was run.

# Test

1\. Unit tests - run on a sideloaded channel

`$ gulp install --test`

2\. Functional / regression tests - run against staging

[github.com/stb-tester/stb-tester-test-pack-veeta](https://github.com/stb-tester/stb-tester-test-pack-veeta)

[Smoke tests](docs/tubi_tv_smoke_test.md) should be manually run for each release.

3\. If you want to provide someone (i.e. QA) a zip file of the app to [sideload](https://tubitv.atlassian.net/wiki/spaces/EC/pages/879460427/Side+Load+Roku+.zip), you first need to modify temporarily 2 values within the Constants.brs file so it is not trying to load the hotpatch/remote components from the local server:

```
constants.starterComponents = false
constants.remoteComponents = false
```

# Submission Release
Submission releases are releases that are sent to Roku.

1\. Run unit tests locally

`$ gulp install --test`

2\. Prepare for submission release.
- Create a new branch based off of master and call it "x_y_branch", where x is the Major Release number and where y is the Minor Release number: i.e. `2_9_branch`.

- Create a new `new_images_since_x_y` file: i.e. `new_images_since_2_9` in the `new_images_since` directory.

- Update version numbers in `config/build.yml`

  - Increment `minor_version`

  - set `build_version` to `1`

- Create a new image to serve as the staging channel launch icon.
	- Using GIMP or Photoshop or other image editor, modify the `channel-store/channel-store-poster-540x405.png` with some text to identify it as the x_y staging channel.

	- Save the modified image as `channel-store/channel-store-poster-staging-540x405.png`, overwriting the old staging channel launch icon.

- Make a new PR of the `x_y_branch` against master. Once the PR has been merged _DO NOT_ delete the `x_y_branch`, as this will remain the source of truth for what is in production.

3\. Create a staging channel for the minor build
- Run `$ gulp install --staging`

- In a browser, navigate to [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to create a new private channel.

	- Upload the `tubi_x_y_z.pkg` file from the `/build` directory.

	- Name the channel `Staging x_y`.

	- Upload `channel-store/channel-store-poster-staging-540x405.png` as the "Channel Poster".


4\. Deploy to staging

- Before deploying to staging, ensure you have the AWS CLI tool installed. If you have not done that yet, then do that now,
[https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
  - Navigate to your `.aws` directory (typically found at `~/.aws`)

  - In the `config` file set the `AWS_DEFAULT_REGION `.

	```
	[default]
	region = us-west-1
	```
  - In the `credentials` file, set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

	```
	[default]
	aws_access_key_id = <<aws_access_key_id>>
	aws_secret_access_key = <<aws_secret_access_key>>
	```

  - Upload the starter components and remote components onto the staging AWS server, run:

    `$ gulp stage`

5\. Run functional tests against staging

```
TBD
```

6\. Submit build to Roku
- Run the following command to increment the build version number, create a new tag for the build,  and output .pkg files that can be submitted to Roku.

  `$ gulp release`

- In a browser, visit [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to update the "Tubi - Free Movies & TV" channel with the `/build/roku_x_y_z.pkg` file.

7\. Update the starter components and remote component files to the CDN
- Create a new branch in the CDN repo [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/). Although it does not matter, traditionally we name the branch "Roku_x_y_z", where "z" is the patch number.

- Copy two files to the CDN repo:

  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z.pkg`) into the folder: hotpatches/roku/components/

  - copy the starter components file (i.e. `build/tubi_starter_components.x.y.pkg`) into folder: hotpatches/roku/starter-components

- Submit a PR to the CDN repo.

8\. Email Roku Partner Success to let them know the build is in their queue.

9\. Push the tag corresponding to the build that was just pushed to Github `$ git push origin x_y_z`

10\. Create a release on Github
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)

- Select "Edit Release"

- Update the "Release Title" to be either Submission Release or Remote Release depending on the type of release.

- Add the changes that were included in the release to the "Describe this release" description text box, with each change ending in a period, and on it's own line.

- Select "Update Release"


# Remote Release
Remote releases are releases that are not sent to Roku, and updates are made when a device loads the Tubi channel, by downloading the hotpatch and remote component files, which are used to build the channel UI.

1\. Checkout the most recent `x_y_branch` branch, and pull any potential updates from origin. Create a new branch off of the `x_y_branch` called something like `qa_x_y_z`, where x is the Major Release number, where y is the Minor Release number, and where "z" is the patch number.

2\. Cherry pick any commits from `master` that are to be included in the next release onto the `x_y_branch`.
(See [this page](https://www.previousnext.com.au/blog/intro-cherry-picking-git) for more info info on the cherry pick git command.)

Ensure the cherry pick commit names include the name of PR number. This usually is done automaticlly but be aware that we need to have the PR numbers to make it easier later on so we know which PRs have been pushed and which ones have not.

3\. Check each of the cherry picked commits for images that have been added or updated as part of any UI updates. Update the `new_images_since/new_images_since_x_y` file with the image locations of any new or updated images.

4\. Make a new commit on the `qa_x_y_z` branch with the hotpatch and new images updates.

5\. Run `$ gulp bump` in order to increment the version number.

6\. Deploy to staging

- Before deploying to staging, ensure you have the AWS CLI tool installed. If you have not done that yet, then do that now, [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

  - Navigate to your `.aws` directory (typically found at `~/.aws`)

  - In the `config` file set the `AWS_DEFAULT_REGION `.

	```
	[default]
	region = us-west-1
	```
  - In the `credentials` file, set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

	```
	[default]
	aws_access_key_id = <<aws_access_key_id>>
	aws_secret_access_key = <<aws_secret_access_key>>
	```

- Run multifactor authentication for AWS. Typically this means running `$ vauth`
- Upload the starter components and remote components onto the staging AWS server, run:

  `$ gulp stage`

7\. Create a CH ticket with any changes that have been made and give to the QA team for manual testing. Once the QA team has signed off on the build...

8\. Run `$ gulp bump` in order to increment the version number once more (the QA build should not be the same version number as the production build).

9\. Ready the release branch for review

- Rename the `qa_x_y_z` branch to `release_x_y_z`.

- Push the `release_x_y_z` branch to Github.

- Make a PR to the `x_y_branch`.

- __DO NOT PROCEED TO THE INFRA SCRIPT STEP UNTIL THIS PR IS APPROVED__

10\. Update the hotpatch and remote component files to the CDN
- Create a new branch in the CDN repo [github.com/adRise/adrise_cdn/](https://github.com/adRise/adrise_cdn/). Although it does not matter, traditionally we name the branch "Roku_x_y_z".

- Copy two files to the CDN repo:

  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z.pkg`) into the folder: hotpatches/roku/components/

  - copy the starter components file (i.e. `build/tubi_starter_components_x.y.brs`) into folder: hotpatches/roku/starter-components/

- Submit a PR to the CDN repo. Wait for the approval and merging of the PR before proceeding to the next step

12\. Use an infra script to move the updates from the CDN repo to the actual CDN servers.
- Ensure you have the latest files. Update your local version of the [adrise_infrastructure repo](https://github.com/adRise/adrise_infrastructure)
- You may find during this step, that you may not have the correct version of python. If that is the case, then you will need to update your version on python based on your system requirmements. If you are on Mac, you may simply have to run the following command within your adrise_infrastructure repo:

  `$ pyenv`

- In terminal, navigate to your adrise_infrastructure repo and run the installation iunstructions that are found on the infrastructure repo's [README file](https://github.com/adRise/adrise_infrastructure)
- Deploy to the CDN by running the Infra script which is detailed on the [CDN README file](https://github.com/adRise/adrise_cdn/).

13\. Verify the release
- Run a smoke test on production checking at minimum:
    - The production channel loads
		- Video plays
		- Ads play
- Monitor various metrics for signs of any issues:
	- [Ad impressions per second](https://app.datadoghq.com/dashboard/ckr-vrw-xh4/ad-server-business-metrics?from_ts=1563412592034&to_ts=1564017392034&live=true&tile_size=m&fullscreen_widget=80673160&fullscreen_section=overview)

14\. Push the tag corresponding to the build that was just pushed to Github `$ git push origin x_y_z`

15\. Create a release on Github
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)


- Select "Edit Release"

- Update the "Release Title" to be either Submission Release or Remote Release depending on the type of release.

- Add the changes that were included in the release to the "Describe this release" description text box, with each change ending in a period, and on it's own line.

- Select "Update Release"


# Informal QA
Sometimes a feature is given to the QA team before an official staging build is ready for them to test. This allows the QA team to get an early start on testing the feature and create tickets for the Roku dev team in a quicker manner. In order to create an informal QA build, use the `qa` config:

`$ gulp install --qa`

The build will have the following features:
- Write the urls of requests that are made to the 8085 telnet console.
- RAF debug output set to `true` so that RAF output is written to the 8085 debug console.
- Content APIs are set to production. Analytics ingestion API, and Logging API set to staging.
- No starter components or remote components are used.

Send the .zip that is created to the appropriate QA team member along with a Club House ticket requesting testing.

# Suitest
To create a build for Suitest testing, update the `qa.yml` file such that the suitest setting is set to true:

`suitest: true`

Then run:

`$ gulp install --qa`


# Experiments
We may want to see how a new feature will affect the app's metrics from a small group of our users before rolling out the feature to everyone on a given  platform. To do this, we will need to use the popper experiment system to let the app know when an experimental feature should be seen. Below are the details of this process.  

## Setting up the experiment within the Popper Experiment System:

- Set up an experiment JSON file in the popper-config github repo under the namespaces > [NameSpace] > offers. Name the JSON something unique for your experiment: i.e. "roku_trailers.json". Note that we can only have one live experiment per namespace per device? So if we have 4 namespaces, then a max of 4 experiments can be seen on one device. However, in most cases, we will only need to ever have one namespace to contain all of the Roku experiements.

- Each experiment JSON file specifies the number of treatments in a given experiment. For a boolean experiment (A/B test), there will be 2 treatments: on and off ("on" and "control"). Each experiment __must have__ at least one treatment named "control". Other treatments can be named arbitrarily, but typically we use "on" for boolean experiments.

- Each experiment JSON file also specifies the resource associative array associated with each treatment. It is considered best practice to use the values in the resource associative array, rather than using the treatment name to place devices into an experiment experience. A resource associative array is a list of properties that the client code can use during the experiment: i.e. background color. Rather than placing the properties in the client code, we have the option of externalizing the properties in popper so it is easy to make changes in Popper during an experiment without touching the client code.

- Each experiment JSON file also specifies the different time phases of the experiment and when each phase ends. Typically there will be a "qa" phase and a "production" phase.

  Please note that during the "qa" phase, in a response from the Popper API, the experiment name will be prepended with the string "qa.". For example, an experiment with the name `roku_vitg` will be rendered as `qa.roku_vitg` during the qa phase.

- For more infoformation on how to format the experiment JSON files, see the [Popper Config Github repo and its ReadMe file](https://github.com/adRise/popper-config).


## Setting up the experiment within the Roku Code:
- Within TubiExperiments.brs, set up a default experiment resource. Although the popper experiment system can set a default value, we should still set a default resource client-side in case the app cannot communicate to the backend. As previously stated, the resource values provide the code a way to externalize the properties of a given experiment. Locate the defaultResources associative array within the TubiExperiments.brs file and add the default resource associative array within the appropriate namespace.  <br> For example:

	```
	defaultResources: {
		RokuNamespace: {
			roku_trailers: {
				background: "FF0000FF",
				delay: 5000
			}
      	}
	}
	```

- For most experiments, you can stop there. But if you wish to have a default value, then you can set one up. The default value will also be returned by getExperimentValue() when a device is placed into the "control" experiment bucket. To add the default value within the BRS file, you should modify the RokuNamespace associative array within the defaultValues associative array. <br>For example:
	```
	defaultValues: {
		RokuNamespace: {
			roku_trailers: "off"
      	}
	}
	```
- After you have set everything up, then you can have your code check which experiment is turned on and display to the user that experiment. To do this, you simply have to add somewhere in your code (where it makes sense) a call to the getExperimentResource() method to check if an experiment has been turned on.  <br> For example:
	```
	if getExperimentResource("RokuNamespace", "roku_trailers") = "on"
		'//Do something to turn on the experiment throughout the app
	end if
	```
- Alternately, you can call the getExperimentResource() method to get the associative array associated with the experiment and do the appropriate things that are particular to your experiment.  <br> For example:
	```
	'//Set the background color based on the experiment
	properties = getExperimentResource("RokuNamespace", "roku_trailers")
	if properties.background <> invalid
		m.background.color = properties.background
	end if
	```
- Calling getExperimentValue() to return the experiment treatment name, is also possible, though it is not considered best practice, due to resources having more functionality on the Popper server. For example, by updating the default resource in Popper Config, it is possible to update all devices to a specific experiment experience without changing any client code.


# Contributing

See [CONTRUBUTING.md](CONTRIBUTING.md)

Last updated by: Rigo
