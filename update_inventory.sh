export PATH=$PATH:/home/linuxbrew/.linuxbrew/bin

ips=( $(terraform output -json external_ips | jq -r '.[]') )

cp ansible/inventory_template.ini ansible/inventory.ini
sed -i \
  -e "s|EXTERNAL_IP_0|${ips[0]}|" \
  -e "s|EXTERNAL_IP_1|${ips[1]}|" \
  -e "s|EXTERNAL_IP_2|${ips[2]}|" \
  -e "s|EXTERNAL_IP_3|${ips[3]}|" \
  -e "s|EXTERNAL_IP_4|${ips[4]}|" \
  ansible/inventory.ini

echo "inventory.ini updated"
