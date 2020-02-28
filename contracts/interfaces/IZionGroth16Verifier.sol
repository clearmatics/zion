pragma solidity ^0.5.12;

interface IZionGroth16Verifier { 
    function verifyCoin(
        uint256[2] calldata a,
        uint256[4] calldata b,
        uint256[2] calldata c,
        uint256[4] calldata vk,
        uint256 sigma,
        uint256[9] calldata input,
        bytes32 pk_sender,
        bytes calldata ciphertext0,
        bytes calldata ciphertext1)
        external payable returns (bool);
}