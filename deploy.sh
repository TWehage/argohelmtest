#!/bin/bash

##################
# CONFIG
##################

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LGRAY='\033[0;37m'
DGRAY='\033[1;30m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
#printf "I ${RED}love${NC} Stack Overflow\n"
#echo -e "I ${RED}love${NC} Stack Overflow"

mode=$1

echo
if [ "$mode" = "live" ]; then
  echo -e "${YELLOW}Production Modus!${NC}"
  debug_mode=false
  stage_mode=false
elif [ "$mode" = "stage" ]; then
  echo -e "${PURPLE}Stage Modus!${NC}"
  debug_mode=false
  stage_mode=true
elif [ "$mode" = "debug-live" ]; then
  echo -e "${PURPLE}Debug Live Modus!${NC}"
  debug_mode=true
  stage_mode=false
elif [ "$mode" = "" ]; then
  echo -e "${PURPLE}Debug Stage Modus!${NC}"
  debug_mode=true
  stage_mode=true
else
  echo -e "USAGE: ${BLUE}deploy.sh #mode#${NC}"
  echo -e "Valid modes: live|stage|debug-live or empty = debug-stage"
  exit
fi

image=ghcr.io/twehage/testapp
if $stage_mode ; then
  echo -e "${PURPLE}Stage Settings!${NC}"
  namespace=testapp
  release=testapp
else
  if $debug_mode ; then
    echo -e "${PURPLE}Debug Live Settings!${NC}"
  else
    read -p "Live Settings: Fortsetzen? (J/N): " confirm && [[ $confirm == [jJ] || $confirm == [jJ][aA] ]] || exit 1
  fi
  namespace=testapp
  release=testapp
fi

##################
# Check Kubernetes Connection
##################

echo -e "${WHITE}Teste Verbindung zu Kubernetes:${NC}"
state=$(kubectl -n $namespace get pods 2>&1)
statepattern='^NAME.*READY.*STATUS.*'
if [ "$state" = "No resources found in $namespace namespace." ] ; then
  echo -e "Kubernetes Verbindung: ${GREEN}OK${NC}"
  pods_available=false
elif [[ ! "$state" =~ $statepattern ]]; then
  echo $state
	echo -e "Kubernetes namespace nicht gefunden: ${BLUE}kubectl config use-context esbtest${NC}"
	exit
else
  echo -e "Kubernetes Verbindung: ${GREEN}OK${NC}"
  pods_available=true
fi

##################
# Specify new version number
##################

echo
echo -e "${WHITE}Aktuelle Docker Images:${NC}"
images=$(docker images | grep -E "^${image}.*\s([0-9]+\.[0-9]\.[0-9])")
echo -e $images

read -p 'Neue Versionsnummer: ' version
vpattern="^[0-9]+\.[0-9]\.[0-9]"
if [[ $version =~ $vpattern ]]; then
  version_already_deployed=$(echo $images | grep $version)
  if [ "$version_already_deployed" = "" ] ; then
    docker_deploy=true
  else
    read -p "Version $version ist bereits vorhanden: Überschreiben? (J/N): " confirm
    if [[ $confirm == [jJ] || $confirm == [jJ][aA] ]] ; then
      docker_deploy=true
    else
      docker_deploy=false
    fi
  fi
else
  echo -e "Ungültige Versionsnummer(${RED}$version${NC}): Format #.#.# (eg. 1.0.5)'"
  exit 1
fi

if $docker_deploy ; then
  ##################
  # Push docker image
  ##################

  echo
  echo -e "${WHITE}Veröffentliche Docker Image:${NC}"
  if $debug_mode ; then
    echo -e "${PURPLE}Debug Modus:${NC} überspringe ${BLUE}docker build . -t \"$image:$version\"${NC}"
    echo -e "${PURPLE}Debug Modus:${NC} überspringe ${BLUE}docker push \"$image:$version\"${NC}"
  else
    read -p "Neues Docker Image veröffentlichen? (J/N): " confirm && [[ $confirm == [jJ] || $confirm == [jJ][aA] ]] || exit 1
    docker build . -t "$image:$version"
    docker push "$image:$version"
  fi
else
  echo
  echo -e "Es wird das bestehende Image: ${GREEN}$image${NC} Version: ${GREEN}$version${NC} deployed"
fi


##################
# Go to chart folder
##################

cd chart

##################
# Prepare helm package
##################

echo
echo -e "${WHITE}Anpassen der Helm Chart Konfiguration:${NC}"
echo -e "${BROWN}Chart.yaml${NC}"
chart=$(cat "Chart.tmpl")
echo -e "Setze Name ${BLUE}$release${NC}"
chart=$(sed -r "s/##NAME##/$release/g" <<< "$chart")
echo -e "Setze App Version ${BLUE}$version${NC}"
chart=$(sed -r "s/##APP_VERSION##/$version/g" <<< "$chart")
chart=$(sed -r "s/##HELM_VERSION##/$version/g" <<< "$chart")
echo "$chart" > "Chart.yaml"

echo -e "${BROWN}values.yaml${NC}"
values=$(cat "values.tmpl")
echo -e "Setze Host ${BLUE}${release}.esb.test-prediger.de${NC}"
values=$(sed -r "s/##HOST##/${release}.esb.test-prediger.de/g" <<< "$values")
values=$(sed -r "s/##TLSHOST##/${release}.esb.test-prediger.de/g" <<< "$values")
echo -e "Setze SecretName ${BLUE}${release}-esb-test-prediger-de-tls${NC}"
values=$(sed -r "s/##SECRETNAME##/${release}-esb-test-prediger-de-tls/g" <<< "$values")
echo "$values" > "values.yaml"

echo -e "${GREEN}Fertig!${NC}"

