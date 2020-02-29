pragma solidity ^0.5.12;

import "./EventVerifier.sol";
import "../libraries/RLP.sol";

contract TradeRespondedEventVerifier is EventVerifier {
    bytes32 eventSignature = keccak256("TradeResponded(bytes32,bytes32)");

    event Bytes(bytes stuff);
    event Bytes32(bytes32 stuff);

    function verify
    (
        bytes20 _contractEmittedAddress, 
        bytes memory _rlpReceipt,  
        bytes32 _expectedCommitmentA,
        bytes32 _expectedCommitmentB
    ) public returns (bool) {

        // Retrieve specific log for given event signature
        RLP.RLPItem[] memory logs = retrieveLogs(eventSignature, _contractEmittedAddress, _rlpReceipt);

        for (uint i = 0; i < logs.length; i++) {
            RLP.RLPItem[] memory log = RLP.toList(logs[i]);
            // Split logs into constituents. Not all constituents are used here
            // bytes memory contractEmittedEvent = RLP.toData(log[0]);
            bytes memory data = RLP.toData(log[2]);

            bytes32 commitmentA = SolUtils.BytesToBytes32(data, 0);
            bytes32 commitmentB = SolUtils.BytesToBytes32(data, 32);

            emit Bytes(data);
            emit Bytes32(commitmentA);
            emit Bytes32(commitmentB);

            emit Bytes32(_expectedCommitmentA);
            emit Bytes32(_expectedCommitmentB);

            bool commitmentAMatch = commitmentA == _expectedCommitmentA;
            bool commitmentBMatch = commitmentB == _expectedCommitmentB;

            return commitmentAMatch && commitmentBMatch;
        }
        return false;
    }
}