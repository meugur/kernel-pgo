
GCDA=/sys/kernel/debug/gcov
if [ ! -d "$GCDA" ] ; then
  mount -t debugfs none /sys/kernel/debug
fi

if [ -e "/root/postgresql.conf" ] ; then
    cp /root/postgresql.conf /var/lib/pgsql/
    chown postgres:postgres /var/lib/pgsql/postgresql.conf
fi

if [ -e "/root/pg_hba.conf" ] ; then
    cp /root/pg_hba.conf /var/lib/pgsql/
    chown postgres:postgres /var/lib/pgsql/pg_hba.conf
fi
