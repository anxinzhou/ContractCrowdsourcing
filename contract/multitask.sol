pragma solidity ^0.4.21;

contract Crowdsourcing {

	uint constant public MAX_TASK = 1;
	uint constant internal TASK_FULL = 10;
	uint constant internal FALSE = 1;
	uint constant internal TRUE = 2;

	enum Stages {
		inital,
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
		uint target;
	}


    struct DataProvider {
    	address account;
    	uint registered;
    	uint submited;
    	uint claimed;
    	bytes submit_data;
    }

    struct ServiceProvider {
    	address account;
    	uint claimed;
    }

    struct Aggregation {
    	bytes aggregation;
    	bytes share;
    	bytes attestatino;
    }

	struct Task {
		Request  request;
		Stages  stage;
		address  owner;
		ServiceProvider service_provider;
		DataProvider [] data_provider;
		mapping(address => uint) data_provider_id;
		Aggregation aggregate;
		uint busy;
		uint register_count;
		uint submit_count;
		uint claim_count;
	}	
    
    uint public lastest_task;
    //Stages public lastest_stage = Stages.solicit;
	Task [MAX_TASK] internal task;

    
	// event Solicit(uint data_fee, uint service_fee, address owner, address service_provider, uint target, uint request_id, bytes32 task_id);
	// event Register(address data_provider, bytes32 task_id);
	// event RegisterCollected(bytes32 task_id);
	// event Submit(address data_provider,  bytes32 task_id);
	// event SubmitCollected(bytes32 task_id);
	// event Aggregate(bytes32 task_id);
	// event Approve(bytes32 task_id);
	// event Claim(address user, uint amount ,bytes32 task_id);
	// event ReceiveFund(uint amount, address supporter);

	constructor () public payable {
		
	}
	
	function () public payable {
	    //emit ReceiveFund(msg.value, msg.sender);
	}

	function getEmptyTaskSlot () internal view returns (uint) {
		for(uint i = 0; i< MAX_TASK ; ++i) {
			if (task[i].busy == FALSE || task[i].busy == 0){
				return i;
			}
		}
		//not found
		return TASK_FULL;
	}

	function atStage (uint task_id, Stages _stage) internal view returns (bool) {
		if(task[task_id].stage == _stage){
			return true;
		} else {
			return false;
		}
	}

	function nextStage(uint task_id) internal {
		if (task[task_id].stage == Stages.claim) {
			task[task_id].stage = Stages.solicit;
		} else {
	    	task[task_id].stage = Stages(uint(task[task_id].stage) + 1);
		}
		//lastest_stage = task[task_id].stage;
	}

	function solicit(uint data_fee, uint service_fee, address service_provider, uint target) public {
		require(address(this).balance > data_fee + service_fee);
		uint task_id = getEmptyTaskSlot();
		//lastest_task = task_id;
		require(task_id != TASK_FULL);
		task[task_id].request = Request(data_fee, service_fee, target);
		task[task_id].owner = msg.sender;
		task[task_id].service_provider = ServiceProvider(service_provider, FALSE);
		task[task_id].busy = TRUE;
		task[task_id].stage = Stages.solicit;
		task[task_id].register_count = 0;
		nextStage(task_id);
		//emit Solicit(data_fee, service_fee, msg.sender, service_provider, target, request_id, task_id);
	}
    
	function register(uint task_id) public {
		require(atStage(task_id, Stages.register));
		address provider = msg.sender;
		uint id = task[task_id].data_provider_id[provider];
		uint lastest_id = task[task_id].register_count;
		require(id == 0 || id > lastest_id || task[task_id].data_provider[id-1].account != provider);
		if (task[task_id].data_provider.length == lastest_id) {
		    task[task_id].data_provider.push(DataProvider(provider,TRUE,FALSE,FALSE,"0x1"));
		} else{
		    task[task_id].data_provider[lastest_id].account = provider;
		    task[task_id].data_provider[lastest_id].registered = TRUE;
		    task[task_id].data_provider[lastest_id].submited = FALSE;
		    task[task_id].data_provider[lastest_id].claimed = FALSE;
		}
		task[task_id].data_provider_id[provider] = lastest_id + 1;
		task[task_id].register_count += 1;
		//emit Register(data_provider, task_id);
		if(task[task_id].register_count == task[task_id].request.target) {
			nextStage(task_id);
			task[task_id].submit_count = 0;
			//emit RegisterCollected(task_id);
		}
	}
    
	function submit(uint task_id, bytes data) public {
		require(atStage(task_id, Stages.submit));
		address provider = msg.sender;
		uint id = task[task_id].data_provider_id[provider];
		require (!(id> task[task_id].register_count || id ==0));
		require (task[task_id].data_provider[id-1].submited == FALSE);
 
		
		task[task_id].data_provider[id-1].submited = TRUE;
		task[task_id].data_provider[id-1].submit_data = data;
		task[task_id].submit_count += 1;
		//emit Submit(data_provider, task_id);
		if(task[task_id].submit_count == task[task_id].request.target){
			task[task_id].claim_count = 0;
			nextStage(task_id);
			//emit SubmitCollected(task_id);
		}
	}

	function aggregate(uint task_id, bytes aggregation, bytes share, bytes attestatino) public {
	    require(atStage(task_id, Stages.aggregate));
	   	require(task[task_id].service_provider.account == msg.sender);
	   	task[task_id].aggregate.aggregation = aggregation;
	   	task[task_id].aggregate.share = share;
	   	task[task_id].aggregate.attestatino = attestatino;
		nextStage(task_id);
		//emit Aggregate(task_id);
	}

	function approve(uint task_id) public {
	    require(atStage(task_id, Stages.approve));
	    require(task[task_id].owner == msg.sender);
		nextStage(task_id);
		//emit Approve(task_id);
	}

	function claim(uint task_id) public {
		require(atStage(task_id, Stages.claim));
	    address user = msg.sender;
	    uint id = task[task_id].data_provider_id[user];
	    bool is_data_provider = !(id> task[task_id].register_count || id == 0) && task[task_id].data_provider[id-1].claimed == FALSE;
	    bool is_service_provider = ( user == task[task_id].service_provider.account && task[task_id].service_provider.claimed==FALSE);
	    require (is_data_provider || is_service_provider);
		if (is_service_provider) {
			address(user).transfer(task[task_id].request.service_fee);
			task[task_id].service_provider.claimed = TRUE;
			task[task_id].claim_count +=1;
			//emit Claim(user, task[task_id].request.service_fee, task_id);
		}
		if (is_data_provider){
			uint reward = task[task_id].request.data_fee/task[task_id].request.target;
			address(user).transfer(reward);
			task[task_id].data_provider[id-1].claimed = TRUE;
			task[task_id].claim_count +=1;
			//emit Claim(user, reward, task_id);
		}
		if(task[task_id].claim_count == task[task_id].request.target + 1 ) {  // number of data_provider + service_provider
			task[task_id].busy = FALSE;
		}
	}

}