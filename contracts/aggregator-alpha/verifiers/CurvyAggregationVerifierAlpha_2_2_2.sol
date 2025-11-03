// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract  CurvyAggregationVerifierAlpha_2_2_2 {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 12397805951025518106727837530396484148707566518486264449692018677592715552738;
    uint256 constant alphay  = 15955090815437592355277639300964029657297847031418701683987115570774046891084;
    uint256 constant betax1  = 4558033428938724707702173270530051784881875483362452783309319477109892316105;
    uint256 constant betax2  = 562684918113878349440529415978735829020597426398767547815813179569677877300;
    uint256 constant betay1  = 20489741225546273474807268360309498543857989566183651420924474108165432690449;
    uint256 constant betay2  = 454381379487956449014758402076019864127573099149576738294140161985720735727;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 14247188116453405673621645482734779597271943579236786988002822486035578351827;
    uint256 constant deltax2 = 19127457743533062382695057246317969331583652196516180652505167533941470596184;
    uint256 constant deltay1 = 1120896676694033813888539165134426369540073925998956380068766205657266649164;
    uint256 constant deltay2 = 11509882780442288397461078955924788953216456968851718873762534083798685470176;


    uint256 constant IC0x = 29462445247651336873197670218881433811515270657621608123062437811400729293;
    uint256 constant IC0y = 18171755157403336899093830921271746363256651403384351735695773262049736733550;

    uint256 constant IC1x = 20155116508805270335695092444982456411255426185965433598991038764554589237491;
    uint256 constant IC1y = 15100236777573876942404435988104314855338324214411252535388491438352277620011;

    uint256 constant IC2x = 10211871721893502392904500352667359944639931168739288628275746498444439334624;
    uint256 constant IC2y = 14857576678067996171949154311157731596082175516312363029732523714738213679225;

    uint256 constant IC3x = 17681178928244319555205465208759196004958135576922343337773782176967565453923;
    uint256 constant IC3y = 12020350826305074268886914285212991819930696406522096455169685411373063924283;

    uint256 constant IC4x = 15990091135939845008053796985720708958381089922139813153004307037770120415376;
    uint256 constant IC4y = 14686431646476347283962842352013379254853767901657891326891810060612370131980;

    uint256 constant IC5x = 9836802977203983623311722609159922779452226468276418069924737841205211059775;
    uint256 constant IC5y = 5851543777081950781696453016189466308824375346225749203286800288308819146995;

    uint256 constant IC6x = 20494598241570455849918685888437752184000806835792517335988569390529750670399;
    uint256 constant IC6y = 5118171864497209081972949748612803357992268865433760622407683235582888296730;

    uint256 constant IC7x = 4161116648736026602325932141983145072422766799723371889670488259084982158410;
    uint256 constant IC7y = 9823852613097441041513408079495633594306721875095369575303676346788966932542;

    uint256 constant IC8x = 18765382825961060386998956112280419451294524096891700144870842762014869263482;
    uint256 constant IC8y = 19072335486260980952513432441473964489080839652759276569808438095375047060405;

    uint256 constant IC9x = 13461757427291354529150925761759132586768268951212262050759971788739599457371;
    uint256 constant IC9y = 4798781689873879774176109834716065302885296520372365401475518178120364765053;

    uint256 constant IC10x = 2825946145004188674530444966368925818974257222272928787863708902753465126277;
    uint256 constant IC10y = 1132081428014299195407240376318746218027138258204471169466177788741899724649;

    uint256 constant IC11x = 6037061286657655112833173191022971038494250639700090848969212974351407272955;
    uint256 constant IC11y = 14288245102826282599683294768365607032501106839126325328556517607105285011189;

    uint256 constant IC12x = 16666416945139505069027327107503900232722595465132986777080649891257196764894;
    uint256 constant IC12y = 16479310741244346892769904991381444059360278176600162038328339853031393579364;

    uint256 constant IC13x = 8457614266693283160896406297631606953977487470037761765606926637481574421021;
    uint256 constant IC13y = 7268797945103287108426579652981774503857175386562341294721963484244801300809;

    uint256 constant IC14x = 17506341415928441858395452534096119812461333575351484400640668498682876605148;
    uint256 constant IC14y = 3698938041800489752726811068263827706724617934585101138986055289302086103389;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[14] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))


                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}
