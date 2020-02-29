pragma solidity ^0.5.12;

import "./EventVerifier.sol";
import "../libraries/RLP.sol";

contract TradeInitiatedEventVerifier is EventVerifier {
    bytes32 eventSignature = keccak256("TradeInitiated(bytes32)");

    event TradeInitiated(bytes32 hash);
    event InitiatorCancelled(bytes32 hash);
    event TradeResponded(bytes32 hash, bytes32 hash2);
    event ResponderCancelled(bytes32 hash, bytes32 hash2);
    event Confirmed(bytes32 hash, bytes32 hash2);

    function verify(bytes20 _contractEmittedAddress, bytes memory _rlpReceipt, bytes32 _expectedCommitment) public view returns (bool) {
        // Retrieve specific log for given event signature
        RLP.RLPItem[] memory logs = retrieveLogs(eventSignature, _contractEmittedAddress, _rlpReceipt);

        for (uint i = 0; i < logs.length; i++) {
            RLP.RLPItem[] memory log = RLP.toList(logs[i]);
            // Split logs into constituents. Not all constituents are used here
            // bytes memory contractEmittedEvent = RLP.toData(log[0]);
            bytes memory data = RLP.toData(log[2]);

            if (SolUtils.BytesToBytes32(data, 0) == _expectedCommitment) {
                return true;
            }
        }
        return false;
    }

    function doEvent() public {
        emit InitiatorCancelled(0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35);
    }

    function doEvent2() public {
        emit Confirmed(0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35, 0x07f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586);
    }
}
