// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+

/*
    Ion Mediator contract test

    Tests here are standalone unit tests for Ion functionality.
    Other contracts have been mocked to simulate basic behaviour.

    Tests the central mediator for block passing and validation registering.
*/

const Verifier = artifacts.require("TradeRespondedEventVerifier");

require('chai')
 .use(require('chai-as-promised'))
 .should();


EXPECTED_COMMITMENTS = [
    {
        "contract_address": "0x81112070638A7f0C6a35f6da78700B83152fABa3",
        "receipt": "0xf90184018257feb9010000000000000000000000000000000000000000000000000000000000800000000000000000000000004000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000f87bf8799481112070638a7f0c6a35f6da78700b83152faba3e1a0be5c902a6efea4a8fdfaeaa050a1f096b4dd7603a8251cfb81c7e266757c1c95b8403471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f3507f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586",
        "commitmentA": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
        "commitmentB": "0x07f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586"
    },
]
INCORRECT_COMMITMENT = {
    "contract_address": "0x81112070638A7f0C6a35f6da78700B83152fABa3",
    "receipt": "0xf90184018257feb9010000000000000000000000000000000000000000000000000000000000800000000000000000000000004000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000f87bf8799481112070638a7f0c6a35f6da78700b83152faba3e1a0be5c902a6efea4a8fdfaeaa050a1f096b4dd7603a8251cfb81c7e266757c1c95b8403471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f3507f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586",
    "commitmentA": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f36",
    "commitmentB": "0x07f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586"
}

contract('TradeRespondedEventVerifier.sol', (accounts) => {
    let verifier;

    before("deploy verifier", async () => {
        verifier = await Verifier.new();
    })

    describe('Verify Commitment Event', () => {
        it('Successful Verification', async () => {
            for (let i = 0; i < EXPECTED_COMMITMENTS.length; i++) {
                expected_commitment = EXPECTED_COMMITMENTS[i]
                let verified = await verifier.verify.call(expected_commitment.contract_address, expected_commitment.receipt, expected_commitment.commitmentA, expected_commitment.commitmentB);
                await verifier.verify(expected_commitment.contract_address, expected_commitment.receipt, expected_commitment.commitmentA, expected_commitment.commitmentB);

                assert(verified);
            }
        })

        it('Fail Verification with incorrect data', async () => {
            let verified = await verifier.verify.call(INCORRECT_COMMITMENT.contract_address, INCORRECT_COMMITMENT.receipt, INCORRECT_COMMITMENT.commitmentA, INCORRECT_COMMITMENT.commitmentB);

            assert(!verified);
        })
    })
})