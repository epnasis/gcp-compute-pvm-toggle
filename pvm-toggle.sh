#!/bin/bash
#
# This script will toggle VM instance between preemptible and on-demand 
# Author: Pawel Wenda <pwenda@google.com>
 
# ---------------------------------------------------------------------------------
# TODO: update this config with your instance information
INSTANCE='instance-test-maintainance-config'
ZONE='southamerica-west1-a'
PROJECT="$GOOGLE_CLOUD_PROJECT" # use direct value if not running in Cloud Shell
# ---------------------------------------------------------------------------------

set -e # stop on error

echo -e "\nInstance config:"
echo "Instance: $INSTANCE"
echo "Zone:     $ZONE"
echo "Project:  $PROJECT"

echo -e "\n[*] Current scheduling config"
gcloud compute instances describe $INSTANCE --zone=$ZONE --format="(scheduling)"

echo -e "\n[*] Stopping instance"
gcloud compute instances stop $INSTANCE --zone=$ZONE

IS_PREEMPTIBLE=$(gcloud compute instances describe $INSTANCE --zone=$ZONE --format="value(scheduling.preemptible)")

if [[ "$IS_PREEMPTIBLE" == "True" ]]; then
  echo -e "\n[*] Turning preemtible instance into on-demand"
  # Using API directly as I couldn't disable preemtible status using gcloud
  curl -X POST -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    https://compute.googleapis.com/compute/v1/projects/$PROJECT/zones/$ZONE/instances/$INSTANCE/setScheduling \
    -d '{ preemptible: false, automaticRestart: true, onHostMaintenance: "MIGRATE" }'
else
  echo -e "\n[*] Turning on-demand instance into preemtible"
  gcloud compute instances set-scheduling $INSTANCE --zone=$ZONE \
    --preemptible --no-restart-on-failure --maintenance-policy=TERMINATE
fi

echo -e "\n[*] New scheduling config"
gcloud compute instances describe $INSTANCE --zone=$ZONE --format="(scheduling)"

echo -e "\n[*] Starting instance"
gcloud compute instances start $INSTANCE --zone=$ZONE

echo -e "\n[*] Done."




