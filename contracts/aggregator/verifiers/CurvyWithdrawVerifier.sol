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

contract CurvyWithdrawVerifier {
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
    uint256 constant deltax1 = 1942957736037963101203219158469259529546799241990758433727523856964538100073;
    uint256 constant deltax2 = 18751923381200656298966034357393007161012447906702590224817337765901518639673;
    uint256 constant deltay1 = 1133999629005264953340361763833931385589890012974815573425435607942024998386;
    uint256 constant deltay2 = 14471269438293025701528144565650621453664657630625879213448935801370895962940;


    uint256 constant IC0x = 11968520527261008482201395429648269043035616497073888658724571012437789293939;
    uint256 constant IC0y = 5136251148319110970366250455217987647549782888975639692208545140414393137884;

    uint256 constant IC1x = 5975241901947889428732629350826663755899042053573889198253119292209887821040;
    uint256 constant IC1y = 2685690711649235809807871684645747831411670364944637928549630358451580743776;

    uint256 constant IC2x = 21457725883524874632812608873663348299725989674105072179521462800873159704544;
    uint256 constant IC2y = 19168217719060062389194429118110295922878525697032925549314953343761367307141;

    uint256 constant IC3x = 17554887761244498448299647193645089417418333466521419290903975536912994480102;
    uint256 constant IC3y = 6828503642628660310065798863926994844602749634343008753314631578060116317289;

    uint256 constant IC4x = 18045958587858551125780098548280608486861406147719724376886960587385758892570;
    uint256 constant IC4y = 1460992944153042284168728471643688563838047682787154519800969757480118977318;

    uint256 constant IC5x = 8036932202895490274341216374336553590284129118220623742481357002018210069085;
    uint256 constant IC5y = 18124381701282194246396478048337342484804646549782698384328525226734865874217;

    uint256 constant IC6x = 20732565017826841759780149484537562794481082473815326973722686385643825053232;
    uint256 constant IC6y = 1578295143682207919150217030105921698678835562616948345397787740004184473466;

    uint256 constant IC7x = 13336419499841102064953828107563315860524065147821200507183965277570290809701;
    uint256 constant IC7y = 15646739618986350809196316363572210110061458933904816195180902726350713059476;

    uint256 constant IC8x = 3781871953990367480957688085798233518568839779161221598822628397760557895286;
    uint256 constant IC8y = 12817226393979548789463163683773821122513428271793963480322864256370266927153;

    uint256 constant IC9x = 2926575412652084811061107906584177183682681890851185080729303468987134565693;
    uint256 constant IC9y = 6977667946282706236499241992533773181650515025258779907882853261697686173390;

    uint256 constant IC10x = 13730737400268905683628732665166925183849825441370098666588386862696253859993;
    uint256 constant IC10y = 21232995117437150082021144389671781866736648491602691192891602074767930210292;


    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[10] calldata _pubSignals) public view returns (bool) {
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


            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}
