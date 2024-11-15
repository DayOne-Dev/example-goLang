clear
# TOKEN SETUP
# jf c add --user=krishnam --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

echo "\n\n**** JFCLI-GO.SH - BEGIN at $(date '+%Y-%m-%d-%H-%M') ****\n\n"

# Config - Artifactory info 
export JF_HOST="psazuse.jfrog.io"  JFROG_RT_USER="krishnam" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export JF_RT_URL="https://${JF_HOST}" RBv2_SIGNING_KEY="krishnam"

# Validate below command for the canonical version number
export RT_REPO_VIRTUAL="krishnam-go-virtual" BUILD_NAME="go-helloworld" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" VERSION="v1.$(date '+%H').0"

regex_pattern=""
if [[ "$VERSION" =~ $regex_pattern ]]; then
    echo "Canonical VERSION: $VERSION"
else
    echo "Invalid Canonical VERSION: $VERSION"
fi

# [[ "$VERSION" =~ ^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$ ]] && echo "yes"

echo "JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
echo "\n JF version $(jf -v) \n Go version $(go version) \n\n"
## Health check
jf rt ping --url=${JF_RT_URL}/artifactory

cd src

# GO: clean
# rm -rf .jfrog
jf go clean

# #init
# go mod tidy && go mod init src/go-helloworld

set -x # activate debugging from here

# GO: Config  # ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/package-managers-integration#setting-go-repositories
echo "\n\n**** PACKAGE: Config ****\n"
jf go-config --repo-deploy=$RT_REPO_VIRTUAL  --repo-resolve=$RT_REPO_VIRTUAL 

jf go list -mod=mod -m
jf go list -mod=mod -f {{with .Module}}{{.Path}}:{{.Version}}{{end}} all

# GO: build  # ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/package-managers-integration#running-go-commandss
            # go build -v ./...
echo "\n\n**** PACKAGE: Build ****\n"
jf go build --build-name=${BUILD_NAME} --build-number=${BUILD_ID} -v

# GO: Publish  # ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/package-managers-integration#publishing-go-packages-to-artifactory
echo "\n\n**** PACKAGE: Publish ****\n"
# jf go-publish v1.0.0 --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --detailed-summary 
jf rt gp v1.0.1 --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary 
jf gp $BUILD_NAME $VERSION --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary 

# GO: run
echo "\n\n**** GO: RUN ****\n"
jf go run . -v

# Build Publish
echo "\n\n**** Build Info: Publish ****\n\n"
jf rt bce ${BUILD_NAME} ${BUILD_ID}
jf rt bag ${BUILD_NAME} ${BUILD_ID}
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary

## RBv2: release bundle - create   ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/release-lifecycle-management
echo "\n\n**** RBv2: Create ****\n\n"
echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n RT_REPO_VIRTUAL: $RT_REPO_VIRTUAL  \n RBv2_SIGNING_KEY: $RBv2_SIGNING_KEY  \n "

  # create spec
export VAR_RBv2_SPEC="RBv2-SPEC-${BUILD_ID}.json"
echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"includeDeps\": \"false\" } ] }"  > $VAR_RBv2_SPEC
#echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"props\": \"build_name=${BUILD_NAME};build_id=${BUILD_ID};PACKAGE_CATEGORY=${PACKAGE_CATEGORY};state=new\" } ] }"  > RBv2-SPEC-${BUILD_ID}.json
echo "\n" && cat $VAR_RBv2_SPEC && echo "\n"

  # create RB to state=NEW
jf rbc ${BUILD_NAME} ${BUILD_ID} --sync --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RBv2_SIGNING_KEY}" --spec="${VAR_RBv2_SPEC}" --server-id="psazuse" # --spec-vars="build_name=${BUILD_NAME};build_id=${BUILD_ID};PACKAGE_CATEGORY=${PACKAGE_CATEGORY};state=new" 

## RBv2: release bundle - DEV promote
echo "\n\n**** RBv2: Promoted to NEW --> DEV ****\n\n"
jf rbp --sync --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RBv2_SIGNING_KEY}" --server-id="psazuse" ${BUILD_NAME} ${BUILD_ID} DEV  


set +x # stop debugging from here
echo "\n\n**** JFCLI-GO.SH - DONE at $(date '+%Y-%m-%d-%H-%M') ****\n\n"


sleep 3
echo "\n\n**** CLEAN UP ****\n\n"
rm -rfv $VAR_RBv2_SPEC

cd ..