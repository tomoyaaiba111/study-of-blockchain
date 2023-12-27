// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
contract Trading6 {
    address public owner;
    uint256 public ContractPrice = 0;
    uint256 public RecalculateCount;
    uint256 ci = 0;                 // consumerListCount                    
    uint256 pi = 0;                 // prosumerListCount                          
    uint256 ti = 1;                 // timeCount (初期値 = 1 )                        
    uint256 public tradeCount = 0;  // dealCount

    event DicisionContractPrice(uint256 ContractPrice);
    modifier onlyOwner() {
        require(owner == msg.sender, "only owner!");
        _;
    }
    address consumeraddress;
    address prosumeraddress;
    struct Consumer {
        address consumer;           // consumerのHash値
        uint256 kwh;                // consumerが欲しい電力量
        uint256 time;               // consumerが板に登録した時刻
        uint256 value;              // consumerが購入する金額
        uint256 sum;                // consumerが保有する電力量
        bool traded;                // 取引済みかのフラグ 
    }
    mapping(address => uint) public confirmConsumer;
    Consumer[] public consumerList;
    Prosumer[] public prosumerList;
    struct Prosumer {
        address prosumer;
        uint256 kwh;
        uint256 time;
        uint256 value;
        uint256 sum;
        bool traded;                 
    }
    mapping(address => uint) public confirmProsumer;
    constructor() {
        ContractPrice = 0;
        RecalculateCount = 0;
        owner = msg.sender;
        consumeraddress = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        prosumeraddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }
    //Consumer Addition
    function pushConsumer(address consumer, uint256 kwh, uint256 time, uint256 value) public returns (uint256) {
        consumerList.push(Consumer(consumer, kwh, time, value, 0, false));
        uint256 index = consumerList.length - 1;
        confirmConsumer[consumer] = index;
        return index;
    }
    //Prosumer Addition
    function pushProsumer(address prosumer, uint256 kwh, uint256 time, uint256 value) public returns (uint256) {
        prosumerList.push(Prosumer(prosumer, kwh, time, value, kwh, false));
        uint256 index = prosumerList.length - 1;
        confirmProsumer[prosumer] = index;
        return index;
    }
    /////////////////////////////////////////////////
    //Consumer Counting-sort by time
    function countingSortConsumers() public {
        // 配列の初期化
        uint256 maxTime = 60;
        uint256[] memory count = new uint256[](maxTime + 1);
        Consumer[] memory sorted = new Consumer[](consumerList.length);
        // 各timeの出現回数カウント
        for (uint i = 0; i < consumerList.length; i++) {
            count[consumerList[i].time]++;
        }
        // 累積カウント計算
        for (uint i = 1; i <= maxTime; i++) {
            count[i] += count[i - 1];
        }
        // 元配列を使用して、ソートされた配列構築
        for (int i = int(consumerList.length) - 1; i >= 0; i--) {
            Consumer storage consumer = consumerList[uint(i)];
            sorted[count[consumer.time] - 1] = consumer;
            count[consumer.time]--;
        }
        // ソートしたデータを元配列にコピー
        for (uint i = 0; i < consumerList.length; i++) {
            consumerList[i] = sorted[i];
        }
    }

    // Prosumer Counting-sort by time
    function countingSortProsumers() public {
        uint256 maxTime = 60;
        uint256[] memory count = new uint256[](maxTime + 1);
        Prosumer[] memory sorted = new Prosumer[](prosumerList.length);

        for (uint i = 0; i < prosumerList.length; i++) {
            count[prosumerList[i].time]++;
        }
        for (uint i = 1; i <= maxTime; i++) {
            count[i] += count[i - 1];
        }
        for (int i = int(prosumerList.length) - 1; i >= 0; i--) {
            Prosumer storage prosumer = prosumerList[uint(i)];
            sorted[count[prosumer.time] - 1] = prosumer;
            count[prosumer.time]--;
        }
        for (uint i = 0; i < prosumerList.length; i++) {
            prosumerList[i] = sorted[i];
        }
    }

    //binary-search
    function findStartIndex(Consumer[] storage list, uint256 time) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = list.length;
            while (low < high) {
                uint256 mid = low + (high - low) / 2;
                if (list[mid].time < time) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        return low;
    }
    function findStartIndex(Prosumer[] storage list, uint256 time) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = list.length;
            while (low < high) {
                uint256 mid = low + (high - low) / 2;
                if (list[mid].time < time) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        return low;
    }
    ///////////////////////////////////////////////////
    //Agreement by Zaraba-trade
    function Agreement() public onlyOwner returns (uint256) {
        require(prosumerList.length > 0 && consumerList.length > 0, "Lists cannot be empty!");

        while (ti <= 60) {
            uint256 consumerStart = findStartIndex(consumerList, ti);
            uint256 prosumerStart = findStartIndex(prosumerList, ti);

            for (uint256 i = consumerStart; i < consumerList.length && consumerList[i].time == ti; i++) {
                Consumer storage consumer = consumerList[i];
                if (consumer.traded || consumer.kwh == 0) continue;

                for (uint256 j = prosumerStart; j < prosumerList.length && prosumerList[j].time == ti; j++) {
                    Prosumer storage prosumer = prosumerList[j];
                    if (prosumer.traded || prosumer.sum == 0) continue;

                    if (prosumer.value <= consumer.value) {
                        uint256 tradeVolume = consumer.kwh < prosumer.sum ? consumer.kwh : prosumer.sum;
                        consumer.kwh -= tradeVolume;
                        consumer.sum += tradeVolume;
                        prosumer.sum -= tradeVolume;
                        tradeCount++;

                        if (consumer.kwh == 0) {
                            consumer.traded = true;
                        }
                        if (prosumer.sum == 0) {
                            prosumer.traded = true;
                        }
                        if (consumer.kwh == 0 || prosumer.sum == 0) {
                            break;
                        }
                    }
                }
            }
            ti++;
        }
        return tradeCount;
    }   
    ////////////////////////////////////////////////////
    //Create Consumer by Gaussian distribution
    function CreateConsumerData(uint steps) public {
        Consumer[] memory consumerresult = new Consumer[](steps);
        uint[13] memory endpoint = [steps*3/100, steps*4/100, steps*7/100, steps*9/100, steps*10/100, steps*11/100, steps*12/100, steps*11/100, steps*10/100, steps*9/100, steps*7/100, steps*4/100, steps*3/100];
        uint8[13] memory endpointdata = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];

        uint sum = 0;
        for (uint loop = 0; loop < endpointdata.length; loop++) {
            for (uint idx = 0; idx < endpoint[loop]; idx++) {
                uint blockHash = uint(keccak256(abi.encodePacked(block.number, loop, idx)));
                uint time = (blockHash % 60) + 1;
                uint kwh = 23 + blockHash % 13;
                uint value = endpointdata[endpoint.length - loop - 1];

                Consumer memory newconsumer = Consumer(consumeraddress, kwh, time, value, 0, false); 
                consumerresult[sum + idx] = newconsumer;
            }
            sum += endpoint[loop];
        }

        for (uint i = 0; i < consumerresult.length; i++) {
            consumerList.push(consumerresult[i]);
        }
    }

    //Create Prosumer by Gaussian distribution
    function CreateProsumerData(uint steps) public {
        Prosumer[] memory prosumerresult = new Prosumer[](steps);
        uint[13] memory endpoint = [steps*3/100, steps*4/100, steps*7/100, steps*9/100, steps*10/100, steps*11/100, steps*12/100, steps*11/100, steps*10/100, steps*9/100, steps*7/100, steps*4/100, steps*3/100];
        uint8[13] memory endpointdata = [20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32];

        uint sum = 0;
        for (uint loop = 0; loop < endpointdata.length; loop++) {
            for (uint idx = 0; idx < endpoint[loop]; idx++) {
                uint blockHash = uint(keccak256(abi.encodePacked(block.timestamp, block.number, loop, idx)));
            
                uint time = (blockHash % 60) + 1;
                uint kwh = 23 + blockHash % 13;
                uint value = endpointdata[endpoint.length - loop - 1];

                Prosumer memory newprosumer = Prosumer(prosumeraddress, kwh, time, value, kwh, false); 
                prosumerresult[sum + idx] = newprosumer;
            }
            sum += endpoint[loop];
        }

        for (uint j = 0; j < prosumerresult.length; j++) {
            prosumerList.push(prosumerresult[j]);
        }
    }
}
