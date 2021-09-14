# Tubi Roku Channel


[![Build Status](https://travis-ci.com/adRise/project-total-recall.svg?token=qNG1ev4HcXszAoNpcy3a&branch=master)](https://travis-ci.com/adRise/project-total-recall)


## Production Channel

![Staging Channel Logo](channel-store/channel-store-poster-540x405.png)

Roku Channel Store: [channelstore.roku.com/details/41468/tubi](https://channelstore.roku.com/details/41468/tubi)

Direct Install: [my.roku.com/add/tubitv](https://my.roku.com/add/tubitv)

## Staging Channel

![Staging Channel Logo](channel-store/channel-store-poster-staging-540x405.png)

Direct Install: [my.roku.com/add/NDDHPHK](https://my.roku.com/add/NDDHPHK)




# Getting Started
1\. Clone repo:

```
$ git clone git@github.com:adRise/project-total-recall.git
```
2\. Install Node (and npm)
https://nodejs.org/en/

3\. Install NPX
```
npm install -g npx
```
4\. Install Gulp CLI
```
npm install -g gulp-cli
```
5\. Navigate to the project-total-recall directory
```
cd project-total-recall
```
6\. Install build libraries from npm (make sure node > 4.x is installed)
```
npm install
```
7\. Enable developer mode on the Roku device remote control:


![](docs/remote.png)

![](docs/dev-mode.png)

When asked to set up a dev password, use "1234" so it's easier for any developer to easily know the password for any device.


8\. Set the developer id on your Roku device. (You will need to get a pkg, password, and developer id from the shared secret "Roku Rekey Info" in LastPass).

* Navigate to the Roku device's IP in your broswer; select Utilities. Take note of the IP address for step #6 when you will set the "ROKU_DEV_TARGET".
* Upload the pkg file and enter the password and select `Rekey`. (This password will be used in step #6 to set "PKG_PASSWORD").
* Check that you have the proper developer ID by navigating in your web browser to the Roku device's IP and then select Packager.

9\.Create a Github Peronal Access Token (this access token will be set as an environment variable in step #6):
  - Follow the instructions at https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token
  - Only select the "repo" scope and "repo" sub scopes.
  - Copy the token, as you will not be able to see it again once you leave the page.

10\. Set the build environment. Add the following environment variables to the appropriate shell configuration file:
- .zprofile for ZSH (ZSH is the default shell for new Macs.)
- .bash_profile for BASH on Macs
- .bashrc for BASH on Linux
(It might need a restart to take effect.)
```
export ROKU_DEV_TARGET="<your-roku-ip>""
export DEV_PASSWORD="<dev password set up on Roku device>"
export PKG_PASSWORD="<password from the GENKEY utility used for signing packages>"
export CDN_GIT_DIRECTORY="<path to the adrise_cdn repo directory ex: ~/dev/adrise_cdn>"
export GITHUB_PAT="<github personal access token>"
export ROKU_DEV_TELNET="sametab" (optional)
```

11\. Create a `dev.yml` file in your `config` directory. Use the existing `dev.yml.example` file as a template.

-----

# Build
Make a development build, sideload to the device, and attach to the developer console
```
$ gulp install
```

## Using Gulp
To see a list of gulp commands `$ gulp --tasks`

__The most commonly used Gulp commands__
* `$ gulp install` - build a zip and side load it to a device (as set by your ROKU_DEV_TARGET)
* `$ gulp stage` - build a zip using the "staging" config and upload starter components, and remote components to the staging CDN.
* `$ gulp release` - bump the build number, build starter and remote components .pkgs using the "production" config. This command will also make PRs to the CDN repo and this project-total-recall repo on Github.

__Gulp options__
* `--<config>` - for example `$ gulp install --staging` will build and install a zip to the targeted device using the "staging" config. There is a .yml file for each accepted config value in the /config directory.
* ``--<IP>`` - for example `$ gulp install --192.168.42.2` will build and install a zip to the device at the IP "192.168.42.2" instead of the device at "ROKU_DEV_TARGET"
* `--sametab` - for example `$ gulp install --sametab` will open the 8085 telnet port automatically in the same tab in which the gulp command was run.

# Test

1\. Unit tests - run on a sideloaded channel using the Rooibos test framework.

For more info on setting up tests in Rooibos, please see:

https://github.com/georgejecook/rooibos/blob/master/docs/index.md#creating-test-suites

For API documentation (ie. what asserts can be run), please see:

https://georgejecook.github.io/rooibos/

To run unit tests, run the following command:

`$ gulp test`

2\. Functional / regression tests - run against staging

[github.com/stb-tester/stb-tester-test-pack-veeta](https://github.com/stb-tester/stb-tester-test-pack-veeta)

[Smoke tests](docs/tubi_tv_smoke_test.md) should be manually run for each release.

3\. If you want to provide someone (i.e. QA) a zip file of the app to [sideload](https://tubitv.atlassian.net/wiki/spaces/EC/pages/879460427/Side+Load+Roku+.zip), please see the section titled "Informal QA".

# Submission Release
Submission releases are releases that are sent to Roku.

1\. Set up the environment variables (listed in the [build step](#build)) as some of the following steps are dependant on these variables.

2\. Run unit tests locally

`$ gulp test`

Note: If you are adding a new unit test, then you can test only this new unit test. You do this by temporarily adding the "@Only" comment right before a specific unit test before running the above command. 

3\. Prepare for submission release.
- Create a new branch based off of master which will be used to make updates as needed for a submission release. Branch name is not important, but for clarity it can be something like: `updates_for_x_y_submission`, where x is the Major Release number and where y is the Minor Release number: i.e. `updates_for_2_14_submission`.

- Create a new `new_images_since_x_y` file: i.e. `new_images_since_2_9` in the `new_images_since` directory.

- Update version numbers in `config/build.yml`

  - Increment `minor_version`

  - set `build_version` to `0`

- Create a new image to serve as the staging channel launch icon.
	- Using GIMP or Photoshop or other image editor, modify the `channel-store/channel-store-poster-540x405.png` with some text to identify it as the x_y staging channel.

	- Save the modified image as `channel-store/channel-store-poster-staging-540x405.png`, overwriting the old staging channel launch icon.

- Make a new PR of the `x_y_branch` against master. Once the PR has been merged delete the branch as normal.

- Create a new branch off of master named "x_y_branch", where x is the Major Release number and where y is the Minor Release number: i.e. `2_14_branch`. Push this branch to Github. This branch will serve as the source of truth for what is in production until the next submission release.

4\. Create a staging channel for the minor build from the `x_y_branch`
- Run `$ gulp install --staging`

- In a browser, navigate to [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to create a new private channel.

	- Upload the `tubi_x_y_z.pkg` file from the `/build` directory.

	- Name the channel `Staging x_y`.

	- Upload `channel-store/channel-store-poster-staging-540x405.png` as the "Channel Poster".


5\. Deploy to staging

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

6\. Run functional tests against staging

```
TBD
```

7\. After QA Sign Off, run `$ gulp release`. This will:
  - increment the version number once more (the QA build should not be the same version number as the production build)
  - install a new build using the "production" config, to create the .pkgs needed to update the production build.
  - rename the current branch to `release_x_y_z`.
  - copy the tubi_starter_components_x_y_z.pkg and tubi_remote_components_x_y_z.pkg files to the local CDN repo.
  - update the local CDN repo by doing the following:
    - checking out master
    - pulling master from origin
    - creating a new branch called `roku_x_y_z`
  - push the `roku_x_y_z` branch to origin
  - make a PR against `master` from the `roku_x_y_z` branch.
  - push the `release_x_y_z` branch to Github.
  - make a PR to the `x_y_branch` on Github from the `release_x_y_z` branch.
  - copy the Github urls for the two PRs made above to the clipboard.


    __Note:__ As an edge case, if you need to manually perform the release steps for the new build, follow the [Manual Submission Release Steps](https://github.com/adRise/project-total-recall/docs/manual_release.md#submission-release)

8\. Inform the team that the PRs are ready for review (you can paste the urls that were added to the clipboard when the last step completed, into the `#roku_dev slack channel`. The PR URLs can also be found on the project-total-recall and adrise_cdn repos respectively), and wait for approval.

9\. Merge the new PR in the adrise_cdn repo. Also merge the release_x_y_z PR into the x_y_branch branch. Once merged, delete both of these branches.

10\. check if you need to tun multifactor authentication for AWS. Typically this means running `$ vauth`. Refer to the [valet repo](https://github.com/adRise/valet#installation) on how to install the vauth command.

- __DO NOT PROCEED TO THE FOLLOWING INFRA SCRIPT STEP UNTIL THE PR FOR THE adRise_cdn REPO AND THE PR FOR THE project-total-recall REPO ARE APPROVED AND MERGED.__

11\. Use an infra script to move the updates from the CDN repo to the actual CDN servers.
- Ensure you have the latest files. Update your local version of the [adrise_infrastructure repo](https://github.com/adRise/adrise_infrastructure)
- You may find during this step, that you may not have the correct version of python. If that is the case, then you will need to update your version on python based on your system requirmements. If you are on Mac, you may simply have to run the following command within your adrise_infrastructure repo:

  `$ pyenv`

- If you still need to setup Infra, then in terminal, navigate to your adrise_infrastructure repo and run the setup instructions that are found on the infrastructure repo's [README file](https://github.com/adRise/adrise_infrastructure#setup)
- Deploy to the CDN by running the Infra script which is detailed on the [CDN README file](https://github.com/adRise/adrise_cdn/#deploy-to-aws-s3).

12\. Submit build to Roku
- In a browser, visit [https://developer.roku.com/developer-channels/channels](https://developer.roku.com/developer-channels/channels), sign in, and follow the process to update the "Tubi - Free Movies & TV" channel with the `/build/roku_x_y_z.pkg` file.

13\. Email Roku Partner Success to let them know the build is in their queue.

14\. Push the tag corresponding to the build that was just pushed to Github `$ git push origin x_y_z`

15\. Once the channel update has been released by Roku, create a release on Github
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)

- Select "Edit Tag"
- If you made a pre-release as part of step #7, uncheck the "This is a pre-release" box and then select "Update Release". You can skip the other sub steps of step #12.
- Update the "Release Title" to be either "Submission Release" or "Remote Release" depending on the type of release.

- In the description area, add the date on which the release was actually deployed (ideally this is the same day as the Github release is being created, but sometimes it might not be.

- Also within the description area, add the changes that were included in the release to the "Describe this release" description text box. As it was mentioned earlier, use the the changes that were submitted to the QA Club House ticket that you made earlier. Each change should be on its own line and end with a period. Remember do not use commit messages, but rather write simple phrases or sentences that are easy to digest and accurately describe what the change was. Assume non technical readers will be consuming this information.

- Select "Publish Release"


# Remote Release
Remote releases are releases that are not sent to Roku, and updates are made when a device loads the Tubi channel, by downloading the starter component and remote component files, which are used to build the channel UI.

1\. Set up the environment variables (listed in the [build step](#build)) if not done already, as some of the following steps are dependent on these variables.

2\. Run `$ gulp compare`. This will do the following:
  - fetch any commits from remote `master` to local `master`
  - fetch any commits from the most recent remote `x_y_branch` to the local `x_y_branch`.
  - Compare the last 200 commits on local `master` with the last 200 commits on the local `x_y_branch`, and print out a list of commits that exist on local `master` but have not yet been cherry picked to the local `x_y_branch`.

3\. Checkout the most recent `x_y_branch` branch. Create a new branch off of the `x_y_branch` called something like `qa_x_y_z`, where x is the Major Release number, where y is the Minor Release number, and where "z" is the patch number.

4\. Cherry pick any commits from local `master` that are to be included in the next release onto the qa branch `qa_x_y_z`.
(See [this page](https://www.previousnext.com.au/blog/intro-cherry-picking-git) for more info info on the cherry pick git command.)

Ensure the cherry pick commit names include the name of PR number. This usually is done automatically but be aware that we need to have the PR numbers to make it easier later on so we know which PRs have been pushed and which ones have not.

5\. Check each of the cherry picked commits for images that have been added or updated as part of any UI updates. Update the `new_images_since/new_images_since_x_y` file with the image locations of any new or updated images.

6\. Make a new commit on the `qa_x_y_z` branch with the hotpatch and new images updates.

7\. Run `$ gulp bump` in order to increment the version number.

8\. Deploy to staging

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

- Run multifactor authentication for AWS. Typically this means running `$ vauth`. Refer to the [valet repo](https://github.com/adRise/valet#installation) on how to install the vauth command.
- Upload the starter components and remote components onto the staging AWS server, run:

  `$ gulp stage`

9\. Create a CH ticket with any changes that have been made and give the ticket the QA team for manual testing. Make sure the changes are written in such a way that non technical readers will be able to consume this information. The title of the changes will be used in one of the last steps when creating a release within Guthub.

10\. Any bugs found by QA should be fixed, committed to master, and then cherry picked into this QA build.

11\. After QA Sign Off, run `$ gulp release`. This will:
  - increment the version number once more (the QA build should not be the same version number as the production build)
  - install a new build using the "production" config, to create the .pkgs needed to update the production build.
  - rename the current branch to `release_x_y_z`.
  - copy the tubi_starter_components_x_y_z.pkg and tubi_remote_components_x_y_z.pkg files to the local CDN repo.
  - update the local CDN repo by doing the following:
    - checking out master
    - pulling master from origin
    - creating a new branch called `roku_x_y_z`
  - push the `roku_x_y_z` branch to origin
  - make a PR against `master` from the `roku_x_y_z` branch.
  - push the `release_x_y_z` branch to Github.
  - make a PR to the `x_y_branch` on Github from the `release_x_y_z` branch.
  - copy the Github urls for the two PRs made above to the clipboard.
  - create a tag based on the last commit named `x_y_z`
  - push the tag to Github
  - prompt you to make a Github release (including adding build notes) in the CLI based on the tag that was just created. __If you choose not to make a release in the CLI, you must do step 14.__
    - Each build note should be correspond to a change that was submitted as part of the QA Club House ticket that you made earlier. Remember, do not use commit messages, but rather write simple phrases or sentences that are easy to digest and accurately describe what the change was. Assume non technical readers will be consuming this information.

  __Note:__ As an edge case, if you need to manually perform the release steps for the new build, follow the [Manual Remote Release Steps](https://github.com/adRise/project-total-recall/docs/manual_release.md#remote-release)

12\. Inform the team that the PRs are ready for review (you can paste the urls that were added to the clipboard when the last step completed, into the `#rokudev slack channel`. The PR URLs can also be found on the project-total-recall and adrise_cdn repos respectively), and wait for approval.

13\. Merge the new PR in the adrise_cdn repo. Also merge the release_x_y_z PR into the x_y_branch branch. Once merged, delete both of these branches.

14\. check if you need to tun multifactor authentication for AWS. Typically this means running `$ vauth`. You ran this in a previous step, but some time may has passed and you may have to run it again. Refer to the [valet repo](https://github.com/adRise/valet#installation) on how to install the vauth command.


- __DO NOT PROCEED TO THE FOLLOWING INFRA SCRIPT STEP UNTIL THIS PR AND THE PREVIOUS PRs ARE APPROVED__


15\. Use an infra script to move the updates from the CDN repo to the actual CDN servers.
- Ensure you have the latest files. Update your local version of the [adrise_infrastructure repo](https://github.com/adRise/adrise_infrastructure)
- You may find during this step, that you may not have the correct version of python. If that is the case, then you will need to update your version on python based on your system requirements. If you are on Mac, you may simply have to run the following command within your adrise_infrastructure repo:

  `$ pyenv`

- If you still need to setup Infra, then in terminal, navigate to your adrise_infrastructure repo and run the setup instructions that are found on the infrastructure repo's [README file](https://github.com/adRise/adrise_infrastructure#setup)
- Deploy to the CDN by running the Infra script which is detailed on the [CDN README file](https://github.com/adRise/adrise_cdn/#deploy-to-aws-s3).

16\. Verify the release
- Run a smoke test on production checking at minimum:
    - The production channel loads
		- Video plays
		- Ads play
- Monitor various metrics for signs of any issues:
	- [Ad impressions per second](https://app.datadoghq.com/dashboard/ckr-vrw-xh4/ad-server-business-metrics?from_ts=1563412592034&to_ts=1564017392034&live=true&tile_size=m&fullscreen_widget=80673160&fullscreen_section=overview)

17\. Create a release on Github (only if you did not create a release in the CLI as part of step 9). As part of the release script, a tag was automatically created and pushed to Github.
- From the following link, find the tag that was just pushed to Github, and click on the link for that tag.
	- [github.com/adRise/project-total-recall/tags](https://github.com/adRise/project-total-recall/tags)


- Select "Edit Tag"

- Update the "Release Title" to be either "Submission Release" or "Remote Release" depending on the type of release.

- In the description area, add the date on which the release was actually deployed (ideally this is the same day as the Github release is being created, but sometimes it might not be).

- Also within the description area, add the changes that were included in the release to the "Describe this release" description text box. As it was mentioned earlier, use the the changes that were submitted to the QA Club House ticket that you made earlier. Each change should be on its own line and end with a period. Remember do not use commit messages, but rather write simple phrases or sentences that are easy to digest and accurately describe what the change was. Assume non technical readers will be consuming this information.

- Select "Publish Release"


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

- For more information on how to format the experiment JSON files, see the [Popper Config Github repo and its ReadMe file](https://github.com/adRise/popper-config).


## Deploying an experiment on Popper Staging:
- Run the `$ vauth` command

- Before you can deploy to staging, you need to ensure your ssh config file has been updated with the ip addresses and hostname info of the popper staging location. This info can be found under "[popper-engine-roku]" in the [staging inventory](https://github.com/adRise/adrise_infrastructure/blob/master/inventory/staging/staging#L317).

- Please follow the [SSH Access Instructions](https://github.com/adRise/adrise_infrastructure#ssh-access) while using the popper info from the previous step to set up your SSH Config file. Below is an example of what is added to the .ssh/config file. (Note: on the Mac, the ssh config file is located in [user]/.ssh/config, where "user" is the username on your mac.)

  ```
  Host popper-engine-roku-01 172.30.27.29
   User ubuntu
   Hostname 172.30.27.29
   IdentityFile ~/.ssh/adrise_aws_ohio_staging.pem
   ProxyCommand ssh -A -q -W %h:%p bastion-staging-1
  ```
  - where the "IdentityFile" is the PEM file you set up for the staging server as described in the SSH Access Instructions,
  - where the "host" and "hostname" (the IP address) are the popper staging info gathered from the previous step

- Once you have set up your ssh config file, you can now follow the directions on how to deploy your JSON popper configuration changes, see [[How to deploy to staging instructions](https://github.com/adRise/popper-config/blob/master/doc/Deployment.md#how-to-deploy-to-staging)]


## Setting up the experiment within the Roku Code:
- Within TubiExperiments.brs, set up a default experiment resource. Although the Popper experiment system can set a default value, we should still set a default resource client-side in case the app cannot communicate to the backend. Additionally, when the experiment ends, Popper will cease to provide a resource for the experiment, so the default resource will be used as a fallback. As previously stated, the resource values provide the code a way to externalize the properties of a given experiment. Locate the defaultResources associative array within the TubiExperiments.brs file and add the default resource associative array within the appropriate namespace.  <br> For example:

	```
	defaultResources: {
		RokuNamespace: {
			roku_trailers: {
				background: "FF0000FF",
				delay: 5000
        on: false
			}
      	}
	}
	```

- After you have set everything up, then you can have your code check which experiment is turned on and display to the user that experiment. To do this, you simply have to add somewhere in your code (where it makes sense) a call to the getExperimentResource() method to check if an experiment has been turned on.  <br> For example:
	```
	if getExperimentResource("RokuNamespace", "roku_trailers").on = true
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
By updating the default resource in Popper Config, it is possible to update all devices to a specific experiment experience without changing any client code.


## Updating the static text (translations) in app
The app stores all of its static text for various languages centrally. If you need to make a change, you should follow the below procedures.

If you need to make a change or addition to the American English text
- Create a new branch and modify the file /translations/en-US.json

- Then run the following command line within the project's root folder:
	```
  gulp update_local_translations
  ```
  This will modify the TubiLanguageTranslate.brs to include the new English text

- Once your branch has been merged into master, then run the following command line within the project's root folder to upload your approved changes to the Crowdin server. "KEY" is the key used for our crowdin account.
	```
  gulp upload_translations --crowdinKey "KEY"
  ```
  This upload command will do two things:
  - Modify the TubiLanguageTranslate.brs to include the new English text (just in case you skipped the previous step).

  - Upload the new change to the Crowdin server so the change can be recorded and our translators can work on obtaining translations for the new change.

If you need to make a change to text that is not the default English, then log into [Crowdin](https://crowdin.com/project/tubiapps) and adjust the translation. Then you will need to follow the directions on how to update the app with the latest translations.


If you need to get the latest translations from the Crowdin servers, then create a new GIT branch and run the below command line within the project's root folder, where "KEY" is the key used for our crowdin account. This will modify the TubiLanguageTranslate.brs to contain all the translations available within Crowdin. You later need to create a PR to start the process of getting the new translations merged to the master branch.

  ```
  gulp download_translations --crowdinKey "KEY"
  ```

NOTE: Instead of passing the crowdin key, you can set the crowdin key as system environment variable labeled as"ROKU_CROWDIN_KEY". This is actually the prefered way of doing things. Check your system on how to create an environment variable. Also note, that the crowdin key can be gotten either from the company's LastPass Account or through the [Crowdin website](https://crowdin.com/project/tubiapps/settings#api).


# Charles Proxy

Roku app integration with Charles proxy.



##  Requirements:



--   Both  the computer and the Roku need to be on the same network.
-- Charles installed (https://www.charlesproxy.com/download/)

##  Charles Setup:



--   In the project root there is file called [CharlesRewrites.xml](https://github.com/adRise/project-total-recall/blob/master/CharlesRewrites.xml).  This file is used to import the required rewrites into Charles.

#### Rewrite

Open the Charles and make a note of local ip address (help->local ip address)

Then go to Tools > Rewrite > Import. From here navigate to the project root and open the  [CharlesRewrites.xml](/docs/CharlesRewrites.xml)

IMP: Now Click on each rewrite rule and change the ip address(192.168.68.57) to local ip address noted above.  ![CharlesRokurewrite](/docs/Charles_roku_rewrite.png)](/docs/Charles_roku_rewrite.png)

(It is also worth noting that if you have changed the port Charles is running on you will need to update the `8888` value to what ever you have configured in Charles.)

#### Settings

 Go to Proxy > Proxy Settings and in the  `HTTP Proxy`  area you will need to turn on the following:

-   `Enable transparent HTTP proxying`

## Roku Setup

Now that Charles is setup and ready to receive requests from your Roku , please insert following in your dev.yml
```
charlesProxyUrl: "http://{{localHostAddress}}:8888"
charlesProxyEnabled: true


If set up correctly the first time your Roku sends a request to Charles, Charles will ask you to approve the connection. Just click `Allow` and you should see the traffic in Charles(except Youbora and Santry related traffic).



# Contributing

See [CONTRUBUTING.md](CONTRIBUTING.md)

Last updated by: Anupama Chandrappa
