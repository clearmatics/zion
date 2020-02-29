// Copyright (c) 2016-2018 Clearmatics Technologies Ltd
// SPDX-License-Identifier: LGPL-3.0+

/*
    Ion Mediator contract test

    Tests here are standalone unit tests for Ion functionality.
    Other contracts have been mocked to simulate basic behaviour.

    Tests the central mediator for block passing and validation registering.
*/

const Verifier = artifacts.require("TradeInitiatedEventVerifier");

require('chai')
 .use(require('chai-as-promised'))
 .should();


EXPECTED_COMMITMENTS = [
    {
        "contract_address": "0xE55240863e78608fb2BcE38a7e28fd3F3b6948C5",
        "receipt": "0xf90163018256e6b9010000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000f85af85894e55240863e78608fb2bce38a7e28fd3f3b6948c5e1a0f7093a9babf9ca9c0781fa7e141629dc78270d74e7296a23afc8f4c55b4e3ba2a03471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
        "commitment": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35"
    },
]
INCORRECT_COMMITMENT = {
    "contract_address": "0xE55240863e78608fb2BcE38a7e28fd3F3b6948C5",
    "receipt": "0xf90163018256e6b9010000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000f85af85894e55240863e78608fb2bce38a7e28fd3f3b6948c5e1a0f7093a9babf9ca9c0781fa7e141629dc78270d74e7296a23afc8f4c55b4e3ba2a03471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f35",
    "commitment": "0x3471555ab9a99528f02f9cdd8f0017fe2f56e01116acc4fe7f78aee900442f36"
}

contract('TradeInitiatedEventVerifier.sol', (accounts) => {
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