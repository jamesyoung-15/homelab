# OpnSense Wireguard Road Warrior Setup

Most of the setup instructions are explained pretty well in the official [OpnSense doc](https://docs.opnsense.org/manual/how-tos/wireguard-client.html). Some additional notes for my setup include:

- For client config on OpnSense, do not put `0.0.0.0/0`, this will bring down other interfaces access to internet
- Since I use Unbound DNS, make sure to add the Wireguard interface that to network interfaces in Unbound settings
- Step 4(b) of creating outbound NAT rule doesn't seem to be necessary for my setup so I'll leave it for now
