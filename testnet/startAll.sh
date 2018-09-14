trap " kill -9 0 " SIGINT

if [ ! -e "node1/geth" ]
then 
	geth --datadir node1 init genesis.json
fi

if [ ! -e "node2/geth" ]
then 
	geth --datadir node2 init genesis.json
fi

if [ ! -e "node3/geth" ]
then 
	geth --datadir node3 init genesis.json
fi

bootnode=bootnode.key
if [ ! -e $bootnode ]
then
	echo 'generate bootnode'
	bootnode -genkey bootnode.key
fi 

bt='enode://'$(bootnode -nodekey bootnode.key -writeaddress)'@127.0.0.1:30301' 
echo $bt &
bootnode -nodekey bootnode.key &
geth --gasprice 0 --txpool.pricelimit 0 --maxpeers 25 --maxpendpeers 25 --mine --datadir node1/ --syncmode 'full' --port 30311 --rpc --rpcaddr 'localhost' \
 --rpcport 8540 --rpcapi 'personal,db,eth,net,web3,txpool,miner' --rpccorsdomain '*'  \
 --ws --wsport 8450 --wsapi="db,eth,net,web3,personal,web3" --wsorigins "*" --targetgaslimit '9000000000000' --bootnodes $bt --networkid 1515  \
  -unlock '0x3c62aa7913bc303ee4b9c07df87b556b6770e3fc' --password password.txt &
geth --gasprice 0 --txpool.pricelimit 0 --maxpeers 25 --maxpendpeers 25 --datadir node2/ --syncmode 'full'  --targetgaslimit '9000000000000' --port 30312 --rpc --rpcaddr 'localhost' \
 --rpcport 8541 --rpcapi 'all' --bootnodes  $bt\
  --networkid 1515  -unlock "0x752befae2efee656811eceeeea46a2d6d9621733" --password password.txt --mine &
geth --gasprice 0 --txpool.pricelimit 0 --maxpeers 25 --maxpendpeers 25 --datadir node3/ --targetgaslimit '9000000000000' --syncmode 'full' --port 30313 --rpc --rpcaddr 'localhost' \
 --rpcport 8542 --rpcapi 'personal,db,eth,net,web3,txpool,miner' --bootnodes $bt --networkid 1515  \
 -unlock '0x81a5c09bb2f15f4548f458b7f3b4d49080e0eb4a' --password password.txt --mine 


