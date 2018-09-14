pragma solidity ^0.4.21;

contract Crowdsourcing {

	enum Stages {
		solicit,
		register,
		submit,
		aggregate,
		approve,
		claim,
		finish
	}

	struct Request {
		uint data_fee;
		uint service_fee;
		address service_provider;
		uint target;
		uint id;
		address owner;
	}

	struct Task {
		bytes32  task_id;
		Request  request;
		Stages  stage;
		address  owner;
		mapping(address => bool)  register_dict;
		address []  register_array;
		mapping(address => bool)  claim_dict;
		address []  claim_array;
		mapping(address => bool)  submit_dict;
		bytes[]  submit_data;
		bytes[]  submit_proof;
		bytes  aggregate_aggregation;
		bytes  aggregate_share;
		bytes  aggregate_attestatino;
	}	
	mapping(bytes32 => Task) task;

	event Solicit(uint data_fee, uint service_fee, address owner, address service_provider, uint target, uint request_id, bytes32 task_id);
	event Register(address data_provider, bytes32 task_id);
	event RegisterCollected(bytes32 task_id);
	event Submit(address data_provider,  bytes32 task_id);
	event SubmitCollected(bytes32 task_id);
	event Aggregate(bytes32 task_id);
	event Approve(bytes32 task_id);
	event Claim(address user, uint amount ,bytes32 task_id);
	event ReceiveFund(uint amount, address supporter);

	constructor () public payable {
		
	}
	
	function () public payable {
	    emit ReceiveFund(msg.value, msg.sender);
	}

	function atStage (bytes32 task_id, Stages _stage) internal view returns (bool) {
		if(task[task_id].stage == _stage){
			return true;
		} else {
			return false;
		}
	}

	function nextStage(bytes32 task_id) internal {
	    task[task_id].stage = Stages(uint(task[task_id].stage) + 1);
	}

	function solicit(uint data_fee, uint service_fee, address service_provider, uint target, uint request_id) public {
		require(address(this).balance > data_fee + service_fee);
		bytes32 task_id = keccak256(abi.encodePacked(data_fee, service_fee, service_provider, target,request_id));
		require(atStage(task_id, Stages.solicit));
		task[task_id].request.owner = msg.sender;
		task[task_id].request.data_fee = data_fee;
		task[task_id].request.service_fee = service_fee;
		task[task_id].request.service_provider =service_provider;
		task[task_id].request.target = target;
		task[task_id].request.id = request_id;
		task[task_id].task_id = task_id;
		nextStage(task_id);
		emit Solicit(data_fee, service_fee, msg.sender, service_provider, target, request_id, task_id);
	} 

	function register(bytes32 task_id) public {
		require(atStage(task_id, Stages.register));
		address data_provider = msg.sender;
		require(!task[task_id].register_dict[data_provider]);
		task[task_id].register_dict[data_provider] = true;
		task[task_id].register_array.push(data_provider);
		emit Register(data_provider, task_id);
		if(task[task_id].register_array.length == task[task_id].request.target) {
			nextStage(task_id);
			emit RegisterCollected(task_id);
		}
	}

	function submit(bytes32 task_id, bytes data, bytes proof) public {
		require(atStage(task_id, Stages.submit));
		address data_provider = msg.sender;
		require(task[task_id].register_dict[data_provider]);
		require(!task[task_id].submit_dict[data_provider]);
		task[task_id].submit_dict[data_provider] = true;
		task[task_id].submit_data.push(data);
		task[task_id].submit_proof.push(proof);
		emit Submit(data_provider, task_id);
		if(task[task_id].submit_data.length == task[task_id].request.target){
			nextStage(task_id);
			emit SubmitCollected(task_id);
		}
	}

	function aggregate(bytes32 task_id, bytes aggregation, bytes share, bytes attestatino) public {
	    require(atStage(task_id, Stages.aggregate));
	   	require(task[task_id].request.service_provider == msg.sender);
		task[task_id].aggregate_aggregation = aggregation;
		task[task_id].aggregate_share = share;
		task[task_id].aggregate_attestatino = attestatino;
		nextStage(task_id);
		emit Aggregate(task_id);
	}

	function approve(bytes32 task_id) public {
	    require(atStage(task_id, Stages.approve));
	    require(task[task_id].request.owner == msg.sender);
		nextStage(task_id);
		emit Approve(task_id);
	}

	function claim(bytes32 task_id) public {
		require(atStage(task_id, Stages.claim));
	    address user = msg.sender;
		require(task[task_id].submit_dict[user] || user == task[task_id].request.service_provider);
		require(!task[task_id].claim_dict[user]);
		task[task_id].claim_dict[user] = true;
		task[task_id].claim_array.push(user);
		if(task[task_id].claim_array.length == task[task_id].request.target + 1 ) {  // number of data_provider + service_provider
			nextStage(task_id);
		}
		if (user == task[task_id].request.service_provider) {
			address(user).transfer(task[task_id].request.service_fee);
			emit Claim(user, task[task_id].request.service_fee, task_id);
		} else {
			address(user).transfer(task[task_id].request.data_fee/task[task_id].request.target);
			emit Claim(user, task[task_id].request.data_fee/task[task_id].request.target, task_id);
		}
	}

	function getRequest(bytes32 task_id) public view returns(uint , uint , address , uint , uint ) {
		return (task[task_id].request.data_fee, task[task_id].request.service_fee, task[task_id].request.service_provider, task[task_id].request.target, task[task_id].request.id);
	}

	function getStage(bytes32 task_id) public view returns(uint) {
		return uint(task[task_id].stage);
	}

	function getOwner(bytes32 task_id) public view returns(address) {
		return task[task_id].owner;
	}

	function isRegistered(bytes32 task_id, address user) public view returns (bool) {
		return task[task_id].register_dict[user];
	}

	function isClaimed(bytes32 task_id, address user) public view returns (bool) {
		return task[task_id].claim_dict[user];
	}

	function isSubmit(bytes32 task_id, address user) public view returns (bool) {
		return task[task_id].submit_dict[user];
	}

	function getSumbit(bytes32 task_id, uint index) public view returns (bytes, bytes) {
	    require(index < task[task_id].submit_data.length);
		return (task[task_id].submit_data[index],task[task_id].submit_proof[index]);
	}

	function getAggregate(bytes32 task_id) public view returns (bytes, bytes, bytes) {
		return (task[task_id].aggregate_aggregation, task[task_id].aggregate_share, task[task_id].aggregate_attestatino);
	}
}