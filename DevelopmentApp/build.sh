#!/bin/sh

reveal_archive_in_finder=true

project="DevelopmentApp.xcodeproj"
framework_name="CompositeOperations"
framework="${framework_name}.framework"
ios_scheme="${framework_name}-iOS"
ios_example_scheme=Example-iOS
osx_scheme="${framework_name}-OSX"
osx_example_scheme="Example-OSX"

project_dir=${PROJECT_DIR:-.}
build_dir=${BUILD_DIR:-Build}
configuration=${CONFIGURATION:-Release}

ios_simulator_path="${build_dir}/${ios_scheme}/${configuration}-iphonesimulator"
ios_simulator_binary="${ios_simulator_path}/${framework}/${framework_name}"

ios_device_path="${build_dir}/${ios_scheme}/${configuration}-iphoneos"
ios_device_binary="${ios_device_path}/${framework}/${framework_name}"

ios_example_device_path="${build_dir}/${ios_example_scheme}/${configuration}-iphoneos"
ios_example_device_binary="${ios_example_device_path}/${ios_example_scheme}.app"

ios_example_simulator_path="${build_dir}/${ios_example_scheme}/${configuration}-iphonesimulator"
ios_example_simulator_binary="${ios_example_simulator_path}/${ios_example_scheme}.app"

osx_example_path="${build_dir}/${osx_example_scheme}/${configuration}-macosx"
osx_example_binary="${osx_example_path}/${osx_example_scheme}.app"

ios_universal_path="${build_dir}/${ios_scheme}/${configuration}-iphoneuniversal"
ios_universal_framework="${ios_universal_path}/${framework}"
ios_universal_binary="${ios_universal_path}/${framework}/${framework_name}"

osx_path="${build_dir}/${osx_scheme}/${configuration}-macosx"
osx_framework="${osx_path}/${framework}"

distribution_path="${project_dir}/../Frameworks"
distribution_path_ios="${distribution_path}/iOS"
distribution_path_osx="${distribution_path}/OSX"

echo "Project:       $project"
echo "Scheme iOS:    $ios_scheme"
echo "Scheme OSX:    $osx_scheme"

echo "Project dir:   $project_dir"
echo "Build dir:     $build_dir"
echo "Configuration: $configuration"
echo "Framework      $framework"

echo "iOS Simulator build path: $ios_simulator_path"
echo "iOS Device build path:    $ios_device_path"
echo "iOS Universal build path: $ios_universal_path"
echo "iOS Universal framework:  $ios_universal_framework"
echo "OSX build path:           $osx_path"
echo "OSX framework:            $osx_framework"

echo "Output folder:     $distribution_path"
echo "iOS output folder: $distribution_path_ios"
echo "OSX output folder: $distribution_path_osx"

run() {
	echo "Running command: $@"
    eval $@ || {
		echo "Command failed: \"$@\""
        exit 1
    }
}

# Clean Build folder

rm -rf "${build_dir}"
mkdir -p "${build_dir}"

# Build iOS Frameworks: iphonesimulator and iphoneos

run xcodebuild -project ${project} \
               -scheme ${ios_scheme} \
               -sdk iphonesimulator \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${ios_simulator_path} \
               clean build 

run xcodebuild -project ${project} \
               -scheme ${ios_scheme} \
               -sdk iphoneos \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${ios_device_path} \
               clean build

# Create directory for universal framework

rm -rf "${ios_universal_path}"
mkdir "${ios_universal_path}"

mkdir -p "${ios_universal_framework}"

# Copy files Framework

cp -r "${ios_device_path}/." "${ios_universal_framework}"

# Make an universal binary

lipo "${ios_simulator_binary}" "${ios_device_binary}" -create -output "${ios_universal_binary}"

# Build OSX framework

run xcodebuild -project ${project} \
               -scheme ${osx_scheme} \
               -sdk macosx \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${osx_path} \
               clean build 
# Copy results to output Frameworks/{iOS,OSX} directories

rm -rf "$distribution_path"
mkdir -p "$distribution_path_ios"
mkdir -p "$distribution_path_osx"

cp -av "${ios_universal_framework}" "${distribution_path_ios}"
cp -av "${osx_framework}" "${distribution_path_osx}"

# Validate iOS example application

# Build Example iOS app against simulator
run xcodebuild -project ${project} \
               -target ${ios_example_scheme} \
               -sdk iphonesimulator \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${ios_example_simulator_path} \
               clean build

# Build Example iOS app against device
run xcodebuild -project ${project} \
               -target ${ios_example_scheme} \
               -sdk iphoneos \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${ios_example_device_path} \
               clean build

run codesign -vvvv --verify --deep ${ios_example_device_binary}

# How To Perform iOS App Validation From the Command Line
# http://stackoverflow.com/questions/7568420/how-to-perform-ios-app-validation-from-the-command-line
run xcrun -v -sdk iphoneos Validation ${ios_example_device_binary}

# Build Example OSX app
run xcodebuild -project ${project} \
               -target ${osx_example_scheme} \
               -sdk macosx \
               -configuration ${configuration} \
               CONFIGURATION_BUILD_DIR=${osx_example_path} \
               clean build

# How To Perform App Validation From the Command Line
# http://stackoverflow.com/questions/7568420/how-to-perform-ios-app-validation-from-the-command-line
run codesign -vvvv --verify --deep ${osx_example_binary}

# See results

if [ ${reveal_archive_in_finder} = true ]; then
    open "${distribution_path}"
fi

