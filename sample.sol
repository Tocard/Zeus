// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZeusLottery {
    mapping(address => bool) public participants;
    address[] public participantList;
    uint public depositAmount = 0.01 ether;
    address public owner;
    address public devadress;

    constructor() {
        owner = msg.sender;
        devadress = 0xBACbC8B7D2a9Bf4339d14A8Cf7B3c76da66578Ca;
    }

    function deposit() external payable {
        require(msg.value == depositAmount, "Deposit amount must be 1 MATIC");
        require(!isParticipant(msg.sender), "You have already deposited MATIC");
        participants[msg.sender] = true;
        participantList.push(msg.sender);
    }

    function refund() external {
        require(participants[msg.sender], "You have not deposited any MATIC");
        participants[msg.sender] = false;
        payable(msg.sender).transfer(depositAmount);
    }

    function getParticipants() external view returns (address[] memory) {
        return participantList;
    }

    function getRandomParticipant() internal view returns (address) {
        require(participantList.length > 0, "There are no participants");
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % participantList.length;
        return participantList[randomIndex];
    }

    function sendToRandomParticipant() external {
        require(msg.sender == owner, "Only the owner can call this function");
        require(participantList.length >= 3, "There must be at least 3 participants to run this function");
        address randomParticipant = getRandomParticipant();
        IERC20 maticToken = IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);
        uint balance = maticToken.balanceOf(address(this));

        maticToken.transfer(randomParticipant, balance * 75 / 100);
        maticToken.transfer(devadress, balance * 24 / 100);
        participantList = new address[](0);
    }

    function isParticipant(address _address) internal view returns (bool) {
        return participants[_address];
    }
}
