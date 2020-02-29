// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+

/*
    Ion Mediator contract test

    Tests here are standalone unit tests for Ion functionality.
    Other contracts have been mocked to simulate basic behaviour.

    Tests the central mediator for block passing and validation registering.
*/

const Verifier = artifacts.require("InitiatorCancelledEventVerifier");

require('chai')
 .use(require('chai-as-promised'))
 .should();


EXPECTED_COMMITMENTS = [
    {
        "contract_address": "0x44991F141a70D4b0662133cE16f8C0782522354a",
        "receipt": "0xf90163018256e6b9010000000000000000000000000000000000000000020100000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000f85af8589444991f141a70d4b0662133ce16f8c0782522354ae1a0635a270dd697068ba0ae02f738aef351b1f56342c3c86257754abbf387dfd849a03471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
        "commitment": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35"
    },
]
INCORRECT_COMMITMENT = {
    "contract_address": "0x44991F141a70D4b0662133cE16f8C0782522354a",
    "receipt": "0xf90163018256e6b9010000000000000000000000000000000000000000020100000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000f85af8589444991f141a70d4b0662133ce16f8c0782522354ae1a0635a270dd697068ba0ae02f738aef351b1f56342c3c86257754abbf387dfd849a03471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
    "commitment": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f36"
}

contract('InitiatorCancelledEventVerifier.sol', (accounts) => {
    let verifier;

    before("deploy verifier", async () => {
        verifier = await Verifier.new();
    })

    describe('Verify Commitment Event', () => {
        it('Successful Verification', async () => {
            for (let i = 0; i < EXPECTED_COMMITMENTS.length; i++) {
                expected_commitment = EXPECTED_COMMITMENTS[i]
                let verified = await verifier.verify.call(expected_commitment.contract_address, expected_commitment.receipt, expected_commitment.commitment);
                await verifier.verify(expected_commitment.contract_address, expected_commitment.receipt, expected_commitment.commitment);

                assert(verified);
            }
        })

        it('Fail Verification with incorrect data', async () => {
            let verified = await verifier.verify.call(INCORRECT_COMMITMENT.contract_address, INCORRECT_COMMITMENT.receipt, INCORRECT_COMMITMENT.commitment);

            assert(!verified);
        })
    })
})