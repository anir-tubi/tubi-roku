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
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack'
  },

  topNavForYouLabelNotFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#TopLabel',
  },

  topNavForYouLabelFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#BottomLabel',
  },

  // We're currently replacing the contents in this section from the existing json file. If you want to add additional elements put them outside this section of the file. Keeping for a little longer in case any lingering keypaths need to be moved over with the script
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
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** Component on the Movie Screen that we can pull content for the Grid from */
  movieScreenRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** Movie screen first row category name */
  movieScreenFirstRowName: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** TV Shows screen row list */
  tvShowsScreenRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** TV Shows screen first row category name */
  tvShowsScreenFirstRowName: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** Live Show screen row list */
  liveScreenHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#programGuide.#headerText',
  },

  /** Component that controls background image display */
  backgroundGroup: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup',
  },

  /** Component contains side nav menu items. Useful for seeing which page is showing or to switch page is showing */
  sideNavMenu: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems',
  },

  /** This is the main menu grid that is used for knowing what is the selected menu item */
  mainMenuSelected: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected',
    xpath: '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid',
  },

  /** Component for video preview playback. Useful for checking that video preview is playing the correct file */
  previewVideoPlayer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#videoPreviewPlayer',
  },

  titleDetailsRatingsLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel'
  },

  closedCaptionPosterInDetailsPage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#ClosedCaptionPoster'
  },

  /** Settings Screen */
  settingsScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen',
  },

  /** Enter Password Message */
  enterPasswordMessage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#Message',
  },

  /** Password Entry Box */
  passwordEntryBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password',
  },

  /** Dialog box text for PC Settings Change for Older Kids */
  parentalControlsSettingsOlderKids: {
    keyPath: '#ContentController.2.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Exit Kids Menu item in Kids more is grayed out */
  exitKidsGrayedOut: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label',
  },

  /** Sign Out button on Settings Page while in Kids mode */
  signOutButtonKidsMode: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.4.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign out verification modal */
  signOutVerificationModalMessage: {
    keyPath: '#ContentController.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  detailScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen',
  },

  channelsDisabledMessage: {
    keyPath: '#ContentController.#444e064.#DialogBox.#ContentArea.#Title',
  },
	
  /** Content title on the detail screen */
  detailScreenTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  /** Component containing year and duration of the current content */
  detailScreenYearAndDuration: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  detailScreenMenu: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu',
  },

  /** Add to My List Button */
  addToMyListButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.4.#DetailsMenuText',
  },

  /** Remove From My List Button */
  removeFromMyListButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3.#DetailsMenuText',
  },

  /** Play Button */
  playListButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#buttonBG',
  },

  /** On Movies Page Button */
  onMoviesPageButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#topNav-movies.#TopNavMenu.1.#TopLabel',
  },

  /** Remove from history button */
  removeFromHistoryButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.5',
  },

  /** Progress bar on resumed button */
  resumedProgressBar: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#ResumeProgressBar',
  },

  /** Movie Run Time */
  movieRunTime: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** YMAL Grid */
  relatedYMALGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup.#RelatedContentGroup.#RelatedGrid',
  },

  /** Detail Page Info Panel */
  detailInfoPanel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset',
  },

  /** Play Button is selected */
  playButtonSelected: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0',
  },

  tubiEspanolPage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem/Group/CategoryGridRowLabel/Label',
  },

  tubiKidsLogo: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LinearGradient1.#BackgroundGradient',
    xpath: '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/BackgroundGradientGroup[2]/Poster',
  },

  exitKidsOption: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.#Label',
    xpath: '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid[2]/SideNavIconComponent[2]/LayoutGroup/Label',
  },

  homePageSponsoredByText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#SponsoredBy.#SponsoredByText',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[11]/Group/CategoryGridRowLabel/LayoutGroup/Label',
  },

  homeScreenRatingsLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  homeScreenRecommendedChannels: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[3]/Group/CategoryGridRowLabel/Label',
  },

  sideNavItems: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#subTxt',
    xpath: '/TubiScene/ContentController/Group/Group/SideNav/LayoutGroup/Group/MarkupGrid[2]/SideNavIconComponent[4]/Label',
  },

  homeRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList',
  },

  countDownSeriesAutoPlay : {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextSeriesGroup.#CountdownLabelSeries',
  },

  youMightAlsoLikeFirstPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup.#RelatedContentGroup.#RelatedGrid.0.#poster',
  },

  topNavRecommendedRedLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#BottomLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem/Label',
  },

  topNavRecommendedWhiteLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem',
  },

  loadingPoster: {
    keyPath: '#customSplashPoster',
    xpath: '/TubiScene/Poster[2]',
  },

  topNavForYouLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#TopLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem/Label[2]',
  },

  leftNavOpen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#sideNavBackground',
    xpath: '/TubiScene/ContentController/Group/Group/SideNav/Poster',
  },

  ageGateScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1',
    xpath: '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]',
  },

  BackgroundGradient: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1.#BackgroundGradient',
    xpath: '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]/Poster',
  },

  NBCDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  unlockScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1.#BackgroundGradient',
    xpath: '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]/Poster',
  },

  homeScreenMyListRow: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList/RowListItem[16]/Group/CategoryGridRowLabel/Label',
  },
	
  homeScreenPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#PosterGroup.#Poster2.#BackgroundPoster', 
  },

  homeInfoPanel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup',
  },

  myStuffEmptyScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#BackgroundGroup.#GradientGroup.#LeftBottomGradient.#gradientGroup.#gradient_1.#BackgroundGradient',
    xpath: '/TubiScene/ContentController/Group/Group/BackgroundGroup/Group[2]/MultipleGradientGroup/Group/BackgroundGradientGroup[2]/Poster',
  },

  kidsDetailsPageRating: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveNewsHomeLinearPlayer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#VideoPreviewGroup',
    xpath: '/TubiScene/ContentController/Group/Group/Group',
  },

  homeScreenPageBackgroundImage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup',
  },

  homescreenRowLists1: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/MaskGroup/CategoryGridList/RowList',
  },

  homeScreenRatingLabelCW: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/Group[2]/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup/LayoutGroup/Group/Label',
  },

  topNavNewsLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.3.#BottomLabel',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/HomeScreen/TopNav/MarkupGrid/TopNavItem[4]/Label',
  },

  /** top Nav element on the home page */
  topNavMenuHome: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home',
  },

  titleMovieDetailsTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  detailsPageMenu: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid',
  },

  secondaryMenuactive: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#SecondaryMenu',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid[2]',
  },

  titleInfoPanel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  addToMyListSelected2: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem[4]',
  },

  addToMyListSelected3: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.3.#DetailsMenuText',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem[4]/Label',
  },

  playButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem',
  },

  secondaryMenu: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#SecondaryMenu',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid[2]',
  },

  titleSeriesBackgroundPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#RelatedContentParentGroup',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/Group',
  },

  raitingLabelInDetailsScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Rating.#RatingLabel',
  },
	
  kidsLogoHomeScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#logoGroup.#tubiKidsLogo',
  },
	
  titleStarringLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DirectorGroup.#DirectorPrefix.#DirectorTag',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/LayoutGroup[3]/LayoutGroup/Label',
  },

  titleResumeProgressBar: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#ResumeProgressBar',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/FilledButtonMarkupGrid/DetailMenuItem/Rectangle',
  },

  titleDescriptionNew: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  titleDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/DetailScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  /** rewind button icon */
  rewindButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
  },

  /** FF button not pressed */
  fastForwardButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#FastForwardButton',
  },

  rewindButton3xPS4b: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  autoplayFirstTitleFocus: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#FocusBox',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/Poster',
  },

  fastForwardButton3x: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#FastForwardButton',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[6]',
  },

  rewindButton3x: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  autoplayUpNextScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]',
  },

  autoplaySecondTitleFocus: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#GridMovie',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/TargetList',
  },

  videoPlayerActual: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#VideoNode',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Video',
  },

  autoplayNextEpisodeLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextSeriesGroup.#InfoSeries.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[3]/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  autoplayLastTitleFocus: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#FocusBox',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/UpNext/Group/Group[2]/Poster',
  },

  rewindButton2xb: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  rewindButton2x: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#RewindButton',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/VideoPlayerScreen/Group[4]/Group/Group/TransportButton[2]',
  },

  olderKidsCheckButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#ParentalControlsMenu.1.#BtnLayout.#Check',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SettingsScreen/PanelSet/ParentalControlsPanel/Group/Group/MarkupList/CheckButton[2]/LayoutGroup/Poster',
  },

  searchResultChannelNameABC: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  searchResultsText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  searchResultFoxWeather: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#Episode',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  searchResultsLiveIcon: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#SecondLineGroup.#SecondLineAvailabilityBadge.#BadgeInfoLayout.#BadgeIcon',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  kidsSearchText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchText',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/SearchScreen/Label',
  },

  btnCC_label: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#sideNav.#sideNav.#btnCC.#btnCC_label',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen/LinearVideoPlayerScreenOverlay/Group/Group/LinearOverlaySideNav/ButtonGroup/Button/Label[2]',
  },

  linearEPGFoxSportsDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  epgFullTVGuide: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#sideNav.#sideNav.#btnBack.#btnBack_label',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen/LinearVideoPlayerScreenOverlay/Group/Group/LinearOverlaySideNav/ButtonGroup/Button[2]/Label[2]',
  },

  linearEPGNHRADescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveNewsFullscreenPlayer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/LinearVideoPlayerScreen',
  },

  /** video player screen */
  videoPlayerScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen',
  },

  linearEPGFoxSportsEnEspanolDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  linearEPGSportsWireDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Group/Label',
  },

  liveTVTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#infoPanelParent.#infoPanel.#infoPanelGroup.#Offset.#Title',
    xpath: '/TubiScene/ContentController/Group/Group/ScreenStack/EPGHomeScreen/Group/InfoPanel/LayoutGroup/LayoutGroup/Label',
  },

  /** Component on the tv Screen that we can pull content for the Grid from */
  tvScreenRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** My List Row element on My Stuff page */
  myStuffGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#ContentArea.#RowList',
  },

  /** My List Screen title element on My Stuff page */
  myListScreenTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#InfoPanel.#infoPanelGroup.#Offset.#Title',
  },

  /** Side Nav User signed in */
  sideNavSignedInLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.0.#LabelParent.#Label',
  },

  /** Left Nav Home Button */
  leftNavHomeButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#LabelParent.0.#Label',
  },
  
  /** left home button label */
  leftNavHomeButtonLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label'
    
  },

  /** Left Nav home icon highlighted */
  leftNavHomeFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.3.#IconParent.#focusedIcon',
  },

  /** Continue Watching Row on My Stuff page */
  continueWatchingRow: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#ContentArea.#RowList.1.title.#CategoryName',
  },

  /** Call to action button on My Stuff page (Press back for menu) */
  myStuffCallToAction: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#nav.#ScreenNavigationHint.#callToAction',
  },

  /** Call to action button on Categories page */
  categoriesCallToAction: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#nav.#ScreenNavigationHint.#callToAction',
  },

  /** Linear Search Results Description */
  searchResultsDesc: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchScreenInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** Play/Pause button */
  playPauseButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#PlayPauseButton',
  },

  /** Forward 30 Button highlighted */
  forward30Button: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#HopForwardButton',
  },

  /** rewind 30 Button highlighted */
  rewind30Button: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#HopBackButton',
  },

  /** The actual Episodes page. Can be used to see if something on the episodes screen has focus */
  episodesScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen',
  },

  /** Marker to determine if we are on the Episodes page */
  episodesScreenPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#episodeScreen.#RowList.0.items.0.#FeaturePoster.#Background',
  },

  /** dialog box sign in button */
  dialogBoxSignInButton: {
    keyPath: '#ContentController.#3206c4d.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** Sign in screen password box */
  signInScreenPasswordBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#signUpLayout.#password.#rectBG',
  },

  /** Kids Sign in screen password box */
  kidSignInScreenPasswordBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password.#rectBG',
  },

  /** Enter your password meesage on dialog box */
  enterPasswordDialogMessage: {
    keyPath: '#ContentController.#390640d.#DialogBox.#ContentArea.#Title',
  },

  /** Password screen keyboard */
  passwordKeyboard: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#signInScreen.#passwordEntryKeyboard.0.#Keyboard.0',
  },

  /** exit Prompt */
  exitPrompt: {
    keyPath: '#ContentController.#2694d4e.#DialogBox.#ContentArea.#Title',
  },

  /** Player controls element */
  playerControls: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons',
  },

  /** Dialog box text for PC Settings Change for Little Kids */
  parentalControlsSettingsLittleKids: {
    keyPath: '#ContentController.#08fb5e0.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Dialog box text for PC Settings Change for Teens */
  parentalControlsSettingsTeens: {
    keyPath: '#ContentController.#c25f262.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Sign in password */
  passwordText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.0.#password.#Text',
  },

  /** Dialog box text for PC Settings Change for Older Kids */
  parentalControlsSettingsOlderKidsMessage: {
    keyPath: '#ContentController.#d15a38c.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Adult control in PC is selected */
  adultControlSelected: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#ParentalControlsMenu.3',
  },

  /** Live Icon */
  liveIcon: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TopHeaderImage',
  },

  /** Preview off button */
  autoplayPreviewOff: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#AutoplayPreviewMenu.1.#BtnLayout',
  },

  /** Autoplay sign in dialog Message */
  autoPlaySignInDialogMessage: {
    keyPath: '#ContentController.#4ec6117.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Sign in Button */
  signInButton: {
    keyPath: '#ContentController.#4ec6117.#DialogBox.#ContentArea.#ButtonList.0',
  },

  /** TV Shows Series text */
  tvShowsSeriesLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** Details page Series Label */
  detailsPageSeriesLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** Continue Watching Row on TV Screen */
  tvContinueWatchingRow: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#tvScreen.#ContentArea.#CategoryGridList.#RowList.0.title.#CategoryName',
  },

  /** email address box for creating account */
  emailAddressBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.2.#emailLayout.1.#emailTextEditBox.1',
  },

  /** age gate year box */
  ageGateYearsBox: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.2.#AgeVerificationAgeBg.#AgeVerificationAgeEntry',
  },

  /** age gate invalid age */
  ageGateInvalidAge: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.#AgeErrorPrompt',
  },

  /** Cannot exit kids mode modal */
  cannotExitKidsMode: {
    keyPath: '#ContentController.#c4796af.#DialogBox.#ContentArea',
  },

  /** Cannot exit kids mode title */
  cannotExitKidsModeTitle: {
    keyPath: '#ContentController.#c4796af.#DialogBox.#ContentArea.#Title'
  },

  /** Button Close text */
  buttonTextClose: {
    keyPath: '#ContentController.#c4796af.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** age gate error prompt */
  ageGateVerificationErrorPrompt: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.1.#AgeVerificationErrorPrompt',
  },

  /** movies details page label */
  detailsMoviesPageLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#DetailInfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** movies label */
  moviesLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** resume playing button */
  resumePlayingButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.0.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Play button */
  playFromBeginning: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#detailScreen.#AnimationGroup.#Menu.1.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** Sign up to save Progress description */
  signUpToSaveProgressDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** poster present */
  movieScreenPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#ContentArea.#CategoryGridList.#RowList.5.items.0.#poster',
  },

  /** settings screen header */
  settingsScreenHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#TitleOne',
  },

  /** terms screen header */
  termsScreenHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Title',
  },

  /** full device ID modal */
  fullDeviceID: {
    keyPath: '#ContentController.#2f12a2f.#DialogBox.#ContentArea.#Title',
  },

  /** About menu item */
  aboutMenuItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.2',
  },

  /** Full Device message */
  fullDeviceMessage: {
    keyPath: '#ContentController.#2f12a2f.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** help page text */
  helpPageText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#TextTwo',
  },

  /** Policy Page Header */
  privacyPolicyHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#panelContentSection.#heading',
  },

  /** Privacy Page scroller */
  privacyPageScroller: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Text.2',
  },

  /** empty My Stuff page */
  emptyMyStuffPage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#myStuffScreen.#ContentArea',
  },

  /** category on category page */
  channelCategoryGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid',
  },

  /** category on category page */
  categoryPageCategory: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.0.#Logo',
  },

  /** recommended tile on Categories page */
  recommendedCategoryPage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.0.#Title',
  },

  /** Call to Action text on Recommended screen */
  recommendedScreenCallToAction: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#nav.#ScreenNavigationHint.#callToAction',
  },

  /** channel page */
  channelPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#ChannelCategoryGrid.6.#PosterRect',
  },

  titleNameInPlayer : {
     keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#TopOverlay.#VideoOverlayTitle'
    },

  titleDescriptionInChannelGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description'
  },

  titleNameInContainer: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsInfoPanel.#infoPanelGroup.#Offset.#Title'
  },

  titleDescriptionOnHomeScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#movieScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description'
  },

  linearNavigationPanel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#overlayContentArea.#EPGHorizontalSlide.#EPG'  
  },

  liveNewsSubtitlesPanel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#linearVideoPlayerScreen.#VideoOverlay.#overlayParent.#closedCaptioningGroup.#closedCaptioningButtonListBackground'
  },

  /**  Invalid deep link dialog */
  invalidDeepLinkDialog: {
    keyPath: '#ContentController.#0e63aed.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** Horses and Ponies, Little Kids Tile in Categories */
  horsesAndPoniesTile: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.9.#Title',
  },

  /** Kid Friendly Classics, Older Kids Tile in Categories */
  kidFriendlyClassics: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.9.#Title',
  },

  /** Art-House Films for Teens Description */
  artHouseFilms: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.5.#Title',
  },

  /** Kids left nav option */
  kidsLeftNavOption: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.1.#LabelParent.0.#Label',
  },

  /** Parental Controls Menu item focused */
  parentalControlsMenuTextFocused: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.0.#DetailsMenuTextParent.#DetailsMenuTextFocused',
  },

  /** Search grid */
  searchGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchGroup.#SearchKeyboard.0',
  },

  /** No results message */
  noResultsMessage: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#ResultArea.#NoResultsMessage',
  },

  /** counter text for live preview */
  countDownText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#PlayerCountdownGroup.#CountdownText',
  },

  /** closed caption audio button */
  closedCaptionAudioButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons.#closedCaptionAudioButton',
  },

  /** Audio tracks section */
  audioTracksSection: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection',
  },

  /** CC section */
  closedCaptionSection: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection',
  },

  /** Audio label */
  audioTracksSectionHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTracksSectionHeaderLabel',
  },

  /** Audio Description text check */
  audioDescriptionText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.1.#BtnLayout.#Text',
  },

  /** sign out button selected */
  signOutButtonSelected: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.6.#DetailsMenuTextParent.#DetailsMenuText',
  },

  /** audio desc enabled */
  audioDescriptionEnabled: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.1.#container.0.#checkIcon',
  },

  /** subtitle OFF */
  subtitleOff: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection.#closedCaptionSelector.0',
  },

  /** subtitle enabled */
  subTitleEnabled: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection.#closedCaptionSelector.1',
  },

  /** audio enabled */
  audioEnabled: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.0',
  },

  /** audio desc enabled check */
  audioDescriptionEnabledCheck: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#audioTracksSection.#audioTrackSelector.1.#container',
  },

  /** autoplay countdown movies */
  countDownMovieAutoPlay: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#CountdownLabelMovie',
  },

  /** remaining time in player timer */
  remainingLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#RemainingLabel',
  },

  /** current time in player timer */
  currentTimePlayed: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#ElapsedLabel',
  },

  /** autoplay option year and duration info */
  autoPlayYearAndDuration: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup.#InfoMovie.#infoPanelGroup.#Offset.#TwoLineInfo.#FirstLineGroup.#Line1',
  },

  /** autoplay UI */
  autoplayUpNextUI: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#UpNext.#UpNextUI.#UpNextMovieGroup',
  },

  /** transport buttons UI */
  transportButtons: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#HUD.#Transport.#TransportButtons',
  },

  /** Settings menu item */
  settingsMenuItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.8',
  },

  /** Dialog box for Device ID */
  dialogBoxContentAreaDeviceID: {
    keyPath: '#ContentController.#2f12a2f.#DialogBox.#ContentArea',
  },

  /** My Stuff Left Nav option */
  myStuffLeftNav: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.4.#LabelParent.0.#Label',
  },

  /** Parental Controls header */
  parentalControlsHeader: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.3.#Offset.#ContentGroup.#Title',
  },

  /** Featured Row */
  featuredRow: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.1.title.#CategoryName',
  },

  /** Featured row poster */
  featuredRowPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#ContentArea.#CategoryGridList.#RowList.0.items.0.#poster',
  },

  /** description of title in CW row */
  homeScreenContentDescription: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#InfoPanelParent.#InfoPanel.#infoPanelGroup.#Offset.#DescriptionGroup.#Description',
  },

  /** age gate number page */
  ageVerificationPad: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.#AgeVerificationNumberPadGroup.#AgeVerificationNumberPad.#keyboard.0',
  },

  /** top nav For You */
  selectedTopNavForYouItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.0.#Underline',
  },

  /** top nav Movies */
  topNavMoviesItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.1.#TopLabel',
  },

  /** top nav TV Shows */
  topNavTVShowsItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.2.#TopLabel',
  },

  /** top nav Live TV */
  topNavLiveItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.3.#TopLabel',
  },

  /**  Live TV option is selected */
  selectedLiveTVItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#homeScreen.#topNav-home.#TopNavMenu.3.#BottomLabel',
  },

  /** Program Guide Header text on the Live TV tab */
  programGuideHeaderText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#epgScreen.#topNav-linearEPG-linearEPG-linearEPG.#TopNavMenu.3.#Underline',
  },

  /** text on Search page header */
  searchMenuText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#leftSide.#searchMenuText',
  },

  /** left nav search button */
  leftNavSearchButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.2',
  },

  leftNavSearchItem: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2'
  },

  /** parental controls button */
  parentalControlsButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#PanelSet.2.#SettingsMenuGroup.#SettingsMenu.0',
  },

  /** Search text */
  searchText: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#SearchText',
  },

  /** side nav element component */
  sideNavComponent: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected',
  },

  /** recommended poster */
  recommendedPoster: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.0.#Title',
  },

  /** categories left nav */
  categoriesLeftNavButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.5',
  },

  /** categories label highlighted */
  categoriesLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.5.#LabelParent.0.#Label',
  },

  /** categories  screen */
  categoriesListScreen: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid',
  },

  /** channels left nav button highlighted */
  channelsLeftNavButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.6',
  },

  /** channels list screen */
  channelsListScreenGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#channelListScreen.#ChannelCategoryGrid',
  },

  /** settings left nav button highlighted */
  settingsLeftNavButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.8',
  },

  /** categories video grid */
  categoriesVideoGrid: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryDetailsScreen.#ChannelsVideoGrid',
  },

  /** settings left nav button highlighted */
  exitLeftNavButton: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.9.#LabelParent.0.#Label',
  },

  /** age verification number pad */
  ageVerificationNumberPad: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.1.#AgeVerificationNumberPadGroup.#AgeVerificationNumberPad.#keyboard.0',
  },

  /** age verification years page */
  yearsVerificationEntry: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.3.#AgeVerificationPageText.#AgeVerificationPageHeader',
  },

  /** CW tile on Categories page */
  categoriesContinueWatchingTile: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#categoryListScreen.#ChannelCategoryGrid.1.#Title',
  },

  /** Search menu highlighted */
  searchMenuItemSelected: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItemsSelected.2',
  },

  /** Search keypad */
  searchKeyPad: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#searchScreen.#searchGroup.#SearchKeyboard.0',
  },

  /** label child in left nav */
  leftNavHomeLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.3.#LabelParent.0.#Label'
  },

  /** search label in left nav */
  leftNavSearchLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.2.#LabelParent.0.#Label',
  },

  /** title of Espanol Disabled dialog box */
  espanolDisabledTitle: {
    keyPath: '#ContentController.#c441913.#DialogBox.#ContentArea.#Title',
  },

  /** title of Espanol Disabled dialog box for teens */
  espanolDisabledTitleTeens: {
    keyPath: '#ContentController.#dd0197e.#DialogBox.#ContentArea.#Title',
  },

  /** message in Espanol Disabled dialog box */
  espanolDisabledMessage: {
    keyPath: '#ContentController.#c441913.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** message in Espanol Disabled box for teens */
  espanolDisabledMessageTeens: {
    keyPath: '#ContentController.#dd0197e.#DialogBox.#ContentArea.#MessageGroup.#Message',
  },

  /** button in Espanol Dissbled dialog box */
  espanolDisabledButton: {
    keyPath: '#ContentController.#c441913.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** button in Espanol Dissbled dialog box for Teens */
  espanolDisabledButtonTeens: {
    keyPath: '#ContentController.#dd0197e.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText',
  },

  /** tubi espanol logo */
  espanolLogo: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#logoGroup.#tubiEspanolLogo',
  },

  /** espanol screen row list  */
  espanolScreenRowList: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#espanolScreen.#ContentArea.#CategoryGridList.#RowList',
  },

  /** espanol screen row list  */
  sideNavChannelsLabel: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#SideNav.#itemGroups.0.#mainItems.6.#LabelParent.0.#Label',
  },

  /** settings Screen Title */
  settingsScreenTitle: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#settingsScreen.#Title'  
  },

  /** Exit Button Text */
  exitDialogButtonText: {
    keyPath: '#ContentController.#2694d4e.#DialogBox.#ContentArea.#ButtonList.0.#buttonTextParent.#buttonText'
  },

  /** Subtitles On */
  closedCaptionOn: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection.#closedCaptionSelector.1.#container.0.#checkIcon'
  },

  /** Subtitles Off */
  closedCaptionOff: {
    keyPath: '#ContentController.#uiGroup.#ContentGroup.#ScreenStack.#videoPlayerScreen.#closedCaptionAndAudioSelectionOverlayGroup.#closedCaptionAndAudioSelectionOverlay.#overlayBackground.0.#closedCaptionSection.#closedCaptionSelector.0.#container.0.#checkIcon'
  }

});

export {
  Element,
  ElementKey,
  ElementOrElementId,
  elements
};
