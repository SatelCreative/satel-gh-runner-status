#!/bin/bash
STATUSES=()
RUNNER_STATUS=()

# One call for all runners — this endpoint returns the whole list, and
# calling it per-runner multiplied API usage until the org rate limit hit.
RESPONSE=$(curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_RUNNER_TOKEN}" \
    -H "X-GitHub-Api-Version: ${GITHUB_API_VERSION}" \
    https://api.github.com/orgs/${ORG_NAME}/actions/runners)

RUNNERS=$(echo "${RESPONSE}" | jq -r '.runners')
if [ "${RUNNERS}" = "null" ]; then
    echo "GitHub API error: $(echo "${RESPONSE}" | jq -r '.message // "unexpected response"')"
    exit 1
fi

function check_status(){
    RUNNER_NAME=$1
    STATUS=$(echo "${RESPONSE}" | jq -r ".runners[] | select(.name == \"${RUNNER_NAME}\") | .status")
    echo "${RUNNER_NAME^^} IS ${STATUS^^}"

    if [ "${STATUS}" = "offline" ]; then
        RUNNER_STATUS+=("${RUNNER_NAME^^} IS ${STATUS^^},\n")
    fi

    STATUSES+=("${STATUS^^}")
}

runners=( ${RUNNER_NAMES} )
for runner in "${runners[@]}"
do
    check_status "${runner}"
done

# These outputs are used in other steps/jobs via action.yml
echo "status=${STATUSES[@]}" >> $GITHUB_OUTPUT
echo "each_runner_status=${RUNNER_STATUS[@]}" >> $GITHUB_OUTPUT
