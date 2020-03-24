#!/bin/sh
OUTPUT=`java -jar Colog/colog.jar $1 $2 $3`
echo $OUTPUT
echo $OUTPUT | grep -Fc "PROOF
COUNTER_MODEL" 
    
