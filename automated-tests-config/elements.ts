import type { BaseType } from 'roku-test-automation';

type Element = {
  id?: ElementKey;
  base?: BaseType;
  keyPath: string;
  xpath?: string;
}


type ElementKey = keyof typeof elements;


type ElementOrElementId = Element | ElementKey;


interface ElementMap {
  [id: string]: Element
}


// This function serves as a clever solution around the the fact that we want to type/type check what the value for each property should on elements but not try to type the parent or else we loose our type checking on those. Taken from: https://stackoverflow.com/questions/51237668/typescript-declare-that-all-properties-on-an-object-must-be-of-the-same-type
const typeCheckElements = <M extends ElementMap>(elements: M) => elements;


const elements = typeCheckElements({
  /** Used for getting the screens currently loaded in the app with the last child being the current screen */
  screenStack: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack',
  },

  topNavForYouLabelNotFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.0.#unfocusedTopLabel',
  },

  topNavForYouLabelFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.0.#focusedBottomLabel',
  },

  previewOff: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.1.#container',
  },

  episodesList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen.#PageGroup.#RowList.0.title.#CategoryName',
  },

  // We're currently replacing the contents in this section from the existing json file. If you want to y additional elements put them outside this section of the file. Keeping for a little longer in case any lingering keypaths need to be moved over with the script
  // START ELEMENTS INJECT
  // END ELEMENTS INJECT

  /** The top level scene for the entire application */
  scene: {
    keyPath: '',
  },

  /** Central controller of the application */
  contentController: {
    keyPath: '#ContentController',
  },

  /** Optimization to avoid getting all of the ContentController fields when all we care about is if it exists */
  contentControllerId: {
    keyPath: '#ContentController.id',
  },

  /** Component on the Home Screen that we can pull content for the Grid from */
  homeScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList',
  },

  /** Component on the Movie Screen that we can pull content for the Grid from */
  movieScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList',
  },

  /** Movie screen first row category name */
  movieScreenFirstRowName: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** Espanol Row List */
  espanolHomeScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#espanolScreen.#PageGroup.#ContentArea.#CategoryGridList.0',
  },

  /** Category name */
  categoryGridRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#espanolScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList',
  },

  /** Categories details page */
  categoriesDetailsPageInfo: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset',
  },

  categoryGridTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.#ChannelCategoryGrid.1.#Title',
  },

  /** Network page infopanel */
  networkPageInfoPanelDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** TV Shows screen row list */
  tvShowsScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** TV Shows screen first row category name */
  tvShowsScreenFirstRowName: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** Sea Lion Sign In to Watch text */
  slSignInToWatch: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#purpleCarpetRow.0.#infoPanelGroup.#ctaButtonList.0.#menuItemTextFocused',
  },

  slWatchLiveButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#purpleCarpetRow.0.#infoPanelGroup.#ctaButtonList.0.#menuItemBg',

  },

  slWatchLiveText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#purpleCarpetRow.0.#infoPanelGroup.#ctaButtonList.0.#menuItemTextFocused',
  },

  /** Live Show screen row list */
  liveScreenHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#PageGroup.#programGuide.#headerText',
  },

  /** Component that controls background image display */
  backgroundGroup: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup',
  },

  /** Background Poster */
  backgroundPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#topRightContentPosterGroup.#poster1.#BackgroundPoster',
  },

  /** Component contains side nav menu items. Useful for seeing which page is showing or to switch page is showing */
  sideNavMenu: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems',
  },

  likeButton: {
    keyPath:
      'ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#SecondaryMenu.0.#buttonBG',
  },

  /** Side Nav Menu contents */
  sideNavMenuContents: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.content',
  },

  /** This is the main menu grid that is used for knowing what is the selected menu item */
  mainMenuSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected',
    xpath:
      '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid',
  },

  categoryMyListMenuItemFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  categoryMyListMenuItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },

  allEpisodesButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },

  allEpisodesButtonFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },



  /** Component for video preview playback. Useful for checking that video preview is playing the correct file */
  previewVideoPlayer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#videoPreviewPlayer',
  },

  titleDetailsRatingsLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
  },

  closedCaptionPosterInDetailsPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#ClosedCaptionPoster',
  },

  /** Settings Screen */
  settingsScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen',
  },

  /** Settings page */
  settingsPagePanelSet: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet',
  },

  /** Enter Password Message */
  enterPasswordMessage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#Message',
  },

  /** Password Entry Box */
  passwordEntryBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password',
  },

  /** Password Entry Box */
  pcPasswordEntryBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#contentGroup.#password.#rectBG',
  },

  /** Dialog box text for PC Settings Change for Older Kids */
  parentalControlsSettingsOlderKids: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },
  /** PC Controls Settings Change Dialog */
  parentalControlsSettingsDialogBox: {
    keyPath: '#ContentController.#DialogBox.#ContentArea',
  },

  /** Exit Kids Menu item in Kids more is grayed out */
  exitKidsGrayedOut: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label',
  },

  /** Sign Out button on Settings Page while in Kids mode */
  signOutButtonKidsMode: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.4.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign out verification modal */
  signOutVerificationModalMessage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  detailScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen',
  },

  exitToUseThisFeatureMesage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },


  exitToUseThisFeatureMesageKids: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },


  /** Content title on the detail screen */
  detailScreenTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  /** Content title on the detail screen */
  detailScreenPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup',
  },

  /** Component containing year and duration of the current content */
  detailScreenYearAndDuration: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  detailScreenMenu: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu',
  },

  /** Add to My List Button */
  addToMyListButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.4.#DetailsMenuText',
  },

  /** Add to My List Button */
  addToMyListButtonFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.3.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Remove From My List Button */
  removeFromMyListButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3.#DetailsMenuText',
  },



  /** Play Button */
  playListButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#buttonBG',
  },

  /** Play Button icon focused */
  playButtonIconFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.0.#IconParent.#IconFocused',
  },

  /** On Movies Page Button */
  onMoviesPageButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#PageGroup.#topNav-movies.#TopNavMenu.1.#selectedBackground',
  },

  myStuffContinueWatchingRow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList.1.title.#CategoryName',
  },

  emailTexEditBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailInputScreen.#emailLayout.1.#emailTextEditBox.0',
  },

  /** Resend button on Magic Link */
  resendButtonMagicLink: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailVerificationScreen.#pageLayout.#buttonGroup.#resendBtn.#focus9Patch',
  },

  /** Progress bar on resumed button */
  resumedProgressBar: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#ResumeProgressBar',
  },

  /** My Stuff button selected */
  myStuffSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.5',
  },

  /** Movie Run Time */
  movieRunTime: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** YMAL Grid */
  relatedYMALGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup.#RelatedContentGroup.#RelatedGrid',
  },

  /** Detail Page Info Panel */
  detailInfoPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset',
  },

  /** Play Button is selected */
  playButtonSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0',
  },

  tubiEspanolPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem/Group/CategoryGridRowLabel/Label',
  },

  tubiKidsLogo: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#logoGroup.#tubiKidsLogo',
  },

  exitKidsOption: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.#Label',
    xpath:
      '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid[2]/SideNavIconComponent[2]/LayoutGroup/Label',
  },

  homePageSponsoredByText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#SponsoredBy.#SponsoredByText',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[11]/Group/CategoryGridRowLabel/LayoutGroup/Label',
  },

  homeScreenRatingsLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  homeScreenRecommendedChannels: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[3]/Group/CategoryGridRowLabel/Label',
  },

  sideNavItems: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#subTxt',
    xpath:
      '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid[2]/SideNavIconComponent[4]/Label',
  },

  channelDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  titleDetailsDescriptionContainer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  homeRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList',
  },

  homeScreenFeaturedPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList.0.items.0.#poster',
  },

  youMightAlsoLikeFirstPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup.#RelatedContentGroup.#RelatedGrid.0.#poster',
  },

  topNavRecommendedRedLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#BottomLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem/Label',
  },

  topNavRecommendedWhiteLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem',
  },

  loadingPoster: {
    keyPath: '#customSplashPoster',
    xpath: '/TubiScene/Poster[2]',
  },

  topNavForYouLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#TopLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem/Label[2]',
  },

  leftNavOpen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#sideNavBackground',
    xpath: '/TubiScene/ContentController/Group/Group/SideNav/Poster',
  },

  ageGateScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1',
    xpath:
      '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]',
  },

  BackgroundGradient: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1.#BackgroundGradient',
    xpath:
      '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]/Poster',
  },

  NBCDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  myStuffEmptyScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#SignedOutUI',
  },

  myStuffRegUserEmptyScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI',
  },

  goHomeButtonMyStuff: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUIMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  myStuffRegScreenTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUITitle',
  },

  myStuffRegScreenSubTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUISubtitle',
  },

  myStuffRegScreenSubTitle2: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUISubtitle2',
  },

  homeScreenMyListRow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[16]/Group/CategoryGridRowLabel/Label',
  },

  homeScreenPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#topRightContentPosterGroup.#poster2.#BackgroundPoster',
  },

  homeInfoPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup',
  },

  kidsDetailsPageRating: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveNewsHomeLinearPlayer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#VideoPreviewGroup',
    xpath: '/TubiScene/ContentController/Group/Group/Group',
  },

  homeScreenPageBackgroundImage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup',
  },

  homescreenRowLists1: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList',
  },

  homeScreenRatingLabelCW: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  topNavNewsLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.3.#BottomLabel',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem[4]/Label',
  },

  /** top Nav element on the home page */
  topNavMenuHome: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home',
  },

  titleMovieDetailsTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  detailsPageMenu: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu',
  },

  secondaryMenuactive: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#SecondaryMenu',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid[2]',
  },

  titleInfoPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  addToMyListSelected2: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem[4]',
  },

  addToMyListSelected3: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3.#DetailsMenuText',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem[4]/Label',
  },

  playButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem',
  },

  secondaryMenu: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#SecondaryMenu',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid[2]',
  },

  titleSeriesBackgroundPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/Group',
  },

  /** Secondary Menu Button - Like */
  secondaryMenuButtonLike: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#SecondaryMenu.0.#buttonBG',
  },

  /** Secondary Menu Button - Dislike  */
  secondaryMenuButtonDislike: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#SecondaryMenu.1.#buttonBG',
  },

  raitingLabelInDetailsScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
  },

  kidsLogoHomeScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#logoGroup.#tubiKidsLogo',
  },

  titleStarringLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DirectorGroup.#DirectorPrefix.#DirectorTag',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup[3]/LayoutGroup/Label',
  },

  titleResumeProgressBar: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#ResumeProgressBar',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem/Rectangle',
  },

  titleDescriptionNew: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  titleDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  /** BWW Row list Poster */
  browseWhileWatchingRowListPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#YmalRow.0.#YmalGroup.#YmalRow.#CategoryGridList.#RowList.0.items.0.#poster',
  },

  /** YMAL detail title */
  ymalDetailsTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#YmalRow.0.#YmalGroup.#Info.#infoPanelGroup.#Offset.#Title',
  },


  /** YMAL player poster */
  videoPlayYmalPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#YmalRow.0.#YmalGroup.#YmalRow.#CategoryGridList.#RowList.0.items.0.#poster',
  },

  /** BWW Featured header */
  browseWhileWatchingHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#BrowseWhileWatchingRow.0.#BrowseWhileWatchingGroup.#BrowseWhileWatchingRow.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** rewind button icon */
  rewindButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
  },

  /** FF button not pressed */
  fastForwardButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#FastForwardButton',
  },

  /** Transport buttons  */
  transportButtons: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons',
  },

  rewindButton3xPS4b: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  autoplayFirstTitleFocus: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#FocusBox',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/Poster',
  },

  fastForwardButton3x: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#FastForwardButton',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[6]',
  },

  rewindButton3x: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  autoplayUpNextScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]',
  },

  autoplaySecondTitleFocus: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#GridMovie',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/TargetList',
  },

  videoPlayerActual: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#VideoNode',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Video',
  },

  videoPlayerScreenTopOverlay: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#TopOverlay',
  },

  autoplayNextEpisodeLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextSeriesGroup.#InfoSeries.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[3]/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  autoplayLastTitleFocus: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#FocusBox',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/Poster',
  },

  rewindButton2xb: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  rewindButton2x: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  olderKidsCheckButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#ParentalControlsMenu.1.#BtnLayout.#Check',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SettingsScreen/PanelSet/ParentalControlsPanel/Group/Group/MarkupList/CheckButton[2]/LayoutGroup/Poster',
  },


  browseWhileWatchingRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#BrowseWhileWatchingRow.0.#BrowseWhileWatchingGroup.#BrowseWhileWatchingRow.#CategoryGridList.#RowList',
  },

  searchResultChannelNameABC: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  directorTag: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DirectorGroup.#DirectorPrefix.#DirectorTag',
  },

  starringTag: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#StarringGroup.#StarringPrefix.#StarringTag',
  },

  searchResultsText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  kidsSearchResultsText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#leftSide.0.#searchMenuText',
  },

  searchResultFoxWeather: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Episode',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  searchResultsLiveIcon: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#SecondLineGroup.#SecondLineAvailabilityBadge.#BadgeInfoLayout.#BadgeIcon',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  kidsSearchText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchText',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/Label',
  },

  kidsSearchResultsGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#ResultArea.#gridContainer.#trendingSearchResultsContainer.#trendingSearchResultGrid',
  },

  trendingSearchResultsGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#rightSide.#ResultArea.#gridContainer.#trendingSearchResultsContainer.#trendingSearchResultGrid',
  },

  kidsSearchSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2.#IconParent',
  },

  trendingSearchesHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#ResultArea.#gridContainer.#resultsContainer.#SearchText',
  },

  trendingSearchResult11: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#ResultArea.#gridContainer.#trendingSearchResultsContainer.#trendingSearchResultGrid.10.#poster',
  },

  btnCC_label: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#sideNav.#sideNav.#btnCC.#btnCC_label',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen/LinearVideoPlayerScreenOverlay/Group/Group/LinearOverlaySideNav/ButtonGroup/Button/Label[2]',
  },

  linearEPGFoxSportsDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  epgFullTVGuide: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#sideNav.#sideNav.#btnBack.#btnBack_label',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen/LinearVideoPlayerScreenOverlay/Group/Group/LinearOverlaySideNav/ButtonGroup/Button[2]/Label[2]',
  },

  linearEPGNHRADescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveNewsFullscreenPlayer: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen',
  },

  /** video player screen */
  videoPlayerScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen',
  },

  /** linear video preview screen */
  linearVideoPlayerScreenPreview: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#LinearPlayerGroup.#linearVideoPlayerScreen',
  },
  /** linear video screen */
  linearVideoPlayerScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen',
  },

  /** Fox Player element ID */
  foxPLayerElementID: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#FoxVideoPlayerWrapperScreen.1.0',
  },

  linearEPGFoxSportsEnEspanolDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  linearEPGSportsWireDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveTVTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#Title',
    xpath:
      '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  /** Component on the tv Screen that we can pull content for the Grid from */
  tvScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** My List Row element on My Stuff page */
  myStuffGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList',
  },

  /** My List Screen title element on My Stuff page */
  myListScreenTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#InfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  /** Side Nav User signed in */
  sideNavSignedInLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.0.#LabelParent.#Label',
  },

  /** Left Nav Home Button */
  leftNavHomeButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#IconParent.#focusedIcon',
  },

  /** Left Nav Home button unfocused */
  leftNavHomeButtonUnfocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#IconParent.0',
  },

  /** left home button label */
  leftNavHomeButtonLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label',
  },

  /** Left Nav home icon highlighted */
  leftNavHomeFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.3.#IconParent.#focusedIcon',
  },

  /** Left Nav home icon focused */
  leftNavHomeIconFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#IconParent.1',
  },


  /** Continue Watching Row on My Stuff page */
  continueWatchingRow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList.0.title.#CategoryName',
  },

  resumeButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.0'
  },

  //** CW Row populated (poster) */
  continueWatchingRowPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList.0.items.0.1.#posterLayout.#Poster.#gradientPoster',
  },

  //** CW Category Row poster */
  continueWatchingCategoryPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid.0.1.#posterLayout.#Poster',
  },
  //** Empty My List Container */
  emptyMyStuffContainer: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList',
  },

  //** Left Nav Categories button */
  leftNavCategoriesButtonSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.4.#LabelParent.0.#Label',
  },

  // ** Poster content exists in container*/
  myListPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#ContentArea.#RowList.1.items.0.0',
  },

  queueRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#ContentArea.#RowList',
  },

  /** Call to action button on My Stuff page (Press back for menu) */
  myStuffCallToAction: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#nav.#ScreenNavigationHint.#callToAction',
  },

  /** Categories page grid */
  categoriesDetailsGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsVideoGrid',
  },

  /** Categories video grid */
  categoriesDetailsVideoGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid.0.#poster',
  },

  /** Categories 6th poster */
  categoriesVideoGridPoster6: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid.5.#poster',
  },

  /** Item counter */
  itemCounter: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#pageTitleAndCounter.#CategoryCount.#ItemCount',
  },

  /** Channels page grid */
  channelsDetailsGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsVideoGrid',
  },
  channelsListScreenPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#PageGroup.#ChannelCategoryGrid.0.#PosterRect',
  },
  categoriesDetailsScreenPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#PageGroup.#ChannelCategoryGrid.0.#PosterRect',
  },

  channelsVideoGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid.0.#poster',
  },

  channelsVideoGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  categoryContent: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.0.content',
  },

  /** Linear Search Results Description */
  searchResultsDesc: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** Play/Pause button */
  playPauseButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#PlayPauseButton',
  },

  /** Forward 30 Button highlighted */
  forward30Button: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#HopForwardButton',
  },

  /** rewind 30 Button highlighted */
  rewind30Button: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#HopBackButton',
  },

  /** The actual Episodes page. Can be used to see if something on the episodes screen has focus */
  episodesScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen.#PageGroup.#RowList.0.items.0.#FeaturePoster.#Background',
  },

  /** Marker to determine if we are on the Episodes page */
  episodesScreenSeasonHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen.#PageGroup.#RowList.0.title.#CategoryName',
  },

  /** Episodes list */
  episodesListButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.2.#DetailsMenuTextParent.#DetailsMenuText',
  },

  episodesScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen.#PageGroup.#RowList',
  },

  /** dialog box sign in button */
  dialogBoxSignInButton: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** Sign in screen password box */
  signInScreenPasswordBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#signUpLayout.#password.#rectBG',
  },

  /** Kids Sign in screen password box */
  kidSignInScreenPasswordBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password.#rectBG',
  },

  continueButtonSignInPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#signUpLayout.#buttonsGroup.#continueBtn.#focus9Patch',
  },

  /** Enter your password meesage on dialog box */
  enterPasswordDialogMessage: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** Enter your password meesage on dialog box */
  enterPasswordContentMessage: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Password screen keyboard */
  passwordKeyboard: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#passwordEntryKeyboard.0.#Keyboard.0',
  },

  /** exit Prompt */
  exitPrompt: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** kids exit prompt */
  kidsExitPrompt: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** Player controls element */
  playerControls: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons',
  },

  /** Dialog box text for PC Settings Change for Little Kids */
  parentalControlsSettingsLittleKids: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Dialog box text for PC Settings Change for Teens */
  parentalControlsSettingsTeens: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },
  /** Group for PC Settings Change */
  parentalControlsSettingsGroup: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup',
  },

  /** PC Dialog Settings Change box */
  parentalControlsChangeDialog: {
    keyPath: '#ContentController.#DialogBox.#ContentArea',
  },

  /** Sign in password */
  passwordText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password.#Text',
  },

  keyboardBackButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#buttonGroup.#back.#focus9Patch',
  },

  /** Dialog box text for PC Settings Change for Older Kids */
  parentalControlsSettingsOlderKidsMessage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Adult control in PC is selected */
  adultControlSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup.#ParentalControlsMenu.3.#container',
  },

  /** Live Icon */
  liveExpireTime: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#ExpireWarning',
  },

  loadingSpinnerLinear: {
    keyPath: '#ContentController.#uiGroup.#LinearVideoPlayerSpinner.#PosterOrMessage.#SpinnerPoster',
  },

  liveBadgeText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList.6.items.0.1.#badgeGroup.0.#BadgeInfoLayout',
  },

  /** Preview off button */
  autoplayPreviewOff: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.1.#BtnLayout',
  },

  /** Autoplay sign in dialog Message */
  autoPlaySignInDialogMessage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Sign in Button */
  signInButton: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0',
  },

  /** TV Shows Series text */
  tvShowsSeriesLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** Details page Series Label */
  detailsPageSeriesLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** Continue Watching Row on TV Screen */
  tvContinueWatchingRow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** email address box for creating account */
  emailAddressBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailInputScreen.#emailLayout.1.#emailTextEditBox',
  },

  /** Enter Email Address Page Title */
  enterEmailAddressTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailInputScreen.#emailLayout.#pageHeading',
  },

  enterEmailAddressHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#purpleCarpetRow.0.#infoPanelGroup.#ctaButtonList.0.#menuItemTextFocused',
  },

  ageVerificationPageHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#AgeVerificationPageText.#AgeVerificationPageHeader',
  },

  continueWatchingConsentScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#rokuContinueWatchingConsentScreen.0.#heading',
  },

  confirmYourAgeText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.1.#AgeVerificationPageText.#AgeVerificationPageHeader',
  },

  ageGateHeaderInRegistrationFlow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#AgeVerificationPageText.#AgeVerificationPageHeader'
  },

  /** age gate year box */
  ageGateYearsBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.2.#AgeVerificationAgeBg.#AgeVerificationAgeEntry',
  },

  /** age gate invalid age */
  ageGateInvalidAge: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#AgeErrorPrompt',
  },

  /** Cannot exit kids mode modal */
  cannotExitKidsMode: {
    keyPath: '#ContentController.#DialogBox.#ContentArea',
  },

  /** Cannot exit kids mode title */
  cannotExitKidsModeTitle: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** Button Close text */
  buttonTextClose: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** age gate error prompt */
  ageGateVerificationErrorPrompt: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.1.#AgeVerificationErrorPrompt',
  },

  /** movies details page label */
  detailsMoviesPageLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** movies label */
  moviesLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** resume playing button */
  resumePlayingButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Play button */
  playFromBeginning: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign up to save Progress description */
  signUpToSaveProgressDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** poster present */
  movieScreenPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#ContentArea.#CategoryGridList.#RowList.5.items.0.#poster',
  },

  emailVerificationButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailVerificationScreen.#pageLayout.#buttonGroup.#resendBtn.#focus9Patch',
  },


  /** settings screen header */
  settingsScreenHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#TitleOne',
  },

  /** terms screen header */
  termsScreenHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Title',
  },

  /** full device ID  */
  fullDeviceID: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** About menu item */
  aboutMenuItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.2',
  },

  /** Full Device message */
  fullDeviceMessage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** help page text */
  helpPageText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#TextTwo',
  },

  /** Help link */
  helpLinkText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup.#TextTwoGroup.0',
  },

  /** Policy Page Header */
  privacyPolicyHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#panelContentSection.#heading',
  },

  goHomeMyStuffButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUIMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Privacy Page scroller */
  privacyPageScroller: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Text.2',
  },

  /** empty My Stuff page */
  emptyMyStuffPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#ContentArea',
  },

  /** category on category page */
  channelCategoryGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  channelNetworksButtonFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  channelSideNav: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu'
  },

  channelRecommendedButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },


  /** channel Info Panel */
  channelInfoPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset',
  },

  networksInfoPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset',
  },

  /** Category  Action */
  channelCategoryPosterTitle2: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.#ChannelCategoryGrid.2.#Title',
  },

  /** Category Adult Animation */
  channelCategoryPosterTitle4: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.#ChannelCategoryGrid.4.#Title',
  },

  /** category on category page */
  categoryPageCategory: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  /** Kid's category page */
  kidsCategory: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  /** Kids menu item text */
  littleKidsMenuItemText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.2.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  //** Category Page Grid */
  categoryPageGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  // ** Category Header */
  categoryHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#pageTitleAndCounter.#CategoryName',
  },


  /** Category ratings label */
  categoryRatingsLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingBackground',
  },


  categoryNameInCategoryDetailsPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#pageTitleAndCounter.#CategoryName',
  },

  categoryPosterFirst: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid.0.#poster',
  },

  actionButtonFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.2',
  },

  /** Networks page header */


  skipIntro: {
    keyPath:
      //#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#ScreenStack.#videoPlayerScreen.#skipCuepointsSimpleButton
      '#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#ScreenStack.#videoPlayerScreen.#skipCuepointsSimpleButton',
  },

  titleNameInCategories: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#Title'
  },

  /** recommended tile on 
   *  page */
  recommendedCategoryPage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.0.#Title',
  },

  /** Call to Action text on Recommended screen */
  recommendedScreenCallToAction: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#nav.#ScreenNavigationHint.#callToAction',
  },

  /** channel page */
  channelPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid.0.#poster',
  },

  titleNameInPlayer: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#TopOverlay.#VideoOverlayTitle',
  },

  titleDescriptionInChannelGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  titleNameInContainer: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  titleDescriptionMovieScreen: {
    keyPath:
      'ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  titleDescriptionHomesScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  titleDescriptionOnHomeScreen: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  linearNavigationPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#EPGHorizontalSlide.#EPG',
  },

  liveNewsSubtitlesPanel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#closedCaptioningGroup.#closedCaptioningButtonList',
  },

  /**  Invalid deep link dialog */
  invalidDeepLinkDialog: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Horses and Ponies, Little Kids Tile in Categories */
  horsesAndPoniesTile: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.9.#Title',
  },

  /** Kid Friendly Classics, Older Kids Tile in Categories */
  kidFriendlyClassics: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.9.#Title',
  },

  /** Art-House Films for Teens Description */
  artHouseFilms: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.7.#DetailsMenuTextParent.#DetailsMenuText',
  },

  bWWTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#BrowseWhileWatchingRow.0.#BrowseWhileWatchingGroup.#Info.#infoPanelGroup.#Offset.#Title',
  },

  /** Kids left nav option */
  kidsLeftNavOption: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label',
  },

  /** Parental Controls Menu item focused */
  parentalControlsMenuTextFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Continue Watching button in Categories */
  continueWatchingButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Search grid */
  searchGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchGroup.#SearchKeyboard.0',
  },

  /** No results message */
  noResultsMessage: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#ResultArea.#NoResultsMessage',
  },

  /** text for liniear to expire 1 hour 27 mins left as example */
  linearExpirationTimeText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#ExpireWarning',
  },

  /** closed caption audio button */
  closedCaptionAudioButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#closedCaptionAudioButton',
  },

  /** Audio tracks section */
  audioTracksSection: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.2.#audioTracks',
  },

  /** CC section */
  closedCaptionSection: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.1.#subtitleTracks',
  },

  /** CC Sectoon Header Label */
  closedCaptionSectionHeaderLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.1.#subtitleTracks',
  },

  /** Audio Tracks Section Header Label */
  audioTracksSectionHeaderLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.2.#audioTracks',
  },

  /** Audio label */
  audioTracksSectionHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTracksSectionHeaderLabel',
  },

  /** Audio Description text check */
  audioDescriptionText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.1.#BtnLayout.#Text',
  },

  /** sign out button selected */
  signOutButtonSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.6.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** audio desc enabled */
  audioDescriptionEnabled: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.2.#OverLayItemsLayoutGroup.2.1.#container',
  },

  /** audio description item content */
  audioDescriptionItemContent: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.1.itemContent',
  },

  /** Audio Descriptio item checked */
  audioDescriptionItemChecked: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.2.#OverLayItemsLayoutGroup.2.1.#container.0.#checkIcon',
  },

  /** subtitle OFF */
  subtitleOff: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection.#closedCaptionSelector.0',
  },

  /** subtitle enabled */
  subTitleEnabled: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.1.#OverLayItemsLayoutGroup.2.1',
  },

  /** audio enabled */
  audioEnabled: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.2.#OverLayItemsLayoutGroup.2.1.#container',
  },

  /* autoplay container */
  autoPlayContentPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextParent.#UpNextSeriesGroup.#GridSeries.0'
  },

  /** autoplay countdown movies */
  countDownMovieAutoPlay: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#CountdownLabelMovie',
  },

  countDownSeriesAutoPlay: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextParent.#UpNextSeriesGroup.#metadataSeries.#CountdownLabelSeries',
  },

  /** remaining time in player timer */
  remainingLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#RemainingLabel',
  },

  /** current time in player timer */
  currentTimePlayed: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#ElapsedLabel',
  },

  /** autoplay option year and duration info */
  autoPlayYearAndDuration: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#InfoMovie.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** autoplay UI */
  autoplayUpNextUI: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup',
  },

  /** Setting Menu Grid */
  settingsMenu: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu',
  },

  /** Settings menu item */
  settingsMenuItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.8',
  },

  /** Dialog box for Device ID */
  dialogBoxContentAreaDeviceID: {
    keyPath: '#ContentController.#DialogBox.#ContentArea',
  },

  /** My Stuff Left Nav option */
  myStuffLeftNav: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.4.#LabelParent.0.#Label',
  },

  /** Parental Controls header */
  parentalControlsHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Title',
  },

  /** Featured Row */
  featuredRow: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.1.title.#CategoryName',
  },

  /** Featured text is shown */
  featuredHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** Featured row poster */
  featuredRowPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.items.0.#poster',
  },

  /** description of title in CW row */
  homeScreenContentDescription: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** info panel title home screen */
  infoPanelTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#Title',
  },
  /** info panel title movies screen */
  infoPanelTitleMovies: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#PageGroup.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  /** age gate number page */
  ageVerificationPad: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#AgeVerificationNumberPadGroup.#AgeVerificationNumberPad.#keyboard.0',
  },

  /** Autoplay Title */
  autoPlayTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextParent.#UpNextMovieGroup.#movieTiles.#FocusBox',
  },

  /** top nav For You */
  selectedTopNavForYouItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.0',
  },

  /** top nav Movies */
  topNavMoviesItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.1.#unfocusedTopLabel',
  },

  /** top nav TV Shows */
  topNavTVShowsItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.2.#unfocusedTopLabel',
  },

  /** top nav Live TV */
  topNavLiveItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#topNav-home.#TopNavMenu.3.#unfocusedTopLabel',
  },

  /**  Live TV option is selected in left nav */
  selectedLiveTVItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.8.#IconParent.1',
  },

  /** TV Shows option is selected in left nav */
  selectedTVShowsItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.7.#IconParent.1',
  },

  /** Selected Movies item */
  selectedMoviesItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.6.#IconParent.1',
  },

  /** Program Guide Header text on the Live TV tab */
  programGuideHeaderText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#topNav-linearEPG-linearEPG-linearEPG.#TopNavMenu.3.#Underline',
  },

  programGuide: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#PageGroup.#programGuide.0',
  },

  epgProgramGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#PageGroup.#programGuide.#channelsGrid.0.#ChannelPoster',
  },

  customSplashPoster: {
    keyPath: '#customSplashPoster',
  },

  /** text on Search page header */
  searchMenuText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#leftSide.#searchMenuText',
  },

  /** left nav search button */
  leftNavSearchButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.2',
  },

  /** Left Nav Movies item - not hovered */
  leftNavMoviesItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.6.#LabelParent.0.#Label',
  },

  //**Left Nav TV Shows item - not hovered */
  leftNavTVShowsItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.7.#LabelParent.0.#Label',
  },

  // * Left Nav TV Shows icon - not focued */
  leftNavTVShowsIconNotFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.7.#IconParent.0',
  },

  //* Left Nav Movies icon - not focued */
  leftNavMoviesIconNotFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.6.#IconParent.0',
  },

  // * Left Nav Live TV - not focused */
  leftNavLiveTVItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.8.#LabelParent.0.#Label',
  },

  // * Left Nav Live TV icon - not focused */
  leftNavLiveTVIconNotFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.8.#IconParent.0',
  },

  /**Left Nav Categories button selected */
  categoriesLeftNavButtonSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.4',
  },

  /**Left Nav Search button  */
  leftNavSearchItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2.#LabelParent.0.#Label',
  },

  //** Category Networks title */
  categoryNetworksTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.#ChannelCategoryGrid.1.#Title',
  },

  networksCategoryButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.2.#MenuGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Networks page */
  networksPageGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#PageGroup.#ChannelCategoryGrid.0.#PosterRect',
  },

  /** Networks Video Grid poster */
  networksVideoGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid.0.#poster',
  },

  networksContentGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  /** Exit item */
  exitItem: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.5.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Exit item selected */
  exitItemSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.5.#IconParent.#IconFocused',
  },

  /** parental controls button */
  parentalControlsButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.0',
  },

  /** Search text */
  searchText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchText',
  },

  foundTitlesSearch: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#ScreenStack.#searchScreen.#PageGroup.#rightSide.#rightSideTextGroup.#searchDirectionsGroup.#searchMenuText',
  },

  /** side nav element component */
  sideNavComponent: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected',
  },

  /** recommended poster */
  recommendedPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.0.#Title',
  },

  continueWatchingPoster: {
    keyPath: ' #ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid.0.1.#posterLayout.#Poster',
  },

  /** categories left nav */
  categoriesLeftNavButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.4.#LabelParent.0.#focusedLabel',
  },

  /** categories label highlighted */
  categoriesLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.5.#LabelParent.0.#Label',
  },

  /** categories  screen */
  categoryPagePoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#PageGroup.#ChannelCategoryGrid.0.#PosterRect',
  },

  /** channels left nav button highlighted */
  channelsLeftNavButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.6',
  },

  accountNeededErrorMessage: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  unlockNowForMyStuff: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#SignedOutUI.#GuestMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  myStuffGuestScreenTextTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#SignedOutUI.#SignedOutUITitle',
  },

  myStuffGuestScreenTextSubTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#SignedOutUI.#SignedOutUISubtitle',
  },

  myStuffGuestScreenTextBlurb: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#SignedOutUI.#SignedOutUIBlurb',
  },

  emptyMyStuffButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#PageGroup.#AllEmptyUI.#AllEmptyUIMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** channels list screen */
  channelsListScreenGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#ChannelsContentGrid',
  },

  /** settings left nav button highlighted */
  settingsLeftNavButtonSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.10.#LabelParent.0.#focusedLabel',
  },

  /** categories video grid */
  categoriesVideoGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#PageGroup.#ChannelCategoryGrid',
  },

  channelVideoGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid',
  },

  categoriesVideoGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#ChannelsVideoGrid.0.#poster',
  },

  /** settings left nav button highlighted */
  exitLeftNavButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.9.#LabelParent.0.#Label',
  },

  /** age verification number pad */
  ageVerificationNumberPad: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.1.#AgeVerificationNumberPadGroup.#AgeVerificationNumberPad.#keyboard.0',
  },

  /** age verification years page */
  yearsVerificationEntry: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.#AgeVerificationPageText.#AgeVerificationPageHeader',
  },

  /** CW tile on Categories page */
  categoriesContinueWatchingTile: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.1.#Title',
  },

  /** Search menu highlighted */
  searchMenuItemSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.2',
  },

  /** Search keypad */
  searchKeyPad: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchGroup.#SearchKeyboard.0',
  },

  /** Kids Search KeyPad */
  kidsSearchKeyPad: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#searchGroup.#SearchKeyboard.0',
  },

  /** label child in left nav */
  leftNavHomeLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#LabelParent.0.#Label',
  },

  /** search label in left nav */
  leftNavSearchLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2.#LabelParent.0.#Label',
  },

  /** title of Espanol Disabled dialog box */
  espanolDisabledTitle: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** title of Espanol Disabled dialog box for teens */
  espanolDisabledTitleTeens: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title',
  },

  /** message in Espanol Disabled dialog box */
  espanolDisabledMessage: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** message in Espanol Disabled box for teens */
  espanolDisabledMessageTeens: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** button in Espanol Disabled dialog box */
  espanolDisabledButton: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** button in Espanol Disabled dialog box for Teens */
  espanolDisabledButtonTeens: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** tubi espanol logo */
  espanolLogo: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#logoGroup.#tubiEspanolLogo',
  },

  /** espanol screen row list  */
  espanolScreenRowList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#espanolScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** espanol screen row list  */
  sideNavChannelsLabel: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.6.#LabelParent.0.#Label',
  },

  /** settings Screen Title */
  settingsScreenTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#Title',
  },

  /** Exit Button Text */
  exitDialogButtonText: {
    keyPath:
      '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** CC Menu */
  closedCaptionCheckBoxList: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#screenStackGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.0.1.1.#OverLayItemsLayoutGroup.2',
  },



  /** Sign Up to Save Progress Series detail menu item button text */
  seriesSignUpToSaveProgressButtonText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign Up to Save Progress Series detail menu item button text when have history */
  seriesSignUpToSaveProgressButtonTextOnDetailsPageWithHistory: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign Up to Save Progress detail menu item badge text */
  seriesSignUpBadgeLabelText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#badgeLabel.#textLabel',
  },

  /** Sign Up to Save Progress Series detail menu item button text */
  moviesSignUpToSaveProgressButtonText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },
  /** Sign Up to Save Progress detail menu item badge text */
  moviesSignUpBadgeLabelText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#badgeLabel.#textLabel',
  },

  /** Email input Screen Page Heading */
  emailInputScreenHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailInputScreen.#emailLayout.#pageHeading',
  },

  /** Email test edit box */
  emailTextEditBox: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#emailInputScreen.#emailLayout.1.#emailTextEditBox.1',
  },

  /** Sign In Screen page header */
  signInScreenPageHeader: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#signUpLayout.#pageHeading',
  },

  /** EPG countdown text */
  epgCountDownText: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#PlayerCountdownGroup.#CountdownText',
  },

  /** homescreen news countdown */
  homeScreenNewsCountdown: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#PlayerCountdownGroup.#CountdownText',
  },

  /* linear Player Group */
  linearPlayerGroup: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#LinearPlayerGroup.#linearVideoPlayerScreen.#VideoNode.1',
  },

  /** The grid containing search results on SearchScreen */
  searchResultGrid: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#rightSide.#ResultArea.#gridContainer.#resultsContainer.#ResultGrid',
  },

  //** Kids Search menu item selected */
  kidsSearchItemSelected: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2.#IconParent',
  },

  /** Search Results Grid content, first result */
  searchResultsGridPoster: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#PageGroup.#ResultArea.#gridContainer.#resultsContainer.#ResultGrid.0.#poster',
  },

  /* Welcome registration modal */
  welcomeRegModal: {
    keyPath: '#ContentController.#dialogBox.#mask',
  },

  /* Welcome registration modal header*/
  welcomeRegModalHeader: {
    keyPath: '#ContentController.#dialogBox.#contentArea.0.#header',
  },

  /* Welcome registration modal sign in button focused*/
  welcomeRegModalSignInButtonFocused: {
    keyPath:
      '#ContentController.#dialogBox.#contentArea.#buttonList.0.#buttonTextParent.#labelFocused',
  },

  /* Welcome registration modal sign in button*/
  welcomeRegModalContinueAsGuestButton: {
    keyPath:
      '#ContentController.#dialogBox.#contentArea.#buttonList.1.#buttonTextParent.#label',
  },

  /* Welcome registration modal sign in button focused*/
  welcomeRegModalContinueAsGuestButtonFocused: {
    keyPath:
      '#ContentController.#dialogBox.#contentArea.#buttonList.1.#buttonTextParent.#labelFocused',
  },

  /** Reaction button Liked */
  reactionButtonLiked: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Secondary Menu Like highlighted */
  likeButtonFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#SecondaryMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Secondary Menu Disliked highlighted */
  DislikedButtonFocused: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#SecondaryMenu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Reaction Button Disliked */
  reactionButtonDisliked: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Secondary Menu Disliked remove button highlighted */
  DislikedButtonRemove: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Like or Dislike Button */
  likeOrDislikeButton: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#PageGroup.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /* the title count on content list page */
  categoryDetailsScreenTitleCount: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#pageTitleAndCounter.#CategoryCount',
  },

  /* the indicator of tile's index on content list page */
  categoryDetailsScreenFocusIndex: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#PageGroup.#pageTitleAndCounter.#CategoryCount.#FocusIndex',
  },

  /** Continue Watching Row Category Name on Home page */
  continueWatchingRowHome: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** Continue Watching Row Title on Home page */
  categoryPageTitle: {
    keyPath:
      '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryPanelListScreen.#PageGroup.#PanelSet.3.#PageGroup.#PageAnimatedGroup.#pageTitleAndCounter.#CategoryName',
  },

  // title on the exit prompt of Sign up to Save Progress
  signUpExitDialogTitle: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title'
  },

  //exit prompt of Sign up to Save Progress
  signUpExitDialog: {
    keyPath: '#ContentController.#DialogBox'
  },

  // Description on the exit prompt of Sign up to Save Progress
  signUpExitDialogDescription: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message'
  },

  // Sign up button on the exit prompt of Sign up to Save Progress
  signUpExitDialogSignUpButton: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText'
  },

  // Accept Now button
  acceptNowButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#PageGroup.#ContentArea.#CategoryGridList.#purpleCarpetRow.0.#infoPanelGroup.#ctaButtonList.0.#menuItemTextFocused',
  },

  // Sign up later button on the exit prompt of Sign up to Save Progress
  signUpExitDialogLaterButton: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#ButtonList.1.#buttonTextParent.#buttonText'
  },

  // Oops wrong password dialog
  wrongPasswordDialog: {
    keyPath: '#ContentController.#DialogBox.#ContentArea'
  },

  // Oops wrong password dialog title
  wrongPasswordTitle: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title'
  },

  // Oops wrong password dialog message
  wrongPasswordMessage: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message'
  },

  // Oops wrong password dialog Forgot Password button
  wrongPasswordForgotButton: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText'
  },

  // Oops wrong password dialog Retry button
  wrongPasswordRetryButton: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#ButtonList.1.#buttonTextParent.#buttonText'
  },

  // title of Help is on the way! screen after user select Forgot Password
  helpIsOnTheWayScreenTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#forgotPasswordProcessingScreen.#pageLayout.#pageHeading'
  },

  // Get Back to What You Love Faster Consent Page
  continueWatchingConsentPage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#rokuContinueWatchingConsentScreen.0.#heading'
  },

  // Get Back to What You Love Faster Consent Page
  continueWatchingConsentPageAcceptButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#rokuContinueWatchingConsentScreen.0.#buttonList.0'
  },

  // Welcome To Tubi Kids
  welcomeToTubiKidsTitle: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#Title'
  },

  // OK Button on the Welcome To Tubi Kids Dialog
  welcomeToTubiKidsOKButton: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonTextFocused'
  },

  // Loading Progress Bar
  loadingProgressBar: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#Loading.#LoadingProgressBar'
  },

  // Privacy Center Continue Watching Header
  privacyCenterContinueWatchingHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.#privacyCenterPanel.#Offset.#panelContentSection.#managePreferences.#preferenceMenu.0.#contentSection.1.#title'
  },

  // Privacy Center Continue Watching Toggle
  privacyCenterContinueWatchingToggle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.#privacyCenterPanel.#Offset.#panelContentSection.#managePreferences.#preferenceMenu.0.#contentSection.2.1.#toggleText'
  },

  /** Preview on button */
  autoplayPreviewOn: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.0'
  },

  // Preview Off Checked
  previewOffCheckMark: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.1.#container.0.#checkIcon',
  },
  // Preview On Checked
  previewOnCheckMark: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PageGroup.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.0.#container.0.#checkIcon',
  }
});

export {
  Element,
  ElementKey,
  ElementOrElementId,
  elements
};
