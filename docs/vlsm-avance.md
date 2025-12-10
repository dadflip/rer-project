| Université | Bloc initial | CIDR | #Host max | Remarques                   |
| ---------- | ------------ | ---- | --------- | --------------------------- |
| UTBM       | 10.10.0.0    | /16  | 65534     | Contient LAN, VPN, services |
| UHA        | 10.20.0.0    | /16  | 65534     | Idem                        |
| CAM        | 10.30.0.0    | /16  | 65534     | Idem                        |
| LMU        | 10.40.0.0    | /16  | 65534     | Idem                        |
| OXF        | 10.50.0.0    | /16  | 65534     | Idem                        |
| UZH        | 10.60.0.0    | /16  | 65534     | Idem                        |


| Sous-réseau    | Besoin hôtes | Masque VLSM | #Hosts max | Plage IP               | Réseau     | Broadcast    | Usage        |
| -------------- | ------------ | ----------- | ---------- | ---------------------- | ---------- | ------------ | ------------ |
| LAN principal  | 5000+        | /19         | 8190       | 10.10.0.1-10.10.31.254 | 10.10.0.0  | 10.10.31.255 | LAN interne (DNS, DHCP, Postgres, Wireguard LAN side) |
| VPN            | 50           | /26         | 62         | 10.10.32.1-10.10.32.62 | 10.10.32.0 | 10.10.32.63  | VPN site (Wireguard VPN side) |
| Réservé        | -            | /25         | 128        | 10.10.64.0-10.10.127.255 | 10.10.64.0 | 10.10.127.255 | Réservé pour expansion future |


| Université | LAN principal | VPN           | Notes |
| ---------- | ------------- | ------------- | ----- |
| UTBM       | 10.10.0.0/19  | 10.10.32.0/26 | DNS, DHCP, Postgres et Wireguard LAN sur le réseau LAN /19 |
| UHA        | 10.20.0.0/19  | 10.20.32.0/26 | Idem |
| CAM        | 10.30.0.0/19  | 10.30.32.0/26 | Idem |
| LMU        | 10.40.0.0/19  | 10.40.32.0/26 | Idem |
| OXF        | 10.50.0.0/19  | 10.50.32.0/26 | Idem |
| UZH        | 10.60.0.0/19  | 10.60.32.0/26 | Idem |

## Détail complet par université

### UTBM
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.10.0.0 | /19 | 10.10.0.1 | 10.10.31.254 | 10.10.0.1 | lan-local-utbm |
| DNS Node | 10.10.0.0 | /19 | 10.10.33.1 | 10.10.33.1 | 10.10.0.1 | lan-local-utbm |
| DHCP Node | 10.10.0.0 | /19 | 10.10.33.2 | 10.10.33.2 | 10.10.0.1 | lan-local-utbm |
| Postgres Node | 10.10.0.0 | /19 | 10.10.33.3 | 10.10.33.3 | 10.10.0.1 | lan-local-utbm |
| VPN (Wireguard) | 10.10.32.0 | /26 | 10.10.32.1 | 10.10.32.62 | 10.10.32.1 | vpn-net-utbm |
| Wireguard LAN | 10.10.0.0 | /19 | 10.10.33.4 | 10.10.33.4 | 10.10.0.1 | lan-local-utbm |

### UHA
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.20.0.0 | /19 | 10.20.0.1 | 10.20.31.254 | 10.20.0.1 | lan-local-uha |
| DNS Node | 10.20.0.0 | /19 | 10.20.33.1 | 10.20.33.1 | 10.20.0.1 | lan-local-uha |
| DHCP Node | 10.20.0.0 | /19 | 10.20.33.2 | 10.20.33.2 | 10.20.0.1 | lan-local-uha |
| Postgres Node | 10.20.0.0 | /19 | 10.20.33.3 | 10.20.33.3 | 10.20.0.1 | lan-local-uha |
| VPN (Wireguard) | 10.20.32.0 | /26 | 10.20.32.1 | 10.20.32.62 | 10.20.32.1 | vpn-net-uha |
| Wireguard LAN | 10.20.0.0 | /19 | 10.20.33.4 | 10.20.33.4 | 10.20.0.1 | lan-local-uha |

### CAM
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.30.0.0 | /19 | 10.30.0.1 | 10.30.31.254 | 10.30.0.1 | lan-local-cam |
| DNS Node | 10.30.0.0 | /19 | 10.30.33.1 | 10.30.33.1 | 10.30.0.1 | lan-local-cam |
| DHCP Node | 10.30.0.0 | /19 | 10.30.33.2 | 10.30.33.2 | 10.30.0.1 | lan-local-cam |
| Postgres Node | 10.30.0.0 | /19 | 10.30.33.3 | 10.30.33.3 | 10.30.0.1 | lan-local-cam |
| VPN (Wireguard) | 10.30.32.0 | /26 | 10.30.32.1 | 10.30.32.62 | 10.30.32.1 | vpn-net-cam |
| Wireguard LAN | 10.30.0.0 | /19 | 10.30.33.4 | 10.30.33.4 | 10.30.0.1 | lan-local-cam |

### LMU
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.40.0.0 | /19 | 10.40.0.1 | 10.40.31.254 | 10.40.0.1 | lan-local-lmu |
| DNS Node | 10.40.0.0 | /19 | 10.40.33.1 | 10.40.33.1 | 10.40.0.1 | lan-local-lmu |
| DHCP Node | 10.40.0.0 | /19 | 10.40.33.2 | 10.40.33.2 | 10.40.0.1 | lan-local-lmu |
| Postgres Node | 10.40.0.0 | /19 | 10.40.33.3 | 10.40.33.3 | 10.40.0.1 | lan-local-lmu |
| VPN (Wireguard) | 10.40.32.0 | /26 | 10.40.32.1 | 10.40.32.62 | 10.40.32.1 | vpn-net-lmu |
| Wireguard LAN | 10.40.0.0 | /19 | 10.40.33.4 | 10.40.33.4 | 10.40.0.1 | lan-local-lmu |

### OXF
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.50.0.0 | /19 | 10.50.0.1 | 10.50.31.254 | 10.50.0.1 | lan-local-oxf |
| DNS Node | 10.50.0.0 | /19 | 10.50.33.1 | 10.50.33.1 | 10.50.0.1 | lan-local-oxf |
| DHCP Node | 10.50.0.0 | /19 | 10.50.33.2 | 10.50.33.2 | 10.50.0.1 | lan-local-oxf |
| Postgres Node | 10.50.0.0 | /19 | 10.50.33.3 | 10.50.33.3 | 10.50.0.1 | lan-local-oxf |
| VPN (Wireguard) | 10.50.32.0 | /26 | 10.50.32.1 | 10.50.32.62 | 10.50.32.1 | vpn-net-oxf |
| Wireguard LAN | 10.50.0.0 | /19 | 10.50.33.4 | 10.50.33.4 | 10.50.0.1 | lan-local-oxf |

### UZH
| Composant | Réseau | Masque | Adresse min | Adresse max | Passerelle | Docker Network |
| --------- | ------ | ------ | ----------- | ----------- | ---------- | -------------- |
| LAN principal | 10.60.0.0 | /19 | 10.60.0.1 | 10.60.31.254 | 10.60.0.1 | lan-local-uzh |
| DNS Node | 10.60.0.0 | /19 | 10.60.33.1 | 10.60.33.1 | 10.60.0.1 | lan-local-uzh |
| DHCP Node | 10.60.0.0 | /19 | 10.60.33.2 | 10.60.33.2 | 10.60.0.1 | lan-local-uzh |
| Postgres Node | 10.60.0.0 | /19 | 10.60.33.3 | 10.60.33.3 | 10.60.0.1 | lan-local-uzh |
| VPN (Wireguard) | 10.60.32.0 | /26 | 10.60.32.1 | 10.60.32.62 | 10.60.32.1 | vpn-net-uzh |
| Wireguard LAN | 10.60.0.0 | /19 | 10.60.33.4 | 10.60.33.4 | 10.60.0.1 | lan-local-uzh |
