pragma solidity ^0.4.21;

contract Crowdsourcing {

	enum Stages {
		solicit,
		register,
		submit,
		aggregate,
		approve,
		claim
	}

	struct Request {
		uint data_fee;
		uint service_fee;
		address service_provider;
		uint target;
		uint id;
	}

	Request public request;
	Stages public stage;
	address internal owner;
	mapping(address => uint) internal reward;
	mapping(bytes32 => mapping(address => bool)) internal register_dict;
	mapping(bytes32 => address[]) internal register_array;
	mapping(bytes32 => mapping(address => bool)) internal claim_dict;
	mapping(bytes32 => address[]) internal claim_array;
	mapping(bytes32 => mapping(address => bool)) internal submit_dict;
	mapping(bytes32 => bytes[]) internal submit_data;
	mapping(bytes32 => bytes[]) internal submit_proof;
	mapping(bytes32 => bytes) internal aggregate_aggregation;
	mapping(bytes32 => bytes) internal aggregate_share;
	mapping(bytes32 => bytes) internal aggregate_attestatino;

	event Solicit(uint data_fee, uint service_fee, address service_provider, uint target, uint request_id);
	event Register(address data_provider, uint request_id);
	event RegisterCollected(uint request_id);
	event Submit(address data_provider, bytes data, bytes proof, uint request_id);
	event SubmitCollected(uint request_id);
	event Aggregate(bytes aggregation, bytes share, bytes attestatino, uint request_id);
	event Approve(uint request_id);
	event Claim(address user, uint amount ,uint request_id);
	event ReceiveFund(uint amount, address supporter);

	constructor () public payable {
		stage = Stages.solicit;
		owner = msg.sender;
	}
	
	function () public payable {
	    emit ReceiveFund(msg.value, msg.sender);
	}

	modifier atStage (Stages _stage) {
		require(stage == _stage);
		_;
	}

	function requestHash() view public returns (bytes32) {
		return keccak256(abi.encodePacked(request.data_fee, request.service_fee, request.service_provider, request.target, request.id));
	}

	function nextStage() internal {
	    if(stage == Stages.claim) {
	        stage = Stages.solicit;
	    } else {
	        stage = Stages(uint(stage) + 1);
	    }
	}

	function solicit(uint data_fee, uint service_fee, address service_provider, uint target, uint request_id) public atStage(Stages.solicit) {
		require(address(this).balance > data_fee + service_fee);
		request.data_fee = data_fee;
		request.service_fee = service_fee;
		request.service_provider =service_provider;
		request.target = target;
		request.id = request_id;
		nextStage();
		emit Solicit(data_fee, service_fee, service_provider, target, request.id);
	} 

	function register(address data_provider) public atStage(Stages.register) {
		bytes32 request_hash = requestHash();
		require(!register_dict[request_hash][data_provider]);
		register_dict[request_hash][data_provider] = true;
		register_array[request_hash].push(data_provider);
		emit Register(data_provider, request.id);
		if(register_array[request_hash].length == request.target) {
			nextStage();
			emit RegisterCollected(request.id);
		}
	}

	function submit(address data_provider, bytes data, bytes proof) public atStage(Stages.submit) {
		bytes32 request_hash = requestHash();
		require(register_dict[request_hash][data_provider]);
		require(!submit_dict[request_hash][data_provider]);
		submit_dict[request_hash][data_provider] = true;
		submit_data[request_hash].push(data);
		submit_proof[request_hash].push(proof);
		emit Submit(data_provider, data, proof, request.id);
		if(submit_data[request_hash].length == request.target){
			nextStage();
			emit SubmitCollected(request.id);
		}
	}

	function aggregate(bytes aggregation, bytes share, bytes attestatino) public atStage(Stages.aggregate) {
		bytes32 request_hash = requestHash();
		aggregate_aggregation[request_hash] = aggregation;
		aggregate_share[request_hash] = share;
		aggregate_attestatino[request_hash] = attestatino;
		nextStage();
		emit Aggregate(aggregation, share, attestatino, request.id);
	}

	function approve() public atStage(Stages.approve) {
		nextStage();
		emit Approve(request.id);
	}

	function claim(address user) public atStage(Stages.claim) {
		bytes32 request_hash = requestHash();
		require(submit_dict[request_hash][user] || user == request.service_provider);
		require(!claim_dict[request_hash][user]);
		claim_dict[request_hash][user] = true;
		claim_array[request_hash].push(user);
		if(claim_array[request_hash].length == request.target + 1 ) {  // number of data_provider + service_provider
			nextStage();
		}
		if (user == request.service_provider) {
			address(user).transfer(request.service_fee);
			emit Claim(user, request.service_fee, request.id);
		} else {
			address(user).transfer(request.data_fee/request.target);
			emit Claim(user, request.data_fee/request.target, request.id);
		}
	}

	function getRequest() public view returns(uint , uint , address , uint , uint ) {
		return (request.data_fee, request.service_fee, request.service_provider, request.target, request.id);
	}

	function getStage() public view returns(uint) {
		return uint(stage);
	}

	function getOwner() public view returns(address) {
		return owner;
	}

	function isRegistered(address user) public view returns (bool) {
		bytes32 request_hash = requestHash();
		return register_dict[request_hash][user];
	}

	function isClaimed(address user) public view returns (bool) {
		bytes32 request_hash = requestHash();
		return claim_dict[request_hash][user];
	}

	function isSubmit(address user) public view returns (bool) {
		bytes32 request_hash = requestHash();
		return submit_dict[request_hash][user];
	}

	function getSumbit(uint index) public view returns (bytes, bytes) {
	    bytes32 request_hash = requestHash();
	    require(index < submit_data[request_hash].length);
		return (submit_data[request_hash][index],submit_proof[request_hash][index]);
	}

	function getAggregate() public view returns (bytes, bytes, bytes) {
		bytes32 request_hash = requestHash();
		return (aggregate_aggregation[request_hash],aggregate_share[request_hash],aggregate_attestatino[request_hash]);
	}
}