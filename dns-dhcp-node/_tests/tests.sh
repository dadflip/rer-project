# Vérifier le DHCP (UDP 67)
sudo netstat -lunp | grep 67

# Vérifier le DNS (UDP/TCP 53)
sudo netstat -tunlp | grep ':53'


# Créer un bridge temporaire
sudo ip link add dev test-lan type bridge
sudo ip link set dev test-lan up

# Demander une IP via DHCP
sudo dhclient -v test-lan

# Libérer l’IP pour nettoyer
sudo dhclient -r test-lan

# Supprimer l’interface
sudo ip link delete dev test-lan


# Test DNS depuis le host
dig @10.10.33.1 example.com
nslookup example.com 10.10.33.1
