#!/bin/bash

thisdir=`dirname $0`
sites="antrum"

if [ -z $PHANTOM_EPU_RABBIT_HOST ]; then
    echo "Please setup the environment"
    exit 1
fi

for site in $sites
do
    cmd="ceictl -b $PHANTOM_EPU_RABBIT_HOST -x $EXCHANGE_SCOPE -u $RABBITMQ_USERNAME -p $RABBITMQ_PASSWORD site add $site --definition $thisdir/$site.yml"
    echo $cmd
    $cmd
done

ceictl -b $PHANTOM_EPU_RABBIT_HOST -x $EXCHANGE_SCOPE -u $RABBITMQ_USERNAME -p $RABBITMQ_PASSWORD site list
