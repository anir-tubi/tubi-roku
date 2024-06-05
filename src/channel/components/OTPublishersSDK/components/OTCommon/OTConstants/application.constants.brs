function applicationConstants()
    constant = {
        info: {
            bannerAllowAll: "Banner - Allow All",
            bannerRejectAll: "Banner - Reject All",
            bannerContinueWithoutAccepting: "Banner - Continue without Accepting",
            bannerClose: "Banner - Close",
            preferenceCenterAllowAll: "Preference Center - Allow All",
            preferenceCenterRejectAll: "Preference Center - Reject All",
            preferenceCenterConfirm: "Preference Center - Confirm",
            '  preferenceCenterClose: "Preference Center - Close",
            vendorListConfirm: "Vendor List - Confirm",
            vendorListAllowAll: "Vendor List - Allow All",
            vendorListRejectAll: "Vendor List - Reject All",
            sdkListAllowAll: "SDK List - Allow All",
            sdkListRejectAll: "SDK List - Reject All",
            sdkListConfirm: "SDK List - Confirm",

            "700": "OT config file is read",
            "701": "OT SDK data is cleared",
            "702": "get lastlaunch = ",
            "703": "save lastlaunch = ",
            "704": "OT SDK version = ",
            "705": " OT public method called.",
            "706": "OT Identifier is set = ",
            "707": "OT IABUSPrivacy_String = ",
            "708": "OT consent logging pending = ",
            "709": "OT Device connection status = ",
            "710": "OT consent time = ",
            "711": "OT IABTCF_AddtlConsent = ",
            "712": " parameters = ",
            "713": "Is Banner Shown status = ",
            "714": "Should show banner status = ",
            "715": "lastConsentTime = ",
            "716": "current Time in Seconds = ",
            "717": "Last consent days = ",
            "718": " url = ",
            "719": "Consent logging receipt = ",
            "720": "countryCode = ",
            "721": "regionCode = ",
            "722": "ccpaGeolocation = ",
            "723": "OT IABTCF_TCString = ",
            "724": "Geolocation Status: Show Banner is $status for current geolocation rule.",
            "725": "Reconsent Status: Show Banner is enabled for current geolocation rule and user consent is older than lastReconsentDateFromServer",
            ' "726": "Enabled auto re-consent because the last given consent has been expired.",
            "727": "Saved allPurposesUpdatedAfterSync = ",
            "728": "IAB region: Showing UI as user has not given consent in IAB region previously",
            "729": "Showing UI as change in group configuration detected",
            "730": "Saved shouldShowBannerAsConsentExpired = ",
            "731": "Reconsent Status: Show Banner is enabled for current geolocation rule and user consent is older than lastReconsentDateFromServer",
            "732": "Reconsent Status: Show Banner is enabled for current geolocation rule and previous lastReconsentDateFromServer is older than lastReconsentDateFromServer",
            "733": "Last re-consent date not initialized, it will be set once OT SDK initialized.",
            "734": "Initializing the last re-consent date to - ",
            "735": "iab related values cleared on auto re-consent",
            "736": "Available space in the registry = ",
            "737": "Vendor count for category ",
            "738": "OT IABGPP_HDR_GppString = ",
            "739": "Gpp $1 for this region,$2 computing Gpp string."
        },
        warning: {
            "900": " is required to download the OT sdk data",
            "901": "  should be boolean type",
            "902": "  should be string type",
            "903": "OT UIview controller is missing",
            "904": "OT setupUI method must first be called, OT UIview controller is missing",
            "905": "No group found with the id ",
            "906": " should not be empty string",
            "907": "Consent model for CCPA Parent category is  set to Notice Only. Cannot opt out or opt in of selected CCPA Parent category",
            "908": "Invalid CCPA configuration. Please assign SDKs to the CCPA category or its subgroups."
            "909": "Max number of profiles already created. Please delete one of the profiles to be able to add a new one."
            "910": "Multi Profile Consent is disabled. Please enable Multi Profile Consent from OneTrust Admin."
        },
        error: {
            "505": "OT ConsentApi is null and unable to log consent",
            "502": "SDK Initialization failed, Cannot parse the data received from Server because it is corrupted",
            "503": "No data found to render the UI, Please initialize the SDK and try again.",
            "504": "please provide valid parameter DSID to public method ",
            "507": "please provide valid parameter category ID to 'getVendorCount' public method.",
            "506": " data not found, Please download the data.",
        },
        failed: {
            "600": "OT Get API Failure = ",
            "601": "OT Post API Failure = ",
            "602": "Failure, Please enter mandatory fields",
            "603": "Failure, Error Message",
            "604": "switchUserProfile failed, selected DSID is a current user profile please provide other user DSID.",
            "605": "Failed to delete profile "
        }
        success: {
            "200": "Aplication Data API Success",
            "201": " Vendorlist Api Success",
            "202": " Api Success",
            "203": "Success, Data Downloaded",
            "204": "Success, data is now cleared",
            "205": " profile has been switched successfully"
            "206": " Profile deleted successfully."
        }
        listener: {
            ' event listener messages

            ' banner
            "ELB100": "OT onShowBanner called.",
            "ELB101": "OT onBannerClickedAcceptAll called.",
            "ELB102": "OT onBannerClickedRejectAll called.",
            "ELB103": "OT onShowPreferenceCenter called.",
            "ELB104": "OT onShowVendorsList called.",
            "ELB105": "OT onHideBanner called.",

            ' preference
            "ELP100": "OT onShowPreferenceCenter called.",
            "ELP101": "OT onPreferenceCenterClickedAcceptAll called.",
            "ELP102": "OT onPreferenceCenterClickedRejectAll called.",
            "ELP103": "OT onPreferenceCenterClickedConfirmChoices called.",
            "ELP104": "OT onPreferenceCenterPurposeLegitimateInterestChanged called.",
            "ELP105": "OT onPreferenceCenterPurposeConsentChanged called.",
            "ELP106": "OT onShowVendorList called.",
            "ELP109": "OT onShowSDKList called.",
            "ELP110": "OT onHidePreferenceCenter called.",

            'vendor
            "ELV100": "OT onHideVendorList called.",
            "ELV101": "OT onVendorListClickedAcceptAll called.",
            "ELV102": "OT onVendorListClickedRejectAll called.",
            "ELV103": "OT onVendorListClickedConfirmChoices called.",
            "ELV107": "OT onVendorListVendorConsentChanged called.",
            "ELV108": "OT onVendorListVendorLegitimateInterestChanged called.",

            'sdk List
            "ELS100": "OT onHideSDKList called.",
            "ELS101": "OT onSDKListClickedAcceptAll called.",
            "ELS102": "OT onSDKListClickedRejectAll called.",
            "ELS103": "OT onSDKListClickedConfirmChoices called.",
            "ELS104": "OT onSDKListSDKConsentChanged called.",
        }
        bannerLogging: {
            "101": "Displaying OT Banner because georule has it enabled.",
            "102": "Displaying OT Banner because sdk has been published with reconsent.",
            "103": "Displaying OT Banner because sdk's reconsent has expired.",
            "104": "Displaying OT Banner because the TC String has expired.",
            "105": "Displaying OT Banner because consent has expired.",
            "106": "Displaying OT Banner because service specific is off as part of TC string details.",
            "107": "Displaying OT Banner because 100% sync has not happened for cross device sync enabled scenario.",
            "108": "Displaying OT Banner because sdk has entered backward compatibility mode and OT SDK UI has never been shown until now.",
            "109": "Displaying OT Banner because we have moved region (from non-IAB to IAB region)",
            "110": "Displaying OT Banner because the application has called the API to show OT SDK UI.",
            "111": "Displaying OT Banner because new category or purpose addition is detected."
        }

    }
    return constant
end function

function getErrorType()
    return {
        Success: "Success",
        Error: "Error",
        Failed: "Failed",
        Warning: "Warning",
        Storage: "Storage",
        Banner: "Banner",
        preferenceCenter: "PreferenceCenter",
        VendorList: "VendorList",
        SDKList: "SDKList",
        Info: "Info",
        Token: "Token",
    }
end function

function getErrorTags()
    return {
        IABHelper: "IABHelper",
        OTPublishersHeadlessSDK: "OTPublishersHeadlessSDK",
        NetworkRequestHandler: "NetworkRequestHandler",
        OneTrust: "OneTrust",
        EventListener: "EventListener",
        VendorUtils: "VendorUtils",
        StorageUtils: "StorageUtils",
        IABCCPA_Consent: "IABCCPA_Consent",
        Buttons: "Buttons",
        Token: "Token",
        DsDataElementPayload: "DsDataElementPayload",
        ConsentLogging: "ConsentLogging",
        MultiProfile: "MultiProfile",
        PublicMethod: "PublicMethod",
        OTUIDisplayReasonMessage: "OTUIDisplayReasonMessage"
    }
end function

function getGPPConstants()
    return {
        ' Template Type
        USNAT_TEMPLATE: "USNATIONAL",
        CALIFORNIA_TEMPLATE: "CPRA",
        VIRGINIA_TEMPLATE: "CDPA",
        COLORADO_TEMPLATE: "COLORADO",
        UTAH_TEMPLATE: "UCPA",
        CONNECTICUT_TEMPLATE: "CTDPA",
        CCPA_CALIFORNIA_TEMPLATE: "CCPA",

        ' Template Json Type
        USNATIONAL: "usnatv1"
        CPRA: "uscav1",
        CDPA: "usvav1",
        COLORADO: "uscov1",
        UCPA: "usutv1",
        CTDPA: "usctv1",

        ' section string keys
        IAB_GPP_TCFEU2_STRING: "IABGPP_2_String", 'gpp tcf str
        IAB_GPP_USP_STRING: "IABGPP_6_String", ' gpp ccpa str
        IAB_GPP_US_NAT_STRING: "IABGPP_7_String", ' gpp us nat str
        IAB_GPP_CALIFORNIA_STRING: "IABGPP_8_String", ' gpp cpra str
        IAB_GPP_USVA_STRING: "IABGPP_9_String", ' gpp cdpa(virginia) str
        IAB_GPP_USCO_STRING: "IABGPP_10_String", ' gpp cpa(colorado) str
        IAB_GPP_USUT_STRING: "IABGPP_11_String", ' gpp ucpa(utah) str
        IAB_GPP_USCT_STRING: "IABGPP_12_String", ' gpp ctdpa(connecticut)

        ' OTGppConsentStates
        NOT_APPLICABLE: 0,
        CONSENT_OR_OPTED: 2,
        NO_CONSENT_OR_OPTED_OUT: 1,
        NOTICE_GIVEN: 1,
        NO_NOTICE_GIVEN: 2,

        ' MSPA Status
        MSP_ENABLED: 1,
        MSP_DISABLED: 2,

        ' MSPAMode
        optOut: "Opt-Out",
        serviceProvider: "Service Provider"
    }
end function

