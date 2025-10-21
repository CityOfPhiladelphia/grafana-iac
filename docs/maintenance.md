# Maintenance

## OS Updates

Downtime: While there could be future optimization to reduce this, currently OS updates cause about 8 minutes of downtime. However, once Grafana is back up, servers will backfill all the missing metrics.

1. Disable Betterstack Alarms
    1. Navigate to Betterstack -> Integrations
    1. For each integration under Grafana, click the three dots and pause them
1. Update AMI in launch template through Github actions
    1. The automatic AMI updater runs monthly. If you need to force it, go to Github repository -> Actions -> Update AMI -> Run Workflow. This will create a pull request with the latest AMI (if it is newer than the current one)
    1. Check pull request, especially the Terraform plan, for validity
    1. Merge the pull request, then wait for the Terraform apply job to run
    1. *Note* This will not actually update or replace any servers, it just means the next server launched will have the newer AMI.
1. SSH onto the old server and stop all docker containers
1. Launch new server
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 2.
1. SSH onto the new server and make sure things looks good
    1. Check `docker ps`
1. Verify Grafana is working
    1. Go to [https://citygeo-grafana.phila.gov/](https://citygeo-grafana.phila.gov/)
1. Terminate the old server
    1. Navigate to AWS web console -> EC2 -> Autoscaling
    1. Set the desired, minimum, and maximum capacity to 1
1. Re-enable Betterstack Alarms
    1. Navigate to Betterstack -> Integrations
    1. For each integration under Grafana, click the three dots and unpause them

## Application Updates

To-do

## DB Maintenance

### OS Upgrades

Are handled automatically by AWS RDS

### Postgres Upgrades

Both Postgres minor and major upgrades result in some downtime, but minor upgrades are very brief, so they are performed automatically.

Major upgrades should be held off until either:

* Grafana states that it supports the new major version
* The current major version is reaching EOL and we have to upgrade

#### Major upgrade process

To-do
