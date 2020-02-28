pragma solidity ^0.5.12;

import "./EventVerifier.sol";
import "../libraries/RLP.sol";

contract ZethCommitmentEventVerifier is EventVerifier {
    bytes32 eventSignature = keccak256("LogCommitment(uint256,bytes32)");

    event Address(uint256 addr);
    event b32Address(bytes32 addr);
    event Commitment(bytes32 commitment);
    event Data(bytes data);

    function verify(bytes20 _contractEmittedAddress, bytes memory _rlpReceipt, uint256 _expectedAddress, bytes32 _expectedCommitment) public returns (bool) {
        // Retrieve specific log for given event signature
        RLP.RLPItem[] memory logs = retrieveLogs(eventSignature, _contractEmittedAddress, _rlpReceipt);

        for  (uint i = 0; i < logs.length; i++) {
            RLP.RLPItem[] memory log = RLP.toList(logs[i]);
            // Split logs into constituents. Not all constituents are used here
            bytes memory contractEmittedEvent = RLP.toData(log[0]);
            bytes memory data = RLP.toData(log[2]);

            bytes32 cmAddr = SolUtils.BytesToBytes32(data, 0);
            bytes32 commitment = SolUtils.BytesToBytes32(data, 32);

            bool addressMatch = cmAddr == bytes32(_expectedAddress);
            bool commitmentMatch = commitment == _expectedCommitment;

            if (addressMatch && commitmentMatch) {
                return true;
            }
        }
        return false;
    }
}
