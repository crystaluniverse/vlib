

- mycelium node has pub & priv key
- need ability to go from mycelium node to ed25519 priv/pub key, only on the node where the mycelium node is, the owner
- need ability to ask to remote node where we know the ip addr from what their ed25519 pub key is (ofcourse never the private key)
- example how to convert the ed25519 priv/pub as we get from mycelium node to ed25519 keypair in V

why

- the owner will use the priv key, to get his V based ed25519 priv/pub 
- the owner talks to other digital twins by knowing the IP addr (or pub key?)
- it can ask other twin what their pub key is, would be nice we can verify the ipv6 vs pub addr, so we know for sure that we are not being tricked, so in other words ipv6/pub combination cannot be faked

