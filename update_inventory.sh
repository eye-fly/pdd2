export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin

ips=( $(terraform output -json external_ips | jq -r '.[]') )
ips+=( $(terraform output -raw driver_ip) )

for ip in "${ips[@]}"; do
  echo "Removing old SSH key for $ip"
  ssh-keygen -R "$ip"
done

cp ansible/inventory_template.ini ansible/inventory.ini
sed -i \
  -e "s|EXTERNAL_IP_0|${ips[0]}|" \
  -e "s|EXTERNAL_IP_1|${ips[1]}|" \
  -e "s|EXTERNAL_IP_2|${ips[2]}|" \
  -e "s|EXTERNAL_IP_3|${ips[3]}|" \
  -e "s|EXTERNAL_IP_4|${ips[4]}|" \
  -e "s|DRIVER_IP|${ips[5]}|" \
  ansible/inventory.ini

#echo "inventory.ini updated"
