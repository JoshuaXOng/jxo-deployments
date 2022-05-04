echo "0 3 * * * ./snapshot-db-volume ../balendar-4bd5baf63ecd.json balendar" > backup-db-volume-job
crontab backup-db-volume-job
rm backup-db-volume-job