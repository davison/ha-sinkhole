#!/bin/bash

# Query the CoreDNS health endpoint
if curl -fsS -o /dev/null "http://127.0.0.1:8080/health"; then
  exit 0
else
  exit 1
fi
