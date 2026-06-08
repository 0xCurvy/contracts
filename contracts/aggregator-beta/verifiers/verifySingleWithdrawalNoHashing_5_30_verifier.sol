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

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 5536961424349605363383079547834611253624935346741365152390207162977808438105;
    uint256 constant alphay  = 13749772433678562890434706129279731963579090160098144777544884938702902460905;
    uint256 constant betax1  = 21539144462070221725621821341946015576120326175803871011603493357885994907466;
    uint256 constant betax2  = 5659603644554161095501694178056314059115677161743536207249127883485320545673;
    uint256 constant betay1  = 4691131688626697606942741238721459887528066028578159700157092274086067572295;
    uint256 constant betay2  = 16115943434355504249774741471862784324432072875945868252002541330617450807010;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 14692817107931602404098963370361182756508991078012062307924207768827368011035;
    uint256 constant deltax2 = 21741390563726943828192050842765425482728323016271391275150067388173968478204;
    uint256 constant deltay1 = 11224379380758683004573192656678606534957150421617547135549318963484849901925;
    uint256 constant deltay2 = 8753628137256007321376070702957484117858282234887666000576423363826145825156;

    
    uint256 constant IC0x = 18211132557641931574610632571630814333148282283086271606274817535649227359407;
    uint256 constant IC0y = 8422153989316746831406582534048839740217438217100787535451554869482117962950;
    
    uint256 constant IC1x = 18077541690670974654936029336670353876552800023899148402567183522689660479211;
    uint256 constant IC1y = 2596753257053666816730484723731072015264594354425032668014386922958903209739;
    
    uint256 constant IC2x = 21671759945312749446242771843364841755783082355545952863305485234118246219371;
    uint256 constant IC2y = 588963967032934912669947797865915848865086334772418543678532051732576264703;
    
    uint256 constant IC3x = 12492832081620259880871231590905614644000554451545798938894417405142378210975;
    uint256 constant IC3y = 9562382846929847493099048416406292411376836845731779823261519257965269829013;
    
    uint256 constant IC4x = 8719843925366952438365085465414024474039885041245128311106915046088629372422;
    uint256 constant IC4y = 6781309666436634922280320964610976399113263838651348799244577914891480787028;
    
    uint256 constant IC5x = 3911507546437008216839311282476604465932931459098441214152644659004931841214;
    uint256 constant IC5y = 8837075732361698533105274810609511889842596318505739063161533559633482387563;
    
    uint256 constant IC6x = 847866614916093112911590602461964397030045478723295439998464061713487998586;
    uint256 constant IC6y = 21810250834155024343741971027420275978956090249886109872799621448050088708362;
    
    uint256 constant IC7x = 12106899436644824932959542125869338945365943178144947373651032392738947000900;
    uint256 constant IC7y = 4236886551479910583161926458287651342061465794081274111544055501835279091097;
    
    uint256 constant IC8x = 13479576637008554049218509512268618146509303982105346535408470680718554197176;
    uint256 constant IC8y = 19425694608557099039882420947455219689423839972104610365956795207048527885546;
    
    uint256 constant IC9x = 12200448484924621049328152281723646726007352537439957463674432744415222064738;
    uint256 constant IC9y = 15110916495683679468527370201499785701396102318051048334094803673365865929200;
    
 
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
