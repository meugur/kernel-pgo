
GCDA=/sys/kernel/debug/gcov
if [ ! -d "$GCDA" ] ; then
  mount -t debugfs none /sys/kernel/debug
fi

