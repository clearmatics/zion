pragma solidity ^0.5.12;

interface IZethCommitmentEventVerifier {
    function verify(bytes20 _contractEmittedAddress, bytes calldata _rlpReceipt, uint256 _expectedAddress, bytes32 _expectedCommitment) external view returns (bool);
}

