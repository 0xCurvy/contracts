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
    uint256 constant deltax1 = 3931960646357558033528948504385394554914129712951264546305599668113003299633;
    uint256 constant deltax2 = 12176054263866704427308009695266760840461882335344417203995952990629882363554;
    uint256 constant deltay1 = 19602661834591283073725233556310875365246093425529761415291088205933131956189;
    uint256 constant deltay2 = 15618277375099060306375345518035261817937081887223025633736890796275629366807;

    
    uint256 constant IC0x = 15277792427798877850134844018770466299614116036697003269531351113108425625650;
    uint256 constant IC0y = 5962644687673595144624872977720419035987880849737925752542447060139852971634;
    
    uint256 constant IC1x = 15696825264287873212838383494001855221214710190765858489205986082837988043260;
    uint256 constant IC1y = 18479242359193139324721915017839326315328688951583900561210856995515342625939;
    
    uint256 constant IC2x = 2258132513569601710494618516332431449443637952588002472601270473023981306004;
    uint256 constant IC2y = 8982090475974322018060748388570200574090014750685774791028825150509396443393;
    
    uint256 constant IC3x = 3368763521628713814293363525731539860283862839346733892240259733769733535666;
    uint256 constant IC3y = 15066813087348373321219867692424097295021182553645046737771960042604589629368;
    
    uint256 constant IC4x = 7649566217482896816302663669907004880041596905233390357359612886891344981002;
    uint256 constant IC4y = 3548534468829853175311919258317230601617517035766711505675317139687274696658;
    
    uint256 constant IC5x = 12097625279242972315512519008112479622261185231345873981138112945461325649185;
    uint256 constant IC5y = 15018005859845463110075792069588582110176693222862309067502920188669233481202;
    
    uint256 constant IC6x = 5187150504537904425539702739083902803232585195492837276120145231935980594757;
    uint256 constant IC6y = 10092409195699048210064949922156843170321111109203204184514465970196679403627;
    
    uint256 constant IC7x = 18970725767701014136493241860845656658865400374079765738465968203467608484306;
    uint256 constant IC7y = 15410081387501273752689386269461301628619393871032250039749880578788934728821;
    
    uint256 constant IC8x = 13889852828105282400397232603809609101440418874444696675450525474401200772725;
    uint256 constant IC8y = 285895990058237936821291602937882485015450558522110253912251824490256930764;
    
    uint256 constant IC9x = 19843290995191081902765005032239785064713547639114787192237936455516618425587;
    uint256 constant IC9y = 7260380275670566115100198485785841207527979872437289029037217954152295215267;
    
    uint256 constant IC10x = 1943417597191442068007237016180418325412418606368111192986042390409830518544;
    uint256 constant IC10y = 20806579218456619242731931266942018211342139737398699365184569868255035438193;
    
    uint256 constant IC11x = 18763537375278224935831881693442711986372328091414959887032690995180506375017;
    uint256 constant IC11y = 8867822532890959745404211527073989441686297637554393667379312548784831287118;
    
    uint256 constant IC12x = 13295206105613164450081635517594543665140755658202816177352457886392051350756;
    uint256 constant IC12y = 10544945988246828166985006844584139385944868464432821220600334443707578399939;
    
    uint256 constant IC13x = 5995438046082017073334673922857542041577407955369854738266727316684477614797;
    uint256 constant IC13y = 19600259987113008421318628154657283737905429646796206091072965661760502200883;
    
    uint256 constant IC14x = 4963311788967615450148771264690203469881545936415848158487874663857346337873;
    uint256 constant IC14y = 35332650301075777217202207256623724862092108809905754770338460257605831909;
    
 
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
