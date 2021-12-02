# Redirect.sh
Redirect.sh is a shell script wich I use to redirect incomming traffic to my home Server, wich has a Dynamic IP and since we cant rout iptables with a domain I wrote that script.
It Looks up the IP behind given Domain and uses the ports.ini file to create IP rules with the given port and protocoll (like TCP and UDP). You can choose different incomming and outgoing ports.

## Example of the Port.ini
| Protocol | Incomming Port | Outgoing Port | Note declared with a ```-``` |
| -------- | -------------- | ------------- | ---------------------------- |
| TCP | 1234 | 4321 | -Website |