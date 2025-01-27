#!/bin/sh

if [ $# -ne 1 ]; then
  echo "entrypoint requires the handler name to be the first argument" 1>&2
  exit 142
fi

export _HANDLER="$1"

# Execute AWS Lambda runtime interface emulator or runtime API
RUNTIME_ENTRYPOINT=/var/runtime/bootstrap
if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
  echo "Running with AWS Lambda Runtime Interface Emulator"
  exec /usr/local/bin/aws-lambda-rie $RUNTIME_ENTRYPOINT
else
  echo "Running with AWS Lambda Runtime API"
  exec $RUNTIME_ENTRYPOINT
fi