function getSettings ()
  return {
    mode: "dev"
    version: "2_10_0"
    contentType: "hls"
    shortAppName: "tubitv"
    platformName: "roku"
    remoteComponentsHost: "http://192.168.31.157:8090"
    remoteComponentsExtension: "pkg"
    migrateToken: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0eXBlIjo0LCJwbGF0Zm9ybSI6InJva3UiLCJpYXQiOjE0NTgzMjkzNDd9.726iJo5B68VLn-HfWj4V5mwrn6vI5MQOfsQcs-gT5TA"
    hotPatchUrl: "http://192.168.31.157:8090/hotpatch/2.10.brs"
    starterComponentsUrl: "http://192.168.31.157:8090/starterComponents-2.10.pkg"
    remoteComponentsUrl: "http://192.168.31.157:8090/tubi_remote_components_2_10_0.pkg"
  }
end function

function getManifest ()
  return {
    title: "Tubi"
    mm_icon_focus_hd: "pkg:/images/channel-icon-hd-336x210.png"
    mm_icon_focus_sd: "pkg:/images/channel-icon-sd-246x140.png"
    splash_screen_fhd: "pkg:/images/splash-fhd.png"
    splash_screen_hd: "pkg:/images/splash-hd.png"
    splash_screen_sd: "pkg:/images/splash-sd.png"
    bs_libs_required: "roku_ads_lib"
    ui_resolutions: "fhd"
    uri_resolution_autosub: "$$RES$$,sd,hd,fhd"
    requires_widevine_drm: 1
    requires_widevine_version: "1.0"
    supports_input_launch: 1
    major_version: 2
    minor_version: 10
    build_version: 0
  }
end function

function getComponent_library_manifest ()
  return {
    title: "Tubi Component Library"
    subtitle: "Remote loading for scenegraph components"
    sg_component_libs_provided: "TubiRemoteLibrary"
    bs_libs_required: "roku_ads_lib"
    requires_widevine_drm: 1
    requires_widevine_version: "1.0"
    hidden: 1
    major_version: 2
    minor_version: 10
    build_version: 0
  }
end function

function getStarter_library_manifest ()
  return {
    title: "Tubi Starter Library"
    subtitle: "Startup components"
    sg_component_libs_provided: "TubiStarterLibrary"
    hidden: 1
    major_version: 2
    minor_version: 10
    build_version: 0
  }
end function
