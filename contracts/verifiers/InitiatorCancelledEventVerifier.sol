pragma solidity ^0.5.12;

import "./EventVerifier.sol";
import "../libraries/RLP.sol";

contract InitiatorCancelledEventVerifier is EventVerifier {
    bytes32 eventSignature = keccak256("InitiatorCancelled(bytes32)");

    function verify
    (
        bytes20 _contractEmittedAddress, 
        bytes memory _rlpReceipt,  
        bytes32 _expectedCommitment
    ) public view returns (bool) {

        // Retrieve specific log for given event signature
        RLP.RLPItem[] memory logs = retrieveLogs(eventSignature, _contractEmittedAddress, _rlpReceipt);

        for (uint i = 0; i < logs.length; i++) {
            RLP.RLPItem[] memory log = RLP.toList(logs[i]);
            // Split logs into constituents. Not all constituents are used here
            // bytes memory contractEmittedEvent = RLP.toData(log[0]);
            bytes memory data = RLP.toData(log[2]);

            bytes32 commitment = SolUtils.BytesToBytes32(data, 0);

            if (commitment == _expectedCommitment) {
                return true;
            }
        }
        return false;
    }
}