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

##################
# Commandline parameters
##################
VERSION=$1
MODE=$2
HELM_STAGE_VERSION='0.0.0'

echo
if [ "$MODE" = "live" ]; then
  echo -e "${YELLOW}Production Mode${NC}"
  namespace=testapp
  release=testapp
elif [ "$MODE" = "stage" ]; then
  echo -e "${PURPLE}Stage Mode${NC}"
  namespace=testapp
  release=testapp
else
  echo -e "USAGE: ${BLUE}deploy.sh #app_version# #MODE#${NC}"
  echo -e "Version: #.#.#  Valid modes: live|stage"
  exit
fi

##################
# Validate VERSION number
##################

echo
vpattern="^[0-9]+\.[0-9]\.[0-9]"
if [[ $VERSION =~ $vpattern ]]; then
  echo -e "Application Version: ${BLUE}$VERSION${NC}"
elif [ "$VERSION" = "stage" ]; then
  echo -e "Application Version: ${BLUE}Stage${NC}"
else
  echo -e "${RED}Invalid Version number: $VERSION${NC} (Format #.#.# (eg. 1.0.5))'"
  exit 1
fi

##################
# Go to chart folder
##################

cd chart

##################
# Prepare helm package
##################

echo
echo -e "${WHITE}Build Helm Chart configuration${NC}"
echo -e "${BROWN}Chart.yaml${NC}"
chart=$(cat "Chart.tmpl")
echo -e "Set name ${BLUE}$release${NC}"
chart=$(sed -r "s/##NAME##/$release/g" <<< "$chart")
echo -e "Set app VERSION ${BLUE}$VERSION${NC}"
chart=$(sed -r "s/##APP_VERSION##/$VERSION/g" <<< "$chart")
if [ "$VERSION" = "stage" ]; then
  chart=$(sed -r "s/##HELM_VERSION##/$HELM_STAGE_VERSION/g" <<< "$chart")
else
  chart=$(sed -r "s/##HELM_VERSION##/$VERSION/g" <<< "$chart")
fi
echo "$chart" > "Chart.yaml"

echo -e "${BROWN}values.yaml${NC}"
values=$(cat "values.tmpl")
echo -e "Set host ${BLUE}${release}.esb.test-prediger.de${NC}"
values=$(sed -r "s/##HOST##/${release}.esb.test-prediger.de/g" <<< "$values")
values=$(sed -r "s/##TLSHOST##/${release}.esb.test-prediger.de/g" <<< "$values")
echo -e "Set secret name ${BLUE}${release}-esb-test-prediger-de-tls${NC}"
values=$(sed -r "s/##SECRETNAME##/${release}-esb-test-prediger-de-tls/g" <<< "$values")
values=$(sed -r "s/##CHANGE-CAUSE##/${VERSION}/g" <<< "$values")
if [ "$VERSION" = "stage" ]; then
  values=$(sed -r "s/##LOCATIONS_JSON##/stagelocations.json/g" <<< "$values")
else
  values=$(sed -r "s/##LOCATIONS_JSON##/locations.json/g" <<< "$values")
fi
echo "$values" > "values.yaml"

##################
# Build helm package
##################

echo
# remove old packages
rm -f ${release}-*.tgz
echo -e "${WHITE}Build new helm package${NC}"
pack=$(helm package .)
package=$(sed -E "s/.*(${release}-.*?\.tgz).*/\1/g" <<<$pack)
echo -e "${GREEN}$package${NC} has been prepared"

echo -e "${GREEN}Done!${NC}"
