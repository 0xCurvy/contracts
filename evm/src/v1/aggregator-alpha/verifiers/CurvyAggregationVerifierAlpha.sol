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

contract CurvyAggregationVerifierAlpha {
    // Scalar field size
    uint256 constant r = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax = 1636846776518434317996733932951972378772913817912419917762768475702381471734;
    uint256 constant alphay = 2557859348676819025385346933609180330308687626659434893060052940731235849018;
    uint256 constant betax1 = 6486908244102514188758219539984059501831627243372326134761579522465959290266;
    uint256 constant betax2 = 20982554991654900079360939570217720062255973982399814758284443662932208191129;
    uint256 constant betay1 = 19182644467787183843647819985681434389712148315951713380764435963668492288076;
    uint256 constant betay2 = 12406681655195816859272397663108739861438627022123343846745568062489563457825;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 14565140526040379252440876868446026484620607365099793488758478248949590866568;
    uint256 constant deltax2 = 15546890603908620513610399539681592401768087510243527001631575420311976331075;
    uint256 constant deltay1 = 3636249996660988291720564391160042487330689987962539285735940284745843948469;
    uint256 constant deltay2 = 18466840172962470138295440946065056126167086066486808070995518921857693340181;

    uint256 constant IC0x = 18281047421811905869067690767469817878227813124194405251958839694770782565744;
    uint256 constant IC0y = 21015879458790283375558908787509173085524379917151716843333723738924460890473;

    uint256 constant IC1x = 10851899448302921875770899633632587151985904839506857746744141136237175322740;
    uint256 constant IC1y = 2394957878670307319595724894152670302385364283510385638593730737439609549567;

    uint256 constant IC2x = 11786763898414854144835088940932105475956170616806344525374604115569788763681;
    uint256 constant IC2y = 17657786896682955029092240726634006876567628770331689315751176094805977395962;

    uint256 constant IC3x = 19363622100346295507845971363009475638600872350251275358292319324943940465294;
    uint256 constant IC3y = 19363463630078709787292698949166898648392452415840415412852353345732047067718;

    uint256 constant IC4x = 4916801306127793974989858246046468790145948617850715088058899892045515989869;
    uint256 constant IC4y = 21825372770541419021766343580566940132127063752729758450884382985027209418826;

    uint256 constant IC5x = 16736386709304050591213407685938689326803883209568752204251898084692783835679;
    uint256 constant IC5y = 12315646500755316004852710207086403210377167622882016517135998596229433012345;

    uint256 constant IC6x = 11764055674308305353711060529322292023954246642376406902398659749018448206560;
    uint256 constant IC6y = 13891554962867460245069585371113999269805999875190487134867139447051774495521;

    uint256 constant IC7x = 18763977845432012010376264958259629820137230526960491789157711149615142485750;
    uint256 constant IC7y = 9638872804273904586683427027881851164890998805599376491736398066895390972072;

    uint256 constant IC8x = 2737499925948538588858101408920493268953083897652379514216387261022763035131;
    uint256 constant IC8y = 13448629921517226045773859100972521531036238616687262161208066697423040007197;

    uint256 constant IC9x = 5239723931588188446458292750596471667188596410036855825393754190107745960540;
    uint256 constant IC9y = 5289866559180373823485441615827186146892304692049365220594643298238926246720;

    uint256 constant IC10x = 9682912213661229540245649251966152581399819355970095975806799658488575499658;
    uint256 constant IC10y = 18581409611187596874324231813868079595584277218090069402578813312148875613;

    uint256 constant IC11x = 19486532844907109944773869334082680266611749304853845137312750802816898996425;
    uint256 constant IC11y = 7279591017446462099182945403278976762852088229025196799806853253650754252428;

    uint256 constant IC12x = 2498185827618853705526246406437476754891902364410367956945439002618952058318;
    uint256 constant IC12y = 15205428768785996361556334439317569383921055038902171414899123752753371640026;

    uint256 constant IC13x = 14395886552513367675568717234032678791223480814625204462167801619894989229493;
    uint256 constant IC13y = 16676161003765952156205135254573875695804669407692686501413087673361995053461;

    uint256 constant IC14x = 15942161432068041084829480233039987449723609716843074425983782106075225853499;
    uint256 constant IC14y = 13002877688944975899456829505679886842169039646833051818998819728598546366671;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[14] calldata _pubSignals
    ) public view returns (bool) {
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
