#!/bin/bash
set -e # Abort script on errors.

# Make sure to run this script from the Backend project root working directory.

export IMAGE_TAG=southamerica-east1-docker.pkg.dev/faltometro-ufrgs/backend-image/faltometro-ufrgs-backend:latest

docker build -t $IMAGE_TAG --platform linux/amd64 -f Dockerfile .
docker push $IMAGE_TAG

gcloud run deploy backend-service \
  --project faltometro-ufrgs \
  --image $IMAGE_TAG \
  --region southamerica-east1 \
  --memory 512Mi
  
gcloud run jobs deploy update-courses \
  --project faltometro-ufrgs \
  --image $IMAGE_TAG \
  --region southamerica-east1 \
  --memory 512Mi \
  --set-env-vars=JOB=UpdateCourses

gcloud run jobs deploy update-course-options \
  --project faltometro-ufrgs \
  --image $IMAGE_TAG \
  --region southamerica-east1 \
  --memory 512Mi \
  --set-env-vars=JOB=UpdateCourseOptions
