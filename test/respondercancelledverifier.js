// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+

/*
    Ion Mediator contract test

    Tests here are standalone unit tests for Ion functionality.
    Other contracts have been mocked to simulate basic behaviour.

    Tests the central mediator for block passing and validation registering.
*/

const Verifier = artifacts.require("ResponderCancelledEventVerifier");

require('chai')
 .use(require('chai-as-promised'))
 .should();


EXPECTED_COMMITMENTS = [
    {
        "contract_address": "0x5e456557bEF887647883664cE97768929763dEaf",
        "receipt": "0xf901840182582ab9010000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f87bf879945e456557bef887647883664ce97768929763deafe1a07d4d0c8de2441cc4200cfef866a2c9d8ea40e8a1b9c6e705a2e269681a6b6c95b8403471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f3507f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586",
        "commitmentA": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
        "commitmentB": "0x07f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586"
    },
]
INCORRECT_COMMITMENT = {
    "contract_address": "0x5e456557bEF887647883664cE97768929763dEaf",
    "receipt": "0xf901840182582ab9010000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f87bf879945e456557bef887647883664ce97768929763deafe1a07d4d0c8de2441cc4200cfef866a2c9d8ea40e8a1b9c6e705a2e269681a6b6c95b8403471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f3507f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586",
    "commitmentA": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f36",
    "commitmentB": "0x07f36c7ad26564fa65daebda75a23dfa95d660199092510743f6c8527dd72586"
}

contract('ResponderCancelledEventVerifier.sol', (accounts) => {
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