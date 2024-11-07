clear
# TOKEN SETUP
# jf c add --user=krishnam --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

echo "\n\n**** JFCLI-GO.SH - BEGIN at $(date '+%Y-%m-%d-%H-%M') ****\n\n"

# Config - Artifactory info
export JF_HOST="psazuse.jfrog.io"  JFROG_RT_USER="krishnam" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export JF_RT_URL="https://${JF_HOST}"

export RT_REPO_VIRTUAL="krishnam-go-virtual" BUILD_NAME="hello" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" VERSION="v$(date '+%d.%H.%M')"

echo "JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
echo "\n JF version $(jf -v) \n Go version $(go version) \n\n"
## Health check
jf rt ping --url=${JF_RT_URL}/artifactory

# GO: clean
# rm -rf .jfrog
jf go clean

# #init
# go mod tidy && go mod init hello

set -x # activate debugging from here

# GO: Config
echo "\n\n**** PACKAGE: Config ****\n"
jf go-config --repo-deploy=$RT_REPO_VIRTUAL  --repo-resolve=$RT_REPO_VIRTUAL 

jf go list -mod=mod -m

# GO: build
echo "\n\n**** PACKAGE: Build ****\n"
jf go build --build-name=${BUILD_NAME} --build-number=${BUILD_ID} -v

# GO: Publish
echo "\n\n**** PACKAGE: Publish ****\n"
jf go-publish v1.0.0 --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary 

# GO: run
echo "\n\n**** GO: RUN ****\n"
jf go run . -v

# Build Publish
echo "\n\n**** Build Info: Publish ****\n\n"
jf rt bce ${BUILD_NAME} ${BUILD_ID}
jf rt bag ${BUILD_NAME} ${BUILD_ID}
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary




set +x # stop debugging from here
echo "\n\n**** JFCLI-GO.SH - DONE at $(date '+%Y-%m-%d-%H-%M') ****\n\n"