pragma solidity ^0.5.12;

interface IEthStore {
    function CheckProofs(bytes32 chainId, bytes32 blockHash, bytes calldata proof) external returns (bytes memory);
}