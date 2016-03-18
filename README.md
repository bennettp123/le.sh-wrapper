# le.sh-wrapper
A wrapper script for letsencrypt.sh. launched letsencrypt.sh, and only prints output if an error occurs. Useful for cron, to prevent it from pestering you unless an error occurred.

Usage:

1. Create do-le.conf in the same path as do-le.sh. Don't forget to chmod go-rwx, especially if setting CF_KEY!
2. Launch do-le.sh
