// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
contract Trading5 {
    address public owner;
    uint256 public ContractPrice = 0;
    uint256 public RecalculateCount;
    uint256 ci = 0;
    uint256 pi = 0;
    uint256 c = 0;
    event DicisionContractPrice(uint256 ContractPrice);
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner!");
        _;
    }
    address consumeraddress;
    address prosumeraddress;
    struct Consumer {
        address consumer;
        uint256 kwh;
        uint256 value;
        uint256 sum;
    }
    Consumer[] public consumerList;
    Prosumer[] public prosumerList;
    struct Prosumer {
        address prosumer;
        uint256 kwh;
        uint256 value;
        uint256 sum;
    }
    constructor() {
        ContractPrice = 0;
        RecalculateCount = 0;
        owner = msg.sender;
        consumeraddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        prosumeraddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }
    function Agreement() public onlyOwner returns (uint256) {
    while (ci < consumerList.length && pi < prosumerList.length) {
        if (consumerList[ci].value >= prosumerList[pi].value) {
            uint256 remainingConsumerKwh = consumerList[ci].kwh - consumerList[ci].sum;
            uint256 prosumerKwhSum = prosumerList[pi].sum;
            
            if (remainingConsumerKwh < prosumerKwhSum) {
                prosumerList[pi].sum -= remainingConsumerKwh;
                consumerList[ci].sum = consumerList[ci].kwh;
                c += 1;
                ci += 1;
            } else if (remainingConsumerKwh == prosumerKwhSum) {
                consumerList[ci].sum = consumerList[ci].kwh;
                prosumerList[pi].sum = 0;
                c += 1;
                ci += 1;
                pi += 1;
            } else {
                consumerList[ci].sum += prosumerKwhSum;
                prosumerList[pi].sum = 0;
                c += 1;
                pi += 1;
            }
        } else {
            ContractPrice = prosumerList[pi].value;
            break;
        }
    }
    emit DicisionContractPrice(ContractPrice);
    return c;
}
    function setConsumerProsumerData(uint steps) public{
    Consumer[] memory consumerresult = new Consumer[](steps);
    Prosumer[] memory prosumerresult = new Prosumer[](steps);
    uint[13] memory endpoint = [steps*3/100, steps*4/100, steps*7/100, steps*9/100, steps*10/100, steps*11/100, steps*12/100, steps*11/100, steps*10/100, steps*9/100, steps*7/100, steps*4/100,steps*3/100];
    uint8[13] memory endpointdata = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];
    uint sum = 0;
    for (uint loop=0; loop < endpointdata.length; loop++){
        for (uint idx=0; idx < endpoint[loop]; idx++) {
            Consumer memory newconsumer = Consumer(consumeraddress, 33 + uint(keccak256(abi.encodePacked(block.number, idx)))%13, endpointdata[endpoint.length - loop - 1], 0);
            consumerresult[sum + idx] = newconsumer;
        }
        sum += endpoint[loop];
    }
    sum = 0;
    for (uint loop=0; loop < endpointdata.length; loop++){
        for (uint idx=0; idx < endpoint[loop]; idx++) {
            Prosumer memory newprosumer = Prosumer(prosumeraddress, 33 + uint(keccak256(abi.encodePacked(block.number, idx)))%13, endpointdata[loop], 33 + uint(keccak256(abi.encodePacked(block.number, idx)))%13);
            prosumerresult[sum + idx] = newprosumer;
        }
        sum += endpoint[loop];
    }
    
    for (uint i = 0; i < consumerresult.length; i++) {
        consumerList.push(consumerresult[i]);
    }
    for (uint j = 0; j < prosumerresult.length; j++) {
        prosumerList.push(prosumerresult[j]);
    }
    }
}













