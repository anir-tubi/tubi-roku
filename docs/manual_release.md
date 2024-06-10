# Submission Release
These are steps that would normally be done by `gulp release`. Follow these steps if you need to perform the steps manually.

1\. After QA Sign Off, run `$ gulp release`. This will increment the version number once more (the QA build should not be the same version number as the production build), create a tag with the new build number, and create pkg files needed for the new release in the `/build` directory.

2\. Update the starter components and remote component files to the CDN repo
- Create a new branch in the CDN repo [github.com/adRise/rcdn/](https://github.com/adRise/rcdn/). Although it does not matter, traditionally we name the branch "Roku_x_y_z_r", where "z" is the patch number and "r" is revision number (generally in this case 0)

- Copy two files to the CDN repo:

  - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z_r.pkg`) into the folder: appFiles/components/

  - copy the starter components file (i.e. `build/tubi_starter_components.x.y.pkg`) into folder: appFiles/starter-components/

    create new folder x_y_z_r under rollbackStarterComponents
  - copy the starter components file (i.e. `build/tubi_starter_components.x.y.pkg`) into folder: rollbackStarterComponents/x_y_z_r/

- Submit a PR to the CDN repo.

- __DO NOT PROCEED TO THE INFRA SCRIPT STEP UNTIL THIS PR AND THE PREVIOUS PRs ARE APPROVED__

# Remote Release

1\. After QA Sign Off, run `$ gulp release`. This will increment the version number once more (the QA build should not be the same version number as the production build), create a tag with the new build number, and create pkg files needed for the new release in the `/build` directory.

2\. Create a new branch based on the `qa_x_y_z_r` branch, and name it `release_x_y_z_r`, where "z" (of the release branch) will match the patch number that was just incremented by the previous step. "r" is revision number (generally in this case 0)

3\. Ready the release branch for review

- Push the `release_x_y_z_r` branch to Github.

- Make a PR to the `x_y_branch` and merge it after approval. Make sure you do not make the PR to master.

4\. Update the starter component and remote component files to the CDN
- Create a new branch in the CDN repo [github.com/adRise/rcdn/](https://github.com/adRise/rcdn/). Although it does not matter, traditionally we name the branch "Roku_x_y_z_r".

- Copy two files to the CDN repo:

 - copy the remote components file (i.e. `build/tubi_remote_components_x_y_z_0.pkg`) into the folder: appFiles/components/

  - copy the starter components file (i.e. `build/tubi_starter_components.x.y.pkg`) into folder: appFiles/starter-components/

  - copy the starter components file (i.e. `build/tubi_starter_components.x.y.pkg`) into folder: rollbackStarterComponents/x_y_z_r/

- Submit a PR to the CDN repo. Wait for the approval and merging of the PR before proceeding to the next step

- __DO NOT PROCEED TO THE INFRA SCRIPT STEP UNTIL THIS PR AND THE PREVIOUS PRs ARE APPROVED__
