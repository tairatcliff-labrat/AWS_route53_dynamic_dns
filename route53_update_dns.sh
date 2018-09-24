#!/bin/vbash
ext_ip_file=/home/{user}/ext_ip_address.txt
log_file=/home/{user}/route53_update.log
run=/opt/vyatta/bin/vyatta-op-cmd-wrapper 
hosted_zone_id={hosted zone id}
DNS_entries=(
	domain.com.au 
	dns.domain.com.au
	dns.domain.com.au
)

# Declare update_dns function

function update_dns(){                                 
  change_id=$(aws route53 change-resource-record-sets --hosted-zone-id "${hosted_zone_id}" --output text --query ChangeInfo.Id --change-batch file://<(echo "
    {                                                           
      \"Changes\": [{                                           
        \"Action\": \"UPSERT\",                                    
        \"ResourceRecordSet\": {                                   
          \"Name\": \"${1}\",                                      
          \"Type\": \"A\",                                         
          \"TTL\": 300,                                            
          \"ResourceRecords\": [{                                      
            \"Value\": \"${external_ip}\"                              
          }]                                                           
        }                                                              
      }]                                                               
    }"                                                                 
    ))
  aws route53 wait resource-record-sets-changed --id "${change_id}"    
}   


#
# Start of the script
#

set -e
  
# Get the current external IP from the router PPoE interface
external_ip_string=$($run show interfaces | grep 'ppoe')
external_ip=$(echo $external_ip_string | awk '{print $2}')

#Check file for previous IP address
if [ -f $ext_ip_file ]; then
  original_ip=$(cat $ext_ip_file)
else
  original_ip=
fi

  
# See if the IP has changed
if [ "$external_ip" != "$original_ip" ]; then
  echo $external_ip > $ext_ip_file
  
  # Call the function to update the DNS records for each record
  for dns in ${DNS_entries[@]}; do
    update_dns $dns
  done
  
  # Log the results to a file
  dt=$(date '+%d/%m/%Y %H:%M:%S');
  echo "AWS route53 DNS was updated at ${dt}" >> $log_file
  echo "The old IP address was -- ${original_ip}" >> $log_file
  echo "The new IP addres is   -- ${external_ip}" >> $log_file
  echo "----------------------------------------------------" >> $log_file
  echo "" >> $log_file
fi
