pragma solidity ^0.5.12;

import "./interfaces/IEthStore.sol";
import "./interfaces/IZethMixer.sol";
import "./interfaces/IZionGroth16Verifier.sol";
import "./interfaces/IonVerifiers/IZethCommitmentEventVerifier.sol";
import "./ZionGroth16Mixer.sol";
import "./verifiers/TradeInitiatedEventVerifier.sol";
import "./verifiers/ConfirmedEventVerifier.sol";
import "./verifiers/ResponderCancelledEventVerifier.sol";
import "./verifiers/TradeRespondedEventVerifier.sol";
import "./verifiers/InitiatorCancelledEventVerifier.sol";

// Preconditions: 
// Both Alice and Bob have Zeth Notes to spend and they agreed on a certain trade

// Flow: 
// Alice initiates on chain A and can cancel on chain B before Bob responds. 
// She uses the proof she cancelled on chain B to release her locked coins on chain A

// If Bob responds on chain B with a valid commitment he can cancel on chain A before Alice confirms 
// If Alice confirms on chain A the trade go through 

// If Bob cancels on chain A before Alice's confirmation Alice's locked commitment is released and
// Bob uses the proof he has cancelled on chain A to release his coin on chain B

contract Zion is ZionGroth16Mixer {
    IEthStore internal blockStore;

    TradeInitiatedEventVerifier internal tradeInitiatedEventVerifier;
    TradeRespondedEventVerifier internal tradeRespondedEventVerifier;
    InitiatorCancelledEventVerifier internal initiatorCancelledEventVerifier;
    ResponderCancelledEventVerifier internal responderCancelledEventVerifier;
    ConfirmedEventVerifier internal confirmedEventVerifier;

    struct ZethProof {
        uint256[2] a;
        uint256[4] b;
        uint256[2] c;
        uint256[4] vk;
        uint256 sigma;
        uint256[nbInputs] input;
        bytes32 pk_sender;
        bytes ciphertext0;
        bytes ciphertext1;
    }

    // cache valid zeth commitments until the trade is finalized and use it to actually create zeth note for counterparty
    // commitment => zeth proof 
    mapping(bytes32 => ZethProof) pendingCommitments;
    mapping(bytes32 => bool) isPendingCommitment;

    // tells if the counterparty has cancelled his commitment 
    // prevents the parties to respond to a cancelled trade
    mapping(bytes32 => bool) isCounterpartyCommitmentCancelled;

    event TradeInitiated(bytes32 commitment);
    event TradeResponded(bytes32 initiatorCommitment, bytes32 responderCommitment);
    event InitiatorCancelled(bytes32 initiatorCommitment);
    event InitiatorRefunded(bytes32 initiatorCommitment);
    event ResponderCancelled(bytes32 initiatorCommitment, bytes32 responderCommitment);
    event ResponderRefunded(bytes32 initiatorCommitment, bytes32 responderCommitment);
    event Confirmed(bytes32 initiatorCommitment, bytes32 responderCommitment);
    event Finalized(bytes32 initiatorCommitment, bytes32 responderCommitment);

    constructor (
        uint256 mk_depth,
        address token,
        uint256[2] memory Alpha,
        uint256[2] memory Beta1,
        uint256[2] memory Beta2,
        uint256[2] memory Delta1,
        uint256[2] memory Delta2,
        uint256[] memory ABC_coords,
        address ethStoreAddr,
        address zethMixerAddr,
        address tradeInitiatedEventVerifierAddr,
        address tradeRespondedEventVerifierAddr,
        address initiatorCancelledEventVerifierAddr,
        address responderCancelledEventVerifierAddr,
        address confirmedEventVerifierAddr
    ) public ZionGroth16Mixer(
        mk_depth,
        token,
        Alpha,
        Beta1,
        Beta2,
        Delta1,
        Delta2,
        ABC_coords
    ) {
        blockStore = IEthStore(ethStoreAddr);
        tradeInitiatedEventVerifier = TradeInitiatedEventVerifier(tradeInitiatedEventVerifierAddr);
        tradeRespondedEventVerifier = TradeRespondedEventVerifier(tradeRespondedEventVerifierAddr);
        initiatorCancelledEventVerifier = InitiatorCancelledEventVerifier(initiatorCancelledEventVerifierAddr);
        responderCancelledEventVerifier = ResponderCancelledEventVerifier(responderCancelledEventVerifierAddr);
        confirmedEventVerifier = ConfirmedEventVerifier(confirmedEventVerifierAddr);
    }

    // 1 - Alice initiates the trade on chain A
    function initiateSwap(
        uint256[2] memory a,
        uint256[4] memory b,
        uint256[2] memory c,
        uint256[4] memory vk,
        uint256 sigma,
        uint256[nbInputs] memory input,
        bytes32 pk_sender,
        bytes memory ciphertext0,
        bytes memory ciphertext1) public {
        // verify commitment with ZionGroth16Verifier
        bytes32[jsOut] memory commitments = verifyProof(a, b, c, vk, sigma, input, pk_sender, ciphertext0, ciphertext1);

        // log info needed to be verified through ION proofs
        for (uint i = 0; i < jsOut; i++) {
            emit TradeInitiated(commitments[i]);
            pendingCommitments[commitments[i]] = ZethProof(a,b,c,vk,sigma,input,pk_sender,ciphertext0,ciphertext1);
        }
    }

    // 2a - Bob accepts on chain B the trade
    function respondToSwap(
        uint256[2] memory a,
        uint256[4] memory b,
        uint256[2] memory c,
        uint256[4] memory vk,
        uint256 sigma,
        uint256[nbInputs] memory input,
        bytes32 pk_sender,
        bytes memory ciphertext0,
        bytes memory ciphertext1,
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(tradeInitiatedEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment), "Event verification failed.");

        // verify the commitment i'm responding to hasn't been cancelled 
        require(!isCounterpartyCommitmentCancelled[_initiatorCommitment], "The trade has been cancelled by the counterparty");

        // to prevent alice from cancelling
        isCounterpartyCommitmentCancelled[_initiatorCommitment] = true;

        rts2(a,b,c,vk,sigma,input,pk_sender,ciphertext0,ciphertext1, _initiatorCommitment);
    }

    function rts2(
        uint256[2] memory a,
        uint256[4] memory b,
        uint256[2] memory c,
        uint256[4] memory vk,
        uint256 sigma,
        uint256[nbInputs] memory input,
        bytes32 pk_sender,
        bytes memory ciphertext0,
        bytes memory ciphertext1,
        bytes32 _initiatorCommitment
    ) private {
        // verify commitment with ZionGroth16Verifier
        bytes32[jsOut] memory commitments = verifyProof(a, b, c, vk, sigma, input, pk_sender, ciphertext0, ciphertext1);

        // log info needed to be verified through ION proofs
        for (uint i = 0; i < jsOut; i++) {
            emit TradeResponded(_initiatorCommitment, commitments[i]);
            // cache the data to be used later on
            pendingCommitments[commitments[i]] = ZethProof(a,b,c,vk,sigma,input,pk_sender,ciphertext0,ciphertext1);
        }
    }

    // 2b - Alice cancels on chain B before Bob accepts
    function initiatorCancel(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(tradeInitiatedEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment), "Event verification failed.");

        // TODO verify with zocrates that i have the right to cancel the coin
        // verify the commitment i'm responding to hasn't been cancelled
        require(!isCounterpartyCommitmentCancelled[_initiatorCommitment], "The trade has already been responded to by counterparty");

        // to prevent Bob to accept the trade
        isCounterpartyCommitmentCancelled[_initiatorCommitment] = true;
        
        // log 
        emit InitiatorCancelled(_initiatorCommitment);
    } 

    // 3a - Bob cancels on chain A after 2a and before 3b
    function responderCancel(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment,
        bytes32 _responderCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(tradeRespondedEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment, _responderCommitment), "Event verification failed.");

        // Check that Alice has not already confirmed the trade
        require(isPendingCommitment[_initiatorCommitment], "The commitment doesn't exist");
        
        // TODO verify with zocrates that i have the right to cancel the coin 

        // to prevent Alice from confirming the trade
        isCounterpartyCommitmentCancelled[_responderCommitment] = true;

        // release Alice note
        delete pendingCommitments[_initiatorCommitment];
        
        // log
        emit ResponderCancelled(_initiatorCommitment, _responderCommitment);
    }

    // 3b - Alice finalizes the trade on chain A after 2a and before 3a
    function confirmTrade(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment,
        bytes32 _responderCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(tradeRespondedEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment, _responderCommitment), "Event verification failed.");

        // check that the commitment still exists
        require(isPendingCommitment[_initiatorCommitment], "The commitment doesn't exist in pending");

        // verify that responder hasn't cancelled
        require(!isCounterpartyCommitmentCancelled[_responderCommitment], "The counterparty cancelled the trade");

        // Fetch cached zeth proof
        ZethProof storage zethProof = pendingCommitments[_initiatorCommitment];

        // Submit zeth proof to mixer to create coin
        mix(
            zethProof.a,
            zethProof.b,
            zethProof.c,
            zethProof.vk,
            zethProof.sigma,
            zethProof.input,
            zethProof.pk_sender,
            zethProof.ciphertext0,
            zethProof.ciphertext1
        );

        // delete alice pending commitment 
        delete pendingCommitments[_initiatorCommitment];
        
        // log
        emit Confirmed(_initiatorCommitment, _responderCommitment);
    }

    // 3c - Alice unlocks her funds on chain A after 2b
    function initiatorRefund(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(initiatorCancelledEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment), "Event verification failed.");

        delete pendingCommitments[_initiatorCommitment];

        emit InitiatorRefunded(_initiatorCommitment);
    }

    // 4a - Bob unlocks his fund on chain B after 3a 
    function responderRefund(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment,
        bytes32 _responderCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(responderCancelledEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment, _responderCommitment), "Event verification failed.");
        
        delete pendingCommitments[_responderCommitment];

        emit ResponderRefunded(_initiatorCommitment, _responderCommitment);
    }

    // 4b - Alice access her zeth note on chain B after 3b
    function Finalize(
        bytes32 _chainId,
        bytes32 _blockHash,
        bytes20 _contractEmittedAddress,
        bytes memory _proof,
        bytes32 _initiatorCommitment,
        bytes32 _responderCommitment
    ) public {
        bytes memory receipt = blockStore.CheckProofs(_chainId, _blockHash, _proof);
        require(confirmedEventVerifier.verify(_contractEmittedAddress, receipt, _initiatorCommitment, _responderCommitment), "Event verification failed.");

        // Fetch cached zeth proof
        ZethProof storage zethProof = pendingCommitments[_responderCommitment];

        // Submit zeth proof to mixer to create coin
        mix(
            zethProof.a,
            zethProof.b,
            zethProof.c,
            zethProof.vk,
            zethProof.sigma,
            zethProof.input,
            zethProof.pk_sender,
            zethProof.ciphertext0,
            zethProof.ciphertext1
        );

        delete pendingCommitments[_responderCommitment];

        emit Finalized(_initiatorCommitment, _responderCommitment);
    }

}