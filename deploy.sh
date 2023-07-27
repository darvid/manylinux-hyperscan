#!/bin/bash
tag="ghcr.io/darvid/python_hyperscan_${POLICY}_${PLATFORM}"
build_id=$(git show -s --format=%cd-%h --date=short ${COMMIT_SHA})

docker tag ${tag}:${COMMIT_SHA} ${tag}:${build_id}
docker tag ${tag}:${COMMIT_SHA} ${tag}:latest
docker push ${tag}:${build_id}
docker push ${tag}:latest
