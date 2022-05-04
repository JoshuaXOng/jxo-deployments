echo "0 3 * * * /root/jxo-deployments/ops/balendar/snapshot-db-volume.sh /root/balendar-4bd5baf63ecd.json balendar-bucket-main" > backup-db-volume-job
crontab backup-db-volume-job
rm backup-db-volume-job