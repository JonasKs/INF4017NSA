#!/bin/bash
#Color for readability
default='\e[39m'
green='\e[32m'
red='\e[31m'
yellow='\e[33m'
#Start the MLN-file
echo "global {
	project backbone
}
superclass common {
	openstack {
		image Ubuntu14.04
		flavor m1.medium
	}
	network eth0 {
	net nsa_master_net
	address dhcp
	}
}" > mlntest.mln

#Ask the user what he wants to name the hosts, put it to variable $host1
echo -e "Enter hostname on the first ${yellow}storage server${default}."
read storage1
echo -e "Enter the hostname on the second ${yellow}storage server${default}"
read storage2
echo -e "Enter the hostname on the first ${yellow}developer server${default}"
read dev1
echo -e "Enter the hostname on the second ${yellow}developer server${default}"
read dev2
echo -e "Enter the hostname on the first ${yellow}compile server${default}"
read comp1
echo -e "Enter the hostname on the second ${yellow}compile server${default}"
read comp2
#Adding input to an array
inputarray=("storage-$storage1" "storage-$storage2" "dev-$dev1" "dev-$dev2" "comp-$comp1" "comp-$comp2")

#Loop through array and generate the hosts in the above created mlntest.mln
for i in "${inputarray[@]}"
do
  echo -e "host $i {
  	superclass common
  	openstack {
  		user_data {
  		echo "10.1.5.243 master.openstacklocal master" >> /etc/hosts
  		wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
  		dpkg -i puppetlabs-release-trusty.deb
  		apt-get update
  		apt-get install -y puppet augeas-tools
  		mkdir /home/ubuntu/tmp
  		wget https://128.39.121.37/mln/ssh_keys.pp -P /home/ubuntu/tmp/ --no-check-certificate
  		wget https://128.39.121.37/mln/puppet_agent.pp -P /home/ubuntu/tmp/ --no-check-certificate
  		chmod +x /home/ubuntu/tmp/ssh_keys.pp
  		chmod +x /home/ubuntu/tmp/puppet_agent.pp
  		puppet apply /home/ubuntu/tmp/ssh_keys.pp
  		puppet apply /home/ubuntu/tmp/puppet_agent.pp
			service rsyslog restart
  		}
  	}
  }" >> mlntest.mln
done

#Check if VM with the same name exists in openstack. If they are, delete old VM's in openstack.
echo "Just making sure there is no similar VM already running.."
source /home/ubuntu/.openstack
for i in "${inputarray[@]}"
do
  if nova list | awk '{print$4}' | grep -q $i.backbone ; then
    nova force-delete $i.backbone &>/dev/null
    echo -e "${red} $i already exists in openstack. Deleting it.${default}"
  else
    echo -e "${green} $i does not exists. No reason to delete.${default}"
  fi
done

echo -e "Checking for foreman duplicates"
#Remove foreman hosts if they already exists
for i in "${inputarray[@]}"
do
  if curl -v --silent -k -u admin:PASSWORD -H "Accept:application/json" https://localhost/api/hosts/$i.openstacklocal 2>&1 | grep "Resource host not found" ; then
    echo -e "${green} $i.openstacklocal does not exist in foreman hosts. No reason to delete.${default}"
  else
    curl -k -u admin:PASSWORD -X DELETE -H "Accept:application/json" https://localhost/api/hosts/$i.openstacklocal &>/dev/null
		echo -e "${red} $i.openstaclocal exist in foreman hosts. Deleting duplicates.${default}"
  fi
done

#Build the mln project
echo "Building project."
sudo mln build -f mlntest.mln -r &>/dev/null
echo -e "${green}The Project has been built!${default}"
#Start the project with mln
sudo mln start -p backbone
echo -e "While we wait for the machines to spawn, we'll clean out any certificates matching our new clients."
for i in "${inputarray[@]}"
do
  sudo puppet cert clean $i.openstacklocal &>/dev/null
done
echo -e "${green}Certificates has now been cleaned.${default}"
#Wait for the services to spawn before we move on.
echo "Now we have to wait for the servers to spawn and install the first needed files."
for i in `seq 1 180`
do
	sleep 1
	echo -ne '\e[33m #####'$((180 - $i))' seconds left##### \r'
done
echo -ne '\n'
echo -e "${green}Thats done!${default}"
echo "Adding all the certificates."
#sign the certificates
for i in "${inputarray[@]}"
do
  sudo puppet cert sign $i.openstacklocal
done
echo -e "${green}Certificates added${default}
