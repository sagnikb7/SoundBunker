"""Deterministic standard Xcode project generation; no external dependencies."""
from pathlib import Path
import hashlib

from update_project_metadata import update
root = Path(__file__).resolve().parents[1]
update(root)
project = root / 'OfflineMusicPlayer.xcodeproj'
project.mkdir(exist_ok=True)
objects = {}
def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(name, content):
    objects[uid(name)] = content
    return uid(name)
def array(items):
    return '(' + ', '.join(items) + (',' if items else '') + ')'
def config(name, settings):
    return add(name, '{isa = XCBuildConfiguration; buildSettings = {' + settings + '}; name = ' + name.split('-')[-1] + ';}')

sources = sorted((root / 'OfflineMusicPlayer').rglob('*.swift'))
tests = sorted((root / 'OfflineMusicPlayerTests').glob('*.swift'))
source_refs, source_builds, test_refs, test_builds = [], [], [], []
for paths, refs, builds in [(sources, source_refs, source_builds), (tests, test_refs, test_builds)]:
    for path in paths:
        rel = str(path.relative_to(root))
        ref = add(rel, '{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "' + rel + '"; sourceTree = SOURCE_ROOT;}')
        refs.append(ref)
        builds.append(add('build-'+rel, '{isa = PBXBuildFile; fileRef = '+ref+';}'))
fixture = add('fixture', '{isa = PBXFileReference; lastKnownFileType = audio.wav; path = OfflineMusicPlayerTests/Fixtures/TestTone.wav; sourceTree = SOURCE_ROOT;}')
fixture_build = add('fixtureBuild', '{isa = PBXBuildFile; fileRef = '+fixture+';}')
app_product = add('appProduct', '{isa = PBXFileReference; explicitFileType = wrapper.application; path = OfflineMusicPlayer.app; sourceTree = BUILT_PRODUCTS_DIR;}')
test_product = add('testProduct', '{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = OfflineMusicPlayerTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;}')
assets = add('assets', '{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = OfflineMusicPlayer/Assets.xcassets; sourceTree = SOURCE_ROOT;}')
notes = add('releaseNotes', '{isa = PBXFileReference; lastKnownFileType = text.json; path = OfflineMusicPlayer/Resources/ReleaseNotes.json; sourceTree = SOURCE_ROOT;}')
project_info = add('projectInfo', '{isa = PBXFileReference; lastKnownFileType = text.json; path = OfflineMusicPlayer/Resources/Project.json; sourceTree = SOURCE_ROOT;}')
project_info_build = add('projectInfoBuild', '{isa = PBXBuildFile; fileRef = '+project_info+';}')
notes_build = add('releaseNotesBuild', '{isa = PBXBuildFile; fileRef = '+notes+';}')
add('assetsBuild', '{isa = PBXBuildFile; fileRef = '+assets+';}')
widget_paths = sorted((root / 'CassetteWidget').glob('*.swift')) + sorted((root / 'OfflineMusicPlayer/Widgets').glob('*.swift'))
widget_refs, widget_builds = [], []
for path in widget_paths:
    rel = str(path.relative_to(root))
    ref = uid(rel) if uid(rel) in objects else add(rel, '{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "'+rel+'"; sourceTree = SOURCE_ROOT;}')
    widget_refs.append(ref)
    widget_builds.append(add('widgetBuild-'+rel, '{isa = PBXBuildFile; fileRef = '+ref+';}'))
widget_product = add('widgetProduct', '{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; path = CassetteWidget.appex; sourceTree = BUILT_PRODUCTS_DIR;}')
widget_assets_ref = add('widgetAssets', '{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = CassetteWidget/Assets.xcassets; sourceTree = SOURCE_ROOT;}')
widget_assets_build = add('widgetAssetsBuild', '{isa = PBXBuildFile; fileRef = '+widget_assets_ref+';}')
embed_widget = add('embedWidget', '{isa = PBXBuildFile; fileRef = '+widget_product+'; platformFilter = ios; settings = {ATTRIBUTES = (RemoveHeadersOnCopy,);};}')
embed_phase = add('embedWidgets', '{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = ('+embed_widget+',); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;}')
products = add('products', '{isa = PBXGroup; children = '+array([app_product,test_product,widget_product])+'; name = Products; sourceTree = "<group>";}')
group = add('rootGroup', '{isa = PBXGroup; children = '+array(list(dict.fromkeys(source_refs+test_refs+widget_refs))+[fixture,assets,widget_assets_ref,notes,project_info,products])+'; sourceTree = "<group>";}')
def phase(name, kind, files):
    return add(name, '{isa = '+kind+'; buildActionMask = 2147483647; files = '+array(files)+'; runOnlyForDeploymentPostprocessing = 0;}')
app_phases = [phase('appSources','PBXSourcesBuildPhase',source_builds),phase('appFrameworks','PBXFrameworksBuildPhase',[]),phase('appResources','PBXResourcesBuildPhase',[uid('assetsBuild'),notes_build,project_info_build])]
test_phases = [phase('testSources','PBXSourcesBuildPhase',test_builds),phase('testFrameworks','PBXFrameworksBuildPhase',[]),phase('testResources','PBXResourcesBuildPhase',[fixture_build])]
def config_list(name, configs):
    return add(name, '{isa = XCConfigurationList; buildConfigurations = '+array(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}')
project_configs, app_configs, test_configs, widget_configs = [], [], [], []
for mode in ['Debug','Release']:
    base = 'IPHONEOS_DEPLOYMENT_TARGET = 15.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; '
    base += 'SWIFT_OPTIMIZATION_LEVEL = "-Onone"; ENABLE_TESTABILITY = YES; DEBUG_INFORMATION_FORMAT = dwarf; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;' if mode == 'Debug' else 'SWIFT_OPTIMIZATION_LEVEL = "-O"; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'
    project_configs.append(config('project-'+mode,base))
    app_configs.append(config('app-'+mode,'PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.local.offlinemusicplayer; INFOPLIST_FILE = OfflineMusicPlayer/Info.plist; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; "CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = OfflineMusicPlayer/OfflineMusicPlayer.entitlements; "CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]" = OfflineMusicPlayer/OfflineMusicPlayer.entitlements; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"; SUPPORTS_MACCATALYST = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";'))
    test_configs.append(config('test-'+mode,'PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.local.offlinemusicplayer.tests; GENERATE_INFOPLIST_FILE = YES; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/OfflineMusicPlayer.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/OfflineMusicPlayer"; BUNDLE_LOADER = "$(TEST_HOST)"; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";'))
    widget_configs.append(config('widget-'+mode, 'PRODUCT_NAME = CassetteWidget; PRODUCT_BUNDLE_IDENTIFIER = com.local.offlinemusicplayer.widget; INFOPLIST_FILE = CassetteWidget/Info.plist; CODE_SIGN_ENTITLEMENTS = CassetteWidget/CassetteWidget.entitlements; CODE_SIGN_STYLE = Automatic; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SUPPORTS_MACCATALYST = NO; TARGETED_DEVICE_FAMILY = "1,2"; APPLICATION_EXTENSION_API_ONLY = YES; SKIP_INSTALL = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";'))
widget_config = config_list('widgetConfigs', widget_configs)
widget_phases = [phase('widgetSources','PBXSourcesBuildPhase',widget_builds),phase('widgetFrameworks','PBXFrameworksBuildPhase',[]),phase('widgetResources','PBXResourcesBuildPhase',[widget_assets_build])]
widget_target = add('widgetTarget','{isa = PBXNativeTarget; buildConfigurationList = '+widget_config+'; buildPhases = '+array(widget_phases)+'; buildRules = (); dependencies = (); name = CassetteWidget; productName = CassetteWidget; productReference = '+widget_product+'; productType = "com.apple.product-type.app-extension";}')
widget_proxy = add('widgetProxy','{isa = PBXContainerItemProxy; containerPortal = '+uid('project')+'; proxyType = 1; remoteGlobalIDString = '+widget_target+'; remoteInfo = CassetteWidget;}')
widget_dep = add('widgetDependency','{isa = PBXTargetDependency; target = '+widget_target+'; targetProxy = '+widget_proxy+'; platformFilter = ios;}')
app_config = config_list('appConfigs',app_configs)
test_config = config_list('testConfigs',test_configs)
project_config = config_list('projectConfigs',project_configs)
proxy = add('proxy','{isa = PBXContainerItemProxy; containerPortal = '+uid('project')+'; proxyType = 1; remoteGlobalIDString = '+uid('appTarget')+'; remoteInfo = OfflineMusicPlayer;}')
dep = add('dependency','{isa = PBXTargetDependency; target = '+uid('appTarget')+'; targetProxy = '+proxy+';}')
app_target = add('appTarget','{isa = PBXNativeTarget; buildConfigurationList = '+app_config+'; buildPhases = '+array(app_phases+[embed_phase])+'; buildRules = (); dependencies = '+array([widget_dep])+'; name = OfflineMusicPlayer; productName = OfflineMusicPlayer; productReference = '+app_product+'; productType = "com.apple.product-type.application";}')
test_target = add('testTarget','{isa = PBXNativeTarget; buildConfigurationList = '+test_config+'; buildPhases = '+array(test_phases)+'; buildRules = (); dependencies = '+array([dep])+'; name = OfflineMusicPlayerTests; productName = OfflineMusicPlayerTests; productReference = '+test_product+'; productType = "com.apple.product-type.bundle.unit-test";}')
proj = add('project','{isa = PBXProject; attributes = {LastUpgradeCheck = 2700; TargetAttributes = {'+test_target+' = {TestTargetID = '+app_target+';};};}; buildConfigurationList = '+project_config+'; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = '+group+'; productRefGroup = '+products+'; projectDirPath = ""; projectRoot = ""; targets = '+array([app_target,test_target,widget_target])+';}')
(project / 'project.pbxproj').write_text('// !$*UTF8*$!\n{archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+ '\n'.join(k+' = '+v+';' for k,v in objects.items())+'\n}; rootObject = '+proj+';}\n')
scheme_dir = project / 'xcshareddata/xcschemes'
scheme_dir.mkdir(parents=True,exist_ok=True)
def reference(identifier,name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{identifier}" BuildableName="{name}" BlueprintName="{name.split(".")[0]}" ReferencedContainer="container:OfflineMusicPlayer.xcodeproj"/>'
app_ref, test_ref = reference(app_target,'OfflineMusicPlayer.app'), reference(test_target,'OfflineMusicPlayerTests.xctest')
(scheme_dir / 'OfflineMusicPlayer.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test_ref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print(project)
