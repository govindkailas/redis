#!/bin/sh
#############################################################################################################
# NAME........... portaladmin
# Project ....... Redis instace management
# AUTHOR......... Govind (govindkailas@gmail.com)
# DATE........... Fri Mar 10 11:10:39 2017
# PURPOSE........ New portaladmin script created for Redis, this will help in start,stop and bounce of
#        ........ redis and sentinel.
# HISTORY ....... Created the initial draft
#
#############################################################################################################

REDISPORT=6379
SENTINELPORT=26379
EXEC=/opt/redis/redis-3.2.8/src/redis-server
CLIEXEC=/opt/redis/redis-3.2.8/src/redis-cli
PIDFILE="/opt/redis/redis-3.2.8/redis_6379.pid"
REDIS_CONF="/opt/redis/redis-3.2.8/redis.conf"
SENTINEL_CONF="/opt/redis/redis-3.2.8/sentinel.conf --sentinel"
SENTINEL_CONF_FILE="/opt/redis/redis-3.2.8/sentinel.conf"

REDIS_PASS=$(grep auth-pass $SENTINEL_CONF_FILE|awk '{print $4}')
start_redis()
{
 if [ -f $PIDFILE ]
        then
                echo "$(date +%F-%H%M%S) :$PIDFILE exists, process is already running or crashed"
        else
                echo "$(date +%F-%H%M%S) :Starting Redis server..."
                $EXEC $REDIS_CONF
 fi
}

start_sentinel()
{
 if [ $( pgrep -f sentinel) ]
        then
                echo "$(date +%F-%H%M%S) :pid $(pgrep -f sentinel) exists, process is already running or crashed"
        else
                echo "$(date +%F-%H%M%S) :Starting Sentinel server..."
                $EXEC $SENTINEL_CONF
 fi
}


stop_redis()
{
 if [ ! -f $PIDFILE ]
        then
                echo "$(date +%F-%H%M%S) :$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "$(date +%F-%H%M%S) :Stopping ..."
                $CLIEXEC -p $REDISPORT -a $REDIS_PASS shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "$(date +%F-%H%M%S) :Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "$(date +%F-%H%M%S) :Redis stopped"
        fi
}

stop_sentinel()
{
 if [ ! $( pgrep -f sentinel) ]
        then
                echo "$(date +%F-%H%M%S) :sentinel process is not running"
        else
                PID=$(pgrep -f sentinel)
                echo "$(date +%F-%H%M%S) :Stopping ..."
                $CLIEXEC -p $SENTINELPORT -a $REDIS_PASS shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "$(date +%F-%H%M%S) :Waiting for Sentinel to shutdown ..."
                    sleep 1
                done
                echo "$(date +%F-%H%M%S) :Sentinel stopped"
        fi
}

stop()
{
if [ "${APPNAME,,}" = "redis" ]
then
        stop_redis
elif [ "${APPNAME,,}" = "sentinel" ]
then
        stop_sentinel
elif [ "${APPNAME,,}" = "all" ]
then
        stop_redis
        stop_sentinel
else
        echo "$(date +%F-%H%M%S) :Unknown application $APPNAME, existing"
        exit 1
fi

}

start()
{
if [ "${APPNAME,,}" = "redis" ]
then
        start_redis
elif [ "${APPNAME,,}" = "sentinel" ]
then
        start_sentinel
elif [ "${APPNAME,,}" = "all" ]
then
        start_redis
        start_sentinel
else
        echo "$(date +%F-%H%M%S) :Unknown application $APPNAME, existing"
        exit 1
fi

}

status()
{
        ps -ef |grep redis|grep -v grep|grep -v root
}


#########################
#Main starts from here
#########################

if [ `/usr/bin/whoami` = "redis" ] || [ `/usr/bin/whoami` = "root" ]
then
        while [ $# -gt 0 ]
        do
                case "$1" in
                        start)          ACTION=start; APPNAME="$2"; shift;;
                        stop)           ACTION=stop; APPNAME="$2"; shift;;
                        bounce)         ACTION=bounce; APPNAME="$2"; shift;;
                                                status)                 ACTION=status;;
                        *)             echo "Please use start or stop as first argument" ;;
                esac
                shift
        done

else
        echo "$(date +%F-%H%M%S) :redis script needs to run as redis only.. exiting.."
        exit 1
fi


if [ ! -z "$APPNAME" ]
then
        echo "$(date +%F-%H%M%S) :APPNAME $APPNAME passed as an argument"
else
        echo "$(date +%F-%H%M%S) :APPNAME (redis/sentinel) is not passed, defaulting to redis"
        APPNAME=redis
fi

echo "$(date +%F-%H%M%S) :Calling $ACTION of $APPNAME"
$ACTION
