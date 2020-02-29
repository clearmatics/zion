pragma solidity ^0.5.12;

import "./interfaces/IEthStore.sol";
import "./interfaces/IZethMixer.sol";
import "./interfaces/IZionGroth16Verifier.sol";
import "./interfaces/IonVerifiers/IZethCommitmentEventVerifier.sol";

// Preconditions: 
// Both Alice and Bob have Zeth Notes to spend and they agreed on a certain trade

// Flow: 
// Alice initiates on chain A and can cancel on chain B before Bob responds. 
// She uses the proof she cancelled on chain B to release her locked coins on chain A

// If Bob responds on chain B with a valid commitment he can cancel on chain A before Alice confirms 
// If Alice confirms on chain A the trade go through 

// If Bob cancels on chain A before Alice's confirmation Alice's locked commitment is released and
// Bob uses the proof he has cancelled on chain A to release his coin on chain B

contract Zion {

    IEthStore internal ethStore;
    IZethMixer internal zethMixer;
    IZionGroth16Verifier internal zethVerifier;
    IZethCommitmentEventVerifier internal zethCommitmentEventVerifier;

    // cache valid zeth commitments until the trade is finalized and use it to actually create zeth note for counterparty
    // commitment => zeth proof 
    mapping(bytes => bytes) pendingCommitments;

    // tells if the counterparty has cancelled his commitment 
    // prevents the parties to respond to a cancelled trade
    mapping(bytes => bool) isCounterpartyCommitmentCancelled; 

    
    // event TradeInitiated(Alice's coin nullifier, proof of commitment) // emitted on chain A and carried over to chain B to be consumed
    // event Cancelled(Alice's cancel proof) // emitted on chain B and carried over to chain A to be consumed by Alice to get back her commitment 
    // event Swap(Bob proof of commitment, ) // emitted on chain B and carried over to chain A, allows A
    // event Confirmed(Alice )

    constructor (
        address ethStoreAddr,
        address zethMixerAddr,
        address zethVerifierAddr,
        address zethCommitmentEventVerifierAddr
    ) public {
        ethStore = IEthStore(ethStoreAddr);
        zethMixer = IZethMixer(zethMixerAddr);
        zethVerifier = IZionGroth16Verifier(zethVerifierAddr);
        zethCommitmentEventVerifier = IZethCommitmentEventVerifier(zethCommitmentEventVerifierAddr);
    }

    // 1 - Alice initiates the trade on chain A
    function initiateSwap(bytes32 commitmentA, bytes zethProof) external {

        // verify commitment with ZionGroth16Verifier 
        require(zethVerifier(commitmentA, zethProof) === true, "This is not a valid zeth commitment");

        // cache the data to be used later on 
        pendingCommitments[commitmentA] = zethProof;
        
        // log info needed to be verified through ION proofs
        emit TradeInitiated(commitmentA);
    }

    // 2a - Bob accepts on chain B the trade
    function respondToSwap( bytes32 commitmentB, bytes zethProof,  bytes32 commitmentA) external {   

        // verify with ION that TradeInitiated(commitmentA) was triggered on chain A;
        require(IZethCommitmentEventVerifier(commitmentA), "The commitment you are responding to doesn't exists on the other chain");

        // verify the commitment i'm responding to hasn't been cancelled 
        require(isCounterpartyCommitmentCancelled[commitmentA] === false, "The trade has been cancelled by the counterparty");

        // verify my commitment is a valid zeth commitment 
        require(zethVerifier(commitmentB, zethProof) === true, "This is not a valid zeth commitment");

        // cache the data to be used later on 
        pendingCommitments[commitmentB] = zethProof;

        // log
        emit TradeResponded(commitmentA, commitmentB);
    }

    // 2b - Alice cancels on chain B before Bob accepts
    function initiatorCancel(bytes commitmentA) external {
        
        // verify with ION that TradeInitiated(commitmentA) was triggered on chain A;
        require(IZethCommitmentEventVerifier(commitmentA), "The commitment you are trying to cancel to doesn't exists on the other chain");

        // TODO verify with zocrates that i have the right to cancel the coin 

        // to prevent Bob to accept the trade
        isCounterpartyCommitmentCancelled[commitmentA] = true;
        
        // log 
        emit InitiatorCancelled(commitmentA);  
    } 

    // 3a - Bob cancels on chain A after 2a and before 3b
    function responderCancel(bytes commitmentA, bytes commitmentB) external {

        // TODO verify TradeResponded(commitmentA, commitmentB)

        // this shouldn't be necessary
        require(isPendingCommitments[commitmentA] === true, "The commitmentA doesn-t exist");
        
        // TODO verify with zocrates that i have the right to cancel the coin 

        // to prevent Alice to finalize the trade
        isCounterpartyCommitmentCancelled[commitmentB] = true;

        // release Alice note
        delete pendingCommitments[commitmentA];
        
        // log
        emit ResponderCancelled(commitmentA, commitmentB);  
    }

    // 3b - Alice finalizes the trade on chain A after 2a and before 3a
    function confirmTrade(bytes commitmentA, bytes commitmentB)  {

        // TODO verify TradeResponded(commitmentA, commitmentB);

        // verify that commitmentB hasn't been cancelled 
        require(isCounterpartyCommitmentCancelled[commitmentB] === false, "The counterparty cancelled the trade");

        // verify that commitment A is in pending commitments - shouldn't be required
        require(pendingCommitments[commitmentA], "The commitment is not pending");
        
        // TODO take the cached zeth proof and pass to zeth mixer to create coin for bob

        // delete alice pending commitment 
        delete pendingCommitments[commitmentA]; 
        
        // log
        emit Confirmed(commitmentA, commitmentB);
    }

    // 3c - Alice unlocks her funds on chain A after 2b
    function initiatorRefund(bytes commitmentA) external {
        
        // TODO verify InitiatorCancelled(commitmentA)

        delete pendingCommitments[commitmentA]; 

        emit InitiatorRefunded(commitmentA); 
    }

    // 4a - Bob unlocks his fund on chain B after 3a 
    function responderRefund(bytes commitmentB) external {
        // TODO verify ResponderCancelled(commitmentB) 
        
        delete pendingCommitments[commitmentB]; 

        emit ResponderRefunded(commitmentB);
    }

    // 4b - Alice access her zeth note on chain B after 3b
    function Finalize(bytes commitmentA. bytes commitmentB) {

        // TODO verify Confirmed(commitmentA, commitmentB);

        // TODO take the cached zeth proof and pass to zeth mixer to create coin for alice on chain B
        
        delete pendingCommitments[commitmentA]; 

        emit Finalized(commitmentA, commitmentB);
    }

}