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

contract CurvyAggregationVerifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 10836818490634473748810626217656420567497611652829427788816876291655878061880;
    uint256 constant alphay  = 19592557294703635441720550325614868352753510476494830041649519998296273581264;
    uint256 constant betax1  = 2752341048559771983195772862858294317736863257256041710711081910575247422768;
    uint256 constant betax2  = 9826333155562493365212222126579590648800651794940684025275309064976384210080;
    uint256 constant betay1  = 16077258703357503886012982016198935205232932528577536718488856615641627642164;
    uint256 constant betay2  = 3871366386588539348769067597142190409258468194405874387375929962459989586389;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 19802886538023662848965973532373572163507641418769737446698688827596962273527;
    uint256 constant deltax2 = 10561672771038369343625382478789002610673159655781418738340371677501503215257;
    uint256 constant deltay1 = 333485058367506998212883076883777110073570132884553211208658878419310049619;
    uint256 constant deltay2 = 19312226915195897803445164760527794036696922340565072975646070813203924109303;

    
    uint256 constant IC0x = 21700362528224288873748961160353489977846957204093322871955261965526333574069;
    uint256 constant IC0y = 2544999834739603862609302962752337652129222500580881969025971869296090242939;
    
    uint256 constant IC1x = 8658164718980363606797750351151172198618190813624634949499311400230597040893;
    uint256 constant IC1y = 14040632331379373779823489245911370794772291676038836396383135665298762942865;
    
    uint256 constant IC2x = 21426805980602392882100317375119023004997655859625660229064946417555224682928;
    uint256 constant IC2y = 20084141888142537605320430967837480881190516660198425026748604235431679505074;
    
    uint256 constant IC3x = 17056752938670749151605229021681176231526961765895567450764230091439313701794;
    uint256 constant IC3y = 6097510779288168552533318817350593902427670540968402081649418497474509638179;
    
    uint256 constant IC4x = 19134611568564825735542048287661976022522151862620989578076569869559995755231;
    uint256 constant IC4y = 18107930029411901959093209914065080297382056527313763032248270989282017557641;
    
    uint256 constant IC5x = 5953221870532566426388643715826525225925662592559249174022122816633045669619;
    uint256 constant IC5y = 8006172289778493651950225308900266772503315754034969201559017839254569654769;
    
    uint256 constant IC6x = 2172098891282270991348311804843541800279054944544854731652044071809267647359;
    uint256 constant IC6y = 8535893741884818871772789701207228935487766466013848267505251246545795861063;
    
    uint256 constant IC7x = 1000862523584239947985927862111091543592681285153024991710167725076783324571;
    uint256 constant IC7y = 5543523222313759171661795423244270806980956973445596416374864017438462836302;
    
    uint256 constant IC8x = 3836941066383754331683092400521946402840862516205347613956276483006170327741;
    uint256 constant IC8y = 21201193209785562457777478545156631627220936301964550257493936597024787535431;
    
    uint256 constant IC9x = 1230030373584262295397828728672148756650454158535661327058210770714229360772;
    uint256 constant IC9y = 1891941179784936411662890712402110059559058327254858946217385331725147996190;
    
    uint256 constant IC10x = 4902359505916727839042628660959338212648221203484130915571806061262009538840;
    uint256 constant IC10y = 637544378535904077235500275980863523659935114639901982891902841660180946354;
    
    uint256 constant IC11x = 17735760372825075586665729128317682112031304335962960299435591037963536714638;
    uint256 constant IC11y = 17211784507615286432212512724347165568656337800891519867610065378156861337850;
    
    uint256 constant IC12x = 4435148574116727640460516130612146387171640879337404197709829002592268271808;
    uint256 constant IC12y = 13828046855898204260698288999844577368634814155992294635831744587360318814897;
    
    uint256 constant IC13x = 7590021633402240264342247293515576618828044702600271078319335927614258463807;
    uint256 constant IC13y = 20481537268492565658186235166955078896946842977607587677647680230705123289295;
    
    uint256 constant IC14x = 510284571213854268787132614620079485149090467850424658680861251465502248901;
    uint256 constant IC14y = 4280717761236014959487718692310001229556803889405061531327858906100284440790;
    
    uint256 constant IC15x = 12668502693837585033643638138090323231894590212224312880204444545879095654532;
    uint256 constant IC15y = 19457788852073369112275392709688380604262152514754445765589031818759545195689;
    
    uint256 constant IC16x = 17832645340359328475005272572635120539953691294245580916542853959697983532729;
    uint256 constant IC16y = 3231908781663024916057944179381309223506528291216017821332093448149497515079;
    
    uint256 constant IC17x = 14634156716815710694904265981921924102604342457438604847837293679186726065319;
    uint256 constant IC17y = 7867711156445474280833644065611779809934956771393968149841137755884263138955;
    
    uint256 constant IC18x = 4443560333002703649150947442905966484421888730753687338415869079522735231942;
    uint256 constant IC18y = 12979213848123113914142351153790485720550942922650854883612627735167715858593;
    
    uint256 constant IC19x = 3405532194898101623901000010238298465572068152078697099533801605743060151729;
    uint256 constant IC19y = 6329568378020610209265748378593508523446018739243622404809471311223329591916;
    
    uint256 constant IC20x = 20629722042820523979499987137343055660171642672558965762532327756659037462848;
    uint256 constant IC20y = 5826180195939241192854316441975159925150966952746817393079700065300171654064;
    
    uint256 constant IC21x = 10202255611515715081736262134113124580071078486161383176286203082398999834566;
    uint256 constant IC21y = 14037913151286294144234762401907112229056636367049673471736571587212976406810;
    
    uint256 constant IC22x = 6364969350041071309046620501629160526179233711725521117766787349568339230703;
    uint256 constant IC22y = 11518329951926245319488993175500358295016038779126070494405470976711967966873;
    
    uint256 constant IC23x = 11146841852857464742168189223584776229130249247095174748140822986636906422645;
    uint256 constant IC23y = 754166105757313256667776524379912844944154820899240715479504516673683308271;
    
    uint256 constant IC24x = 17725272319244253729382743353502395368593075175815554299993836499027539346464;
    uint256 constant IC24y = 5207733708043488446443397181747291794741400799116089233265260425864890929295;
    
    uint256 constant IC25x = 5852005968621565282124796403707743722113802066419804099094043454892712600957;
    uint256 constant IC25y = 14988688817388823957262060613074558447462218374178258823787196431556362128114;
    
    uint256 constant IC26x = 3247386117041721852214882627987286733844961258755435887284159667637562368250;
    uint256 constant IC26y = 12027105387762135782521171173800327446060057155749849379790404852537492385227;
    
    uint256 constant IC27x = 10344980456348215306437086680859558801438266845335756125036433727464533082350;
    uint256 constant IC27y = 6115735932855887102682947713942137446767180179072347846477240477751077132976;
    
    uint256 constant IC28x = 1666244774717105482005668144876525908875410553817619528200524855865999818814;
    uint256 constant IC28y = 17084825725851659946166477692948065670338724558613504092540521596769509958923;
    
    uint256 constant IC29x = 8928933290818933762190534792759069207218747377892926190395682978078517582107;
    uint256 constant IC29y = 6426805612416532531890685194793436047144958132437712118129751688332500013623;
    
    uint256 constant IC30x = 2617409862830476641738591461187796443343922472331008399757154058846039156898;
    uint256 constant IC30y = 21328615647254223506488416586263027152846294084445183122029861597008460050789;
    
    uint256 constant IC31x = 5048067367767669338018054143990937763182965419148086855737552997818878848732;
    uint256 constant IC31y = 4865455730124111166833085154157604682762221774084579900356382581531867685276;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[31] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                

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
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            
            checkField(calldataload(add(_pubSignals, 960)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
