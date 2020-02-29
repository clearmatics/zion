pragma solidity ^0.5.12;

import "./interfaces/IEthStore.sol";
import "./interfaces/IZethMixer.sol";
import "./interfaces/IZionGroth16Verifier.sol";
import "./interfaces/IonVerifiers/IZethCommitmentEventVerifier.sol";

// Flow: Alice initiates on chain A and can cancel on chain B (and then taking back the coin on A) before Bob responds 

// unlock proof = used by Bob to unlock his commitment on chain A and to generate his commitment for Alice
// is a proof that Bob's commitment is a valid Zeth Commitment (spendable only by alice) plus that the underlying metadata matches the one agreed with alice (same value)

// zeth proof = proof of a commitment 

// cancel proof = proves that Alice commitment for bob was created by alice spent coin nullifier 
// C

contract Zion {

    IEthStore internal ethStore;
    IZethMixer internal zethMixer;
    IZionGroth16Verifier internal zethVerifier;
    IZethCommitmentEventVerifier internal zethCommitmentEventVerifier;

    // cache valid zeth commitments until the trade is finalized and use it to actually create zeth note for counterparty
    // commitment => zeth proof 
    mapping(bytes => bytes) pendingCommitments;

    // tells if I can still cancel my commitment on my chain
    mapping(bytes => bool) isCCTradeCounterpartyCancellable; 

    // tells if the counterparty has cancelled his commitment on my chain to prevent someone to respond to a cancelled trade
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


    // takes proof of the deposited coin and require eth 
    // check the proof 
    // store it in transit data structure 
    // emit event of the deposited proof with Alice old coin nullifier and the new committment for bob
    function initiateSwap(bytes32 commitment, bytes zethProof) external payable {

        // TODO msg.value where is checked against the commitment ? 

        // verify commitment with ZionGroth16Verifier 
        require(zethVerifier(commitment, zethProof) === true, "This is not a valid zeth commitment");

        // alice can still cancel through a proof of cancelling from chain B
        isCCTradeCounterpartyCancellable[AliceCommitment] = true; 

        // cache the data to be used later on 
        pendingCommitments[commitments] = zethProof;
        
        // log info needed to be verified through ION proofs
        emit TradeInitiated(commitment);
    }

    // bob reads commitment info from block store 
    // bob submits proof that he has committed a coin with the agreed metadata that matches alice coin - this will go into the event to carry over
    // bob submits the right amount of eth
    // submits the proof that he has created the coin for alice - his commitment is stored in zeth ready for alice
    function respondToSwap(
        bytes32 commitment, 
        bytes zethProof, 
        bytes32 counterpartyCommitment
    ) external 
        isCounterpartyCommitmentCancelled(counterpartyCommitment) 
    { 
        
        // verify the commitment i'm responding to hasn't been cancelled 
        require(isCounterpartyCommitmentCancelled[commitment] === false, "The trade has been cancelled by the counterparty");

        // verify the counterparty commitment has happened with ION 
        require(IZethCommitmentEventVerifier(counterpartyCommitment), "The commitment you are responding to doesn't exists on the other chain");

        // verify my commitment is a valid zeth commitment 
        require(zethVerifier(commitment, zethProof) === true, "This is not a valid zeth commitment");

        // cache the data to be used later on 
        pendingCommitments[commitments] = zethProof;

        // bob can cancel his commitment 
        isCCTradeCounterpartyCancellable[BobCommitment] = true; 

        // log info needed to be verified through ION proofs
        emit TradeResponded(commitment);
    }

    // on the counterparty chain 
    function cancelTrade(bytes commitmentToCancel) external {
        
        // verify ION proof that the commitment to cancel has happened 
        require(IZethCommitmentEventVerifier(counterpartyCommitment), "The commitment you are trying to cancel to doesn't exists on the other chain");

        // TODO verify with zocrates that i have the right to cancel the coin 

        isCounterpartyCommitmentCancelled[commitment] = true;
        
        emit Cancelled(commitmentToCancel);  
    } 

    // to unlock my pending transaction with the proof of cancel on chain B 
    function finalizeCancel(bytes commitmentToCancel) external {

        require(isCCTradeCounterpartyCancellable[commitmentToCancel] === true, "You can't cancel this commitment");

        // TODO require ION proof of cancelling 

        isCCTradeCounterpartyCancellable[alice/BobCommitment] = false; 
        
        delete pendingCommitments[commitmentToCancel]; 

        emit Cancelled(commitmentToCancel);
        
    }

    // initiatior finalizes the trade 
    function confirmTrade(bytes commitmentA, bytes commitmentB)  {

        // commitment A should be in pending commitments 
        require(pendingCommitments[commitmentA], "The commitment is not pending");

        // how do we check commitment B is still in pending 
        
        // verify ION proof that the commitment B to cancel has happened 
        // require(IZethCommitmentEventVerifier(counterpartyCommitment), "The commitment you are trying to cancel to doesn't exists on the other chain");


        submits ion proof that bob responded to swap 
        take the cached zeth proof and pass to zeth mixer to create coin for bob
        delete cached stuff 
        isCCTradeCounterpartyCancellable[alice/BobCommitment] = false; 
        emit event 
    }


    function unlockTransaction(bytes commitment) external {

        // commitment A should be in pending commitments 
        require(pendingCommitments[commitmentA], "The commitment is not pending");

        // verify ION proof that alice confirmed the trade on chain A 
        // take the cached bob zeth proof and pass to zeth mixer to create coin  
    }

}