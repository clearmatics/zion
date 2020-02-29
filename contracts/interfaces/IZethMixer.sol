pragma solidity ^0.5.12;

interface IZethMixer {
    
    function mix(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2][2] calldata vk,
        uint sigma,
        uint[] calldata input,
        bytes32 pk_sender,
        bytes calldata ciphertext0,
        bytes calldata ciphertext1
    ) external;
}