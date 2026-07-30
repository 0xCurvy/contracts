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

contract CurvyAggregationVerifierAlpha_2_2_2_30 {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 1636846776518434317996733932951972378772913817912419917762768475702381471734;
    uint256 constant alphay  = 2557859348676819025385346933609180330308687626659434893060052940731235849018;
    uint256 constant betax1  = 6486908244102514188758219539984059501831627243372326134761579522465959290266;
    uint256 constant betax2  = 20982554991654900079360939570217720062255973982399814758284443662932208191129;
    uint256 constant betay1  = 19182644467787183843647819985681434389712148315951713380764435963668492288076;
    uint256 constant betay2  = 12406681655195816859272397663108739861438627022123343846745568062489563457825;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 9747844980327646408377936853901576964882208162979095558491855258874644032428;
    uint256 constant deltax2 = 16756406287301157016584371495328426384230959009782353619418027108198900859045;
    uint256 constant deltay1 = 12031563974052658626813022123817729103548385673602489380797509408050168362251;
    uint256 constant deltay2 = 13429401639598153332715865509706776334046884142780191754811231453515278136324;

    
    uint256 constant IC0x = 17399625455729226858193731763381735313995214152427932693079209346443273813361;
    uint256 constant IC0y = 12859111834604210549529111813676435741477721204446408540561580131023612373119;
    
    uint256 constant IC1x = 19269508121721386291058841803585817118599674808849286017476018587604958075748;
    uint256 constant IC1y = 9739083346977226558755028796693364133601235625996618276883249540221132637793;
    
    uint256 constant IC2x = 4906510788248149510349692841186321223500356486988078983311568678766686617420;
    uint256 constant IC2y = 6556693659005449888057044633727477467849788892491025455409405901466816779011;
    
    uint256 constant IC3x = 14044972721113237465916458767885969838881931162770098020949856358124091314799;
    uint256 constant IC3y = 14117139287964659766273454103382038851225246363664392925580043228576662736937;
    
    uint256 constant IC4x = 3012371627291579470375119311705692169706993162491904502205704114402133122481;
    uint256 constant IC4y = 11314079418441590611909244855959271743770501270574709172645731877756340642847;
    
    uint256 constant IC5x = 12014747518500042396257254926854732905212065822893454718881040190806844834766;
    uint256 constant IC5y = 9147262807133758476810323056110110965120211575681576794111913832114045819253;
    
    uint256 constant IC6x = 17208228463546580386283793027479680747415863706121256054456908792476918249987;
    uint256 constant IC6y = 15455064688675952318632388873661983654124978426049461390082396053486080921802;
    
    uint256 constant IC7x = 11890869179344231511453890841634284101019213344221032352195689057090808444836;
    uint256 constant IC7y = 1686632724578012404026531741296202004554825601863464229764451159902739394058;
    
    uint256 constant IC8x = 19740126978733293930114609559282015871184836365480012469082695053739727687465;
    uint256 constant IC8y = 12529311631088881627469970608969522997871884804075518341540042128460362543503;
    
    uint256 constant IC9x = 10097827894510155216618449121665995035774394468628598818421588397182493478809;
    uint256 constant IC9y = 9726499558835181108437959744805754000607141454601461826622961981576422672141;
    
    uint256 constant IC10x = 1105597600508673395153704990296305545165923034140397026472508603328041426472;
    uint256 constant IC10y = 13934527933778711255168756830771167066267892265285651597997494803168274058956;
    
    uint256 constant IC11x = 10556009619270442534492625284926806630007434804571327583511131615527605130705;
    uint256 constant IC11y = 693363830989493332783658305850455646188088196371520355545151751865010014079;
    
    uint256 constant IC12x = 8534554792067915579614604389696182629499240739879062333502112419263796212856;
    uint256 constant IC12y = 7072896253070058670565264175517999411490551474277670667755271140222925088212;
    
    uint256 constant IC13x = 16851058908720463266568610634766740724322613878197515393707044621237493592474;
    uint256 constant IC13y = 2921798703043006803004466566848382014657571511688478540130957201734680757760;
    
    uint256 constant IC14x = 7620393642241690544543596497893247026112057615774774075422598527638630237828;
    uint256 constant IC14y = 15268439033903233729000463443675295853249877185817343709378544191244820858078;
    
 
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
