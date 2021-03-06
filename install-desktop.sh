#!/bin/bash

path=$(dirname $(readlink -f $0))  # Script path. Resolves symlinks
me=$(basename $0)  # script.sh
errors="\n"        # Container for error messages
download_path='/tmp/dotfiles'
files_path="${path}/files"


function showHelp
{
  cat <<EndOfHelp

    Install desktop applications

    Usage:
        $me <packages>
        $me [ -h | --help ]

    Packages:
        chrome        Google Chrome browser
        dropbox       Dropbox
        sublime-text  Sublime Text 3 editor
        guake         Guake dropdown terminal
        grub-cust     Grub customizer
        screenrec     Simple Screen Recorder
        gimp          Gimp with plugins, filters and effects

EndOfHelp

  exit 0
}


function logError
{
  errors="${errors}\n[ERROR] $1"
}


function checkCurlInstalled
{
  type curl &> /dev/null &&
    return 0

  echo -e "\nThis action requires \"curl\" to be installed."
  echo -ne "Install it now? [Y/n] "
  read -s -n 1 confirm

  [ -n "$confirm" ] && [ "$confirm" != 'Y' ] && [ "$confirm" != 'y' ] &&
    echo -e "\n" &&
    return 1

  echo -e "\n"

  sudo apt-get install -y curl &&
    return 0

  logError "curl install failed"
  return 1
}


function installGoogleChrome
{
  latest_url='https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb'
  deb_file="${download_path}/google-chrome.deb"

  wget --output-document "$deb_file" "$latest_url" &&
    sudo dpkg -i --force-depends "$deb_file"
  sudo apt-get install -f
}


function installDropbox
{
  installer_url='https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb'
  deb_file="${download_path}/dropbox.deb"

  wget --output-document "$deb_file" "$installer_url" &&
    sudo dpkg -i "$deb_file" ||
    logError "dropbox install failed"
}


function installSublimeText
{
  if ! checkCurlInstalled
  then
    logError "sublime-text install failed. Missing \"curl\""
    return 1
  fi

  updatecheck_url='http://www.sublimetext.com/updates/3/stable/updatecheck?platform=linux&arch=x64'
  latest_version_regex='(?<="latest_version": )[0-9]+'
  latest_version=$(curl -s "$updatecheck_url" | grep -Po "$latest_version_regex")

  latest_url="https://download.sublimetext.com/sublime-text_build-${latest_version}_amd64.deb"
  deb_file="${download_path}/sublime-text-3.deb"

  wget --output-document "$deb_file" "$latest_url" &&
    sudo dpkg -i "$deb_file" ||
    logError "sublime-text install failed"
}


function installGuake
{
  sudo apt-get install -y guake ||
    { logError "guake install failed"; return 1; }

  mkdir -p ~/.config/autostart &&
    cp /usr/share/applications/guake.desktop ~/.config/autostart/ ||
    logError "guake autostart configuration failed"

  cp -r ${files_path}/guake/* ~/.gconf/apps/guake/ ||
    logError "guake custom configuration failed"
}


function installGrubCustomizer
{
  sudo add-apt-repository ppa:danielrichter2007/grub-customizer &&
    sudo apt-get update &&
    sudo apt-get install -y grub-customizer ||
    logError "grub-customizer install failed"
}


function installSimpleScreenRecorder
{
  sudo add-apt-repository ppa:maarten-baert/simplescreenrecorder &&
    sudo apt-get update &&
    sudo apt-get install -y simplescreenrecorder ||
    logError "simplescreenrecorder install failed"
}


function installGimp
{
  sudo add-apt-repository ppa:otto-kesselgulasch/gimp &&
    sudo apt-get update &&
    sudo apt-get install -y gimp &&
    sudo apt-get install -y gimp-plugin-registry gimp-gmic ||  # Plugins, filters and effects
    logError "gimp install failed"
}


# Check params
[ $# -eq 0 ] && showHelp

mkdir -p "$download_path"

for param in "$@"
do
  case "$param" in
    "-h" | "--help" )
      showHelp
    ;;
    "chrome" )
      installGoogleChrome
    ;;
    "dropbox" )
      installDropbox
    ;;
    "sublime-text" )
      installSublimeText
    ;;
    "guake" )
      installGuake
    ;;
    "grub-cust" )
      installGrubCustomizer
    ;;
    "screenrec" )
      installSimpleScreenRecorder
    ;;
    "gimp" )
      installGimp
    ;;
    * )
      logError "Invalid parameter: $param"
    ;;
  esac
done

echo -e "$errors\n"


exit 0
