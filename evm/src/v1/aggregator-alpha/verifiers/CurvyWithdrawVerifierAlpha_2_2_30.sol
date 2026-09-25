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

contract CurvyWithdrawVerifierAlpha_2_2_30 {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 13609597477422817544806719940578211239660138492812767741570640666225907996628;
    uint256 constant alphay  = 3315096884673693139303582008970220799715870802021815302955257248960229394132;
    uint256 constant betax1  = 20244502790401697640374985581353359627000854646412500262318694555628864857705;
    uint256 constant betax2  = 18009540316062949354047865494362899064185820891461168067970621853171214969025;
    uint256 constant betay1  = 21485324237153900776296822920524193097954549703233921348239585839570605636041;
    uint256 constant betay2  = 18873349741553391434573540024886497503852362769056818998084383144689457732005;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 1326573999234008915860970255668288665544687867246129633383511223618949749675;
    uint256 constant deltax2 = 4671378872751554262593117516718744941438728548819807763673365133047577037789;
    uint256 constant deltay1 = 16788886948198384057861007888463049568905967713972406315720808677012605857589;
    uint256 constant deltay2 = 11763588175345468321335670711599742080686820706950268603977732622497589861879;

    
    uint256 constant IC0x = 1565517161687003293015203570982904294478626690646768701975043216594621592173;
    uint256 constant IC0y = 9694355955203911819720634547311219374077692615266951917112047220710786696066;
    
    uint256 constant IC1x = 979945337289157544465183094998207304988359546651753529054442854403648860856;
    uint256 constant IC1y = 19527314231074839844772667723668224759674402860087649048034186839079758285399;
    
    uint256 constant IC2x = 14522339657615904046051278782672208276707120841768130534814843332473328376222;
    uint256 constant IC2y = 11309944904233649642419513097668591526894933049496988389467872182124635975426;
    
    uint256 constant IC3x = 17854426610750151012676330172911429119329082369774743182642967443717533145246;
    uint256 constant IC3y = 13422631716882796157367980767149467009150631687579343367693154869559844831183;
    
    uint256 constant IC4x = 14381632278275491454733551438059761643253582687536284462920350647287073126817;
    uint256 constant IC4y = 14823985165837034859254520683016322640783231019809121812600711785852273166108;
    
    uint256 constant IC5x = 16790879009575318221954224842324031534536849545047916454607058538194724276745;
    uint256 constant IC5y = 6899814906212521666943103904395568640983758257879132097464129073206566126873;
    
    uint256 constant IC6x = 8018893499351236263103155285420032758820796440251410495471541816315495266277;
    uint256 constant IC6y = 4762898927554697058046729761410725160386295046666187561218166645241266489872;
    
    uint256 constant IC7x = 2077665499933989871395901398270067713684599048254726261637808647152187513748;
    uint256 constant IC7y = 6645012713224753527444993508873936964659179606799301448287822376656176150474;
    
    uint256 constant IC8x = 21310265414724367103657686595975716121777979372889010619048140799543879599363;
    uint256 constant IC8y = 18020192422922234349073163820329272314687512021497633628908475759070524238330;
    
    uint256 constant IC9x = 21745711951983953323143648715757143291929632148515174524254308490186139094942;
    uint256 constant IC9y = 8231097676639530057501848745731491430367422729950269437691529859914575582399;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[9] calldata _pubSignals) public view returns (bool) {
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
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
