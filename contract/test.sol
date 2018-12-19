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
	Task [MAX_TASK] public task;


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
		uint task_id = 0;
		//lastest_task = task_id;
		require(task_id != TASK_FULL);
		task[task_id].request = Request(data_fee, service_fee, target);
		task[task_id].owner = msg.sender;
		task[task_id].service_provider = ServiceProvider(service_provider, FALSE);
		task[task_id].busy = TRUE;
		task[task_id].stage = Stages.solicit;
		task[task_id].register_count = 0;
		task[task_id].submit_count = 0;
		//emit Solicit(data_fee, service_fee, msg.sender, service_provider, target, request_id, task_id);
	}

	function register(uint task_id, uint batch) public {
	    address provider = msg.sender;
	    if(task[task_id].register_count == batch) {
	        task[task_id].register_count = 0;
	    }
		uint lastest_id = task[task_id].register_count;
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
	}

	function submit(uint task_id,bytes data,uint id) public {

		task[task_id].data_provider[id].submited = TRUE;
		task[task_id].data_provider[id].submit_data = data;
		task[task_id].submit_count += 1;
	}

	function clean() public {
	    for(uint i=0;i<MAX_TASK;++i) {
	        delete task[i].data_provider;
	        task[i].data_provider.length = 0;
	        delete task[i].register_count;
	    }
	}

}