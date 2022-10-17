// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MultiSignatureWallet{
    event Deposit(address indexed sender, uint value, uint _bal);
    event Submit(string _msg, uint contractBalance);
    event Approved(address indexed owner, uint txId);
    event Revoked(address indexed owner, uint txId);
    event Executed(uint txId, bool success);

    struct Transaction {
        address to;
        uint value;
        bool isExecuted;
        bytes data;
        uint approvedCount;
    }

    // [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]


    mapping(address => bool) owners;
    uint requiredNumerOfApproval;
    mapping(uint => Transaction) transactions;
    mapping(uint => mapping(address => bool)) isConfirmed;
    uint txCount;

    constructor(address[] memory _owners, uint _required){
        require(_owners.length > 0, "Owners required");
        require(_required != 0 && _required <= _owners.length, "Please enter valid Required number");

        for(uint i; i < _owners.length; i++){
            require(!owners[_owners[i]], "Please enter unique owners");
            owners[_owners[i]] = true;
        }

        requiredNumerOfApproval = _required;
    }

     receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }


    function submitTransaction(address _to,uint _data, uint _value) external {
        transactions[txCount] = Transaction(_to, _value,false, abi.encodePacked(_data),0);   
        txCount++;
        emit Submit("Tx Submitted",address(this).balance);
    }

    function approveTx(uint txId) external{
        require(txId <= txCount, "Invalid TxId");
        require(owners[msg.sender],"Only owner can approve Tx");
        require(!transactions[txId].isExecuted, "Already Executed");
        require(!isConfirmed[txId][msg.sender], "Already Approved");

        isConfirmed[txId][msg.sender] = true;
        transactions[txId].approvedCount += 1 ; 

        emit Approved(msg.sender,txId);

    }

    function revoke(uint txId) external{
        require(owners[msg.sender],"Only owner can access this function");
        require(txId <= txCount, "Invalid TxId");
        require(!transactions[txId].isExecuted, "Already Executed");
        require(isConfirmed[txId][msg.sender], "You didn't approved this Tx");

        isConfirmed[txId][msg.sender] = false;
        transactions[txId].approvedCount -= 1 ;
        emit Revoked(msg.sender,txId);

    } 

    function executeTransaction(uint txId) external{
        require(txId <= txCount, "Invalid TxId");
        require(!transactions[txId].isExecuted, "Already Executed");
        require(transactions[txId].approvedCount >= requiredNumerOfApproval, "Get enough number of approval to execute this Tx");

        Transaction storage transaction = transactions[txId];

        transaction.isExecuted = true;

        (bool success,) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        emit Executed(txId, success);
        
    }
}