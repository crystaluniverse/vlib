# Mycelium example

## Requirements

A mycelium container image which can be built using the [mycelium vbuilder](https://github.com/threefoldtech/vbuilders/tree/development/builders/core/mycelium).

## created Containers

- mycelium_1
  - Public key: 7a91a3c193e94eb0fd2918eb189dc0b0180510fd8a90f934e7ff5d97f975f244
  - Address: 233:3180:f2f9:d40b:62ce:eeb9:9357:d95b
- mycelium_2
  - Public key: 380e9c1eba6ec52f6e8200ed82d4de0fd3847c1f686f9b8ed246b52b9e049f38
  - Address: 2d9:b4ab:7811:d556:7642:b3e5:697e:6748
- mycelium_3
  - Public key: b7e278078cf99f607a3951da83c0dc190ba435ed4205680bb6c3a026300bc472
  - Address: 310:5061:724c:6964:5873:2bf1:4dfb:2703

## start the containers

```sh
v run mycelium.v
```

## test the connection

open a shell in the mycelium_3 container:

```sh
docker exec -it mycelium_3 bash
```

ping container 2 over mycelium:

```sh
ping 2d9:b4ab:7811:d556:7642:b3e5:697e:6748 
```
