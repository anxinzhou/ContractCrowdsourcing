const Web3 = require('web3');
const productionMode = "p_";
const testMode = "t_";

const mode = "p_"; //production
var config;
if (mode === productionMode) {
    config = require('./etc/productionConfig');
} else if(mode === testMode) {
    config = require('./etc/contractConfig');
} else {
    console.log("please specify right mode");
    process.exit(-1);
}
const abi = require('./etc/abi.json');

const web3 = new Web3(new Web3.providers.HttpProvider(config.url));
const contract = new web3.eth.Contract(abi, config.address);
const owner = config.owner;
const sendOptions = {
    from: owner,
    gas: config.gas,
    gasPrice: config.gasPrice
};

function receiptHandler(receipt) {
    return new Promise((resolve,reject)=>{
        if (receipt.status === '0x0') {
            reject(new Error("public pay transaction revert"))
        } else {
            resolve()
        }
    });
}


const solicit = (...args) => {
    return contract.methods.solicit(...args)
        .send(sendOptions)
        .then(receiptHandler);
};

const register = (...args) => {
    return contract.methods.register(...args)
        .send(sendOptions)
        .then(receiptHandler)
};

const submit = (...args) => {
    return contract.methods.submit(...args)
        .send(sendOptions)
        .then(receiptHandler)
};

const clean = () => {
    return contract.methods.clean()
        .send(sendOptions)
        .then(receiptHandler)
};

module.exports = {
    solicit: solicit,
    register: register,
    submit: submit,
    clean: clean,
    mode: mode
};